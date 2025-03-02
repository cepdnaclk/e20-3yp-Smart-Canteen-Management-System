# canteen/customer_urls.py
from django.urls import path
from . import views

urlpatterns = [
    path('', views.home, name='customer_dashboard'),
    # Add other customer-specific pages here
]
