from django.urls import path
from . import views

app_name = 'syncplay'

urlpatterns = [
    # Room management
    path('rooms/create/', views.create_room, name='create_room'),
    path('rooms/join/', views.join_room, name='join_room'),
    path('rooms/', views.list_rooms, name='list_rooms'),
    path('rooms/<uuid:room_id>/', views.get_room, name='get_room'),
    path('rooms/<uuid:room_id>/leave/', views.leave_room, name='leave_room'),
    
    # Video control
    path('rooms/<uuid:room_id>/control/', views.control_video, name='control_video'),
    path('rooms/<uuid:room_id>/change-video/', views.change_video, name='change_video'),
    
    # Messages
    path('rooms/<uuid:room_id>/messages/', views.get_room_messages, name='get_room_messages'),
    
    # Health check
    path('health/', views.health_check, name='health_check'),
] 