import json
import logging
from datetime import timedelta
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from django.utils import timezone
from .models import Room, User, Message, RoomSession

logger = logging.getLogger('syncplay')

class SyncPlayConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.room_id = self.scope['url_route']['kwargs']['room_id']
        self.room_group_name = f'room_{self.room_id}'
        self.user_id = None
        self.user = None
        self.room = None
        
        # Join room group
        await self.channel_layer.group_add(
            self.room_group_name,
            self.channel_name
        )
        
        await self.accept()
        logger.info(f"WebSocket connected to room {self.room_id}")

    async def disconnect(self, close_code):
        # Leave room group
        await self.channel_layer.group_discard(
            self.room_group_name,
            self.channel_name
        )
        
        # Handle user leaving
        if self.user_id and self.room:
            await self.handle_user_leave()
        
        # Remove session
        await self.remove_session()
        
        logger.info(f"WebSocket disconnected from room {self.room_id}")

    async def receive(self, text_data):
        try:
            logger.info(f"🔥 BACKEND RECEIVED: {text_data}")
            data = json.loads(text_data)
            message_type = data.get('type')
            logger.info(f"🔥 MESSAGE TYPE: {message_type}, DATA: {data}")
            
            if message_type == 'join':
                await self.handle_join(data)
            elif message_type == 'play':
                logger.info(f"🎬 HANDLING PLAY MESSAGE: {data}")
                await self.handle_play(data)
            elif message_type == 'pause':
                logger.info(f"⏸️ HANDLING PAUSE MESSAGE: {data}")
                await self.handle_pause(data)
            elif message_type == 'seek':
                await self.handle_seek(data)
            elif message_type == 'video_changed':
                await self.handle_video_change(data)
            elif message_type == 'heartbeat':
                await self.handle_heartbeat(data)
            else:
                logger.error(f"❌ Unknown message type: {message_type}")
                await self.send_error(f"Unknown message type: {message_type}")
                
        except json.JSONDecodeError:
            logger.error(f"❌ Invalid JSON format: {text_data}")
            await self.send_error("Invalid JSON format")
        except Exception as e:
            logger.error(f"❌ Error processing message: {e}")
            await self.send_error("Internal server error")

    async def handle_join(self, data):
        # Fix data parsing to match Flutter message format
        # Flutter sends: {"type": "join", "userId": "...", "data": {"userName": "...", "name": "...", "id": "..."}}
        user_name = data.get('data', {}).get('userName') or data.get('data', {}).get('name')
        user_id = data.get('userId') or data.get('data', {}).get('id')
        
        if not user_name or not user_id:
            await self.send_error("Missing user name or user ID")
            return
        
        try:
            # Get or create room
            self.room = await self.get_room(self.room_id)
            if not self.room:
                await self.send_error("Room not found")
                return
            
            existing_user_by_id = await self.get_user_by_id(self.room, user_id)
            
            if existing_user_by_id:
                self.user = existing_user_by_id
                self.user_id = user_id
            else:
                # Check if user name is already taken
                existing_user = await self.get_user_by_name(self.room, user_name)
                if existing_user:
                    await self.send_error("User name already taken")
                    return
                
                # Create user
                self.user = await self.create_user(self.room, user_id, user_name)
                self.user_id = user_id
            
            # Create session
            await self.create_session()
            
            # Store message
            await self.store_message('join', {'userName': user_name})
            
            # Notify others about new user
            await self.channel_layer.group_send(
                self.room_group_name,
                {
                    'type': 'user_joined',
                    'user': await self.user_to_dict(self.user),
                    'room': await self.room_to_dict(self.room)
                }
            )
            
            # Send room state to the new user
            await self.send(text_data=json.dumps({
                'type': 'room_update',
                'data': await self.room_to_dict(self.room)
            }))
            
            logger.info(f"User {user_name} joined room {self.room_id}")
            
        except Exception as e:
            logger.error(f"Error joining room: {e}")
            await self.send_error("Failed to join room")

    async def handle_play(self, data):
        logger.info(f"🎬 PLAY HANDLER - user_id: {self.user_id}, room: {self.room_id}")
        
        #if not await self.check_host_permission():
        #    logger.warning(f"❌ PLAY denied - user {self.user_id} is not host")
        #    return
        
        # Fix data parsing to match Flutter message format
        position = data['data'].get('position', 0)
        logger.info(f"🎬 PLAY position extracted: {position}")
        
        # Update room state
        await self.update_room_playback(True, position)
        logger.info(f"🎬 Room state updated to playing")
        
        # Store message
        await self.store_message('play', {'position': position})
        
        # Broadcast to all users
        logger.info(f"🎬 Broadcasting PLAY to group: {self.room_group_name}")
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'video_play',
                'position': position,
                'user_id': self.user_id
            }
        )
        logger.info(f"🎬 PLAY broadcast completed")

    async def handle_pause(self, data):
        #if not await self.check_host_permission():
        #    return
        
        # Fix data parsing to match Flutter message format
        position = data['data'].get('position', 0)
        # Update room state
        await self.update_room_playback(False, position)
        
        # Store message
        await self.store_message('pause', {'position': position})
        
        # Broadcast to all users
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'video_pause',
                'position': position,
                'user_id': self.user_id
            }
        )

    async def handle_seek(self, data):
        # if not await self.check_host_permission():
        #     return
        
        # Fix data parsing to match Flutter message format
        print("DATA FOR SEEK:", data)
        position = data['data'].get('position', 0)
        
        # Update room position
        await self.update_room_position(position)
        
        # Store message
        await self.store_message('seek', {'position': position})
        
        # Broadcast to all users
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'video_seek',
                'position': position,
                'user_id': self.user_id
            }
        )

    async def handle_video_change(self, data):
        if not await self.check_host_permission():
            return
        
        # Fix data parsing to match Flutter message format
        video_url = data.get('videoUrl')
        video_title = data.get('videoTitle')
        
        # Update room video
        await self.update_room_video(video_url, video_title)
        
        # Store message
        await self.store_message('video_changed', {
            'videoUrl': video_url,
            'videoTitle': video_title
        })
        
        # Broadcast to all users
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'video_changed',
                'video_url': video_url,
                'video_title': video_title,
                'user_id': self.user_id
            }
        )

    async def handle_heartbeat(self, data):
        # Update last activity
        await self.update_session_activity()
        
        # Send heartbeat response
        await self.send(text_data=json.dumps({
            'type': 'heartbeat',
            'data': {'timestamp': timezone.now().timestamp()}
        }))

    async def handle_user_leave(self):
        if self.user:
            # Remove user from room
            await self.remove_user()
            
            # Store message
            await self.store_message('leave', {})
            
            # Notify others
            await self.channel_layer.group_send(
                self.room_group_name,
                {
                    'type': 'user_left',
                    'user_id': self.user_id,
                    'room': await self.room_to_dict(self.room)
                }
            )

    # Group message handlers
    async def user_joined(self, event):
        await self.send(text_data=json.dumps({
            'type': 'user_joined',
            'data': event['user']
        }))

    async def user_left(self, event):
        await self.send(text_data=json.dumps({
            'type': 'user_left',
            'data': {'user_id': event['user_id']}
        }))

    async def video_play(self, event):
        logger.info(f"🎬 VIDEO_PLAY event received - sender: {event['user_id']}, receiver: {self.user_id}")
        if event['user_id'] != self.user_id:  # Don't send back to sender
            message = {
                'type': 'play',
                'data': {'position': event['position']}
            }
            logger.info(f"🎬 Sending PLAY to client: {message}")
            await self.send(text_data=json.dumps(message))
        else:
            logger.info(f"🎬 Skipping PLAY send to sender")

    async def video_pause(self, event):
        logger.info(f"⏸️ VIDEO_PAUSE event received - sender: {event['user_id']}, receiver: {self.user_id}")
        if event['user_id'] != self.user_id:  # Don't send back to sender
            message = {
                'type': 'pause',
                'data': {'position': event['position']}
            }
            logger.info(f"⏸️ Sending PAUSE to client: {message}")
            await self.send(text_data=json.dumps(message))
        else:
            logger.info(f"⏸️ Skipping PAUSE send to sender")

    async def video_seek(self, event):
        if event['user_id'] != self.user_id:  # Don't send back to sender
            await self.send(text_data=json.dumps({
                'type': 'seek',
                'data': {'position': event['position']}
            }))

    async def video_changed(self, event):
        if event['user_id'] != self.user_id:  # Don't send back to sender
            await self.send(text_data=json.dumps({
                'type': 'video_changed',
                'data': {
                    'videoUrl': event['video_url'],
                    'videoTitle': event['video_title']
                }
            }))

    # Helper methods
    async def send_error(self, message):
        await self.send(text_data=json.dumps({
            'type': 'error',
            'data': {'error': message}
        }))

    async def check_host_permission(self):
        if not self.user or not await self.is_user_host(self.user):
            await self.send_error("Only the host can control playback")
            return False
        return True

    # Database operations
    @database_sync_to_async
    def get_room(self, room_id):
        try:
            return Room.objects.get(id=room_id)
        except Room.DoesNotExist:
            return None

    @database_sync_to_async
    def get_user_by_name(self, room, name):
        try:
            return User.objects.get(room=room, name=name)
        except User.DoesNotExist:
            return None

    @database_sync_to_async
    def get_user_by_id(self, room, name):
        try:
            return User.objects.get(room=room, id=name)
        except User.DoesNotExist:
            return None

    @database_sync_to_async
    def create_user(self, room, user_id, name):
        is_host = not room.users.exists()  # First user becomes host
        return User.objects.create(
            id=user_id,
            room=room,
            name=name,
            is_host=is_host
        )

    @database_sync_to_async
    def remove_user(self):
        if self.user:
            self.user.delete()

    @database_sync_to_async
    def is_user_host(self, user):
        return user.is_host

    @database_sync_to_async
    def update_room_playback(self, is_playing, position):
        self.room.is_playing = is_playing
        self.room.current_position = timedelta(seconds=position)
        self.room.save()

    @database_sync_to_async
    def update_room_position(self, position):
        self.room.current_position = timedelta(seconds=position)
        self.room.save()

    @database_sync_to_async
    def update_room_video(self, video_url, video_title):
        self.room.current_video_url = video_url
        self.room.current_video_title = video_title
        self.room.current_position = timedelta(0)
        self.room.is_playing = False
        self.room.save()

    @database_sync_to_async
    def store_message(self, message_type, data):
        return Message.objects.create(
            room=self.room,
            user_id=self.user_id,
            message_type=message_type,
            data=data
        )

    @database_sync_to_async
    def create_session(self):
        return RoomSession.objects.create(
            room=self.room,
            user_id=self.user_id,
            channel_name=self.channel_name
        )

    @database_sync_to_async
    def remove_session(self):
        RoomSession.objects.filter(channel_name=self.channel_name).delete()

    @database_sync_to_async
    def update_session_activity(self):
        RoomSession.objects.filter(channel_name=self.channel_name).update(
            last_activity=timezone.now()
        )

    @database_sync_to_async
    def room_to_dict(self, room):
        return room.to_dict()

    @database_sync_to_async
    def user_to_dict(self, user):
        return user.to_dict() 
