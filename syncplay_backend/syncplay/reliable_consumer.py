import json
import logging
import uuid
from datetime import timedelta

from channels.db import database_sync_to_async
from channels.generic.websocket import AsyncWebsocketConsumer
from django.db import transaction
from django.utils import timezone

from .models import Message, Room, RoomSession, User

logger = logging.getLogger('syncplay')


class ReliableSyncPlayConsumer(AsyncWebsocketConsumer):
    """Room transport with durable membership and authoritative playback state."""

    async def connect(self):
        self.room_id = self.scope['url_route']['kwargs']['room_id']
        self.room_group_name = f'room_{self.room_id}'
        self.user_id = self.user = self.room = None
        await self.channel_layer.group_add(self.room_group_name, self.channel_name)
        await self.accept()

    async def disconnect(self, close_code):
        await self.channel_layer.group_discard(self.room_group_name, self.channel_name)
        became_offline = await self.remove_session_and_update_presence()
        if became_offline and self.user_id:
            await self.channel_layer.group_send(
                self.room_group_name,
                {
                    'type': 'user_left',
                    'user_id': str(self.user_id),
                    'user_name': self.user.name if self.user else 'Unknown',
                },
            )

    async def receive(self, text_data=None, bytes_data=None):
        try:
            data = json.loads(text_data or '')
            kind = data.get('type')
            if kind == 'join':
                await self.handle_join(data)
                return
            if kind == 'heartbeat':
                await self.handle_heartbeat()
                return
            if not await self.require_joined():
                return
            handlers = {
                'play': self.handle_playback,
                'pause': self.handle_playback,
                'seek': self.handle_playback,
                'video_changed': self.handle_video_change,
                'chat': self.handle_chat,
                'reaction': self.handle_reaction,
                'typing': self.handle_typing,
                'leave': self.send_ack,
            }
            handler = handlers.get(kind)
            if not handler:
                await self.send_error(f'Unknown message type: {kind}')
                return
            await handler(data)
        except json.JSONDecodeError:
            await self.send_error('Invalid JSON format')
        except (KeyError, TypeError, ValueError) as exc:
            await self.send_error(str(exc))
        except Exception:
            logger.exception('Failed to process WebSocket message')
            await self.send_error('Internal server error')

    async def handle_join(self, data):
        payload = data.get('data') or {}
        # Normalise the name the same way the HTTP join/create serializers do
        # (they .strip()), otherwise a trailing/leading space makes the stored
        # membership name and the socket name mismatch and the join never binds.
        name = (payload.get('userName') or payload.get('name') or '').strip()
        user_id = data.get('userId') or payload.get('id')
        if not name or not user_id:
            await self.send_error('Missing user name or user ID')
            return
        room, user = await self.join_user(user_id, name)
        if room is None:
            await self.send_error('Room or user not found')
            return
        self.room, self.user, self.user_id = room, user, str(user.id)
        await self.create_session()
        await self.store_message('join', {'userName': user.name}, data)
        await self.channel_layer.group_send(
            self.room_group_name,
            {'type': 'user_joined', 'user': await self.user_to_dict(user)},
        )
        await self.send_room_state()
        await self.send_ack(data)

    async def handle_playback(self, data):
        action = data['type']
        position_ms = self.parse_position_ms(data.get('data') or {})
        state, applied = await self.commit_playback(action, position_ms, data)
        if not applied:
            await self.send_ack(data)
            await self.send_room_state()
            return
        await self.channel_layer.group_send(
            self.room_group_name,
            {'type': 'playback_event', 'action': action, 'state': state},
        )
        await self.send_ack(data)

    async def handle_chat(self, data):
        text = str((data.get('data') or {}).get('message') or '').strip()
        if not text:
            raise ValueError('Chat message cannot be empty')
        event_id = self.parse_event_id(data)
        if event_id and await self.message_exists(event_id):
            await self.send_ack(data)
            return
        stored, created = await self.store_message(
            'chat', {'message': text, 'userName': self.user.name}, data
        )
        if not created:
            await self.send_ack(data)
            return
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'chat_message',
                'message': text,
                'user_id': self.user_id,
                'user_name': self.user.name,
                'timestamp': stored.timestamp.isoformat(),
                'event_id': str(stored.id),
            },
        )
        await self.send_ack(data)

    async def handle_video_change(self, data):
        if not self.user.is_host:
            await self.send_error('Only the host can change media')
            return
        payload = data.get('data') or {}
        title = str(payload.get('videoTitle') or '').strip()
        if not title:
            raise ValueError('Media title cannot be empty')
        # A LAN-hosted room carries a playable stream URL so joiners can watch
        # without the file. A classic local-file room leaves this empty and
        # each peer supplies their own copy.
        video_url = str(payload.get('videoUrl') or '').strip() or None
        state, applied = await self.commit_video_change(title, video_url, data)
        if applied:
            await self.channel_layer.group_send(
                self.room_group_name,
                {'type': 'media_changed_event', 'state': state},
            )
        else:
            await self.send_room_state()
        await self.send_ack(data)

    async def handle_reaction(self, data):
        emoji = str((data.get('data') or {}).get('emoji') or '').strip()
        if not emoji:
            raise ValueError('Reaction cannot be empty')
        event_id = str(self.parse_event_id(data) or uuid.uuid4())
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'reaction_event',
                'event_id': event_id,
                'emoji': emoji,
                'user_id': self.user_id,
                'user_name': self.user.name,
                'timestamp': timezone.now().isoformat(),
            },
        )
        await self.send_ack(data)

    async def handle_typing(self, data):
        is_typing = (data.get('data') or {}).get('isTyping')
        if not isinstance(is_typing, bool):
            raise ValueError('Typing state must be a boolean')
        event_id = str(self.parse_event_id(data) or uuid.uuid4())
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'typing_event',
                'event_id': event_id,
                'is_typing': is_typing,
                'user_id': self.user_id,
                'user_name': self.user.name,
                'timestamp': timezone.now().isoformat(),
            },
        )
        await self.send_ack(data)

    async def handle_heartbeat(self):
        if self.user_id:
            await self.update_session_activity()
        await self.send_json(
            {'type': 'heartbeat', 'data': {'serverTime': timezone.now().isoformat()}}
        )

    async def require_joined(self):
        if self.user_id and self.room:
            return True
        await self.send_error('Join the room before sending events')
        return False

    @staticmethod
    def parse_position_ms(payload):
        raw = payload.get('positionMs')
        if raw is None:
            raw = float(payload.get('position', 0)) * 1000
        value = int(round(float(raw)))
        if value < 0:
            raise ValueError('Playback position cannot be negative')
        return value

    @staticmethod
    def parse_event_id(data):
        raw = data.get('eventId') or data.get('event_id')
        if not raw:
            return None
        try:
            return uuid.UUID(str(raw))
        except ValueError as exc:
            raise ValueError('Invalid event ID') from exc

    async def send_room_state(self):
        await self.send_json({'type': 'room_update', 'data': await self.room_state()})

    async def send_ack(self, data):
        event_id = data.get('eventId') or data.get('event_id')
        if event_id:
            await self.send_json({'type': 'ack', 'data': {'eventId': event_id}})

    async def send_error(self, message):
        await self.send_json({'type': 'error', 'data': {'error': message}})

    async def send_json(self, payload):
        await self.send(text_data=json.dumps(payload))

    async def user_joined(self, event):
        await self.send_json({'type': 'user_joined', 'data': event['user']})

    async def user_left(self, event):
        await self.send_json(
            {
                'type': 'user_left',
                'data': {
                    'id': event['user_id'],
                    'user_id': event['user_id'],
                    'name': event['user_name'],
                },
            }
        )

    async def playback_event(self, event):
        await self.send_json({'type': event['action'], 'data': event['state']})

    async def chat_message(self, event):
        await self.send_json(
            {
                'type': 'chat',
                'eventId': event['event_id'],
                'data': {
                    'message': event['message'],
                    'userId': event['user_id'],
                    'userName': event['user_name'],
                    'timestamp': event['timestamp'],
                },
            }
        )

    async def reaction_event(self, event):
        await self.send_json(
            {
                'type': 'reaction',
                'eventId': event['event_id'],
                'data': {
                    'emoji': event['emoji'],
                    'userId': event['user_id'],
                    'userName': event['user_name'],
                    'timestamp': event['timestamp'],
                },
            }
        )

    async def typing_event(self, event):
        await self.send_json(
            {
                'type': 'typing',
                'eventId': event['event_id'],
                'data': {
                    'isTyping': event['is_typing'],
                    'userId': event['user_id'],
                    'userName': event['user_name'],
                    'timestamp': event['timestamp'],
                },
            }
        )

    async def media_changed_event(self, event):
        await self.send_json({'type': 'video_changed', 'data': event['state']})

    @database_sync_to_async
    def join_user(self, user_id, name):
        try:
            room = Room.objects.get(id=self.room_id)
            user = User.objects.get(id=user_id, room=room, name=name)
        except (Room.DoesNotExist, ValueError):
            return None, None
        except User.DoesNotExist:
            # Durable membership: adopt the existing (room, name) identity even if
            # the client sent a legacy/self-generated user id, or the row is still
            # marked online from a previous socket that did not disconnect cleanly.
            reserved = User.objects.filter(room=room, name=name).first()
            if reserved is None:
                return None, None
            was_host = reserved.is_host
            reserved.delete()
            user = User.objects.create(
                id=user_id,
                room=room,
                name=name,
                is_host=was_host,
                is_online=False,
            )
        user.is_online = True
        user.save(update_fields=['is_online', 'last_seen'])
        return room, user

    @database_sync_to_async
    def create_session(self):
        RoomSession.objects.update_or_create(
            channel_name=self.channel_name,
            defaults={'room': self.room, 'user_id': self.user.id},
        )

    @database_sync_to_async
    def remove_session_and_update_presence(self):
        RoomSession.objects.filter(channel_name=self.channel_name).delete()
        if not self.user_id:
            return False
        if RoomSession.objects.filter(
            room_id=self.room_id, user_id=self.user_id
        ).exists():
            return False
        User.objects.filter(id=self.user_id, room_id=self.room_id).update(
            is_online=False, last_seen=timezone.now()
        )
        return True

    @database_sync_to_async
    def update_session_activity(self):
        RoomSession.objects.filter(channel_name=self.channel_name).update(
            last_activity=timezone.now()
        )
        User.objects.filter(id=self.user_id).update(last_seen=timezone.now())

    @database_sync_to_async
    def commit_playback(self, action, position_ms, envelope):
        with transaction.atomic():
            room = Room.objects.select_for_update().get(id=self.room.id)
            event_id = self.parse_event_id(envelope)
            if event_id and Message.objects.filter(
                id=event_id, room=self.room
            ).exists():
                return room.to_dict(), False
            room.current_position = timedelta(milliseconds=position_ms)
            if action == 'play':
                room.is_playing = True
            elif action == 'pause':
                room.is_playing = False
            room.playback_revision += 1
            room.save(
                update_fields=[
                    'current_position', 'is_playing', 'playback_revision', 'updated_at'
                ]
            )
            Message.objects.create(
                **({'id': event_id} if event_id else {}),
                room=room,
                user_id=self.user_id,
                message_type=action,
                data={
                    'positionMs': position_ms,
                    'revision': room.playback_revision,
                },
            )
            self.room = room
            return room.to_dict(), True

    @database_sync_to_async
    def commit_video_change(self, title, video_url, envelope):
        with transaction.atomic():
            room = Room.objects.select_for_update().get(id=self.room.id)
            event_id = self.parse_event_id(envelope)
            if event_id and Message.objects.filter(id=event_id, room=room).exists():
                return room.to_dict(), False
            room.current_video_url = video_url
            room.current_video_title = title
            room.current_position = timedelta(0)
            room.is_playing = False
            room.playback_revision += 1
            room.save(
                update_fields=[
                    'current_video_url', 'current_video_title', 'current_position',
                    'is_playing', 'playback_revision', 'updated_at',
                ]
            )
            Message.objects.create(
                **({'id': event_id} if event_id else {}),
                room=room,
                user_id=self.user_id,
                message_type='video_changed',
                data={
                    'videoTitle': title,
                    'videoUrl': video_url,
                    'revision': room.playback_revision,
                },
            )
            self.room = room
            return room.to_dict(), True

    @database_sync_to_async
    def message_exists(self, event_id):
        return Message.objects.filter(id=event_id, room=self.room).exists()

    @database_sync_to_async
    def store_message(self, message_type, payload, envelope):
        event_id = self.parse_event_id(envelope)
        values = {
            'room': self.room,
            'user_id': self.user_id,
            'message_type': message_type,
            'data': payload,
        }
        if event_id:
            return Message.objects.get_or_create(id=event_id, defaults=values)
        return Message.objects.create(**values), True

    @database_sync_to_async
    def room_state(self):
        room = Room.objects.prefetch_related('users').get(id=self.room.id)
        state = room.to_dict()
        messages = Message.objects.filter(
            room=room, message_type='chat'
        ).order_by('-timestamp')[:50]
        state['messages'] = [message.to_dict() for message in reversed(messages)]
        return state

    @database_sync_to_async
    def user_to_dict(self, user):
        return user.to_dict()
