import tkinter as tk
from tkinter import messagebox, ttk
import requests
import threading
import time
from mfrc522 import SimpleMFRC522
import RPi.GPIO as GPIO
import json
import os
from PIL import Image, ImageTk
import io
from collections import defaultdict
from http.server import BaseHTTPRequestHandler, HTTPServer
import sys

# Suppress RPi.GPIO warnings
GPIO.setwarnings(False)
os.system("fuser -k 5001/tcp")

# --- API URLs ---
SPRING_BOOT_BASE_URL = "http://18.142.44.110:8081/api/"
PROFILE_URL = f"{SPRING_BOOT_BASE_URL}"
MENU_URL = f"{SPRING_BOOT_BASE_URL}menu-items"
ORDER_URL = f"{SPRING_BOOT_BASE_URL}orders/place"
BIOMETRIC_CONFIRM_URL = f"{SPRING_BOOT_BASE_URL}biometric/confirm"

# ESP32 Configuration
ESP32_IP = "192.168.1.100"
ESP32_VERIFY_URL = f"http://{ESP32_IP}/verify"

# UI Client Configuration
UI_CLIENT_SERVER_IP = "100.93.177.42"
UI_CLIENT_SERVER_PORT = 5001

# Initialize RFID reader
reader = SimpleMFRC522()

# --- Global variables ---
customer_data = {}
menu_items = []
selected_items = {}
jwt_token = None
image_cache = {}  # Cache for loaded images

# --- Enhanced Tkinter UI Setup ---
root = tk.Tk()
root.title("Smart Canteen - Enhanced")
root.geometry("800x700")
root.configure(bg="#1a1a2e")

# Create a style for ttk widgets
style = ttk.Style()
style.theme_use('clam')
style.configure('Custom.TNotebook', background='#1a1a2e')
style.configure('Custom.TNotebook.Tab', padding=[20, 10])

# StringVars for UI updates
biometric_status_var = tk.StringVar(value="Waiting for order...")
name_var = tk.StringVar()
balance_var = tk.StringVar()
subtotal_var = tk.StringVar(value="Subtotal: Rs. 0.00")

# --- Main Frames ---
welcome_frame = tk.Frame(root, bg="#1a1a2e")
info_frame = tk.Frame(root, bg="#1a1a2e")
menu_frame = tk.Frame(root, bg="#1a1a2e")

# Enhanced Welcome Frame
welcome_title = tk.Label(welcome_frame, text="🍽️ Smart Canteen", 
                        font=('Arial', 24, 'bold'), fg="#00d4aa", bg="#1a1a2e")
welcome_title.pack(pady=40)

welcome_subtitle = tk.Label(welcome_frame, text="Tap your RFID card to start", 
                           font=('Arial', 14), fg="#ffffff", bg="#1a1a2e")
welcome_subtitle.pack(pady=10)

# Animated loading indicator
loading_label = tk.Label(welcome_frame, text="💳 Ready to scan...", 
                        font=('Arial', 12), fg="#00d4aa", bg="#1a1a2e")
loading_label.pack(pady=20)

welcome_frame.pack(expand=True)

# Enhanced Info Frame
info_container = tk.Frame(info_frame, bg="#16213e", relief="raised", bd=2)
info_container.pack(fill="x", padx=20, pady=10)

customer_icon = tk.Label(info_container, text="👤", font=('Arial', 16), fg="#00d4aa", bg="#16213e")
customer_icon.pack(side="left", padx=10, pady=10)

customer_info = tk.Frame(info_container, bg="#16213e")
customer_info.pack(side="left", fill="x", expand=True, padx=10, pady=10)

name_label = tk.Label(customer_info, textvariable=name_var, 
                     font=('Arial', 14, 'bold'), fg="#ffffff", bg="#16213e")
name_label.pack(anchor="w")

balance_label = tk.Label(customer_info, textvariable=balance_var, 
                        font=('Arial', 12), fg="#00d4aa", bg="#16213e")
balance_label.pack(anchor="w")

biometric_label = tk.Label(customer_info, textvariable=biometric_status_var, 
                          font=('Arial', 10), fg="#ffa500", bg="#16213e")
biometric_label.pack(anchor="w")

# Enhanced Menu Frame with Categories
menu_container = tk.Frame(menu_frame, bg="#1a1a2e")
menu_container.pack(fill="both", expand=True, padx=20, pady=10)

