# canteen/urls.py
from django.urls import path
from . import views

urlpatterns = [
    path('', views.home, name='home'),
    path('menu/', views.menu, name='menu'),
    path('live-view/', views.live_view, name='live_view'),
    path('features/', views.features, name='features'),
    path('dashboard/', views.dashboard, name='dashboard'),
    path('register/', views.register, name='register'),  # Registration page
    path('login/', views.login_view, name='login'),  # Login page
]
