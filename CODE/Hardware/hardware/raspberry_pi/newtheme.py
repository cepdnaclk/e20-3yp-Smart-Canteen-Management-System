import tkinter as tk
from tkinter import messagebox, ttk
import requests
import threading
import time
from mfrc522 import SimpleMFRC522
import RPi.GPIO as GPIO
import json
from PIL import Image, ImageTk
import io
from collections import defaultdict
from http.server import BaseHTTPRequestHandler, HTTPServer
import socket
import queue
import subprocess

# Suppress RPi.GPIO warnings
GPIO.setwarnings(False)

# Free port 5001 at startup
try:
    subprocess.run(["sudo", "fuser", "-k", "5001/tcp"], check=False, capture_output=True)
    print("DEBUG: Attempted to free port 5001")
except Exception as e:
    print(f"DEBUG: Error freeing port 5001: {e}")

# --- API URLs ---
SPRING_BOOT_BASE_URL = "http://18.142.44.110:8081/api/"
PROFILE_URL = f"{SPRING_BOOT_BASE_URL}"
MENU_URL = f"{SPRING_BOOT_BASE_URL}menu-items"
ORDER_URL = f"{SPRING_BOOT_BASE_URL}orders/place"
BIOMETRIC_CONFIRM_URL = f"{SPRING_BOOT_BASE_URL}biometric/confirm"

# ESP32 Configuration
ESP32_IP = "192.168.1.102"
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
image_cache = {}
biometric_server = None
biometric_queue = queue.Queue()
server_lock = threading.Lock()
cancel_operation = False  # Flag for canceling operations

# --- Color Palette ---
BACKGROUND_COLOR = "#E9D9F4"  # Light lavender
PRIMARY_ACCENT = "#6A1B9A"    # Deep purple
SECONDARY_ACCENT = "#AB47BC"  # Medium purple
TEXT_COLOR = "#2E2E2E"        # Dark gray
SUCCESS_COLOR = "#4CAF50"     # Green
ERROR_COLOR = "#D32F2F"       # Red
NEUTRAL_BG = "#F5F5F5"       # Light gray

# --- Enhanced Tkinter UI Setup ---
root = tk.Tk()
root.title("Smart Canteen - Enhanced")
root.geometry("800x700")
root.configure(bg=BACKGROUND_COLOR)

# Create a style for ttk widgets
style = ttk.Style()
style.theme_use('clam')
style.configure('Custom.TNotebook', background=BACKGROUND_COLOR, tabmargins=[10, 5, 10, 0])
style.configure('Custom.TNotebook.Tab', background=NEUTRAL_BG, foreground=TEXT_COLOR, padding=[20, 10], font=('Arial', 12, 'bold'))
style.map('Custom.TNotebook.Tab', background=[('selected', PRIMARY_ACCENT), ('active', SECONDARY_ACCENT)], foreground=[('selected', '#FFFFFF'), ('active', '#FFFFFF')])
style.configure('Custom.TButton', background=PRIMARY_ACCENT, foreground='#FFFFFF', font=('Arial', 12, 'bold'), padding=10, borderwidth=2)
style.map('Custom.TButton', background=[('active', SECONDARY_ACCENT)], foreground=[('active', '#FFFFFF')])
style.configure('Custom.TProgressbar', troughcolor=BACKGROUND_COLOR, background=SUCCESS_COLOR, bordercolor=PRIMARY_ACCENT)
style.layout('Custom.TProgressbar', [
    ('Horizontal.Progressbar.trough', {
        'children': [('Horizontal.Progressbar.pbar', {'side': 'left', 'sticky': 'ns'})],
        'sticky': 'nswe'
    })
])

# StringVars for UI updates
biometric_status_var = tk.StringVar(value="Waiting for order...")
name_var = tk.StringVar()
balance_var = tk.StringVar()
subtotal_var = tk.StringVar(value="Subtotal: Rs. 0.00")
loading_dots_var = tk.StringVar(value="...")
timer_var = tk.StringVar(value="")  # For biometric countdown

# --- Main Frames ---
welcome_frame = tk.Frame(root, bg=BACKGROUND_COLOR)
info_frame = tk.Frame(root, bg=BACKGROUND_COLOR)
menu_frame = tk.Frame(root, bg=BACKGROUND_COLOR)

