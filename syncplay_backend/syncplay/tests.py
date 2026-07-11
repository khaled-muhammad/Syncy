import uuid

from asgiref.sync import async_to_sync
from channels.testing import WebsocketCommunicator
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
