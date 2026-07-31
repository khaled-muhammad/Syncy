import uuid

from asgiref.sync import async_to_sync, sync_to_async
from channels.testing.websocket import WebsocketCommunicator
from django.test import TransactionTestCase, override_settings

from syncplay_backend.asgi import application
from .models import Message, Room, User


@override_settings(
    CHANNEL_LAYERS={
        'default': {'BACKEND': 'channels.layers.InMemoryChannelLayer'}
    }
)
class ReliableWebSocketTests(TransactionTestCase):
    reset_sequences = True

    def setUp(self):
        self.user_id = uuid.uuid4()
        self.room = Room.objects.create(name='Test room', host_id=self.user_id)
        self.user = User.objects.create(
            id=self.user_id,
            room=self.room,
            name='Alice',
            is_host=True,
            is_online=False,
        )

    async def receive_types(self, communicator, expected):
        received = {}
        while set(received) != set(expected):
            message = await communicator.receive_json_from(timeout=2)
            if message['type'] in expected:
                received[message['type']] = message
        return received

    def test_playback_is_precise_revisioned_and_restored_on_reconnect(self):
        async_to_sync(self._playback_reconnect_scenario)()
        self.room.refresh_from_db()
        self.assertEqual(self.room.playback_revision, 1)
        self.assertEqual(round(self.room.current_position.total_seconds() * 1000), 1234)
        self.assertFalse(User.objects.get(id=self.user_id).is_online)

    def test_heartbeat_can_refresh_authoritative_playback_state(self):
        async_to_sync(self._heartbeat_refresh_scenario)()

    async def _heartbeat_refresh_scenario(self):
        socket = WebsocketCommunicator(
            application, f'/ws/room/{self.room.id}/'
        )
        await socket.connect()
        await socket.send_json_to(self.join_envelope())
        await self.receive_types(socket, {'user_joined', 'room_update', 'ack'})

        await socket.send_json_to(
            {
                'type': 'pause',
                'userId': str(self.user_id),
                'eventId': str(uuid.uuid4()),
                'data': {'positionMs': 4321},
            }
        )
        await self.receive_types(socket, {'pause', 'ack'})

        await socket.send_json_to(
            {
                'type': 'heartbeat',
                'userId': str(self.user_id),
                'data': {'requestState': True},
            }
        )
        events = await self.receive_types(socket, {'room_update', 'heartbeat'})
        state = events['room_update']['data']
        self.assertFalse(state['is_playing'])
        self.assertEqual(state['position_ms'], 4321)
        self.assertEqual(state['playback_revision'], 1)
        await socket.disconnect()

    async def _playback_reconnect_scenario(self):
        socket = WebsocketCommunicator(
            application, f'/ws/room/{self.room.id}/'
        )
        connected, _ = await socket.connect()
        self.assertTrue(connected)
        await socket.send_json_to(self.join_envelope())
        await self.receive_types(socket, {'user_joined', 'room_update', 'ack'})

        event_id = str(uuid.uuid4())
        await socket.send_json_to(
            {
                'type': 'play',
                'userId': str(self.user_id),
                'eventId': event_id,
                'data': {'positionMs': 1234},
            }
        )
        events = await self.receive_types(socket, {'play', 'ack'})
        self.assertEqual(events['play']['data']['position_ms'], 1234)
        self.assertEqual(events['play']['data']['playback_revision'], 1)
        await socket.disconnect()

        reconnected = WebsocketCommunicator(
            application, f'/ws/room/{self.room.id}/'
        )
        connected, _ = await reconnected.connect()
        self.assertTrue(connected)
        await reconnected.send_json_to(self.join_envelope())
        events = await self.receive_types(
            reconnected, {'user_joined', 'room_update', 'ack'}
        )
        state = events['room_update']['data']
        self.assertTrue(state['is_playing'])
        self.assertEqual(state['position_ms'], 1234)
        self.assertEqual(state['playback_revision'], 1)
        await reconnected.disconnect()

    def test_chat_is_idempotent_and_included_in_reconnect_history(self):
        event_id = str(uuid.uuid4())
        async_to_sync(self._chat_reconnect_scenario)(event_id)
        self.assertEqual(Message.objects.filter(id=event_id).count(), 1)

    def test_typing_and_reactions_are_broadcast_with_stable_event_identity(self):
        async_to_sync(self._ephemeral_events_scenario)()
        self.assertFalse(
            Message.objects.filter(message_type__in=['typing', 'reaction']).exists()
        )

    def test_countdown_and_rating_are_broadcast_as_ephemeral_room_events(self):
        async_to_sync(self._countdown_and_rating_scenario)()
        self.assertFalse(
            Message.objects.filter(message_type__in=['countdown', 'rating']).exists()
        )

    async def _countdown_and_rating_scenario(self):
        socket = WebsocketCommunicator(
            application, f'/ws/room/{self.room.id}/'
        )
        await socket.connect()
        await socket.send_json_to(self.join_envelope())
        await self.receive_types(socket, {'user_joined', 'room_update', 'ack'})

        countdown_id = str(uuid.uuid4())
        await socket.send_json_to(
            {
                'type': 'countdown',
                'userId': str(self.user_id),
                'eventId': countdown_id,
                'data': {'seconds': 3},
            }
        )
        events = await self.receive_types(socket, {'countdown', 'ack'})
        self.assertEqual(events['countdown']['eventId'], countdown_id)
        self.assertEqual(events['countdown']['data']['seconds'], 3)
        self.assertIn('endsAt', events['countdown']['data'])

        rating_id = str(uuid.uuid4())
        await socket.send_json_to(
            {
                'type': 'rating',
                'userId': str(self.user_id),
                'eventId': rating_id,
                'data': {'rating': 5},
            }
        )
        events = await self.receive_types(socket, {'rating', 'ack'})
        self.assertEqual(events['rating']['eventId'], rating_id)
        self.assertEqual(events['rating']['data']['rating'], 5)
        self.assertEqual(events['rating']['data']['userName'], 'Alice')
        await socket.disconnect()

    async def _ephemeral_events_scenario(self):
        socket = WebsocketCommunicator(
            application, f'/ws/room/{self.room.id}/'
        )
        connected, _ = await socket.connect()
        self.assertTrue(connected)
        await socket.send_json_to(self.join_envelope())
        await self.receive_types(socket, {'user_joined', 'room_update', 'ack'})

        typing_id = str(uuid.uuid4())
        await socket.send_json_to(
            {
                'type': 'typing',
                'userId': str(self.user_id),
                'eventId': typing_id,
                'data': {'isTyping': True, 'userName': 'Spoofed'},
            }
        )
        events = await self.receive_types(socket, {'typing', 'ack'})
        self.assertEqual(events['typing']['eventId'], typing_id)
        self.assertTrue(events['typing']['data']['isTyping'])
        self.assertEqual(events['typing']['data']['userName'], 'Alice')

        reaction_id = str(uuid.uuid4())
        await socket.send_json_to(
            {
                'type': 'reaction',
                'userId': str(self.user_id),
                'eventId': reaction_id,
                'data': {'emoji': '🔥', 'userName': 'Spoofed'},
            }
        )
        events = await self.receive_types(socket, {'reaction', 'ack'})
        self.assertEqual(events['reaction']['eventId'], reaction_id)
        self.assertEqual(events['reaction']['data']['emoji'], '🔥')
        self.assertEqual(events['reaction']['data']['userName'], 'Alice')
        await socket.disconnect()

    def test_host_media_change_resets_and_broadcasts_room_state(self):
        async_to_sync(self._media_change_scenario)()
        self.room.refresh_from_db()
        self.assertEqual(self.room.current_video_title, 'New movie.mp4')
        self.assertFalse(self.room.is_playing)
        self.assertEqual(self.room.playback_revision, 1)

    async def _media_change_scenario(self):
        socket = WebsocketCommunicator(
            application, f'/ws/room/{self.room.id}/'
        )
        await socket.connect()
        await socket.send_json_to(self.join_envelope())
        await self.receive_types(socket, {'user_joined', 'room_update', 'ack'})
        await socket.send_json_to(
            {
                'type': 'video_changed',
                'userId': str(self.user_id),
                'eventId': str(uuid.uuid4()),
                'data': {'videoTitle': 'New movie.mp4'},
            }
        )
        events = await self.receive_types(socket, {'video_changed', 'ack'})
        self.assertEqual(
            events['video_changed']['data']['current_video_title'],
            'New movie.mp4',
        )
        self.assertEqual(events['video_changed']['data']['position_ms'], 0)
        await socket.disconnect()

    async def _chat_reconnect_scenario(self, event_id):
        socket = WebsocketCommunicator(
            application, f'/ws/room/{self.room.id}/'
        )
        await socket.connect()
        await socket.send_json_to(self.join_envelope())
        await self.receive_types(socket, {'user_joined', 'room_update', 'ack'})
        chat = {
            'type': 'chat',
            'userId': str(self.user_id),
            'eventId': event_id,
            'data': {'message': 'hello', 'userName': 'Alice'},
        }
        await socket.send_json_to(chat)
        await self.receive_types(socket, {'chat', 'ack'})
        await socket.send_json_to(chat)
        await self.receive_types(socket, {'ack'})
        await socket.disconnect()

        reconnected = WebsocketCommunicator(
            application, f'/ws/room/{self.room.id}/'
        )
        await reconnected.connect()
        await reconnected.send_json_to(self.join_envelope())
        events = await self.receive_types(
            reconnected, {'user_joined', 'room_update', 'ack'}
        )
        history = events['room_update']['data']['messages']
        self.assertEqual([item['id'] for item in history], [event_id])
        await reconnected.disconnect()

    def join_envelope(self):
        return {
            'type': 'join',
            'userId': str(self.user_id),
            'eventId': str(uuid.uuid4()),
            'data': {'userName': 'Alice'},
        }

    def test_create_room_persists_couple_mode(self):
        response = self.client.post(
            '/api/rooms/create/',
            {'room_name': 'Date night', 'user_name': 'Jamie', 'room_mode': 'couple'},
            content_type='application/json',
        )
        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.json()['room']['room_mode'], 'couple')

    def test_room_join_code_is_serialized_and_accepts_formatted_input(self):
        self.assertEqual(len(self.room.join_code), 8)
        self.assertNotIn('0', self.room.join_code)
        self.assertNotIn('O', self.room.join_code)
        self.assertNotIn('1', self.room.join_code)
        self.assertNotIn('I', self.room.join_code)

        response = self.client.post(
            '/api/rooms/join/',
            {
                'room_id': self.room.display_join_code.lower(),
                'user_name': 'Bob',
            },
            content_type='application/json',
        )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()['room']['join_code'], self.room.join_code)
        self.assertEqual(response.json()['room']['id'], str(self.room.id))

    def test_join_room_keeps_accepting_legacy_uuid(self):
        response = self.client.post(
            '/api/rooms/join/',
            {'room_id': str(self.room.id), 'user_name': 'Bob'},
            content_type='application/json',
        )
        self.assertEqual(response.status_code, 200)

    def test_leave_preserves_membership_for_one_tap_rejoin(self):
        response = self.client.delete(
            f'/api/rooms/{self.room.id}/leave/',
            {'user_id': str(self.user.id)},
            content_type='application/json',
        )

        self.assertEqual(response.status_code, 200)
        self.user.refresh_from_db()
        self.assertFalse(self.user.is_online)

        rejoin = self.client.post(
            '/api/rooms/join/',
            {'room_id': self.room.join_code, 'user_name': self.user.name},
            content_type='application/json',
        )
        self.assertEqual(rejoin.status_code, 200)
        self.assertEqual(rejoin.json()['user']['id'], str(self.user.id))
        self.assertTrue(rejoin.json()['user']['is_host'])

    def test_locked_room_rejects_new_people_but_allows_members_to_rejoin(self):
        self.room.is_locked = True
        self.room.save(update_fields=['is_locked', 'updated_at'])

        blocked = self.client.post(
            '/api/rooms/join/',
            {'room_id': self.room.join_code, 'user_name': 'Bob'},
            content_type='application/json',
        )
        self.assertEqual(blocked.status_code, 403)

        rejoin = self.client.post(
            '/api/rooms/join/',
            {'room_id': self.room.join_code, 'user_name': self.user.name},
            content_type='application/json',
        )
        self.assertEqual(rejoin.status_code, 200)

    def test_room_permissions_are_serialized(self):
        self.room.is_locked = True
        self.room.seek_permission = 'selected'
        self.room.save(
            update_fields=['is_locked', 'seek_permission', 'updated_at']
        )
        self.user.can_seek = True
        self.user.save(update_fields=['can_seek', 'last_seen'])

        response = self.client.get(f'/api/rooms/{self.room.id}/')
        payload = response.json()['room']
        self.assertTrue(payload['is_locked'])
        self.assertEqual(payload['seek_permission'], 'selected')
        self.assertTrue(payload['users'][0]['can_seek'])

    def test_selected_participant_seek_is_enforced_over_websocket(self):
        async_to_sync(self._selected_seek_scenario)()

    async def _selected_seek_scenario(self):
        self.room.seek_permission = 'selected'
        await sync_to_async(self.room.save)(
            update_fields=['seek_permission', 'updated_at']
        )
        bob = await sync_to_async(User.objects.create)(
            room=self.room,
            name='Bob',
            is_online=False,
        )
        socket = WebsocketCommunicator(
            application, f'/ws/room/{self.room.id}/'
        )
        await socket.connect()
        await socket.send_json_to(
            {
                'type': 'join',
                'userId': str(bob.id),
                'eventId': str(uuid.uuid4()),
                'data': {'userName': 'Bob'},
            }
        )
        await self.receive_types(socket, {'user_joined', 'room_update', 'ack'})

        await socket.send_json_to(
            {
                'type': 'seek',
                'userId': str(bob.id),
                'eventId': str(uuid.uuid4()),
                'data': {'positionMs': 5000},
            }
        )
        denied = await self.receive_types(socket, {'error', 'room_update'})
        self.assertIn('not allowed', denied['error']['data']['error'])

        bob.can_seek = True
        await sync_to_async(bob.save)(update_fields=['can_seek', 'last_seen'])
        await socket.send_json_to(
            {
                'type': 'seek',
                'userId': str(bob.id),
                'eventId': str(uuid.uuid4()),
                'data': {'positionMs': 5000},
            }
        )
        allowed = await self.receive_types(socket, {'seek', 'ack'})
        self.assertEqual(allowed['seek']['data']['position_ms'], 5000)
        await socket.disconnect()