# --- Fade Transition Helper ---
def fade_frame_out(frame, alpha=1.0, callback=None):
    if alpha > 0:
        frame.winfo_toplevel().attributes('-alpha', alpha)
        frame.after(30, lambda: fade_frame_out(frame, alpha - 0.1, callback))
    else:
        frame.pack_forget()
        frame.winfo_toplevel().attributes('-alpha', 1.0)
        if callback:
            callback()

def fade_frame_in(frame):
    frame.pack(expand=True, fill='both')
    frame.winfo_toplevel().attributes('-alpha', 0.1)
    def increase_alpha(alpha=0.1):
        if alpha < 1.0:
            frame.winfo_toplevel().attributes('-alpha', alpha)
            frame.after(30, lambda: increase_alpha(alpha + 0.1))
        else:
            frame.winfo_toplevel().attributes('-alpha', 1.0)
    increase_alpha()

# --- Loading Animation ---
def update_loading_dots():
    dots = loading_dots_var.get()
    if dots == "...":
        loading_dots_var.set(".")
    elif dots == ".":
        loading_dots_var.set("..")
    else:
        loading_dots_var.set("...")
    root.after(500, update_loading_dots)

# --- Biometric Timer ---
def start_biometric_timer(order_id, timeout=90):
    def update_timer(remaining):
        if remaining > 0 and not cancel_operation:
            timer_var.set(f"Time left: {remaining}s")
            root.after(1000, lambda: update_timer(remaining - 1))
        else:
            timer_var.set("")
    root.after(0, lambda: update_timer(timeout))

# --- Tooltip Class ---
class Tooltip:
    def __init__(self, widget, text):
        self.widget = widget
        self.text = text
        self.tip_window = None
        self.widget.bind("<Enter>", self.show_tip)
        self.widget.bind("<Leave>", self.hide_tip)

    def show_tip(self, event=None):
        if self.tip_window or not self.text:
            return
        x, y, _, _ = self.widget.bbox("insert")
        x += self.widget.winfo_rootx() + 25
        y += self.widget.winfo_rooty() + 25
        self.tip_window = tw = tk.Toplevel(self.widget)
        tw.wm_overrideredirect(True)
        tw.wm_geometry(f"+{x}+{y}")
        label = tk.Label(tw, text=self.text, justify='left', background=NEUTRAL_BG, foreground=TEXT_COLOR, relief='solid', borderwidth=1, font=('Arial', 10))
        label.pack()

    def hide_tip(self, event=None):
        if self.tip_window:
            self.tip_window.destroy()
            self.tip_window = None

# --- Enhanced Welcome Frame ---
welcome_title = tk.Label(welcome_frame, text="🍽️ Smart Canteen", font=('Arial', 28, 'bold'), fg=PRIMARY_ACCENT, bg=BACKGROUND_COLOR)
welcome_title.pack(pady=50)
welcome_subtitle = tk.Label(welcome_frame, text="Tap your RFID card to start", font=('Arial', 16), fg=TEXT_COLOR, bg=BACKGROUND_COLOR)
welcome_subtitle.pack(pady=15)
loading_label = tk.Label(welcome_frame, text="💳 Ready to scan", font=('Arial', 14), fg=SUCCESS_COLOR, bg=BACKGROUND_COLOR)
loading_label.pack(pady=20)
loading_dots_label = tk.Label(welcome_frame, textvariable=loading_dots_var, font=('Arial', 14), fg=SUCCESS_COLOR, bg=BACKGROUND_COLOR)
loading_dots_label.pack()
welcome_frame.pack(expand=True)
root.after(0, update_loading_dots)

