import tkinter as tk
from tkinter import messagebox
import requests
import threading
import time
from mfrc522 import SimpleMFRC522
import RPi.GPIO as GPIO
import json
import os
# import ssl # No longer required for HTTP server
from http.server import BaseHTTPRequestHandler, HTTPServer
import sys

# Suppress RPi.GPIO warnings, especially useful during development
GPIO.setwarnings(False)

# This command attempts to kill any process using port 5001.
# This is crucial for development to ensure the port is free for the UI Client's server.
# Be cautious in production as it can forcefully terminate other services.
os.system("fuser -k 5001/tcp") # Kill process on port 5001 (UI Client's listening port)

# --- API URLs ---
# Base URL for your Spring Boot Backend
SPRING_BOOT_BASE_URL = "http://100.86.40.55:8081/api/"
PROFILE_URL = f"{SPRING_BOOT_BASE_URL}"
MENU_URL = f"{SPRING_BOOT_BASE_URL}menu-items"
ORDER_URL = f"{SPRING_BOOT_BASE_URL}orders/place"
BIOMETRIC_CONFIRM_URL = f"{SPRING_BOOT_BASE_URL}biometric/confirm" # ESP32 sends to this

# ESP32 Sensor Configuration
ESP32_IP = "192.168.1.102"
ESP32_VERIFY_URL = f"http://{ESP32_IP}/verify" # UI Client sends to ESP32 via HTTP

# UI Client's own server configuration (for receiving from Backend)
# This is the IP of your Raspberry Pi where the Tkinter app runs
UI_CLIENT_SERVER_IP = "100.93.177.42"
UI_CLIENT_SERVER_PORT = 5001 # This must match what your Spring Boot Backend sends to
# Paths to your SSL certificates (These are no longer used for the server if it's HTTP)
CERT_FILE = 'server.crt'
KEY_FILE = 'server.key'

# Initialize RFID reader
reader = SimpleMFRC522()

# --- Global variables for application state ---
customer_data = {}
menu_items = []
selected_items = {}
jwt_token = None # Global variable to store the JWT token

# --- Tkinter UI Setup ---
root = tk.Tk()
root.title("Smart Canteen")
root.geometry("520x600")
root.configure(bg="#1e1e2f")

# Now, it's safe to create StringVars because 'root' exists
biometric_status_var = tk.StringVar(value="Waiting for order...") # New var for biometric status

# Tkinter StringVars for dynamic UI updates
name_var = tk.StringVar()
balance_var = tk.StringVar()
subtotal_var = tk.StringVar(value="Subtotal: Rs. 0.00")

# --- Frames ---
welcome_frame = tk.Frame(root, bg="#1e1e2f")
info_frame = tk.Frame(root, bg="#1e1e2f")
menu_frame = tk.Frame(root, bg="#1e1e2f")

# Welcome Frame Content
tk.Label(welcome_frame, text="Welcome to Smart Canteen", font=('Helvetica', 16), fg="#00adb5", bg="#1e1e2f").pack(pady=20)
tk.Label(welcome_frame, text="Tap your RFID card", font=('Helvetica', 12), fg="white", bg="#1e1e2f").pack()
welcome_frame.pack(expand=True) # Show welcome frame initially

# Info Frame Content (for customer name and balance)
tk.Label(info_frame, textvariable=name_var, font=('Helvetica', 14), fg="white", bg="#1e1e2f").pack(pady=5)
tk.Label(info_frame, textvariable=balance_var, font=('Helvetica', 12), fg="#00adb5", bg="#1e1e2f").pack(pady=5)
# Display biometric status
tk.Label(info_frame, textvariable=biometric_status_var, font=('Helvetica', 10), fg="#FFA500", bg="#1e1e2f").pack(pady=5)

# Scrollable menu area within menu_frame
canvas = tk.Canvas(menu_frame, bg="#1e1e2f", highlightthickness=0)
scroll_y = tk.Scrollbar(menu_frame, orient="vertical", command=canvas.yview)
scroll_frame = tk.Frame(canvas, bg="#1e1e2f") # Frame to hold menu items

# Configure scroll_frame to update canvas scrollregion when its size changes
scroll_frame.bind("<Configure>", lambda e: canvas.configure(scrollregion=canvas.bbox("all")))
canvas.create_window((0, 0), window=scroll_frame, anchor="nw")
canvas.configure(yscrollcommand=scroll_y.set)

