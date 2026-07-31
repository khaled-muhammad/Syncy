from django.db import IntegrityError, models, transaction
from django.utils import timezone
import secrets
import uuid


JOIN_CODE_ALPHABET = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ'
JOIN_CODE_LENGTH = 8


def generate_join_code():
    """Return a readable code without ambiguous 0/O or 1/I characters."""
    return ''.join(
        secrets.choice(JOIN_CODE_ALPHABET) for _ in range(JOIN_CODE_LENGTH)
    )


def normalize_join_code(value):
    return ''.join(character for character in str(value).upper() if character.isalnum())


class Room(models.Model):
    """Model representing a SyncPlay room"""
    ROOM_MODES = [
        ('friends', 'Friends'),
        ('couple', 'Couple'),
        ('party', 'Party'),
        ('horror', 'Horror'),
        ('roast', 'Roast'),
        ('movieClub', 'Movie Club'),
    ]
    SEEK_PERMISSIONS = [
        ('host', 'Host only'),
        ('everyone', 'Everyone'),
        ('selected', 'Selected participants'),
    ]
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    join_code = models.CharField(
        max_length=JOIN_CODE_LENGTH,
        unique=True,
        db_index=True,
        editable=False,
    )
    is_locked = models.BooleanField(default=False)
    seek_permission = models.CharField(
        max_length=10,
        choices=SEEK_PERMISSIONS,
        default='everyone',
    )
    name = models.CharField(max_length=100)
    room_mode = models.CharField(max_length=16, choices=ROOM_MODES, default='friends')
    host_id = models.UUIDField()
    current_video_url = models.URLField(blank=True, null=True)
    current_video_title = models.CharField(max_length=255, blank=True, null=True)
    current_position = models.DurationField(default=timezone.timedelta)
    is_playing = models.BooleanField(default=False)
    playback_revision = models.PositiveBigIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"Room: {self.name} ({self.id})"

    def save(self, *args, **kwargs):
        if self.join_code:
            self.join_code = normalize_join_code(self.join_code)
            return super().save(*args, **kwargs)

        # The unique constraint is the final authority. Retrying inside a
        # savepoint also handles the extremely unlikely concurrent collision.
        for _ in range(10):
            self.join_code = generate_join_code()
            try:
                with transaction.atomic():
                    return super().save(*args, **kwargs)
            except IntegrityError:
                self.join_code = ''
        raise RuntimeError('Could not allocate a unique room join code.')

    @classmethod
    def resolve_reference(cls, value):
        """Resolve either a legacy UUID or a formatted human join code."""
        raw_value = str(value).strip()
        try:
            return cls.objects.filter(id=uuid.UUID(raw_value)).first()
        except (ValueError, AttributeError):
            join_code = normalize_join_code(raw_value)
            if len(join_code) != JOIN_CODE_LENGTH:
                return None
            return cls.objects.filter(join_code=join_code).first()

    @property
    def display_join_code(self):
        return f'{self.join_code[:4]}-{self.join_code[4:]}'
    
    @property
    def user_count(self):
        return self.users.count()
    
    def to_dict(self):
        return {
            'id': str(self.id),
            'join_code': self.join_code,
            'name': self.name,
            'room_mode': self.room_mode,
            'is_locked': self.is_locked,
            'seek_permission': self.seek_permission,
            'host_id': str(self.host_id),
            'current_video_url': self.current_video_url,
            'current_video_title': self.current_video_title,
            'current_position': self.current_position.total_seconds() if self.current_position else 0,
            'position_ms': round(self.current_position.total_seconds() * 1000) if self.current_position else 0,
            'is_playing': self.is_playing,
            'playback_revision': self.playback_revision,
            'playback_updated_at': self.updated_at.isoformat(),
            'server_time': timezone.now().isoformat(),
            'created_at': self.created_at.isoformat(),
            'users': [user.to_dict() for user in self.users.all()],
        }

class User(models.Model):
    """Model representing a user in a room"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    room = models.ForeignKey(Room, on_delete=models.CASCADE, related_name='users')
    name = models.CharField(max_length=50)
    is_host = models.BooleanField(default=False)
    can_seek = models.BooleanField(default=False)
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
            'can_seek': self.can_seek,
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
        ('room_settings', 'Room Settings'),
        ('participant_removed', 'Participant Removed'),
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