# --- Enhanced Info Frame ---
info_container = tk.Frame(info_frame, bg=NEUTRAL_BG, relief="flat", bd=2)
info_container.pack(fill="x", padx=20, pady=10)
info_container.grid_columnconfigure(0, weight=1)
info_container.grid_columnconfigure(1, weight=3)
customer_icon = tk.Label(info_container, text="👤", font=('Arial', 20), fg=PRIMARY_ACCENT, bg=NEUTRAL_BG)
customer_icon.grid(row=0, column=0, padx=10, pady=10, sticky='w')
customer_info = tk.Frame(info_container, bg=NEUTRAL_BG)
customer_info.grid(row=0, column=1, sticky='w', padx=10, pady=10)
name_label = tk.Label(customer_info, textvariable=name_var, font=('Arial', 16, 'bold'), fg=TEXT_COLOR, bg=NEUTRAL_BG)
name_label.pack(anchor="w")
balance_label = tk.Label(customer_info, textvariable=balance_var, font=('Arial', 14), fg=SUCCESS_COLOR, bg=NEUTRAL_BG)
balance_label.pack(anchor="w")
biometric_label = tk.Label(customer_info, textvariable=biometric_status_var, font=('Arial', 12), fg=SECONDARY_ACCENT, bg=NEUTRAL_BG)
biometric_label.pack(anchor="w")
timer_label = tk.Label(customer_info, textvariable=timer_var, font=('Arial', 12), fg=SECONDARY_ACCENT, bg=NEUTRAL_BG)
timer_label.pack(anchor="w")

# --- Enhanced Menu Frame with Categories ---
menu_container = tk.Frame(menu_frame, bg=BACKGROUND_COLOR)
menu_container.pack(fill="both", expand=True, padx=20, pady=10)
notebook = ttk.Notebook(menu_container, style='Custom.TNotebook')
notebook.pack(fill="both", expand=True)
bottom_frame = tk.Frame(menu_frame, bg=BACKGROUND_COLOR)
bottom_frame.pack(fill="x", padx=20, pady=10)
subtotal_display = tk.Label(bottom_frame, textvariable=subtotal_var, font=('Arial', 18, 'bold'), fg=TEXT_COLOR, bg=BACKGROUND_COLOR)
subtotal_display.pack(pady=10)
progress_bar = ttk.Progressbar(bottom_frame, style='Custom.TProgressbar', mode='indeterminate', length=200)
cancel_button = ttk.Button(bottom_frame, text="❌ Cancel", command=lambda: cancel_order(), style='Custom.TButton')
submit_button = ttk.Button(bottom_frame, text="🛒 Submit Order", command=lambda: submit_order(), style='Custom.TButton')
submit_button.pack(pady=10)
Tooltip(submit_button, "Submit your selected items")

# --- Image Loading Functions ---
def load_image_from_url(image_path, size=(120, 120)):
    if image_path in image_cache:
        return image_cache[image_path]
    try:
        if image_path.startswith('/uploads/'):
            image_url = f"http://18.142.44.110:8081{image_path}"
        else:
            image_url = image_path
        print(f"DEBUG: Loading image from: {image_url}")
        response = requests.get(image_url, timeout=10)
        if response.status_code == 200:
            image = Image.open(io.BytesIO(response.content))
            image = image.resize(size, Image.Resampling.LANCZOS)
            photo = ImageTk.PhotoImage(image)
            image_cache[image_path] = photo
            return photo
        else:
            print(f"DEBUG: Failed to load image: {response.status_code}")
            return create_placeholder_image(size)
    except Exception as e:
        print(f"DEBUG: Error loading image {image_path}: {e}")
        return create_placeholder_image(size)

def create_placeholder_image(size=(120, 120)):
    try:
        placeholder = Image.new('RGB', size, color=NEUTRAL_BG)
        return ImageTk.PhotoImage(placeholder)
    except Exception as e:
        print(f"DEBUG: Error creating placeholder: {e}")
        return None

# --- Enhanced Menu Building Functions ---
def build_menu():
    for tab in notebook.tabs():
        notebook.forget(tab)
    selected_items.clear()
    update_subtotal()
    categories = defaultdict(list)
    for item in menu_items:
        categories[item['categoryName']].append(item)
    for category_name, items in categories.items():
        create_category_tab(category_name, items)

def create_category_tab(category_name, items):
    tab_frame = tk.Frame(notebook, bg=BACKGROUND_COLOR)
    notebook.add(tab_frame, text=f"  {get_category_icon(category_name)} {category_name}  ")
    canvas = tk.Canvas(tab_frame, bg=BACKGROUND_COLOR, highlightthickness=0)
    scrollbar = tk.Scrollbar(tab_frame, orient="vertical", command=canvas.yview)
    scrollable_frame = tk.Frame(canvas, bg=BACKGROUND_COLOR)
    scrollable_frame.bind("<Configure>", lambda e: canvas.configure(scrollregion=canvas.bbox("all")))
    canvas.create_window((0, 0), window=scrollable_frame, anchor="nw")
    canvas.configure(yscrollcommand=scrollbar.set)
    canvas.pack(side="left", fill="both", expand=True)
    scrollbar.pack(side="right", fill="y")
    for item in items:
        create_menu_item_widget(scrollable_frame, item)

