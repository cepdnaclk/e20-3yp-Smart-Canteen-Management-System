




# canteen/views.py
from django.shortcuts import render, redirect
from django.contrib.auth.forms import UserCreationForm, AuthenticationForm
from django.contrib.auth import login, authenticate
from django.contrib import messages
from django.http import HttpResponse

def home(request):
    return render(request, 'home/home.html')

def menu(request):
    return render(request, 'home/menu.html')

def live_view(request):
    return render(request, 'home/live_view.html')

def features(request):
    return render(request, 'home/features.html')

def dashboard(request):
    return render(request, 'home/dashboard.html')

# Register view
def register(request):
    if request.method == 'POST':
        form = UserCreationForm(request.POST)
        if form.is_valid():
            form.save()
            username = form.cleaned_data.get('username')
            messages.success(request, f"Account created for {username}!")
            return redirect('login')
    else:
        form = UserCreationForm()
    return render(request, 'home/register.html', {'form': form})

# Login view
def login_view(request):
    if request.method == 'POST':
        form = AuthenticationForm(request, data=request.POST)
        if form.is_valid():
            username = form.cleaned_data.get('username')
            password = form.cleaned_data.get('password')
            user = authenticate(username=username, password=password)
            if user is not None:
                login(request, user)
                messages.info(request, f"Welcome back, {username}!")
                return redirect('home')
            else:
                messages.error(request, "Invalid username or password")
        else:
            messages.error(request, "Invalid username or password")
    else:
        form = AuthenticationForm()
    return render(request, 'home/login.html', {'form': form})

# home/views.py
from django.shortcuts import render

def fingerprint(request):
    return render(request, 'home/fingerprint.html')


# views.py
from django.shortcuts import render
from django.http import HttpResponse

def display_string(request):
    # Define the string to send
    my_string = "Hello, welcome to the fingerprint recognition system!"
    
    # Pass the string to the template via context
    return render(request, 'home/my_template.html', {'my_string': my_string})

def order(request):
    return render(request,'home/pages/orders.html')

from django.contrib.auth import logout
from django.shortcuts import redirect

def logout_view(request):
    # Log the user out
    logout(request)
    
    # Redirect to the login page
    return redirect('login')  # Replace 'login' with your actual login URL name


def fingerprintTest(request,name):
    return HttpResponse(f"<h1>User : {name}<h1>")