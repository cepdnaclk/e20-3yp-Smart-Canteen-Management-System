from django.shortcuts import render, redirect
from django.contrib.auth import authenticate, login, logout
from django.contrib import messages
from django.shortcuts import render, redirect
from django.contrib.auth.forms import UserCreationForm

def home(request):
    return render(request, 'home_home.html')

def features(request):
    return render(request, 'home_features.html')

def about(request):
    return render(request, 'home_about_us.html')

def contact(request):
    return render(request, 'home_contact_locations.html')

def privacy(request):
    return render(request, 'home_privacy.html')

# Login view
def login_view(request):
    if request.method == 'POST':
        username = request.POST['username']
        password = request.POST['password']
        user = authenticate(request, username=username, password=password)
        if user is not None:
            login(request, user)
            return redirect('home-home')
        else:
            messages.error(request, 'Invalid credentials')
    return render(request, 'login.html')

# Logout view
def logout_view(request):
    logout(request)
    return redirect('home-home')




def register(request):
    if request.method == 'POST':
        form = UserCreationForm(request.POST)
        if form.is_valid():
            form.save()
            messages.success(request, 'Your account has been created successfully. You can now log in.')
            return redirect('login')  # Redirect to login page after successful registration
        else:
            messages.error(request, 'There was an error with your registration. Please try again.')
    else:
        form = UserCreationForm()

    return render(request, 'register.html', {'form': form})
