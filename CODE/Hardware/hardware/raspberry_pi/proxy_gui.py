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
SPRING_BOOT_BASE_URL = "http://13.229.83.22:8081/api/"
PROFILE_URL = f"{SPRING_BOOT_BASE_URL}"
MENU_URL = f"{SPRING_BOOT_BASE_URL}menu-items"
ORDER_URL = f"{SPRING_BOOT_BASE_URL}orders/place"
BIOMETRIC_CONFIRM_URL = f"{SPRING_BOOT_BASE_URL}biometric/confirm" # ESP32 sends to this

# ESP32 Sensor Configuration
ESP32_IP = "192.168.1.110"
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

# --- Backend Communication Functions ---

def authenticate_rfid(rfid_text):
    """
    Authenticates the RFID card with the backend and retrieves JWT token.
    """
    global jwt_token
    try:
        res = requests.post(f"{PROFILE_URL}auth/login/rfid", json={"cardID": rfid_text})
        if res.status_code == 200:
            jwt_token = res.json().get("token")
            if jwt_token:
                print("Token received. Fetching customer data...")
                # Use the rfid_text (card ID) to fetch customer profile
                get_customer_data(rfid_text)
            else:
                messagebox.showerror("Error", "Authentication successful but token not received.")
        else:
            messagebox.showerror("Authentication Failed", res.json().get("message", "Invalid RFID or authentication error."))
    except requests.exceptions.RequestException as e:
        messagebox.showerror("Network Error", f"Could not connect to backend for RFID authentication: {str(e)}")
    except Exception as e:
        messagebox.showerror("Error", f"An unexpected error occurred during RFID authentication: {str(e)}")

def get_customer_data(rfid):
    """
    Fetches customer profile data using the RFID.
    """
    try:
        # Authorization header is not strictly needed for this specific endpoint
        # if your backend's customer profile by RFID endpoint is public.
        # If it requires auth, uncomment the headers.
        # headers = {"Authorization": f"Bearer {jwt_token}"}
        res = requests.get(f"{PROFILE_URL}customer/profile/rfid/{rfid}") # , headers=headers)
        if res.status_code == 200:
            global customer_data
            customer_data = res.json()

            def update_ui():
                name_var.set(f"Name: {customer_data['username']}")
                balance_var.set(f"Balance: Rs. {customer_data['creditBalance']:.2f}")
                show_menu() # Transition to menu display
                biometric_status_var.set("Waiting for order...")
            root.after(0, update_ui)
        else:
            root.after(0, lambda: messagebox.showerror("Error", res.json().get("message", "User not found or error fetching profile.")))
    except requests.exceptions.RequestException as e:
        root.after(0, lambda: messagebox.showerror("Network Error", f"Could not connect to backend for customer data: {str(e)}"))
    except Exception as e:
        root.after(0, lambda: messagebox.showerror("Error", f"An unexpected error occurred while fetching customer data: {str(e)}"))

def fetch_menu():
    """
    Fetches menu items from the backend.
    """
    try:
        res = requests.get(MENU_URL)
        if res.status_code == 200:
            global menu_items
            menu_items = res.json()
            build_menu() # Populate the menu display
        else:
            messagebox.showerror("Error", res.json().get("message", "Failed to load menu items."))
    except requests.exceptions.RequestException as e:
        messagebox.showerror("Network Error", f"Could not connect to backend for menu: {str(e)}")
    except Exception as e:
        messagebox.showerror("Error", f"An unexpected error occurred while fetching menu: {str(e)}")

def submit_order():
    """
    Submits the order to the backend. The backend will then trigger biometric auth.
    """
    global jwt_token
    if not selected_items:
        messagebox.showinfo("Empty Order", "Please select at least one item.")
        return

    email = customer_data.get("email")
    if not email:
        messagebox.showerror("Error", "Customer email not found. Please re-authenticate.")
        return

    payload = {
        "email": email,
        "items": {str(k): v for k, v in selected_items.items()},
        "scheduledTime": None
    }

    if not jwt_token:
        messagebox.showerror("Unauthorized", "Authentication token missing. Please re-authenticate.")
        return

    headers = {"Authorization": f"Bearer {jwt_token}", "Content-Type": "application/json"}
    try:
        # Send order to Spring Boot backend
        res = requests.post(ORDER_URL, json=payload, headers=headers)
        print(f"Order Submission Response [{res.status_code}]: {res.text}")

        if res.status_code == 200:
            response_data = res.json()
            order_id = response_data.get("id")
            if order_id:
                root.after(0, lambda: messagebox.showinfo("Order Submitted", f"Order #{order_id} submitted! Backend will now trigger biometric verification."))
                root.after(0, lambda: biometric_status_var.set("Order submitted. Waiting for backend to trigger biometric scan..."))
            else:
                root.after(0, lambda: messagebox.showerror("Order Error", "Order submitted, but no order ID received."))
            # Do NOT reset UI immediately. Wait for biometric confirmation or timeout.
        elif res.status_code == 400:
            error_msg = res.json().get("message", "Bad Request. Check order details.")
            root.after(0, lambda: messagebox.showerror("Order Failed", error_msg))
            reset_ui()
        elif res.status_code == 401:
            root.after(0, lambda: messagebox.showerror("Unauthorized", "Authentication required or token expired. Please re-authenticate."))
            reset_ui()
        else:
            root.after(0, lambda: messagebox.showerror("Order Failed", f"Order submission failed with status: {res.status_code}"))
            reset_ui()
    except requests.exceptions.RequestException as e:
        root.after(0, lambda: messagebox.showerror("Network Error", f"Could not connect to backend for order submission: {str(e)}"))
        reset_ui()
    except Exception as e:
        root.after(0, lambda: messagebox.showerror("Error", f"An unexpected error occurred during order submission: {str(e)}"))
        reset_ui()

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
            try:
                payload = json.loads(post_data.decode('utf-8'))
                email = payload.get('email')
                order_id = payload.get('orderId')
                print(f"Received biometric trigger from Backend: Email={email}, OrderID={order_id}")

                auth_header = self.headers.get('Authorization')
                root.after(0, lambda: biometric_status_var.set("Fingerprint scan initiated. Please place finger..."))

                self.forward_to_esp32(email, order_id, auth_header)

                self.send_response(200)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({"status": "success", "message": "Biometric trigger received and forwarded"}).encode('utf-8'))

            except json.JSONDecodeError:
                self.send_error(400, "Invalid JSON payload")
            except Exception as e:
                print(f"Error handling biometric trigger: {e}")
                self.send_error(500, f"Internal server error: {e}")
        else:
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
