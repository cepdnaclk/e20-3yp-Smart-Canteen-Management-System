# canteen/views.py
from django.shortcuts import render

# Existing views ...

# Customer Dashboard view
def home(request):
    return render(request, 'customer/home.html')
