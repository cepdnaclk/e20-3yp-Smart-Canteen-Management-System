# home/routing.py
from django.urls import re_path
from .consumers import FingerprintConsumer

websocket_urlpatterns = [
    re_path(r'ws/fingerprint/', FingerprintConsumer.as_asgi()),
]
