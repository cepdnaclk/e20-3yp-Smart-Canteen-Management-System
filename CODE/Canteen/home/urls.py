# canteen/urls.py
from django.urls import path
from . import views
from django.urls import re_path
from .consumers import FingerprintConsumer

urlpatterns = [
    path('', views.home, name='home'),
    path('menu/', views.menu, name='menu'),
    path('live-view/', views.live_view, name='live_view'),
    path('features/', views.features, name='features'),
    path('dashboard/', views.dashboard, name='dashboard'),
    path('register/', views.register, name='register'),  # Registration page
    path('login/', views.login_view, name='login'),  # Login page
    path('fingerprint/', views.fingerprint, name='fingerprint'),
]

websocket_urlpatterns = [
    re_path(r'ws/fingerprint/', FingerprintConsumer.as_asgi()),
]