# Create notebook for categories
notebook = ttk.Notebook(menu_container, style='Custom.TNotebook')
notebook.pack(fill="both", expand=True)

# Bottom frame for subtotal and order button
bottom_frame = tk.Frame(menu_frame, bg="#1a1a2e")
bottom_frame.pack(fill="x", padx=20, pady=10)

subtotal_display = tk.Label(bottom_frame, textvariable=subtotal_var, 
                           font=('Arial', 16, 'bold'), fg="#ffffff", bg="#1a1a2e")
subtotal_display.pack(pady=10)

submit_button = tk.Button(bottom_frame, text="🛒 Submit Order", 
                         command=lambda: submit_order(),
                         bg="#00d4aa", fg="#1a1a2e", 
                         font=("Arial", 14, "bold"),
                         relief="raised", bd=3,
                         pady=10)
submit_button.pack(pady=10)

# --- Image Loading Functions ---
def load_image_from_url(image_path, size=(80, 80)):
    """
    Load and resize image from server URL with caching
    """
    if image_path in image_cache:
        return image_cache[image_path]
    
    try:
        # Construct full URL
        if image_path.startswith('/uploads/'):
            image_url = f"http://18.142.44.110:8081{image_path}"
        else:
            image_url = image_path
        
        print(f"DEBUG: Loading image from: {image_url}")
        
        # Download image
        response = requests.get(image_url, timeout=10)
        if response.status_code == 200:
            # Open and resize image
            image = Image.open(io.BytesIO(response.content))
            image = image.resize(size, Image.Resampling.LANCZOS)
            
            # Convert to PhotoImage
            photo = ImageTk.PhotoImage(image)
            image_cache[image_path] = photo
            return photo
        else:
            print(f"DEBUG: Failed to load image: {response.status_code}")
            return create_placeholder_image(size)
    except Exception as e:
        print(f"DEBUG: Error loading image {image_path}: {e}")
        return create_placeholder_image(size)

def create_placeholder_image(size=(80, 80)):
    """
    Create a placeholder image when actual image fails to load
    """
    try:
        # Create a simple colored rectangle as placeholder
        placeholder = Image.new('RGB', size, color='#333333')
        return ImageTk.PhotoImage(placeholder)
    except Exception as e:
        print(f"DEBUG: Error creating placeholder: {e}")
        return None

# --- Enhanced Menu Building Functions ---
def build_menu():
    """
    Build categorized menu with images
    """
    # Clear existing tabs
    for tab in notebook.tabs():
        notebook.forget(tab)
    
    # Clear selections
    selected_items.clear()
    update_subtotal()
    
    # Group items by category
    categories = defaultdict(list)
    for item in menu_items:
        categories[item['categoryName']].append(item)
    
    # Create tabs for each category
    for category_name, items in categories.items():
        create_category_tab(category_name, items)

def create_category_tab(category_name, items):
    """
    Create a tab for a specific category
    """
    # Create tab frame
    tab_frame = tk.Frame(notebook, bg="#1a1a2e")
    notebook.add(tab_frame, text=f"  {get_category_icon(category_name)} {category_name}  ")
    
    # Create scrollable frame for items
    canvas = tk.Canvas(tab_frame, bg="#1a1a2e", highlightthickness=0)
    scrollbar = tk.Scrollbar(tab_frame, orient="vertical", command=canvas.yview)
    scrollable_frame = tk.Frame(canvas, bg="#1a1a2e")
    
    scrollable_frame.bind(
        "<Configure>",
        lambda e: canvas.configure(scrollregion=canvas.bbox("all"))
    )
    
    canvas.create_window((0, 0), window=scrollable_frame, anchor="nw")
    canvas.configure(yscrollcommand=scrollbar.set)
    
    # Pack canvas and scrollbar
    canvas.pack(side="left", fill="both", expand=True)
    scrollbar.pack(side="right", fill="y")
    
    # Add items to scrollable frame
    for item in items:
        create_menu_item_widget(scrollable_frame, item)

def get_category_icon(category_name):
    """
    Get emoji icon for category
    """
    icons = {
        'BreakFast': '🌅',
        'Lunch': '🍽️',
        'Dinner': '🌙',
        'Snacks': '🍿',
        'Beverages': '🥤',
        'Desserts': '🍰'
    }
    return icons.get(category_name, '🍴')

