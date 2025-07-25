from django.db import models
from django.utils import timezone
import uuid

class Room(models.Model):
    """Model representing a SyncPlay room"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=100)
    host_id = models.UUIDField()
    current_video_url = models.URLField(blank=True, null=True)
    current_video_title = models.CharField(max_length=255, blank=True, null=True)
    current_position = models.DurationField(default=timezone.timedelta)
    is_playing = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"Room: {self.name} ({self.id})"
    
    @property
    def user_count(self):
        return self.users.count()
    
    def to_dict(self):
        return {
            'id': str(self.id),
            'name': self.name,
            'host_id': str(self.host_id),
            'current_video_url': self.current_video_url,
            'current_video_title': self.current_video_title,
            'current_position': int(self.current_position.total_seconds()) if self.current_position else 0,
            'is_playing': self.is_playing,
            'created_at': self.created_at.isoformat(),
            'users': [user.to_dict() for user in self.users.all()],
        }

class User(models.Model):
    """Model representing a user in a room"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    room = models.ForeignKey(Room, on_delete=models.CASCADE, related_name='users')
    name = models.CharField(max_length=50)
    is_host = models.BooleanField(default=False)
    is_online = models.BooleanField(default=True)
    joined_at = models.DateTimeField(auto_now_add=True)
    last_seen = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-is_host', 'joined_at']
        unique_together = ['room', 'name']  # Unique name per room
    
    def __str__(self):
        return f"{self.name} in {self.room.name} ({'Host' if self.is_host else 'Member'})"
    
    def to_dict(self):
        return {
            'id': str(self.id),
            'name': self.name,
            'is_host': self.is_host,
            'is_online': self.is_online,
            'joined_at': self.joined_at.isoformat(),
        }

class Message(models.Model):
    """Model for storing synchronization messages"""
    MESSAGE_TYPES = [
        ('join', 'Join'),
        ('leave', 'Leave'),
        ('play', 'Play'),
        ('pause', 'Pause'),
        ('seek', 'Seek'),
        ('video_changed', 'Video Changed'),
        ('room_update', 'Room Update'),
        ('user_joined', 'User Joined'),
        ('user_left', 'User Left'),
        ('error', 'Error'),
        ('heartbeat', 'Heartbeat'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    room = models.ForeignKey(Room, on_delete=models.CASCADE, related_name='messages')
    user_id = models.UUIDField()
    message_type = models.CharField(max_length=20, choices=MESSAGE_TYPES)
    data = models.JSONField(default=dict)
    timestamp = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-timestamp']
    
    def __str__(self):
        return f"{self.message_type} message in {self.room.name} at {self.timestamp}"
    
    def to_dict(self):
        return {
            'id': str(self.id),
            'room_id': str(self.room.id),
            'user_id': str(self.user_id),
            'type': self.message_type,
            'data': self.data,
            'timestamp': self.timestamp.isoformat(),
        }

class RoomSession(models.Model):
    """Model to track active WebSocket connections"""
    room = models.ForeignKey(Room, on_delete=models.CASCADE, related_name='sessions')
    user_id = models.UUIDField()
    channel_name = models.CharField(max_length=255, unique=True)
    connected_at = models.DateTimeField(auto_now_add=True)
    last_activity = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-connected_at']
    
    def __str__(self):
        return f"Session for user {self.user_id} in room {self.room.name}"