# Pack canvas and scrollbar
canvas.pack(side="left", fill="both", expand=True)
scroll_y.pack(side="right", fill="y")

# Subtotal label and Submit Order button within menu_frame
subtotal_label = tk.Label(menu_frame, textvariable=subtotal_var, font=('Helvetica', 12), fg="white", bg="#1e1e2f")
subtotal_label.pack(pady=10)

submit_btn = tk.Button(menu_frame, text="Submit Order", command=lambda: submit_order(), bg="#00adb5", fg="white", font=("Helvetica", 12, "bold"))
submit_btn.pack(pady=10)

# --- Helper function for safe JSON parsing ---
def safe_json_parse(response):
    """
    Safely parse JSON response, handling cases where response is not valid JSON.
    Returns (success, data) tuple.
    """
    print(f"DEBUG: Response Status: {response.status_code}")
    print(f"DEBUG: Response Headers: {dict(response.headers)}")
    print(f"DEBUG: Raw Response Text: {response.text}")
    print(f"DEBUG: Response Content Length: {len(response.text)}")
    
    try:
        json_data = response.json()
        print(f"DEBUG: Parsed JSON: {json_data}")
        return True, json_data
    except (json.JSONDecodeError, ValueError) as e:
        print(f"DEBUG: JSON Parse Error: {e}")
        print(f"DEBUG: Returning raw text instead")
        return False, response.text

# --- Backend Communication Functions ---

def authenticate_rfid(rfid_text):
    """
    Authenticates the RFID card with the backend and retrieves JWT token.
    """
    global jwt_token
    print(f"DEBUG: Authenticating RFID: {rfid_text}")
    print(f"DEBUG: Making request to: {PROFILE_URL}auth/login/rfid")
    
    try:
        payload = {"cardID": rfid_text}
        print(f"DEBUG: Request payload: {payload}")
        
        res = requests.post(f"{PROFILE_URL}auth/login/rfid", json=payload)
        print(f"DEBUG: RFID Auth Response received")
        
        if res.status_code == 200:
            success, data = safe_json_parse(res)
            if success and isinstance(data, dict):
                jwt_token = data.get("token")
                if jwt_token:
                    print(f"DEBUG: JWT Token received: {jwt_token[:50]}...")  # Show first 50 chars
                    print("Token received. Fetching customer data...")
                    # Use the rfid_text (card ID) to fetch customer profile
                    get_customer_data(rfid_text)
                else:
                    print("DEBUG: No token in response")
                    messagebox.showerror("Error", "Authentication successful but token not received.")
            else:
                print("DEBUG: Invalid response format")
                messagebox.showerror("Error", "Invalid response format from server.")
        else:
            success, data = safe_json_parse(res)
            if success and isinstance(data, dict):
                error_msg = data.get("message", "Invalid RFID or authentication error.")
            else:
                error_msg = f"Authentication failed with status {res.status_code}: {data}"
            print(f"DEBUG: Authentication failed: {error_msg}")
            messagebox.showerror("Authentication Failed", error_msg)
    except requests.exceptions.RequestException as e:
        print(f"DEBUG: Network error during RFID auth: {e}")
        messagebox.showerror("Network Error", f"Could not connect to backend for RFID authentication: {str(e)}")
    except Exception as e:
        print(f"DEBUG: Unexpected error during RFID auth: {e}")
        messagebox.showerror("Error", f"An unexpected error occurred during RFID authentication: {str(e)}")

