# canteen/views.py
from django.shortcuts import render

# Existing views ...

# Merchant Dashboard view
def merchant_dashboard(request):
    return render(request, 'merchant/home.html')

