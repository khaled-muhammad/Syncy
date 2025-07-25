from django.shortcuts import render
from rest_framework import status
from rest_framework.decorators import api_view
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from django.utils import timezone
from datetime import timedelta
import uuid
import logging

from .models import Room, User, Message
from .serializers import (
    RoomSerializer, CreateRoomSerializer, JoinRoomSerializer,
    VideoControlSerializer, VideoChangeSerializer, RoomStatusSerializer
)

logger = logging.getLogger('syncplay')

@api_view(['POST'])
def create_room(request):
    """Create a new SyncPlay room"""
    serializer = CreateRoomSerializer(data=request.data)
    
    if serializer.is_valid():
        room_name = serializer.validated_data['room_name']
        user_name = serializer.validated_data['user_name']
        
        # Create room
        room = Room.objects.create(
            name=room_name,
            host_id=uuid.uuid4()
        )
        
        # Create host user
        user = User.objects.create(
            id=room.host_id,
            room=room,
            name=user_name,
            is_host=True
        )
        
        logger.info(f"Room '{room_name}' created by {user_name}")
        
        return Response({
            'status': 'success',
            'message': 'Room created successfully',
            'room': RoomSerializer(room).data,
            'user': {
                'id': str(user.id),
                'name': user.name,
                'is_host': user.is_host
            }
        }, status=status.HTTP_201_CREATED)
    
    return Response({
        'status': 'error',
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
def join_room(request):
    """Join an existing SyncPlay room"""
    serializer = JoinRoomSerializer(data=request.data)
    
    if serializer.is_valid():
        room_id = serializer.validated_data['room_id']
        user_name = serializer.validated_data['user_name']
        
        room = get_object_or_404(Room, id=room_id)
        
        # Check if username is already taken in this room
        if User.objects.filter(room=room, name=user_name).exists():
            return Response({
                'status': 'error',
                'message': 'Username already taken in this room'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        logger.info(f"User {user_name} attempting to join room {room.name}")
        
        return Response({
            'status': 'success',
            'message': 'Ready to join room',
            'room': RoomSerializer(room).data,
            'websocket_url': f'/ws/room/{room_id}/'
        }, status=status.HTTP_200_OK)
    
    return Response({
        'status': 'error',
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET'])
def get_room(request, room_id):
    """Get room details"""
    room = get_object_or_404(Room, id=room_id)
    
    return Response({
        'status': 'success',
        'room': RoomSerializer(room).data
    }, status=status.HTTP_200_OK)

@api_view(['GET'])
def list_rooms(request):
    """List all active rooms"""
    # Only show rooms with at least one user that was active in the last hour
    recent_time = timezone.now() - timedelta(hours=1)
    active_rooms = Room.objects.filter(
        users__last_seen__gte=recent_time
    ).distinct().order_by('-created_at')
    
    rooms_data = []
    for room in active_rooms:
        room_data = RoomSerializer(room).data
        rooms_data.append(room_data)
    
    return Response({
        'status': 'success',
        'rooms': rooms_data,
        'count': len(rooms_data)
    }, status=status.HTTP_200_OK)

@api_view(['POST'])
def control_video(request, room_id):
    """Control video playback (host only)"""
    room = get_object_or_404(Room, id=room_id)
    user_id = request.data.get('user_id')
    
    if not user_id:
        return Response({
            'status': 'error',
            'message': 'User ID required'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    # Check if user is host
    user = get_object_or_404(User, id=user_id, room=room)
    if not user.is_host:
        return Response({
            'status': 'error',
            'message': 'Only the host can control video playback'
        }, status=status.HTTP_403_FORBIDDEN)
    
    serializer = VideoControlSerializer(data=request.data)
    if serializer.is_valid():
        action = serializer.validated_data['action']
        position = serializer.validated_data['position']
        
        # Update room state
        if action in ['play', 'pause']:
            room.is_playing = (action == 'play')
            room.current_position = timedelta(seconds=position)
            room.save()
        elif action == 'seek':
            room.current_position = timedelta(seconds=position)
            room.save()
        
        # Store message
        Message.objects.create(
            room=room,
            user_id=user_id,
            message_type=action,
            data={'position': position}
        )
        
        logger.info(f"Video {action} by {user.name} in room {room.name}")
        
        return Response({
            'status': 'success',
            'message': f'Video {action} command sent',
            'room': RoomSerializer(room).data
        }, status=status.HTTP_200_OK)
    
    return Response({
        'status': 'error',
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
def change_video(request, room_id):
    """Change the current video (host only)"""
    room = get_object_or_404(Room, id=room_id)
    user_id = request.data.get('user_id')
    
    if not user_id:
        return Response({
            'status': 'error',
            'message': 'User ID required'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    # Check if user is host
    user = get_object_or_404(User, id=user_id, room=room)
    if not user.is_host:
        return Response({
            'status': 'error',
            'message': 'Only the host can change videos'
        }, status=status.HTTP_403_FORBIDDEN)
    
    serializer = VideoChangeSerializer(data=request.data)
    if serializer.is_valid():
        video_url = serializer.validated_data['video_url']
        video_title = serializer.validated_data['video_title']
        
        # Update room
        room.current_video_url = video_url
        room.current_video_title = video_title
        room.current_position = timedelta(0)
        room.is_playing = False
        room.save()
        
        # Store message
        Message.objects.create(
            room=room,
            user_id=user_id,
            message_type='video_changed',
            data={
                'videoUrl': video_url,
                'videoTitle': video_title
            }
        )
        
        logger.info(f"Video changed to '{video_title}' by {user.name} in room {room.name}")
        
        return Response({
            'status': 'success',
            'message': 'Video changed successfully',
            'room': RoomSerializer(room).data
        }, status=status.HTTP_200_OK)
    
    return Response({
        'status': 'error',
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET'])
def get_room_messages(request, room_id):
    """Get recent messages for a room"""
    room = get_object_or_404(Room, id=room_id)
    
    # Get last 50 messages
    messages = Message.objects.filter(room=room).order_by('-timestamp')[:50]
    
    messages_data = []
    for message in messages:
        messages_data.append({
            'id': str(message.id),
            'user_id': str(message.user_id),
            'type': message.message_type,
            'data': message.data,
            'timestamp': message.timestamp.isoformat()
        })
    
    return Response({
        'status': 'success',
        'messages': list(reversed(messages_data)),  # Return chronological order
        'count': len(messages_data)
    }, status=status.HTTP_200_OK)

@api_view(['DELETE'])
def leave_room(request, room_id):
    """Leave a room"""
    user_id = request.data.get('user_id')
    
    if not user_id:
        return Response({
            'status': 'error',
            'message': 'User ID required'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    room = get_object_or_404(Room, id=room_id)
    user = get_object_or_404(User, id=user_id, room=room)
    
    # Store leave message
    Message.objects.create(
        room=room,
        user_id=user_id,
        message_type='leave',
        data={}
    )
    
    user_name = user.name
    user.delete()
    
    logger.info(f"User {user_name} left room {room.name}")
    
    # If no users left, clean up the room after some time
    if not room.users.exists():
        logger.info(f"Room {room.name} is now empty")
    
    return Response({
        'status': 'success',
        'message': 'Left room successfully'
    }, status=status.HTTP_200_OK)

@api_view(['GET'])
def health_check(request):
    """Health check endpoint"""
    return Response({
        'status': 'healthy',
        'timestamp': timezone.now().isoformat(),
        'version': '1.0.0'
    }, status=status.HTTP_200_OK)