def get_customer_data(rfid):
    """
    Fetches customer profile data using the RFID.
    """
    print(f"DEBUG: Fetching customer data for RFID: {rfid}")
    print(f"DEBUG: Making request to: {PROFILE_URL}customer/profile/rfid/{rfid}")
    
    try:
        # Authorization header is not strictly needed for this specific endpoint
        # if your backend's customer profile by RFID endpoint is public.
        # If it requires auth, uncomment the headers.
        headers = {"Authorization": f"Bearer {jwt_token}"}
        res = requests.get(f"{PROFILE_URL}customer/profile/rfid/{rfid}") # , headers=headers)
        print(f"DEBUG: Customer data response received")
        
        if res.status_code == 200:
            success, data = safe_json_parse(res)
            if success and isinstance(data, dict):
                global customer_data
                customer_data = data
                print(f"DEBUG: Customer data loaded: {customer_data}")

                def update_ui():
                    name_var.set(f"Name: {customer_data['username']}")
                    balance_var.set(f"Balance: Rs. {customer_data['creditBalance']:.2f}")
                    show_menu() # Transition to menu display
                    biometric_status_var.set("Waiting for order...")
                root.after(0, update_ui)
            else:
                print("DEBUG: Invalid customer data format")
                root.after(0, lambda: messagebox.showerror("Error", "Invalid response format from server."))
        else:
            success, data = safe_json_parse(res)
            if success and isinstance(data, dict):
                error_msg = data.get("message", "User not found or error fetching profile.")
            else:
                error_msg = f"Failed to fetch profile with status {res.status_code}: {data}"
            print(f"DEBUG: Customer data fetch failed: {error_msg}")
            root.after(0, lambda msg=error_msg: messagebox.showerror("Error", msg))
    except requests.exceptions.RequestException as e:
        print(f"DEBUG: Network error fetching customer data: {e}")
        root.after(0, lambda: messagebox.showerror("Network Error", f"Could not connect to backend for customer data: {str(e)}"))
    except Exception as e:
        print(f"DEBUG: Unexpected error fetching customer data: {e}")
        root.after(0, lambda: messagebox.showerror("Error", f"An unexpected error occurred while fetching customer data: {str(e)}"))

def fetch_menu():
    """
    Fetches menu items from the backend.
    """
    try:
        res = requests.get(MENU_URL)
        if res.status_code == 200:
            success, data = safe_json_parse(res)
            if success and isinstance(data, list):
                global menu_items
                menu_items = data
                build_menu() # Populate the menu display
            else:
                messagebox.showerror("Error", "Invalid menu data format from server.")
        else:
            success, data = safe_json_parse(res)
            if success and isinstance(data, dict):
                error_msg = data.get("message", "Failed to load menu items.")
            else:
                error_msg = f"Failed to fetch menu with status {res.status_code}: {data}"
            messagebox.showerror("Error", error_msg)
    except requests.exceptions.RequestException as e:
        messagebox.showerror("Network Error", f"Could not connect to backend for menu: {str(e)}")
    except Exception as e:
        messagebox.showerror("Error", f"An unexpected error occurred while fetching menu: {str(e)}")
def submit_order():
    global jwt_token, customer_data, selected_items
    
    if not jwt_token:
        messagebox.showerror("Error", "No authentication token. Please scan RFID again.")
        return
    
    if not customer_data:
        messagebox.showerror("Error", "No customer data available. Please scan RFID again.")
        return
    
    if not selected_items:
        messagebox.showerror("Error", "No items selected. Please select items before submitting order.")
        return
    
    try:
        # Get customer email
        customer_email = customer_data.get("email")
        if not customer_email:
            messagebox.showerror("Error", "Customer email not found in profile.")
            return
        
        # Prepare payload in the correct format
        payload = {
            "email": customer_email,
            "items": {str(item_id): quantity for item_id, quantity in selected_items.items()},
            "scheduledTime": None  # Required field
        }
        
        headers = {"Authorization": f"Bearer {jwt_token}", "Content-Type": "application/json"}
        
        print(f"DEBUG: Submitting order: {payload}")
        biometric_status_var.set("Submitting order...")
        
        # Submit order to backend
        res = requests.post(ORDER_URL, json=payload, headers=headers)
        
        print(f"DEBUG: Order submission response status: {res.status_code}")
        print(f"DEBUG: Response text: {res.text}")
        
        if res.status_code == 200:
            response_data = res.json()
            order_id = response_data.get("id")  # Note: field is "id" not "orderId"
            
            if order_id:
                print(f"DEBUG: Order placed successfully. Order ID: {order_id}")
                biometric_status_var.set("Order placed! Starting biometric...")
                initiate_biometric_authentication(order_id)
            else:
                messagebox.showerror("Error", "Order placed but no order ID received.")
        else:
            try:
                error_data = res.json()
                error_message = error_data.get("message", f"HTTP {res.status_code} error")
            except:
                error_message = f"HTTP {res.status_code}: {res.text}"
            
            messagebox.showerror("Order Failed", error_message)
            biometric_status_var.set("Order failed. Please try again.")
            
    except requests.exceptions.RequestException as e:
        messagebox.showerror("Network Error", f"Could not connect to backend: {str(e)}")
        biometric_status_var.set("Network error. Please try again.")
    except Exception as e:
        messagebox.showerror("Error", f"Unexpected error: {str(e)}")
        biometric_status_var.set("Error occurred. Please try again.")

