from rest_framework import serializers
from .models import Room, User, Message
import uuid

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'name', 'is_host', 'can_seek', 'is_online', 'joined_at']
        read_only_fields = ['id', 'joined_at']

class RoomSerializer(serializers.ModelSerializer):
    users = UserSerializer(many=True, read_only=True)
    user_count = serializers.ReadOnlyField()
    position_ms = serializers.SerializerMethodField()
    playback_updated_at = serializers.DateTimeField(source='updated_at', read_only=True)
    
    class Meta:
        model = Room
        fields = [
            'id', 'join_code', 'name', 'room_mode', 'is_locked',
            'seek_permission', 'host_id', 'current_video_url',
            'current_video_title', 'current_position', 'position_ms',
            'is_playing', 'playback_revision', 'playback_updated_at',
            'created_at', 'users', 'user_count'
        ]
        read_only_fields = ['id', 'join_code', 'created_at']

    def get_position_ms(self, room):
        return round(room.current_position.total_seconds() * 1000)

class CreateRoomSerializer(serializers.Serializer):
    room_name = serializers.CharField(max_length=100)
    user_name = serializers.CharField(max_length=50)
    room_mode = serializers.ChoiceField(
        choices=['friends', 'couple', 'party', 'horror', 'roast', 'movieClub'],
        default='friends',
    )
    
    def validate_room_name(self, value):
        if len(value.strip()) < 3:
            raise serializers.ValidationError("Room name must be at least 3 characters long.")
        return value.strip()
    
    def validate_user_name(self, value):
        if len(value.strip()) < 2:
            raise serializers.ValidationError("User name must be at least 2 characters long.")
        return value.strip()

class JoinRoomSerializer(serializers.Serializer):
    # Kept as room_id for backwards-compatible clients, but accepts either the
    # original UUID or the new eight-character join code.
    room_id = serializers.CharField(max_length=64)
    user_name = serializers.CharField(max_length=50)
    
    def validate_user_name(self, value):
        if len(value.strip()) < 2:
            raise serializers.ValidationError("User name must be at least 2 characters long.")
        return value.strip()
    
    def validate_room_id(self, value):
        room = Room.resolve_reference(value)
        if room is None:
            raise serializers.ValidationError("Room not found.")
        return room

class MessageSerializer(serializers.ModelSerializer):
    class Meta:
        model = Message
        fields = ['id', 'room', 'user_id', 'message_type', 'data', 'timestamp']
        read_only_fields = ['id', 'timestamp']

class VideoControlSerializer(serializers.Serializer):
    action = serializers.ChoiceField(choices=['play', 'pause', 'seek'])
    position = serializers.IntegerField(min_value=0, help_text="Position in seconds")
    
class VideoChangeSerializer(serializers.Serializer):
    video_url = serializers.URLField()
    video_title = serializers.CharField(max_length=255)

class RoomStatusSerializer(serializers.Serializer):
    room = RoomSerializer()
    user = UserSerializer()
    is_host = serializers.BooleanField()
    message = serializers.CharField()