def get_category_icon(category_name):
    icons = {
        'BreakFast': '🌅',
        'Lunch': '🍽️',
        'Dinner': '🌙',
        'Snacks': '🍟',
        'Beverages': '🥤',
        'Desserts': '🍰'
    }
    return icons.get(category_name, '🍴')

def create_menu_item_widget(parent, item):
    item_id = item["id"]
    item_frame = tk.Frame(parent, bg=NEUTRAL_BG, relief="flat", bd=2)
    item_frame.pack(fill="x", padx=10, pady=8)
    item_frame.grid_columnconfigure(1, weight=1)
    image_frame = tk.Frame(item_frame, bg=NEUTRAL_BG)
    image_frame.grid(row=0, column=0, padx=10, pady=10)
    image_widget = tk.Label(image_frame, bg=NEUTRAL_BG)
    image_widget.pack()
    def load_image():
        photo = load_image_from_url(item.get("image", ""), size=(120, 120))
        if photo:
            root.after(0, lambda: image_widget.configure(image=photo))
            image_widget.image = photo
    threading.Thread(target=load_image, daemon=True).start()
    details_frame = tk.Frame(item_frame, bg=NEUTRAL_BG)
    details_frame.grid(row=0, column=1, sticky='w', padx=10, pady=10)
    name_label = tk.Label(details_frame, text=item["name"], font=('Arial', 16, 'bold'), fg=TEXT_COLOR, bg=NEUTRAL_BG)
    name_label.pack(anchor="w")
    price_label = tk.Label(details_frame, text=f"Rs. {item['price']:.2f}", font=('Arial', 14), fg=SUCCESS_COLOR, bg=NEUTRAL_BG)
    price_label.pack(anchor="w")
    stock_label = tk.Label(details_frame, text=f"Stock: {item['stock']}", font=('Arial', 12), fg=TEXT_COLOR, bg=NEUTRAL_BG)
    stock_label.pack(anchor="w")
    controls_frame = tk.Frame(item_frame, bg=NEUTRAL_BG)
    controls_frame.grid(row=0, column=2, padx=10, pady=10)
    qty_var = tk.IntVar(value=selected_items.get(item_id, 0))
    def increment():
        current = qty_var.get()
        if current < item['stock']:
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
    btn_frame = tk.Frame(controls_frame, bg=NEUTRAL_BG)
    btn_frame.pack()
    minus_btn = ttk.Button(btn_frame, text="−", command=decrement, width=4, style='Custom.TButton')
    minus_btn.pack(side="left", padx=5)
    Tooltip(minus_btn, "Decrease quantity")
    qty_label = tk.Label(btn_frame, textvariable=qty_var, width=4, fg=TEXT_COLOR, bg=NEUTRAL_BG, font=("Arial", 14, "bold"))
    qty_label.pack(side="left", padx=10)
    plus_btn = ttk.Button(btn_frame, text="+", command=increment, width=4, style='Custom.TButton')
    plus_btn.pack(side="left", padx=5)
    Tooltip(plus_btn, "Increase quantity")

# --- Helper Functions ---
def safe_json_parse(response):
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
    total = 0.0
    for item in menu_items:
        item_id = item["id"]
        if item_id in selected_items:
            qty = selected_items[item_id]
            total += item["price"] * qty
    subtotal_var.set(f"Subtotal: Rs. {total:.2f}")

def show_menu():
    def callback():
        info_frame.pack(fill="x")
        menu_frame.pack(fill="both", expand=True)
        fetch_menu()
    fade_frame_out(welcome_frame, callback=callback)

def reset_ui():
    global jwt_token, cancel_operation
    cancel_operation = False
    selected_items.clear()
    name_var.set("")
    balance_var.set("")
    subtotal_var.set("Subtotal: Rs. 0.00")
    jwt_token = None
    biometric_status_var.set("Ready for next customer")
    timer_var.set("")
    fade_frame_out(menu_frame)
    fade_frame_out(info_frame)
    fade_frame_in(welcome_frame)