def initiate_biometric_authentication(order_id):
    """
    Initiates biometric authentication by sending request to Spring Boot backend.
    """
    global jwt_token, customer_data
    
    try:
        # Prepare biometric authentication request
        biometric_data = {
            "email": customer_data.get("email"),
            "orderId": order_id
        }
        
        headers = {"Authorization": f"Bearer {jwt_token}", "Content-Type": "application/json"}
        
        print(f"DEBUG: Initiating biometric authentication: {biometric_data}")
        biometric_status_var.set("Starting biometric authentication...")
        root.update()  # Force UI update
        
        # Send biometric authentication request to Spring Boot backend
        res = requests.post(f"{PROFILE_URL}biometric/initiate", json=biometric_data, headers=headers)
        
        print(f"DEBUG: Biometric auth initiation response status: {res.status_code}")
        print(f"DEBUG: Response headers: {dict(res.headers)}")
        
        if res.status_code == 200:
            response_data = res.json()
            print(f"DEBUG: Biometric authentication initiated successfully: {response_data}")
            
            # Update UI to show waiting for biometric scan
            biometric_status_var.set("Please scan your biometric...")
            root.update()
            
            # Start waiting for biometric trigger
            wait_for_biometric_trigger()
            
        else:
            print(f"DEBUG: Biometric auth initiation failed with status {res.status_code}")
            try:
                error_data = res.json()
                error_message = error_data.get("message", f"HTTP {res.status_code} error")
            except:
                error_message = f"HTTP {res.status_code}: {res.text}"
            
            print(f"DEBUG: Biometric auth error: {error_message}")
            messagebox.showerror("Biometric Authentication Failed", error_message)
            biometric_status_var.set("Biometric authentication failed.")
            
    except requests.exceptions.RequestException as e:
        print(f"DEBUG: Network error during biometric auth initiation: {str(e)}")
        messagebox.showerror("Network Error", f"Could not connect to backend for biometric authentication: {str(e)}")
        biometric_status_var.set("Network error during biometric auth.")
    except Exception as e:
        print(f"DEBUG: Unexpected error during biometric auth initiation: {str(e)}")
        messagebox.showerror("Error", f"An unexpected error occurred during biometric authentication: {str(e)}")
        biometric_status_var.set("Error during biometric authentication.")

def wait_for_biometric_trigger():
    """
    Waits for the biometric trigger from the backend.
    This function polls or waits for the backend to send the trigger to start physical scan.
    """
    try:
        print("DEBUG: Waiting for biometric trigger from backend...")
        biometric_status_var.set("Waiting for biometric trigger...")
        root.update()
        
        # This is where the backend will send a request to http://100.93.177.42:5001/trigger-biometric
        # You'll need to implement a way to receive this trigger, either through:
        # 1. A simple HTTP server running on port 5001
        # 2. Polling the backend for status
        # 3. WebSocket connection
        
        # For now, I'll implement a simple HTTP server approach
        start_biometric_trigger_server()
        
    except Exception as e:
        print(f"DEBUG: Error waiting for biometric trigger: {str(e)}")
        messagebox.showerror("Error", f"Error waiting for biometric trigger: {str(e)}")

