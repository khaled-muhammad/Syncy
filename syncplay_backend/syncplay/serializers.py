from rest_framework import serializers
from .models import Room, User, Message
import uuid

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'name', 'is_host', 'is_online', 'joined_at']
        read_only_fields = ['id', 'joined_at']

class RoomSerializer(serializers.ModelSerializer):
    users = UserSerializer(many=True, read_only=True)
    user_count = serializers.ReadOnlyField()
    
    class Meta:
        model = Room
        fields = [
            'id', 'name', 'host_id', 'current_video_url', 
            'current_video_title', 'current_position', 
            'is_playing', 'created_at', 'users', 'user_count'
        ]
        read_only_fields = ['id', 'created_at']

class CreateRoomSerializer(serializers.Serializer):
    room_name = serializers.CharField(max_length=100)
    user_name = serializers.CharField(max_length=50)
    
    def validate_room_name(self, value):
        if len(value.strip()) < 3:
            raise serializers.ValidationError("Room name must be at least 3 characters long.")
        return value.strip()
    
    def validate_user_name(self, value):
        if len(value.strip()) < 2:
            raise serializers.ValidationError("User name must be at least 2 characters long.")
        return value.strip()

class JoinRoomSerializer(serializers.Serializer):
    room_id = serializers.UUIDField()
    user_name = serializers.CharField(max_length=50)
    
    def validate_user_name(self, value):
        if len(value.strip()) < 2:
            raise serializers.ValidationError("User name must be at least 2 characters long.")
        return value.strip()
    
    def validate_room_id(self, value):
        try:
            room = Room.objects.get(id=value)
        except Room.DoesNotExist:
            raise serializers.ValidationError("Room not found.")
        return value

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