def cancel_order():
    global cancel_operation
    cancel_operation = True
    progress_bar.stop()
    progress_bar.pack_forget()
    cancel_button.pack_forget()
    submit_button.pack(pady=10)
    biometric_status_var.set("❌ Operation canceled")
    root.after(2000, reset_ui)

# --- Backend Communication Functions ---
def authenticate_rfid(rfid_text):
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
                    root.after(0, lambda: messagebox.showerror("Error", "Authentication successful but token not received.", icon='error'))
            else:
                root.after(0, lambda: messagebox.showerror("Error", "Invalid response format from server.", icon='error'))
        else:
            success, data = safe_json_parse(res)
            error_msg = data.get("message", "Invalid RFID or authentication error.") if success else f"Authentication failed with status {res.status_code}"
            root.after(0, lambda: messagebox.showerror("Authentication Failed", error_msg, icon='error'))
    except Exception as e:
        print(f"DEBUG: Error during RFID auth: {e}")
        root.after(0, lambda: messagebox.showerror("Error", f"Authentication error: {str(e)}", icon='error'))

def get_customer_data(rfid):
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
                root.after(0, lambda: messagebox.showerror("Error", "Invalid response format.", icon='error'))
        else:
            success, data = safe_json_parse(res)
            error_msg = data.get("message", "User not found.") if success else "Failed to fetch profile"
            root.after(0, lambda: messagebox.showerror("Error", error_msg, icon='error'))
    except Exception as e:
        print(f"DEBUG: Error fetching customer data: {e}")
        root.after(0, lambda: messagebox.showerror("Error", f"Error fetching profile: {str(e)}", icon='error'))

def fetch_menu():
    try:
        res = requests.get(MENU_URL)
        if res.status_code == 200:
            success, data = safe_json_parse(res)
            if success and isinstance(data, list):
                global menu_items
                menu_items = data
                build_menu()
            else:
                root.after(0, lambda: messagebox.showerror("Error", "Invalid menu data format.", icon='error'))
        else:
            root.after(0, lambda: messagebox.showerror("Error", "Failed to load menu.", icon='error'))
    except Exception as e:
        root.after(0, lambda: messagebox.showerror("Error", f"Error loading menu: {str(e)}", icon='error'))

def submit_order():
    global jwt_token, customer_data, selected_items, cancel_operation
    if not jwt_token or not customer_data or not selected_items:
        root.after(0, lambda: messagebox.showerror("Error", "Missing required data for order submission.", icon='error'))
        return
    try:
        cancel_operation = False
        progress_bar.pack(pady=10)
        progress_bar.start(10)
        submit_button.pack_forget()
        cancel_button.pack(pady=10)
        payload = {
            "email": customer_data.get("email"),
            "items": {str(item_id): quantity for item_id, quantity in selected_items.items()},
            "scheduledTime": None
        }
        headers = {"Authorization": f"Bearer {jwt_token}", "Content-Type": "application/json"}
        biometric_status_var.set("⏳ Submitting order...")
        res = requests.post(ORDER_URL, json=payload, headers=headers)
        progress_bar.stop()
        progress_bar.pack_forget()
        cancel_button.pack_forget()
        submit_button.pack(pady=10)
        if cancel_operation:
            return
        if res.status_code == 200:
            response_data = res.json()
            order_id = response_data.get("id")
            if order_id:
                biometric_status_var.set(f"✅ Order {order_id} placed! Scan fingerprint...")
                initiate_biometric_authentication(order_id)
            else:
                root.after(0, lambda: messagebox.showerror("Error", "Order placed but no order ID received.", icon='error'))
        else:
            error_data = res.json() if res.headers.get('content-type') == 'application/json' else {"message": res.text}
            root.after(0, lambda: messagebox.showerror("Order Failed", error_data.get("message", "Order submission failed"), icon='error'))
            biometric_status_var.set("❌ Order failed. Please try again.")
    except Exception as e:
        progress_bar.stop()
        progress_bar.pack_forget()
        cancel_button.pack_forget()
        submit_button.pack(pady=10)
        root.after(0, lambda: messagebox.showerror("Error", f"Order submission error: {str(e)}", icon='error'))
        biometric_status_var.set("❌ Error occurred. Please try again.")