def start_biometric_trigger_server():
    """
    Starts a simple HTTP server to receive the biometric trigger from the backend.
    """
    from http.server import HTTPServer, BaseHTTPRequestHandler
    import threading
    import json
    
    class BiometricTriggerHandler(BaseHTTPRequestHandler):
        def do_POST(self):
            if self.path == '/trigger-biometric':
                try:
                    # Read the request body
                    content_length = int(self.headers.get('Content-Length', 0))
                    post_data = self.rfile.read(content_length)
                    
                    print(f"DEBUG: Received biometric trigger: {post_data.decode()}")
                    
                    # Send response back to backend
                    self.send_response(200)
                    self.send_header('Content-type', 'application/json')
                    self.end_headers()
                    response = json.dumps({"status": "trigger_received"})
                    self.wfile.write(response.encode())
                    
                    # Update UI and start actual biometric scanning
                    root.after(0, lambda: start_biometric_scanning())
                    
                except Exception as e:
                    print(f"DEBUG: Error processing biometric trigger: {str(e)}")
                    self.send_response(500)
                    self.end_headers()
            else:
                self.send_response(404)
                self.end_headers()
        
        def log_message(self, format, *args):
            # Suppress default logging
            pass
    
    try:
        # Start HTTP server on port 5001
        server = HTTPServer(('0.0.0.0', 5001), BiometricTriggerHandler)
        server_thread = threading.Thread(target=server.serve_forever, daemon=True)
        server_thread.start()
        
        print("DEBUG: Biometric trigger server started on port 5001")
        biometric_status_var.set("Biometric trigger server ready...")
        
        # Store server reference for cleanup if needed
        global biometric_server
        biometric_server = server
        
    except Exception as e:
        print(f"DEBUG: Error starting biometric trigger server: {str(e)}")
        messagebox.showerror("Error", f"Could not start biometric trigger server: {str(e)}")

def start_biometric_scanning():
    """
    Starts the actual biometric scanning process after receiving the trigger.
    """
    try:
        print("DEBUG: Starting biometric scanning...")
        biometric_status_var.set("Starting biometric scan...")
        root.update()
        
        # This is where you would integrate with your actual biometric scanner
        # For now, I'll simulate the scanning process
        
        # Update UI to show scanning in progress
        biometric_status_var.set("Scanning biometric... Please wait...")
        root.update()
        
        # Here you would call your actual biometric scanning function
        # For example: result = scan_biometric()
        
        # Simulate scanning delay
        root.after(3000, lambda: complete_biometric_scan())
        
    except Exception as e:
        print(f"DEBUG: Error during biometric scanning: {str(e)}")
        messagebox.showerror("Error", f"Error during biometric scanning: {str(e)}")
        biometric_status_var.set("Biometric scan failed.")

def complete_biometric_scan():
    """
    Completes the biometric scan and sends results back to backend.
    """
    try:
        print("DEBUG: Completing biometric scan...")
        
        # This is where you would process the actual biometric scan results
        # For simulation, assume successful scan
        scan_successful = True  # Replace with actual scan result
        
        if scan_successful:
            biometric_status_var.set("Biometric scan successful! Processing payment...")
            
            # Send scan results back to backend
            send_biometric_results(True)
            
        else:
            biometric_status_var.set("Biometric scan failed. Please try again.")
            send_biometric_results(False)
            
    except Exception as e:
        print(f"DEBUG: Error completing biometric scan: {str(e)}")
        messagebox.showerror("Error", f"Error completing biometric scan: {str(e)}")
        biometric_status_var.set("Error during biometric scan.")

def send_biometric_results(success):
    """
    Sends biometric scan results back to the backend.
    """
    global jwt_token, customer_data
    
    try:
        result_data = {
            "email": customer_data.get("email"),
            "scanSuccess": success,
            "timestamp": int(time.time() * 1000)  # Current timestamp in milliseconds
        }
        
        headers = {"Authorization": f"Bearer {jwt_token}", "Content-Type": "application/json"}
        
        print(f"DEBUG: Sending biometric results: {result_data}")
        
        res = requests.post(f"{PROFILE_URL}biometric/result", json=result_data, headers=headers)
        
        print(f"DEBUG: Biometric result response status: {res.status_code}")
        
        if res.status_code == 200:
            response_data = res.json()
            print(f"DEBUG: Biometric results sent successfully: {response_data}")
            
            if success:
                biometric_status_var.set("Payment processed successfully!")
                # Show success message and return to main screen
                root.after(3000, lambda: reset_to_main_screen())
            else:
                biometric_status_var.set("Payment failed. Please try again.")
                
        else:
            print(f"DEBUG: Failed to send biometric results with status {res.status_code}")
            biometric_status_var.set("Error processing payment.")
            
    except Exception as e:
        print(f"DEBUG: Error sending biometric results: {str(e)}")
        messagebox.showerror("Error", f"Error sending biometric results: {str(e)}")
        biometric_status_var.set("Error processing payment.")

