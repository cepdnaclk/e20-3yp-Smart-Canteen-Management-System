from django.urls import path
from . import views

urlpatterns = [
    path('', views.home, name='home-home'),
    path('features/', views.features, name='home-features'),
    path('about_us/', views.about, name='home-about'),
    path('contact_us/', views.contact, name='home-contact'),
    path('privacyPolicy/', views.privacy, name='home-privacy'),
    path('login/', views.login_view, name='login'),
    path('logout/', views.logout_view, name='logout'),
    path('register/', views.register, name='register'),  # Register page URL
]