def initiate_biometric_authentication(order_id):
    global jwt_token, customer_data
    try:
        biometric_data = {
            "email": customer_data.get("email"),
            "orderId": order_id
        }
        headers = {"Authorization": f"Bearer {jwt_token}", "Content-Type": "application/json"}
        biometric_status_var.set("🔒 Initiating biometric authentication...")
        res = requests.post(f"{PROFILE_URL}biometric/initiate", json=biometric_data, headers=headers)
        if res.status_code == 200:
            biometric_queue.put((customer_data.get("email"), order_id, headers.get("Authorization")))
            root.after(0, lambda: biometric_status_var.set(f"👆 Queued for fingerprint scan (Order {order_id}, Queue size: {biometric_queue.qsize()})"))
            start_biometric_timer(order_id)
            if not any(t.name == "BiometricQueueWorker" for t in threading.enumerate()):
                threading.Thread(target=process_biometric_queue, daemon=True, name="BiometricQueueWorker").start()
        else:
            error_data = res.json() if res.headers.get('content-type') == 'application/json' else {"message": res.text}
            root.after(0, lambda: messagebox.showerror("Biometric Authentication Failed", error_data.get("message", "Biometric auth failed"), icon='error'))
            biometric_status_var.set("❌ Biometric authentication failed.")
    except Exception as e:
        print(f"DEBUG: Error during biometric auth initiation: {e}")
        root.after(0, lambda: messagebox.showerror("Error", f"Biometric authentication error: {str(e)}", icon='error'))
        biometric_status_var.set("❌ Error during biometric authentication.")

def start_biometric_trigger_server(email, order_id, auth_header):
    global biometric_server
    with server_lock:
        if biometric_server is not None:
            print("DEBUG: Biometric trigger server already running")
            return
        try:
            class BiometricTriggerHandler(BaseHTTPRequestHandler):
                def do_POST(self):
                    try:
                        content_length = int(self.headers.get('Content-Length', 0))
                        post_data = self.rfile.read(content_length)
                        payload = json.loads(post_data.decode('utf-8'))
                        self.send_response(200)
                        self.send_header('Content-type', 'application/json')
                        self.end_headers()
                        self.wfile.write(json.dumps({"status": "received"}).encode())
                        if self.path == '/trigger-biometric':
                            print(f"DEBUG: Received biometric trigger: {post_data.decode()}")
                            received_email = payload.get('email')
                            received_order_id = payload.get('orderId')
                            received_auth_header = self.headers.get('Authorization')
                            if received_email == email and received_order_id == order_id:
                                root.after(0, lambda: start_biometric_scanning(email, order_id, received_auth_header))
                            else:
                                print(f"DEBUG: Mismatched biometric trigger: expected {email}/{order_id}, received {received_email}/{received_order_id}")
                        elif self.path == '/queue-status':
                            print(f"DEBUG: Received queue status: {post_data.decode()}")
                            queue_size = payload.get('queueSize', 0)
                            root.after(0, lambda: biometric_status_var.set(f"👆 Queued for fingerprint scan (Order {order_id}, ESP32 Queue: {queue_size})"))
                        elif self.path == '/error':
                            print(f"DEBUG: Received error: {post_data.decode()}")
                            error_msg = payload.get('error', 'Unknown error')
                            root.after(0, lambda: biometric_status_var.set(f"❌ Biometric error: {error_msg}"))
                            root.after(0, lambda: messagebox.showerror("Biometric Error", error_msg, icon='error'))
                        else:
                            self.send_response(404)
                            self.end_headers()
                    except Exception as e:
                        print(f"DEBUG: Error processing request: {e}")
                        self.send_response(500)
                        self.end_headers()
                def log_message(self, format, *args):
                    pass
            server = HTTPServer(('0.0.0.0', 5001), BiometricTriggerHandler)
            server.socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            server_thread = threading.Thread(target=server.serve_forever, daemon=True)
            server_thread.start()
            biometric_server = server
            print("DEBUG: Biometric trigger server started on port 5001")
        except Exception as e:
            print(f"DEBUG: Error starting biometric server: {e}")
            root.after(0, lambda: messagebox.showerror("Error", f"Could not start biometric server: {str(e)}", icon='error'))
            biometric_status_var.set("❌ Error starting biometric server.")

