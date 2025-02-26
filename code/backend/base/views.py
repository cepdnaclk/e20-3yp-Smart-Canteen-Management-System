# views.py
from django.shortcuts import render, redirect
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.models import User
from django.contrib.auth.decorators import login_required
# views.py
from django.shortcuts import render, get_object_or_404, redirect
from .models import MenuItem  # Assuming you have a MenuItem model


def home(request):
    return render(request, 'home.html')

def user_dashboard(request):
    return render(request, 'user_dashboard.html')

def merchant_dashboard(request):
    return render(request, 'merchant_dashboard.html')

def admin_dashboard(request):
    return render(request, 'admin_dashboard.html')

def login_view(request):
    if request.method == 'POST':
        username = request.POST['username']
        password = request.POST['password']
        user = authenticate(request, username=username, password=password)
        if user is not None:
            login(request, user)
            return redirect('home')
        else:
            return render(request, 'login.html', {'error': 'Invalid credentials'})
    return render(request, 'login.html')

def register_view(request):
    if request.method == 'POST':
        username = request.POST['username']
        email = request.POST['email']
        password = request.POST['password']
        User.objects.create_user(username=username, email=email, password=password)
        return redirect('login')
    return render(request, 'register.html')

def locations(request):
    return render(request, 'locations.html')

def about_us(request):
    return render(request, 'about_us.html')

def privacy_policy(request):
    return render(request, 'privacy_policy.html')

def chat_room(request):
    return render(request, 'chat_room.html')

def support(request):
    if request.method == 'POST':
        issue = request.POST['issue']
        # Save issue to database or send email
        return render(request, 'support.html', {'success': 'Your issue has been submitted.'})
    return render(request, 'support.html')


@login_required
def add_credits(request):
    if request.method == 'POST':
        amount = float(request.POST['amount'])
        # Assuming you have a Profile model with a credit_balance field
        profile = request.user.profile
        profile.credit_balance += amount
        profile.save()
        return render(request, 'add_credits.html', {'success': f'Added ${amount:.2f} to your balance.'})
    return render(request, 'add_credits.html')

@login_required
def menu(request):
    menu_items = MenuItem.objects.all()
    return render(request, 'menu.html', {'menu_items': menu_items})

@login_required
def add_menu_item(request):
    if request.method == 'POST':
        name = request.POST['name']
        price = float(request.POST['price'])
        MenuItem.objects.create(name=name, price=price)
        return redirect('menu')
    return redirect('menu')

@login_required
def edit_menu_item(request, item_id):
    item = get_object_or_404(MenuItem, id=item_id)
    if request.method == 'POST':
        item.name = request.POST['name']
        item.price = float(request.POST['price'])
        item.save()
        return redirect('menu')
    return render(request, 'edit_menu_item.html', {'item': item})

@login_required
def delete_menu_item(request, item_id):
    item = get_object_or_404(MenuItem, id=item_id)
    item.delete()
    return redirect('menu')