def create_menu_item_widget(parent, item):
    """
    Create an enhanced menu item widget with image
    """
    item_id = item["id"]
    
    # Main item container
    item_frame = tk.Frame(parent, bg="#16213e", relief="raised", bd=2)
    item_frame.pack(fill="x", padx=10, pady=5)
    
    # Image container
    image_frame = tk.Frame(item_frame, bg="#16213e")
    image_frame.pack(side="left", padx=10, pady=10)
    
    # Load and display image
    image_widget = tk.Label(image_frame, bg="#16213e")
    image_widget.pack()
    
    # Load image in background thread to avoid blocking UI
    def load_image():
        photo = load_image_from_url(item.get("image", ""), size=(100, 100))
        if photo:
            root.after(0, lambda: image_widget.configure(image=photo))
            # Keep a reference to prevent garbage collection
            image_widget.image = photo
    
    threading.Thread(target=load_image, daemon=True).start()
    
    # Item details container
    details_frame = tk.Frame(item_frame, bg="#16213e")
    details_frame.pack(side="left", fill="x", expand=True, padx=10, pady=10)
    
    # Item name
    name_label = tk.Label(details_frame, text=item["name"], 
                         font=('Arial', 14, 'bold'), fg="#ffffff", bg="#16213e")
    name_label.pack(anchor="w")
    
    # Price
    price_label = tk.Label(details_frame, text=f"Rs. {item['price']:.2f}", 
                          font=('Arial', 12, 'bold'), fg="#00d4aa", bg="#16213e")
    price_label.pack(anchor="w")
    
    # Stock info
    stock_label = tk.Label(details_frame, text=f"Stock: {item['stock']}", 
                          font=('Arial', 10), fg="#cccccc", bg="#16213e")
    stock_label.pack(anchor="w")
    
    # Quantity controls container
    controls_frame = tk.Frame(item_frame, bg="#16213e")
    controls_frame.pack(side="right", padx=10, pady=10)
    
    # Quantity variable
    qty_var = tk.IntVar(value=selected_items.get(item_id, 0))
    
    # Quantity controls
    def increment():
        current = qty_var.get()
        if current < item['stock']:  # Check stock limit
            qty_var.set(current + 1)
            selected_items[item_id] = qty_var.get()
            update_subtotal()
    
    def decrement():
        current = qty_var.get()
        if current > 0:
            qty_var.set(current - 1)
            if qty_var.get() == 0:
                selected_items.pop(item_id, None)
            else:
                selected_items[item_id] = qty_var.get()
            update_subtotal()
    
    # Control buttons
    btn_frame = tk.Frame(controls_frame, bg="#16213e")
    btn_frame.pack()
    
    minus_btn = tk.Button(btn_frame, text="−", command=decrement, 
                         width=3, bg="#ff6b6b", fg="white", 
                         font=("Arial", 12, "bold"), relief="raised")
    minus_btn.pack(side="left", padx=2)
    
    qty_label = tk.Label(btn_frame, textvariable=qty_var, 
                        width=4, fg="#ffffff", bg="#16213e", 
                        font=("Arial", 12, "bold"))
    qty_label.pack(side="left", padx=5)
    
    plus_btn = tk.Button(btn_frame, text="+", command=increment, 
                        width=3, bg="#00d4aa", fg="white", 
                        font=("Arial", 12, "bold"), relief="raised")
    plus_btn.pack(side="left", padx=2)

# --- Helper Functions ---
def safe_json_parse(response):
    """
    Safely parse JSON response
    """
    print(f"DEBUG: Response Status: {response.status_code}")
    print(f"DEBUG: Response Headers: {dict(response.headers)}")
    print(f"DEBUG: Raw Response Text: {response.text}")
    
    try:
        json_data = response.json()
        print(f"DEBUG: Parsed JSON: {json_data}")
        return True, json_data
    except (json.JSONDecodeError, ValueError) as e:
        print(f"DEBUG: JSON Parse Error: {e}")
        return False, response.text

def update_subtotal():
    """
    Calculate and update subtotal
    """
    total = 0.0
    for item in menu_items:
        item_id = item["id"]
        if item_id in selected_items:
            qty = selected_items[item_id]
            total += item["price"] * qty
    
    subtotal_var.set(f"Subtotal: Rs. {total:.2f}")