def reset_to_main_screen():
    """
    Resets the UI back to the main screen for the next customer.
    """
    global customer_data, jwt_token
    
    # Clear customer data
    customer_data = None
    jwt_token = None
    
    # Reset UI variables
    name_var.set("Please scan your RFID card")
    balance_var.set("")
    biometric_status_var.set("Ready for next customer")
    
    # Show main screen (you'll need to implement this based on your UI structure)
    show_main_screen()
    
    print("DEBUG: Reset to main screen completed")

# --- UI Management Functions ---

def build_menu():
    """
    Dynamically creates menu item widgets in the scrollable frame.
    """
    for widget in scroll_frame.winfo_children():
        widget.destroy()

    selected_items.clear()
    update_subtotal()

    for item in menu_items:
        item_id = item["id"]
        row = tk.Frame(scroll_frame, bg="#2e2e3f", pady=5, padx=10, relief="flat", bd=0)
        row.pack(fill="x", pady=3, padx=5)

        tk.Label(row, text=item["name"], width=15, anchor="w", fg="white", bg="#2e2e3f", font=("Helvetica", 10, "bold")).pack(side="left", padx=5)
        tk.Label(row, text=f"Rs. {item['price']:.2f}", width=10, anchor="w", fg="#00adb5", bg="#2e2e3f", font=("Helvetica", 10)).pack(side="left", padx=5)

        qty_var = tk.IntVar(value=0)

        if item_id in selected_items:
            qty_var.set(selected_items[item_id])

        def increment(qv=qty_var, iid=item_id):
            qv.set(qv.get() + 1)
            selected_items[iid] = qv.get()
            update_subtotal()

        def decrement(qv=qty_var, iid=item_id):
            if qv.get() > 0:
                qv.set(qv.get() - 1)
                if qv.get() == 0:
                    selected_items.pop(iid, None)
                else:
                    selected_items[iid] = qv.get()
                update_subtotal()

        tk.Button(row, text="-", command=decrement, width=3, bg="#ff6b6b", fg="white", font=("Helvetica", 10, "bold"), relief="raised").pack(side="left", padx=2)
        tk.Label(row, textvariable=qty_var, width=4, fg="white", bg="#2e2e3f", font=("Helvetica", 10)).pack(side="left", padx=2)
        tk.Button(row, text="+", command=increment, width=3, bg="#6bffa8", fg="white", font=("Helvetica", 10, "bold"), relief="raised").pack(side="left", padx=2)

def update_subtotal():
    """
    Calculates and updates the displayed subtotal based on selected items.
    """
    total = 0.0
    for item in menu_items:
        item_id = item["id"]
        if item_id in selected_items:
            qty = selected_items[item_id]
            total += item["price"] * qty
    subtotal_var.set(f"Subtotal: Rs. {total:.2f}")