def stop_biometric_trigger_server():
    global biometric_server
    with server_lock:
        if biometric_server is not None:
            try:
                biometric_server.server_close()
                print("DEBUG: Biometric trigger server stopped")
            except Exception as e:
                print(f"DEBUG: Error stopping biometric server: {e}")
            finally:
                biometric_server = None

def process_biometric_queue():
    while True:
        try:
            email, order_id, auth_header = biometric_queue.get()
            print(f"DEBUG: Processing biometric request for email: {email}, orderId: {order_id}")
            start_biometric_trigger_server(email, order_id, auth_header)
            biometric_queue.task_done()
        except Exception as e:
            print(f"DEBUG: Error processing biometric queue: {e}")
            root.after(0, lambda: biometric_status_var.set("❌ Error processing biometric queue."))
            root.after(0, lambda: messagebox.showerror("Error", f"Error processing biometric queue: {str(e)}", icon='error'))

def start_biometric_scanning(email, order_id, auth_header=None):
    global cancel_operation
    try:
        print("DEBUG: Starting biometric scanning...")
        biometric_status_var.set(f"👆 Order {order_id}: Scan fingerprint...")
        root.update()
        esp32_payload = {"email": email, "orderId": order_id}
        esp32_headers = {"Content-Type": "application/json"}
        if auth_header:
            esp32_headers["Authorization"] = auth_header
        print(f"DEBUG: ESP32 payload: {esp32_payload}")
        esp32_res = requests.post(ESP32_VERIFY_URL, json=esp32_payload, headers=esp32_headers, timeout=10)
        print(f"DEBUG: ESP32 response status: {esp32_res.status_code}")
        print(f"DEBUG: ESP32 response headers: {dict(esp32_res.headers)}")
        print(f"DEBUG: ESP32 raw response: {esp32_res.text}")
        if cancel_operation:
            return
        if esp32_res.status_code == 200:
            biometric_status_var.set(f"✅ Fingerprint scan initiated for Order {order_id}!")
            root.after(500, lambda: [reset_to_main_screen(), stop_biometric_trigger_server()])
        else:
            biometric_status_var.set(f"❌ ESP32 error for Order {order_id}: HTTP {esp32_res.status_code}")
            root.after(0, lambda: messagebox.showerror("Biometric Error", f"ESP32 returned error: {esp32_res.text}", icon='error'))
            stop_biometric_trigger_server()
    except requests.exceptions.RequestException as e:
        print(f"DEBUG: Network error during biometric scanning: {e}")
        biometric_status_var.set(f"❌ Network error during fingerprint scan for Order {order_id}.")
        root.after(0, lambda: messagebox.showerror("Network Error", f"Could not connect to ESP32: {str(e)}", icon='error'))
        stop_biometric_trigger_server()
    except Exception as e:
        print(f"DEBUG: Unexpected error during biometric scanning: {e}")
        biometric_status_var.set(f"❌ Error during fingerprint scan for Order {order_id}.")
        root.after(0, lambda: messagebox.showerror("Error", f"Unexpected error during biometric scanning: {str(e)}", icon='error'))
        stop_biometric_trigger_server()

def reset_to_main_screen():
    global customer_data, jwt_token, cancel_operation
    cancel_operation = False
    customer_data = None
    jwt_token = None
    name_var.set("")
    balance_var.set("")
    biometric_status_var.set("Ready for next customer")
    timer_var.set("")
    reset_ui()

# --- RFID Loop ---
def rfid_loop():
    while True:
        try:
            id, text = reader.read()
            rfid_text = text.strip()
            if rfid_text:
                print(f"Read RFID: {rfid_text}")
                authenticate_rfid(rfid_text)
            time.sleep(0.5)
        except Exception as e:
            print(f"RFID error: {e}")
            time.sleep(0.5)

# --- Main Application ---
if __name__ == "__main__":
    threading.Thread(target=rfid_loop, daemon=True).start()
    try:
        root.mainloop()
    finally:
        stop_biometric_trigger_server()
        GPIO.cleanup()
        print("Application terminated. GPIO cleaned up.")
