from django.urls import re_path
from .reliable_consumer import ReliableSyncPlayConsumer

websocket_urlpatterns = [
    re_path(r'ws/room/(?P<room_id>[0-9a-f-]+)/$', ReliableSyncPlayConsumer.as_asgi()),
]
