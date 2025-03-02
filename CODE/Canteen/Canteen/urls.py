# my_project/urls.py
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path("admin/", admin.site.urls),
    path("", include('home.urls')),  # Includes home and other app URLs
    path("customer/", include('customer.urls')),  # Customer section
    path("merchant/", include('merchant.urls')),  # Merchant section
]
