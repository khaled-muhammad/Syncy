from django.contrib import admin
from .models import Room, User, Message, RoomSession

@admin.register(Room)
class RoomAdmin(admin.ModelAdmin):
    list_display = ['name', 'id', 'host_id', 'user_count', 'is_playing', 'created_at']
    list_filter = ['is_playing', 'created_at']
    search_fields = ['name', 'id', 'host_id']
    readonly_fields = ['id', 'created_at', 'updated_at']
    
    def user_count(self, obj):
        return obj.user_count
    user_count.short_description = 'Users'

@admin.register(User)
class UserAdmin(admin.ModelAdmin):
    list_display = ['name', 'room', 'is_host', 'is_online', 'joined_at']
    list_filter = ['is_host', 'is_online', 'joined_at']
    search_fields = ['name', 'room__name']
    readonly_fields = ['id', 'joined_at']

@admin.register(Message)
class MessageAdmin(admin.ModelAdmin):
    list_display = ['message_type', 'room', 'user_id', 'timestamp']
    list_filter = ['message_type', 'timestamp']
    search_fields = ['room__name', 'user_id']
    readonly_fields = ['id', 'timestamp']
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('room')

@admin.register(RoomSession)
class RoomSessionAdmin(admin.ModelAdmin):
    list_display = ['room', 'user_id', 'channel_name', 'connected_at', 'last_activity']
    list_filter = ['connected_at', 'last_activity']
    search_fields = ['room__name', 'user_id', 'channel_name']
    readonly_fields = ['connected_at']
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('room')

# Customize admin site
admin.site.site_header = 'SyncPlay Administration'
admin.site.site_title = 'SyncPlay Admin'
admin.site.index_title = 'Welcome to SyncPlay Administration'