def show_menu():
    """
    Show the menu interface
    """
    welcome_frame.pack_forget()
    info_frame.pack(fill="x")
    menu_frame.pack(fill="both", expand=True)
    fetch_menu()

def reset_ui():
    """
    Reset UI to welcome screen
    """
    global jwt_token
    selected_items.clear()
    name_var.set("")
    balance_var.set("")
    subtotal_var.set("Subtotal: Rs. 0.00")
    jwt_token = None
    biometric_status_var.set("Waiting for order...")
    
    info_frame.pack_forget()
    menu_frame.pack_forget()
    welcome_frame.pack(expand=True)

# --- Keep all your existing backend communication functions ---
def authenticate_rfid(rfid_text):
    """
    Authenticates the RFID card with the backend and retrieves JWT token.
    """
    global jwt_token
    print(f"DEBUG: Authenticating RFID: {rfid_text}")
    
    try:
        payload = {"cardID": rfid_text}
        res = requests.post(f"{PROFILE_URL}auth/login/rfid", json=payload)
        
        if res.status_code == 200:
            success, data = safe_json_parse(res)
            if success and isinstance(data, dict):
                jwt_token = data.get("token")
                if jwt_token:
                    print(f"DEBUG: JWT Token received")
                    get_customer_data(rfid_text)
                else:
                    messagebox.showerror("Error", "Authentication successful but token not received.")
            else:
                messagebox.showerror("Error", "Invalid response format from server.")
        else:
            success, data = safe_json_parse(res)
            if success and isinstance(data, dict):
                error_msg = data.get("message", "Invalid RFID or authentication error.")
            else:
                error_msg = f"Authentication failed with status {res.status_code}"
            messagebox.showerror("Authentication Failed", error_msg)
    except Exception as e:
        print(f"DEBUG: Error during RFID auth: {e}")
        messagebox.showerror("Error", f"Authentication error: {str(e)}")

def get_customer_data(rfid):
    """
    Fetches customer profile data using the RFID.
    """
    try:
        res = requests.get(f"{PROFILE_URL}customer/profile/rfid/{rfid}")
        
        if res.status_code == 200:
            success, data = safe_json_parse(res)
            if success and isinstance(data, dict):
                global customer_data
                customer_data = data
                
                def update_ui():
                    name_var.set(f"👤 {customer_data['username']}")
                    balance_var.set(f"💰 Balance: Rs. {customer_data['creditBalance']:.2f}")
                    show_menu()
                    biometric_status_var.set("Ready to order...")
                
                root.after(0, update_ui)
            else:
                root.after(0, lambda: messagebox.showerror("Error", "Invalid response format."))
        else:
            success, data = safe_json_parse(res)
            error_msg = data.get("message", "User not found.") if success else "Failed to fetch profile"
            root.after(0, lambda: messagebox.showerror("Error", error_msg))
    except Exception as e:
        print(f"DEBUG: Error fetching customer data: {e}")
        root.after(0, lambda: messagebox.showerror("Error", f"Error fetching profile: {str(e)}"))

def fetch_menu():
    """
    Fetch menu items from backend
    """
    try:
        res = requests.get(MENU_URL)
        if res.status_code == 200:
            success, data = safe_json_parse(res)
            if success and isinstance(data, list):
                global menu_items
                menu_items = data
                build_menu()
            else:
                messagebox.showerror("Error", "Invalid menu data format.")
        else:
            messagebox.showerror("Error", "Failed to load menu.")
    except Exception as e:
        messagebox.showerror("Error", f"Error loading menu: {str(e)}")

def submit_order():
    """
    Submit order to backend
    """
    global jwt_token, customer_data, selected_items
    
    if not jwt_token or not customer_data or not selected_items:
        messagebox.showerror("Error", "Missing required data for order submission.")
        return
    
    try:
        payload = {
            "email": customer_data.get("email"),
            "items": {str(item_id): quantity for item_id, quantity in selected_items.items()},
            "scheduledTime": None
        }
        
        headers = {"Authorization": f"Bearer {jwt_token}", "Content-Type": "application/json"}
        biometric_status_var.set("⏳ Submitting order...")
        
        res = requests.post(ORDER_URL, json=payload, headers=headers)
        
        if res.status_code == 200:
            response_data = res.json()
            order_id = response_data.get("id")
            
            if order_id:
                biometric_status_var.set("✅ Order placed! Starting biometric...")
                initiate_biometric_authentication(order_id)
            else:
                messagebox.showerror("Error", "Order placed but no order ID received.")
        else:
            error_data = res.json() if res.headers.get('content-type') == 'application/json' else {"message": res.text}
            messagebox.showerror("Order Failed", error_data.get("message", "Order submission failed"))
            biometric_status_var.set("❌ Order failed. Please try again.")
            
    except Exception as e:
        messagebox.showerror("Error", f"Order submission error: {str(e)}")
        biometric_status_var.set("❌ Error occurred. Please try again.")

