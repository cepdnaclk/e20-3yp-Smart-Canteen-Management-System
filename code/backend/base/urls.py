# urls.py
from django.urls import path
from . import views

urlpatterns = [
    path('', views.home, name='home'),
    path('user-dashboard/', views.user_dashboard, name='user_dashboard'),
    path('merchant-dashboard/', views.merchant_dashboard, name='merchant_dashboard'),
    path('admin-dashboard/', views.admin_dashboard, name='admin_dashboard'),
    path('login/', views.login_view, name='login'),
    path('register/', views.register_view, name='register'),
    path('locations/', views.locations, name='locations'),
    path('about-us/', views.about_us, name='about_us'),
    path('privacy-policy/', views.privacy_policy, name='privacy_policy'),
    path('chat-room/', views.chat_room, name='chat_room'),
    path('support/', views.support, name='support'),
    path('add-credits/', views.add_credits, name='add_credits'),
    path('menu/', views.menu, name='menu'),
    path('menu/add/', views.add_menu_item, name='add_menu_item'),
    path('menu/edit/<int:item_id>/', views.edit_menu_item, name='edit_menu_item'),
    path('menu/delete/<int:item_id>/', views.delete_menu_item, name='delete_menu_item'),
]