def reset_ui():
    """
    Resets the UI to the welcome screen and clears all selections.
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

def show_menu():
    """
    Transitions the UI from welcome/info to the menu display.
    """
    welcome_frame.pack_forget()
    info_frame.pack()
    menu_frame.pack(fill="both", expand=True)
    fetch_menu() # Load menu items when showing the menu

# --- RFID Loop ---
def rfid_loop():
    """
    Continuously reads RFID cards in a background thread.
    """
    while True:
        try:
            id, text = reader.read()
            rfid_text = text.strip()
            if rfid_text:
                print(f"Read RFID card text: {rfid_text}")
                # Authenticate RFID and proceed to get customer data
                authenticate_rfid(rfid_text)
            time.sleep(2)
        except Exception as e:
            print("RFID error:", e)
            time.sleep(1)

# --- UI Client's HTTP Server for Biometric Trigger ---
class BiometricTriggerHandler(BaseHTTPRequestHandler):
    """
    Handles incoming HTTP requests from the Spring Boot Backend.
    This class is instantiated for each request.
    """
    def do_POST(self):
        if self.path == '/trigger-biometric':
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            print(f"DEBUG: Received POST request to /trigger-biometric")
            print(f"DEBUG: Content-Length: {content_length}")
            print(f"DEBUG: Raw POST data: {post_data}")
            print(f"DEBUG: Request headers: {dict(self.headers)}")
            
            try:
                payload = json.loads(post_data.decode('utf-8'))
                print(f"DEBUG: Parsed JSON payload: {payload}")
                
                email = payload.get('email')
                order_id = payload.get('orderId')
                print(f"DEBUG: Received biometric trigger from Backend: Email={email}, OrderID={order_id}")

                auth_header = self.headers.get('Authorization')
                print(f"DEBUG: Authorization header: {auth_header}")
                
                root.after(0, lambda: biometric_status_var.set("Fingerprint scan initiated. Please place finger..."))

                self.forward_to_esp32(email, order_id, auth_header)

                response_data = {"status": "success", "message": "Biometric trigger received and forwarded"}
                print(f"DEBUG: Sending response: {response_data}")
                
                self.send_response(200)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps(response_data).encode('utf-8'))

            except json.JSONDecodeError as e:
                print(f"DEBUG: JSON decode error: {e}")
                self.send_error(400, "Invalid JSON payload")
            except Exception as e:
                print(f"DEBUG: Error handling biometric trigger: {e}")
                self.send_error(500, f"Internal server error: {e}")
        else:
            print(f"DEBUG: Received request to unknown path: {self.path}")
            self.send_error(404, "Not Found")

    def forward_to_esp32(self, email, order_id, auth_header=None):
        """
        Sends the biometric verification request to the ESP32.
        Includes the Authorization header if provided.
        """
        esp32_payload = {"email": email, "orderId": order_id}

        esp32_headers = {"Content-Type": "application/json"}
        if auth_header:
            esp32_headers["Authorization"] = auth_header

        try:
            esp32_res = requests.post(ESP32_VERIFY_URL, json=esp32_payload, headers=esp32_headers, timeout=10)
            print(f"Forwarded to ESP32 [{ESP32_VERIFY_URL}]: Status={esp32_res.status_code}, Response={esp32_res.text}")
            if esp32_res.status_code == 200:
                root.after(0, lambda: biometric_status_var.set("Sent to ESP32. Waiting for fingerprint..."))
            else:
                root.after(0, lambda: biometric_status_var.set(f"Error sending to ESP32: {esp32_res.status_code}"))
                root.after(0, lambda msg=esp32_res.text: messagebox.showerror("Biometric Error", f"Could not initiate scan on ESP32: {msg}"))

        except requests.exceptions.RequestException as e:
            print(f"Network error forwarding to ESP32: {e}")
            root.after(0, lambda: biometric_status_var.set("Network error with ESP32."))
            root.after(0, lambda err=e: messagebox.showerror("Network Error", f"Could not connect to ESP32 for biometric scan: {str(err)}"))

        except Exception as e:
            print(f"Unexpected error forwarding to ESP32: {e}")
            root.after(0, lambda: biometric_status_var.set("An error occurred with ESP32."))
            root.after(0, lambda err=e: messagebox.showerror("Error", f"An unexpected error occurred while forwarding to ESP32: {str(err)}"))


def run_server():
    """
    Runs the HTTP server for the UI Client to receive triggers from the Backend.
    """
    server_address = (UI_CLIENT_SERVER_IP, UI_CLIENT_SERVER_PORT)
    httpd = HTTPServer(server_address, BiometricTriggerHandler) # HTTPServer is the base class for HTTP

    try:
        # No SSL wrapping needed for HTTP
        print(f"UI Client HTTP server listening on http://{UI_CLIENT_SERVER_IP}:{UI_CLIENT_SERVER_PORT}/")
        httpd.serve_forever()
    except Exception as e:
        print(f"Failed to start UI Client HTTP server: {e}")
        root.after(0, lambda: messagebox.showerror("Server Error", f"Failed to start UI Client HTTP server: {e}"))


# --- Main Application Execution ---

# Start the RFID reading loop in a background thread
threading.Thread(target=rfid_loop, daemon=True).start()

# Start the UI Client's HTTP server in a background thread
server_thread = threading.Thread(target=run_server, daemon=True)
server_thread.start()

try:
    # Start the Tkinter event loop. This blocks the main thread.
    root.mainloop()
finally:
    # Ensure GPIO pins are cleaned up when the Tkinter window is closed
    GPIO.cleanup()
    print("Application terminated. GPIO cleaned up.")