def initiate_biometric_authentication(order_id):
    """
    Initiate biometric authentication
    """
    global jwt_token, customer_data
    
    try:
        biometric_data = {
            "email": customer_data.get("email"),
            "orderId": order_id
        }
        
        headers = {"Authorization": f"Bearer {jwt_token}", "Content-Type": "application/json"}
        biometric_status_var.set("🔒 Starting biometric authentication...")
        
        res = requests.post(f"{PROFILE_URL}biometric/initiate", json=biometric_data, headers=headers)
        
        if res.status_code == 200:
            biometric_status_var.set("👆 Please scan your biometric...")
            start_biometric_trigger_server()
        else:
            error_data = res.json() if res.headers.get('content-type') == 'application/json' else {"message": res.text}
            messagebox.showerror("Biometric Authentication Failed", error_data.get("message", "Biometric auth failed"))
            biometric_status_var.set("❌ Biometric authentication failed.")
            
    except Exception as e:
        messagebox.showerror("Error", f"Biometric authentication error: {str(e)}")
        biometric_status_var.set("❌ Error during biometric authentication.")

def start_biometric_trigger_server():
    """
    Start HTTP server for biometric triggers
    """
    from http.server import HTTPServer, BaseHTTPRequestHandler
    
    class BiometricTriggerHandler(BaseHTTPRequestHandler):
        def do_POST(self):
            if self.path == '/trigger-biometric':
                try:
                    content_length = int(self.headers.get('Content-Length', 0))
                    post_data = self.rfile.read(content_length)
                    
                    self.send_response(200)
                    self.send_header('Content-type', 'application/json')
                    self.end_headers()
                    response = json.dumps({"status": "trigger_received"})
                    self.wfile.write(response.encode())
                    
                    # Update UI
                    root.after(0, lambda: biometric_status_var.set("🔄 Processing biometric scan..."))
                    root.after(3000, lambda: complete_biometric_process())
                    
                except Exception as e:
                    print(f"DEBUG: Error processing biometric trigger: {e}")
                    self.send_response(500)
                    self.end_headers()
            else:
                self.send_response(404)
                self.end_headers()
        
        def log_message(self, format, *args):
            pass
    
    try:
        server = HTTPServer(('0.0.0.0', 5001), BiometricTriggerHandler)
        server_thread = threading.Thread(target=server.serve_forever, daemon=True)
        server_thread.start()
        
        global biometric_server
        biometric_server = server
        
    except Exception as e:
        print(f"DEBUG: Error starting biometric server: {e}")
        messagebox.showerror("Error", f"Could not start biometric server: {str(e)}")

def complete_biometric_process():
    """
    Complete biometric authentication process
    """
    biometric_status_var.set("✅ Payment processed successfully!")
    root.after(3000, reset_to_main_screen)

def reset_to_main_screen():
    """
    Reset to main screen for next customer
    """
    global customer_data, jwt_token
    
    customer_data = None
    jwt_token = None
    
    name_var.set("")
    balance_var.set("")
    biometric_status_var.set("Ready for next customer")
    
    reset_ui()

# --- RFID Loop ---
def rfid_loop():
    """
    Continuously read RFID cards
    """
    while True:
        try:
            id, text = reader.read()
            rfid_text = text.strip()
            if rfid_text:
                print(f"Read RFID: {rfid_text}")
                authenticate_rfid(rfid_text)
            time.sleep(2)
        except Exception as e:
            print(f"RFID error: {e}")
            time.sleep(1)

# --- Main Application ---
if __name__ == "__main__":
    # Start RFID loop
    threading.Thread(target=rfid_loop, daemon=True).start()
    
    try:
        root.mainloop()
    finally:
        GPIO.cleanup()
        print("Application terminated. GPIO cleaned up.")
