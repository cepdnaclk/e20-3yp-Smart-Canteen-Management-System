# canteen/merchant_urls.py
from django.urls import path
from . import views

urlpatterns = [
    path('', views.merchant_dashboard, name='merchant_dashboard'),
    # Add other merchant-specific pages here
]
