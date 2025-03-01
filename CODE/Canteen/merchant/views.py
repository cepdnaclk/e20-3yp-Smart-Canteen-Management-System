from django.shortcuts import render

def merchant_home(request):
    return render(request,"merchant/home.html")
