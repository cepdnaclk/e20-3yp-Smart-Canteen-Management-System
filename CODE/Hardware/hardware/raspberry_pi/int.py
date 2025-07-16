import tkinter as tk
from tkinter import ttk, messagebox
import threading
import requests
import json
from flask import Flask, request, jsonify
from mfrc522 import SimpleMFRC522
import RPi.GPIO as GPIO
import uuid
import os
import time
import sys
from PIL import Image, ImageTk
import io
from collections import defaultdict
from http.server import BaseHTTPRequestHandler, HTTPServer
import socket
import queue
import subprocess

# Suppress RPi.GPIO warnings
GPIO.setwarnings(False)

# Free ports 5000 and 5001 at startup
for port in [5000, 5001]:
    try:
        subprocess.run(["sudo", "fuser", "-k", f"{port}/tcp"], check=False, capture_output=True)
        print(f"DEBUG: Attempted to free port {port}")
    except Exception as e:
        print(f"DEBUG: Error freeing port {port}: {e}")

# --- Configuration ---
ESP32_IP = os.environ.get('ESP32_IP', '192.168.1.107')
ESP32_PORT = os.environ.get('ESP32_PORT', '80')
ESP32_CAPTURE_ENDPOINT = f"http://{ESP32_IP}:{ESP32_PORT}/capture"
ESP32_VERIFY_ENDPOINT = f"http://{ESP32_IP}:{ESP32_PORT}/verify"
SPRING_BOOT_URL = "http://18.142.44.110:8081"
UPDATE_DATA_URL = f"{SPRING_BOOT_URL}/api/merchant/update-biometrics-data"
PROFILE_URL = f"{SPRING_BOOT_URL}/api/"
MENU_URL = f"{SPRING_BOOT_URL}/api/menu-items"
ORDER_URL = f"{SPRING_BOOT_URL}/api/orders/place"
BIOMETRIC_CONFIRM_URL = f"{SPRING_BOOT_URL}/api/biometric/confirm"
UI_CLIENT_SERVER_IP = "100.93.177.42"
UI_CLIENT_SERVER_PORT = 5001

app = Flask(__name__)
rfid_reader_thread = None
biometric_server = None
biometric_queue = queue.Queue()
server_lock = threading.Lock()

# --- Color Palette ---
BACKGROUND_COLOR = "#E9D9F4"  # Light lavender
PRIMARY_ACCENT = "#6A1B9A"    # Deep purple
SECONDARY_ACCENT = "#AB47BC"  # Medium purple
TEXT_COLOR = "#2E2E2E"        # Dark gray
SUCCESS_COLOR = "#4CAF50"     # Green
ERROR_COLOR = "#D32F2F"       # Red
NEUTRAL_BG = "#F5F5F5"       # Light gray

# --- Global Variables ---
temp_data = {'rfidCode': None, 'customerEmail': None, 'jwtToken': None}
customer_data = {}
menu_items = []
selected_items = {}
jwt_token = None
image_cache = {}
cancel_operation = False

# --- Flask Endpoints ---
@app.route('/api/merchant/request-biometrics', methods=['POST'])
def trigger_biometric_collection():
    auth_header = request.headers.get('Authorization')
    if not auth_header or not auth_header.startswith('Bearer '):
        app.logger.error("Missing or invalid Authorization header for /request-biometrics.")
        return jsonify({"error": "Missing or invalid Authorization header"}), 401
    
    jwt_token = auth_header.split(' ')[1]
    temp_data['jwtToken'] = jwt_token
    
    data = request.get_json()
    customer_email = data.get('email')
    if not customer_email:
        app.logger.error("Missing customer email in /request-biometrics request.")
        return jsonify({"error": "Missing customer email"}), 400

    temp_data['customerEmail'] = customer_email
    print(f"DEBUG: Email received: {customer_email}")
    print(f"DEBUG: JWT Token received: {jwt_token[:15]}...")

    if hasattr(app, 'gui') and app.gui and isinstance(app.gui, RegistrationGUI):
        app.gui.set_status("⏳ Email stored. Ready for RFID/Fingerprint.")
        app.gui.start_registration()
    return jsonify({"status": "Biometric collection triggered"}), 200

@app.route('/proxy-verify', methods=['POST'])
def proxy_verify():
    if not request.is_json:
        app.logger.error("Request from backend to /proxy-verify is not JSON.")
        return jsonify({"message": "Request must be JSON"}), 400

    auth_header = request.headers.get('Authorization')
    if not auth_header or not auth_header.startswith('Bearer '):
        app.logger.error("Missing or invalid Authorization header for /proxy-verify.")
        return jsonify({"error": "Missing or invalid Authorization header"}), 401

    backend_payload = request.get_json()
    forward_headers = {'Content-Type': 'application/json', 'Authorization': auth_header}

    try:
        response_from_esp32 = requests.post(
            ESP32_VERIFY_ENDPOINT,
            data=json.dumps(backend_payload),
            headers=forward_headers,
            timeout=10
        )
        response_from_esp32.raise_for_status()
        app.logger.info(f"Forwarded to ESP32 /verify, response status: {response_from_esp32.status_code}")
        app.logger.info(f"Response from ESP32 /verify: {response_from_esp32.text}")
        if hasattr(app, 'gui') and app.gui:
            app.gui.set_status(f"✅ Verification initiated for Order {backend_payload.get('orderId', 'unknown')}")
        return response_from_esp32.text, response_from_esp32.status_code, {'Content-Type': 'text/plain'}
    except requests.exceptions.Timeout:
        app.logger.error(f"Timeout while connecting to ESP32 at {ESP32_VERIFY_ENDPOINT}")
        if hasattr(app, 'gui') and app.gui:
            app.gui.set_status("❌ ESP32 timeout during verification.")
        return jsonify({"message": "ESP32 did not respond in time"}), 504
    except requests.exceptions.ConnectionError as e:
        app.logger.error(f"Could not connect to ESP32 at {ESP32_VERIFY_ENDPOINT}: {e}")
        if hasattr(app, 'gui') and app.gui:
            app.gui.set_status(f"❌ ESP32 connection error: {e}")
        return jsonify({"message": f"Could not connect to ESP32: {e}"}), 503
    except requests.exceptions.RequestException as e:
        app.logger.error(f"Error forwarding request to ESP32: {e}")
        if hasattr(app, 'gui') and app.gui:
            app.gui.set_status(f"❌ ESP32 error: {e}")
        return jsonify({"message": f"Error from ESP32: {e}"}), 500
    except Exception as e:
        app.logger.error(f"An unexpected error occurred in /proxy-verify: {e}")
        if hasattr(app, 'gui') and app.gui:
            app.gui.set_status(f"❌ Internal error: {e}")
        return jsonify({"message": f"Internal proxy error: {e}"}), 500

# --- Helper Function for ESP32 Enrollment Trigger ---
def trigger_fingerprint_enroll(rfid_code):
    if not temp_data['jwtToken']:
        print("DEBUG: No JWT token available for enrollment.")
        if hasattr(app, 'gui') and app.gui:
            app.gui.set_status("❌ Error: No JWT token for enrollment.")
        return False

    try:
        print("DEBUG: Sending capture request to ESP32...")
        payload = {
            "email": temp_data['customerEmail'],
            "rfid": rfid_code,
            "token": temp_data['jwtToken']
        }
        response = requests.post(
            ESP32_CAPTURE_ENDPOINT,
            json=payload,
            timeout=30
        )
        print(f"DEBUG: ESP32 enrollment response: {response.status_code} - {response.text}")
        if hasattr(app, 'gui') and app.gui:
            if response.status_code == 200:
                app.gui.set_status("✅ Fingerprint enrollment triggered. Scan finger on ESP32.")
                app.gui.start_timer(30)
            else:
                app.gui.set_status(f"❌ ESP32 enrollment failed: HTTP {response.status_code}")
        return response.status_code == 200
    except requests.exceptions.RequestException as e:
        print(f"DEBUG: ESP32 capture request failed: {e}")
        if hasattr(app, 'gui') and app.gui:
            app.gui.set_status(f"❌ ESP32 connection error: {e}")
        return False

# --- RFID Reader Thread ---
class RFIDReader(threading.Thread):
    def __init__(self, gui):
        threading.Thread.__init__(self)
        self.gui = gui
        self.reader = SimpleMFRC522()
        self.daemon = True
        self._running = True
        self.cancelled = False

    def run(self):
        if not self._running or self.cancelled:
            return
        self.gui.set_status("⏳ Generating unique RFID...")
        try:
            unique_id = str(uuid.uuid4())[:8].upper()
            print(f"DEBUG: Writing ID: {unique_id} to RFID tag")
            self.gui.set_status("⏳ Writing to RFID tag...")
            self.reader.write(unique_id)
            self.gui.set_status("⏳ Verifying RFID tag...")
            id_read, text = self.reader.read()
            read_value = text.strip()
            if read_value != unique_id:
                print(f"DEBUG: RFID Verification failed! Written: {unique_id}, Read: {read_value}")
                self.gui.set_status("❌ RFID verification failed!")
                return
            temp_data['rfidCode'] = read_value
            print(f"DEBUG: RFID stored: {read_value}")
            self.gui.set_status("✅ RFID tag scanned successfully")
            if not self.cancelled:
                self.gui.set_progress("Place finger on ESP32 scanner...")
                if trigger_fingerprint_enroll(read_value):
                    self.gui.set_status("✅ Fingerprint enrollment in progress...")
                else:
                    self.gui.set_status("❌ Failed to start fingerprint enrollment.")
            temp_data['rfidCode'] = None
            temp_data['customerEmail'] = None
            temp_data['jwtToken'] = None
        except Exception as e:
            print(f"DEBUG: RFID error: {e}")
            self.gui.set_status(f"❌ RFID error: {str(e)}")
            temp_data['jwtToken'] = None
        finally:
            GPIO.cleanup()
            self.stop()

    def stop(self):
        self._running = False
        self.cancelled = True

# --- Launcher GUI ---
class LauncherGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("Smart Canteen - Launcher")
        self.root.geometry("800x700")
        self.root.configure(bg=BACKGROUND_COLOR)
        self.root.resizable(False, False)
        self.current_frame = None
        app.gui = None

        # Center window
        self.root.eval('tk::PlaceWindow . center')

        # Style configuration
        style = ttk.Style()
        style.theme_use('clam')
        style.configure('Custom.TButton', background=PRIMARY_ACCENT, foreground='#FFFFFF', font=('Arial', 12, 'bold'), padding=10)
        style.map('Custom.TButton', background=[('active', SECONDARY_ACCENT)], foreground=[('active', '#FFFFFF')])
        style.configure('Custom.TProgressbar', troughcolor=BACKGROUND_COLOR, background=SUCCESS_COLOR, bordercolor=PRIMARY_ACCENT)
        style.layout('Custom.TProgressbar', [
            ('Horizontal.Progressbar.trough', {
                'children': [('Horizontal.Progressbar.pbar', {'side': 'left', 'sticky': 'ns'})],
                'sticky': 'nswe'
            })
        ])

        # Show launcher frame
        self.show_launcher()

    def _add_tooltip(self, widget, text):
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
                x = self.widget.winfo_rootx() + 25
                y = self.widget.winfo_rooty() + self.widget.winfo_height() + 5
                self.tip_window = tw = tk.Toplevel(self.widget)
                tw.wm_overrideredirect(True)
                tw.wm_geometry(f"+{x}+{y}")
                label = tk.Label(tw, text=self.text, justify='left', background=NEUTRAL_BG,
                                 foreground=TEXT_COLOR, relief='solid', borderwidth=1, font=('Arial', 10))
                label.pack()

            def hide_tip(self, event=None):
                if self.tip_window:
                    self.tip_window.destroy()
                    self.tip_window = None
        Tooltip(widget, text)

    def fade_transition(self, callback=None):
        def fade_out(alpha=1.0):
            if alpha > 0:
                self.root.attributes('-alpha', alpha)
                self.root.after(30, lambda: fade_out(alpha - 0.1))
            else:
                if callback:
                    callback()
                self.root.attributes('-alpha', 1.0)
        self.root.after(0, lambda: fade_out())

    def show_launcher(self):
        if self.current_frame:
            self.current_frame.pack_forget()
        app.gui = None
        self.current_frame = tk.Frame(self.root, bg=BACKGROUND_COLOR)
        self.current_frame.pack(expand=True, fill='both', padx=20, pady=20)

        welcome_label = tk.Label(self.current_frame, text="🍽️ Welcome to Smart Canteen", fg=PRIMARY_ACCENT, bg=BACKGROUND_COLOR,
                                 font=('Noto Color Emoji', 28, 'bold'), wraplength=750, justify="center")
        welcome_label.pack(pady=50)

        buttons_frame = tk.Frame(self.current_frame, bg=BACKGROUND_COLOR)
        buttons_frame.pack(pady=20)

        reg_button = ttk.Button(buttons_frame, text="👆 Registration", command=lambda: self.fade_transition(self.show_registration), style='Custom.TButton')
        reg_button.pack(pady=10)
        self._add_tooltip(reg_button, "Enroll RFID and fingerprint")

        shop_button = ttk.Button(buttons_frame, text="🛒 Shopping", command=lambda: self.fade_transition(self.show_shopping), style='Custom.TButton')
        shop_button.pack(pady=10)
        self._add_tooltip(shop_button, "Place an order")

    def show_registration(self):
        if self.current_frame:
            self.current_frame.pack_forget()
        self.current_frame = RegistrationGUI(self.root, self.show_launcher)
        app.gui = self.current_frame
        self.current_frame.pack(expand=True, fill='both', padx=20, pady=20)

    def show_shopping(self):
        if self.current_frame:
            self.current_frame.pack_forget()
        self.current_frame = ShoppingGUI(self.root, self.show_launcher)
        app.gui = self.current_frame
        print(f"DEBUG: app.gui set to {type(app.gui).__name__}")
        self.current_frame.pack(expand=True, fill='both', padx=20, pady=20)

# --- Registration GUI ---
class RegistrationGUI(tk.Frame):
    def __init__(self, root, back_callback):
        super().__init__(root, bg=BACKGROUND_COLOR)
        self.root = root
        self.back_callback = back_callback
        self.status_label = None
        self.progress_label = None
        self.start_button = None
        self.cancel_button = None
        self.progress_bar = None
        self.cancelled = False
        self.timer_var = tk.StringVar(value="")
        self.setup_gui()

    def setup_gui(self):
        self.root.title("Smart Canteen - Biometric Registration")
        style = ttk.Style()
        style.configure('Custom.TButton', background=PRIMARY_ACCENT, foreground='#FFFFFF', font=('Arial', 12, 'bold'), padding=10)
        style.map('Custom.TButton', background=[('active', SECONDARY_ACCENT)], foreground=[('active', '#FFFFFF')])
        style.configure('Custom.TProgressbar', troughcolor=BACKGROUND_COLOR, background=SUCCESS_COLOR, bordercolor=PRIMARY_ACCENT)

        self.status_label = tk.Label(self, text="⏳ Waiting for merchant...", fg=TEXT_COLOR, bg=BACKGROUND_COLOR,
                                     font=('Noto Color Emoji', 16, 'bold'), wraplength=750, justify="center")
        self.status_label.pack(pady=50)

        self.progress_bar = ttk.Progressbar(self, style='Custom.TProgressbar', mode='indeterminate', length=300)

        self.timer_label = tk.Label(self, textvariable=self.timer_var, fg=SECONDARY_ACCENT, bg=BACKGROUND_COLOR,
                                    font=('Arial', 14), wraplength=750, justify="center")
        self.timer_label.pack(pady=20)

        buttons_frame = tk.Frame(self, bg=BACKGROUND_COLOR)
        buttons_frame.pack(pady=20)

        self.start_button = ttk.Button(buttons_frame, text="Start RFID Registration", command=self._start_registration_manual,
                                       style='Custom.TButton')
        self.start_button.pack(side='left', padx=10)
        self.start_button.config(state='disabled')
        self._add_tooltip(self.start_button, "Manually start RFID enrollment")

        self.cancel_button = ttk.Button(buttons_frame, text="❌ Cancel", command=self._cancel_operation,
                                        style='Custom.TButton')
        self.cancel_button.pack(side='left', padx=10)
        self.cancel_button.config(state='disabled')
        self._add_tooltip(self.cancel_button, "Cancel the current operation")

        back_button = ttk.Button(buttons_frame, text="⬅ Back", command=lambda: self.fade_transition(self.back_callback),
                                 style='Custom.TButton')
        back_button.pack(side='left', padx=10)
        self._add_tooltip(back_button, "Return to main menu")

        self.progress_label = tk.Label(self, text="", fg=TEXT_COLOR, bg=BACKGROUND_COLOR,
                                       font=('Noto Color Emoji', 14), wraplength=750, justify="center")
        self.progress_label.pack(pady=20)

    def set_status(self, message):
        print(f"DEBUG: Registration GUI Status: {message}")
        if self.status_label:
            self.root.after(0, lambda: self.status_label.config(text=message))

    def set_progress(self, message):
        print(f"DEBUG: Registration GUI Progress: {message}")
        if self.progress_label:
            self.root.after(0, lambda: self.progress_label.config(text=message))

    def start_timer(self, timeout):
        def update_timer(remaining):
            if remaining > 0 and not self.cancelled:
                self.timer_var.set(f"Time left: {remaining}s")
                self.root.after(1000, lambda: update_timer(remaining - 1))
            else:
                self.timer_var.set("")
        self.root.after(0, lambda: update_timer(timeout))

    def _start_registration_manual(self):
        if self.start_button:
            self.start_button.config(state='disabled')
            self.cancel_button.config(state='normal')
            self.progress_bar.pack(pady=20)
            self.progress_bar.start(10)
        self.start_registration()

    def start_registration(self):
        global rfid_reader_thread
        if self.cancelled:
            return
        self.set_status("⏳ Initializing RFID Reader...")
        if self.start_button:
            self.start_button.config(state='disabled')
            self.cancel_button.config(state='normal')
            self.progress_bar.pack(pady=20)
            self.progress_bar.start(10)
        if rfid_reader_thread and rfid_reader_thread.is_alive():
            self.set_status("❌ RFID registration already in progress.")
            return
        rfid_reader_thread = RFIDReader(gui=self)
        rfid_reader_thread.start()
        self.set_progress("Place RFID tag on the reader.")

    def _cancel_operation(self):
        global rfid_reader_thread
        self.cancelled = True
        if rfid_reader_thread and rfid_reader_thread.is_alive():
            rfid_reader_thread.stop()
        self.progress_bar.stop()
        self.progress_bar.pack_forget()
        self.cancel_button.config(state='disabled')
        self.start_button.config(state='normal')
        self.set_status("❌ Operation canceled")
        self.set_progress("")
        self.timer_var.set("")
        temp_data['rfidCode'] = None
        temp_data['customerEmail'] = None
        temp_data['jwtToken'] = None
        self.root.after(2000, lambda: [self.set_status("⏳ Waiting for merchant..."), setattr(self, 'cancelled', False)])

    def fade_transition(self, callback=None):
        def fade_out(alpha=1.0):
            if alpha > 0:
                self.root.attributes('-alpha', alpha)
                self.root.after(30, lambda: fade_out(alpha - 0.1))
            else:
                if callback:
                    callback()
                self.root.attributes('-alpha', 1.0)
        self.root.after(0, lambda: fade_out())

    def _add_tooltip(self, widget, text):
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
                x = self.widget.winfo_rootx() + 25
                y = self.widget.winfo_rooty() + self.widget.winfo_height() + 5
                self.tip_window = tw = tk.Toplevel(self.widget)
                tw.wm_overrideredirect(True)
                tw.wm_geometry(f"+{x}+{y}")
                label = tk.Label(tw, text=self.text, justify='left', background=NEUTRAL_BG,
                                 foreground=TEXT_COLOR, relief='solid', borderwidth=1, font=('Arial', 10))
                label.pack()

            def hide_tip(self, event=None):
                if self.tip_window:
                    self.tip_window.destroy()
                    self.tip_window = None
        Tooltip(widget, text)

# --- Shopping GUI ---
class ShoppingGUI(tk.Frame):
    def __init__(self, root, back_callback):
        super().__init__(root, bg=BACKGROUND_COLOR)
        self.root = root
        self.back_callback = back_callback
        self.biometric_status_var = tk.StringVar(value="Waiting for order...")
        self.name_var = tk.StringVar()
        self.balance_var = tk.StringVar()
        self.subtotal_var = tk.StringVar(value="Subtotal: Rs. 0.00")
        self.loading_dots_var = tk.StringVar(value="...")
        self.timer_var = tk.StringVar(value="")
        self.welcome_frame = None
        self.info_frame = None
        self.menu_frame = None
        self.progress_bar = None
        self.cancel_button = None
        self.submit_button = None
        self.notebook = None
        self.reader = SimpleMFRC522()
        self.setup_gui()
        self.start_rfid_loop()
        self.update_loading_dots()

    def setup_gui(self):
        self.root.title("Smart Canteen - Shopping")
        style = ttk.Style()
        style.configure('Custom.TNotebook', background=BACKGROUND_COLOR, tabmargins=[10, 5, 10, 0])
        style.configure('Custom.TNotebook.Tab', background=NEUTRAL_BG, foreground=TEXT_COLOR, padding=[20, 10], font=('Arial', 12, 'bold'))
        style.map('Custom.TNotebook.Tab', background=[('selected', PRIMARY_ACCENT), ('active', SECONDARY_ACCENT)], foreground=[('selected', '#FFFFFF'), ('active', '#FFFFFF')])
        style.configure('Custom.TButton', background=PRIMARY_ACCENT, foreground='#FFFFFF', font=('Arial', 12, 'bold'), padding=10, borderwidth=2)
        style.map('Custom.TButton', background=[('active', SECONDARY_ACCENT)], foreground=[('active', '#FFFFFF')])
        style.configure('Custom.TProgressbar', troughcolor=BACKGROUND_COLOR, background=SUCCESS_COLOR, bordercolor=PRIMARY_ACCENT)

        # Welcome Frame
        self.welcome_frame = tk.Frame(self, bg=BACKGROUND_COLOR)
        welcome_title = tk.Label(self.welcome_frame, text="🍽️ Smart Canteen", font=('Noto Color Emoji', 28, 'bold'), fg=PRIMARY_ACCENT, bg=BACKGROUND_COLOR)
        welcome_title.pack(pady=50)
        welcome_subtitle = tk.Label(self.welcome_frame, text="Tap your RFID card to start", font=('Arial', 16), fg=TEXT_COLOR, bg=BACKGROUND_COLOR)
        welcome_subtitle.pack(pady=15)
        loading_label = tk.Label(self.welcome_frame, text="💳 Ready to scan", font=('Arial', 14), fg=SUCCESS_COLOR, bg=BACKGROUND_COLOR)
        loading_label.pack(pady=20)
        loading_dots_label = tk.Label(self.welcome_frame, textvariable=self.loading_dots_var, font=('Arial', 14), fg=SUCCESS_COLOR, bg=BACKGROUND_COLOR)
        loading_dots_label.pack()
        self.welcome_frame.pack(expand=True)

        # Info Frame
        self.info_frame = tk.Frame(self, bg=BACKGROUND_COLOR)
        info_container = tk.Frame(self.info_frame, bg=NEUTRAL_BG, relief="flat", bd=2)
        info_container.pack(fill="x", padx=20, pady=10)
        info_container.grid_columnconfigure(0, weight=1)
        info_container.grid_columnconfigure(1, weight=3)
        customer_icon = tk.Label(info_container, text="👤", font=('Arial', 20), fg=PRIMARY_ACCENT, bg=NEUTRAL_BG)
        customer_icon.grid(row=0, column=0, padx=10, pady=10, sticky='w')
        customer_info = tk.Frame(info_container, bg=NEUTRAL_BG)
        customer_info.grid(row=0, column=1, sticky='w', padx=10, pady=10)
        name_label = tk.Label(customer_info, textvariable=self.name_var, font=('Arial', 16, 'bold'), fg=TEXT_COLOR, bg=NEUTRAL_BG)
        name_label.pack(anchor="w")
        balance_label = tk.Label(customer_info, textvariable=self.balance_var, font=('Arial', 14), fg=SUCCESS_COLOR, bg=NEUTRAL_BG)
        balance_label.pack(anchor="w")
        biometric_label = tk.Label(customer_info, textvariable=self.biometric_status_var, font=('Arial', 12), fg=SECONDARY_ACCENT, bg=NEUTRAL_BG)
        biometric_label.pack(anchor="w")
        timer_label = tk.Label(customer_info, textvariable=self.timer_var, font=('Arial', 12), fg=SECONDARY_ACCENT, bg=NEUTRAL_BG)
        timer_label.pack(anchor="w")

        # Menu Frame
        self.menu_frame = tk.Frame(self, bg=BACKGROUND_COLOR)
        menu_container = tk.Frame(self.menu_frame, bg=BACKGROUND_COLOR)
        menu_container.pack(fill="both", expand=True, padx=20, pady=10)
        self.notebook = ttk.Notebook(menu_container, style='Custom.TNotebook')
        self.notebook.pack(fill="both", expand=True)
        bottom_frame = tk.Frame(self.menu_frame, bg=BACKGROUND_COLOR)
        bottom_frame.pack(fill="x", padx=20, pady=10)
        subtotal_display = tk.Label(bottom_frame, textvariable=self.subtotal_var, font=('Arial', 18, 'bold'), fg=TEXT_COLOR, bg=BACKGROUND_COLOR)
        subtotal_display.pack(pady=10)
        self.progress_bar = ttk.Progressbar(bottom_frame, style='Custom.TProgressbar', mode='indeterminate', length=300)
        self.cancel_button = ttk.Button(bottom_frame, text="❌ Cancel", command=self.cancel_order, style='Custom.TButton')
        self.submit_button = ttk.Button(bottom_frame, text="🛒 Submit Order", command=self.submit_order, style='Custom.TButton')
        self.submit_button.pack(pady=10)
        self._add_tooltip(self.submit_button, "Submit your selected items")
        back_button = ttk.Button(bottom_frame, text="⬅ Back", command=lambda: self.fade_transition(self.back_callback), style='Custom.TButton')
        back_button.pack(pady=10)
        self._add_tooltip(back_button, "Return to main menu")

    def update_loading_dots(self):
        dots = self.loading_dots_var.get()
        if dots == "...":
            self.loading_dots_var.set(".")
        elif dots == ".":
            self.loading_dots_var.set("..")
        else:
            self.loading_dots_var.set("...")
        self.root.after(500, self.update_loading_dots)

    def start_timer(self, timeout):
        def update_timer(remaining):
            if remaining > 0 and not cancel_operation:
                self.timer_var.set(f"Time left: {remaining}s")
                self.root.after(1000, lambda: update_timer(remaining - 1))
            else:
                self.timer_var.set("")
        self.root.after(0, lambda: update_timer(timeout))

    def load_image_from_url(self, image_path, size=(120, 120)):
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
                return self.create_placeholder_image(size)
        except Exception as e:
            print(f"DEBUG: Error loading image {image_path}: {e}")
            return self.create_placeholder_image(size)

    def create_placeholder_image(self, size=(120, 120)):
        try:
            placeholder = Image.new('RGB', size, color=NEUTRAL_BG)
            return ImageTk.PhotoImage(placeholder)
        except Exception as e:
            print(f"DEBUG: Error creating placeholder: {e}")
            return None

    def build_menu(self):
        for tab in self.notebook.tabs():
            self.notebook.forget(tab)
        selected_items.clear()
        self.update_subtotal()
        categories = defaultdict(list)
        for item in menu_items:
            categories[item['categoryName']].append(item)
        for category_name, items in categories.items():
            self.create_category_tab(category_name, items)

    def create_category_tab(self, category_name, items):
        tab_frame = tk.Frame(self.notebook, bg=BACKGROUND_COLOR)
        self.notebook.add(tab_frame, text=f"  {self.get_category_icon(category_name)} {category_name}  ")
        canvas = tk.Canvas(tab_frame, bg=BACKGROUND_COLOR, highlightthickness=0)
        scrollbar = tk.Scrollbar(tab_frame, orient="vertical", command=canvas.yview)
        scrollable_frame = tk.Frame(canvas, bg=BACKGROUND_COLOR)
        scrollable_frame.bind("<Configure>", lambda e: canvas.configure(scrollregion=canvas.bbox("all")))
        canvas.create_window((0, 0), window=scrollable_frame, anchor="nw")
        canvas.configure(yscrollcommand=scrollbar.set)
        canvas.pack(side="left", fill="both", expand=True)
        scrollbar.pack(side="right", fill="y")
        for item in items:
            self.create_menu_item_widget(scrollable_frame, item)

    def get_category_icon(self, category_name):
        icons = {
            'BreakFast': '🌅',
            'Lunch': '🍽️',
            'Dinner': '🌙',
            'Snacks': '🍟',
            'Beverages': '🥤',
            'Desserts': '🍰'
        }
        return icons.get(category_name, '🍴')

    def create_menu_item_widget(self, parent, item):
        item_id = item["id"]
        item_frame = tk.Frame(parent, bg=NEUTRAL_BG, relief="flat", bd=2)
        item_frame.pack(fill="x", padx=10, pady=8)
        item_frame.grid_columnconfigure(1, weight=1)
        image_frame = tk.Frame(item_frame, bg=NEUTRAL_BG)
        image_frame.grid(row=0, column=0, padx=10, pady=10)
        image_widget = tk.Label(image_frame, bg=NEUTRAL_BG)
        image_widget.pack()
        def load_image():
            photo = self.load_image_from_url(item.get("image", ""), size=(120, 120))
            if photo:
                self.root.after(0, lambda: image_widget.configure(image=photo))
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
                self.update_subtotal()
        def decrement():
            current = qty_var.get()
            if current > 0:
                qty_var.set(current - 1)
                if qty_var.get() == 0:
                    selected_items.pop(item_id, None)
                else:
                    selected_items[item_id] = qty_var.get()
                self.update_subtotal()
        btn_frame = tk.Frame(controls_frame, bg=NEUTRAL_BG)
        btn_frame.pack()
        minus_btn = ttk.Button(btn_frame, text="−", command=decrement, width=4, style='Custom.TButton')
        minus_btn.pack(side="left", padx=5)
        self._add_tooltip(minus_btn, "Decrease quantity")
        qty_label = tk.Label(btn_frame, textvariable=qty_var, width=4, fg=TEXT_COLOR, bg=NEUTRAL_BG, font=("Arial", 14, "bold"))
        qty_label.pack(side="left", padx=10)
        plus_btn = ttk.Button(btn_frame, text="+", command=increment, width=4, style='Custom.TButton')
        plus_btn.pack(side="left", padx=5)
        self._add_tooltip(plus_btn, "Increase quantity")

    def update_subtotal(self):
        total = 0.0
        for item in menu_items:
            item_id = item["id"]
            if item_id in selected_items:
                qty = selected_items[item_id]
                total += item["price"] * qty
        self.subtotal_var.set(f"Subtotal: Rs. {total:.2f}")

    def show_menu(self):
        self.welcome_frame.pack_forget()
        self.info_frame.pack(fill="x")
        self.menu_frame.pack(fill="both", expand=True)
        self.fetch_menu()

    def reset_ui(self):
        global jwt_token, cancel_operation
        cancel_operation = False
        selected_items.clear()
        self.name_var.set("")
        self.balance_var.set("")
        self.subtotal_var.set("Subtotal: Rs. 0.00")
        jwt_token = None
        self.biometric_status_var.set("Ready for next customer")
        self.timer_var.set("")
        self.fade_frame_out(self.menu_frame)
        self.fade_frame_out(self.info_frame)
        self.fade_frame_in(self.welcome_frame)

    def cancel_order(self):
        global cancel_operation
        cancel_operation = True
        self.progress_bar.stop()
        self.progress_bar.pack_forget()
        self.cancel_button.pack_forget()
        self.submit_button.pack(pady=10)
        self.biometric_status_var.set("❌ Operation canceled")
        self.root.after(2000, self.reset_ui)

    def safe_json_parse(self, response):
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

    def authenticate_rfid(self, rfid_text):
        global jwt_token
        print(f"DEBUG: Authenticating RFID: {rfid_text}")
        try:
            payload = {"cardID": rfid_text}
            res = requests.post(f"{PROFILE_URL}auth/login/rfid", json=payload)
            if res.status_code == 200:
                success, data = self.safe_json_parse(res)
                if success and isinstance(data, dict):
                    jwt_token = data.get("token")
                    if jwt_token:
                        print(f"DEBUG: JWT Token received")
                        self.get_customer_data(rfid_text)
                    else:
                        self.root.after(0, lambda: messagebox.showerror("Error", "Authentication successful but token not received.", icon='error'))
                else:
                    self.root.after(0, lambda: messagebox.showerror("Error", "Invalid response format from server.", icon='error'))
            else:
                success, data = self.safe_json_parse(res)
                error_msg = data.get("message", "Invalid RFID or authentication error.") if success else f"Authentication failed with status {res.status_code}"
                self.root.after(0, lambda: messagebox.showerror("Authentication Failed", error_msg, icon='error'))
        except Exception as e:
            print(f"DEBUG: Error during RFID auth: {e}")
            self.root.after(0, lambda: messagebox.showerror("Error", f"Authentication error: {str(e)}", icon='error'))

    def get_customer_data(self, rfid):
        try:
            res = requests.get(f"{PROFILE_URL}customer/profile/rfid/{rfid}")
            if res.status_code == 200:
                success, data = self.safe_json_parse(res)
                if success and isinstance(data, dict):
                    global customer_data
                    customer_data = data
                    def update_ui():
                        self.name_var.set(f"👤 {customer_data['username']}")
                        self.balance_var.set(f"💰 Balance: Rs. {customer_data['creditBalance']:.2f}")
                        self.show_menu()
                        self.biometric_status_var.set("Ready to order...")
                    self.root.after(0, update_ui)
                else:
                    self.root.after(0, lambda: messagebox.showerror("Error", "Invalid response format.", icon='error'))
            else:
                success, data = self.safe_json_parse(res)
                error_msg = data.get("message", "User not found.") if success else "Failed to fetch profile"
                self.root.after(0, lambda: messagebox.showerror("Error", error_msg, icon='error'))
        except Exception as e:
            print(f"DEBUG: Error fetching customer data: {e}")
            self.root.after(0, lambda: messagebox.showerror("Error", f"Error fetching profile: {str(e)}", icon='error'))

    def fetch_menu(self):
        try:
            res = requests.get(MENU_URL)
            if res.status_code == 200:
                success, data = self.safe_json_parse(res)
                if success and isinstance(data, list):
                    global menu_items
                    menu_items = data
                    self.build_menu()
                else:
                    self.root.after(0, lambda: messagebox.showerror("Error", "Invalid menu data format.", icon='error'))
            else:
                self.root.after(0, lambda: messagebox.showerror("Error", "Failed to load menu.", icon='error'))
        except Exception as e:
            self.root.after(0, lambda: messagebox.showerror("Error", f"Error loading menu: {str(e)}", icon='error'))

    def submit_order(self):
        global jwt_token, customer_data, cancel_operation
        if not jwt_token or not customer_data or not selected_items:
            self.root.after(0, lambda: messagebox.showerror("Error", "Missing required data for order submission.", icon='error'))
            return
        try:
            cancel_operation = False
            self.progress_bar.pack(pady=10)
            self.progress_bar.start(10)
            self.submit_button.pack_forget()
            self.cancel_button.pack(pady=10)
            payload = {
                "email": customer_data.get("email"),
                "items": {str(item_id): quantity for item_id, quantity in selected_items.items()},
                "scheduledTime": None
            }
            headers = {"Authorization": f"Bearer {jwt_token}", "Content-Type": "application/json"}
            self.biometric_status_var.set("⏳ Submitting order...")
            res = requests.post(ORDER_URL, json=payload, headers=headers)
            self.progress_bar.stop()
            self.progress_bar.pack_forget()
            self.cancel_button.pack_forget()
            self.submit_button.pack(pady=10)
            if cancel_operation:
                return
            if res.status_code == 200:
                response_data = res.json()
                order_id = response_data.get("id")
                if order_id:
                    self.biometric_status_var.set(f"✅ Order {order_id} placed! Scan fingerprint...")
                    self.initiate_biometric_authentication(order_id)
                else:
                    self.root.after(0, lambda: messagebox.showerror("Error", "Order placed but no order ID received.", icon='error'))
            else:
                error_data = res.json() if res.headers.get('content-type') == 'application/json' else {"message": res.text}
                self.root.after(0, lambda: messagebox.showerror("Order Failed", error_data.get("message", "Order submission failed"), icon='error'))
                self.biometric_status_var.set("❌ Order failed. Please try again.")
        except Exception as e:
            self.progress_bar.stop()
            self.progress_bar.pack_forget()
            self.cancel_button.pack_forget()
            self.submit_button.pack(pady=10)
            self.root.after(0, lambda: messagebox.showerror("Error", f"Order submission error: {str(e)}", icon='error'))
            self.biometric_status_var.set("❌ Error occurred. Please try again.")

    def initiate_biometric_authentication(self, order_id):
        global jwt_token, customer_data
        try:
            biometric_data = {
                "email": customer_data.get("email"),
                "orderId": order_id
            }
            headers = {"Authorization": f"Bearer {jwt_token}", "Content-Type": "application/json"}
            self.biometric_status_var.set("🔒 Initiating biometric authentication...")
            res = requests.post(f"{PROFILE_URL}biometric/initiate", json=biometric_data, headers=headers)
            if res.status_code == 200:
                biometric_queue.put((customer_data.get("email"), order_id, headers.get("Authorization")))
                self.root.after(0, lambda: self.biometric_status_var.set(f"👆 Queued for fingerprint scan (Order {order_id}, Queue size: {biometric_queue.qsize()})"))
                self.start_timer(90)
                if not any(t.name == "BiometricQueueWorker" for t in threading.enumerate()):
                    threading.Thread(target=self.process_biometric_queue, daemon=True, name="BiometricQueueWorker").start()
            else:
                error_data = res.json() if res.headers.get('content-type') == 'application/json' else {"message": res.text}
                self.root.after(0, lambda: messagebox.showerror("Biometric Authentication Failed", error_data.get("message", "Biometric auth failed"), icon='error'))
                self.biometric_status_var.set("❌ Biometric authentication failed.")
        except Exception as e:
            print(f"DEBUG: Error during biometric auth initiation: {e}")
            self.root.after(0, lambda: messagebox.showerror("Error", f"Biometric authentication error: {str(e)}", icon='error'))
            self.biometric_status_var.set("❌ Error during biometric authentication.")

    def start_biometric_trigger_server(self, email, order_id, auth_header):
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
                                    self.root.after(0, lambda: self.start_biometric_scanning(email, order_id, received_auth_header))
                                else:
                                    print(f"DEBUG: Mismatched biometric trigger: expected {email}/{order_id}, received {received_email}/{received_order_id}")
                            elif self.path == '/queue-status':
                                print(f"DEBUG: Received queue status: {post_data.decode()}")
                                queue_size = payload.get('queueSize', 0)
                                self.root.after(0, lambda: self.biometric_status_var.set(f"👆 Queued for fingerprint scan (Order {order_id}, ESP32 Queue: {queue_size})"))
                            elif self.path == '/error':
                                print(f"DEBUG: Received error: {post_data.decode()}")
                                error_msg = payload.get('error', 'Unknown error')
                                self.root.after(0, lambda: self.biometric_status_var.set(f"❌ Biometric error: {error_msg}"))
                                self.root.after(0, lambda: messagebox.showerror("Biometric Error", error_msg, icon='error'))
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
                self.root.after(0, lambda: messagebox.showerror("Error", f"Could not start biometric server: {str(e)}", icon='error'))
                self.biometric_status_var.set("❌ Error starting biometric server.")

    def stop_biometric_trigger_server(self):
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

    def process_biometric_queue(self):
        while True:
            try:
                email, order_id, auth_header = biometric_queue.get()
                print(f"DEBUG: Processing biometric request for email: {email}, orderId: {order_id}")
                self.start_biometric_trigger_server(email, order_id, auth_header)
                biometric_queue.task_done()
            except Exception as e:
                print(f"DEBUG: Error processing biometric queue: {e}")
                self.root.after(0, lambda: self.biometric_status_var.set("❌ Error processing biometric queue."))
                self.root.after(0, lambda: messagebox.showerror("Error", f"Error processing biometric queue: {str(e)}", icon='error'))

    def start_biometric_scanning(self, email, order_id, auth_header=None):
        global cancel_operation
        try:
            print("DEBUG: Starting biometric scanning...")
            self.biometric_status_var.set(f"👆 Order {order_id}: Scan fingerprint...")
            self.root.update()
            esp32_payload = {"email": email, "orderId": order_id}
            esp32_headers = {"Content-Type": "application/json"}
            if auth_header:
                esp32_headers["Authorization"] = auth_header
            print(f"DEBUG: ESP32 payload: {esp32_payload}")
            esp32_res = requests.post(ESP32_VERIFY_ENDPOINT, json=esp32_payload, headers=esp32_headers, timeout=10)
            print(f"DEBUG: ESP32 response status: {esp32_res.status_code}")
            print(f"DEBUG: ESP32 response headers: {dict(esp32_res.headers)}")
            print(f"DEBUG: ESP32 raw response: {esp32_res.text}")
            if cancel_operation:
                return
            if esp32_res.status_code == 200:
                self.biometric_status_var.set(f"✅ Fingerprint scan initiated for Order {order_id}!")
                self.root.after(500, lambda: [self.reset_ui(), self.stop_biometric_trigger_server()])
            else:
                self.biometric_status_var.set(f"❌ ESP32 error for Order {order_id}: HTTP {esp32_res.status_code}")
                self.root.after(0, lambda: messagebox.showerror("Biometric Error", f"ESP32 returned error: {esp32_res.text}", icon='error'))
                self.stop_biometric_trigger_server()
        except requests.exceptions.RequestException as e:
            print(f"DEBUG: Network error during biometric scanning: {e}")
            self.biometric_status_var.set(f"❌ Network error during fingerprint scan for Order {order_id}.")
            self.root.after(0, lambda: messagebox.showerror("Network Error", f"Could not connect to ESP32: {str(e)}", icon='error'))
            self.stop_biometric_trigger_server()
        except Exception as e:
            print(f"DEBUG: Unexpected error during biometric scanning: {e}")
            self.biometric_status_var.set(f"❌ Error during fingerprint scan for Order {order_id}.")
            self.root.after(0, lambda: messagebox.showerror("Error", f"Unexpected error during biometric scanning: {str(e)}", icon='error'))
            self.stop_biometric_trigger_server()

    def start_rfid_loop(self):
        def rfid_loop():
            while True:
                try:
                    id, text = self.reader.read()
                    rfid_text = text.strip()
                    if rfid_text:
                        print(f"Read RFID: {rfid_text}")
                        self.authenticate_rfid(rfid_text)
                    time.sleep(0.5)
                except Exception as e:
                    print(f"RFID error: {e}")
                    time.sleep(0.5)
        if isinstance(app.gui, ShoppingGUI):
            threading.Thread(target=rfid_loop, daemon=True).start()

    def fade_frame_out(self, frame, callback=None):
        if not frame.winfo_ismapped():
            if callback:
                callback()
            return
        def fade_out(alpha=1.0):
            if alpha > 0:
                frame.winfo_toplevel().attributes('-alpha', alpha)
                frame.after(30, lambda: fade_out(alpha - 0.1))
            else:
                frame.pack_forget()
                frame.winfo_toplevel().attributes('-alpha', 1.0)
                if callback:
                    callback()
        frame.after(0, lambda: fade_out())

    def fade_frame_in(self, frame):
        frame.pack(expand=True, fill='both')
        frame.winfo_toplevel().attributes('-alpha', 0.1)
        def increase_alpha(alpha=0.1):
            if alpha < 1.0:
                frame.winfo_toplevel().attributes('-alpha', alpha)
                frame.after(30, lambda: increase_alpha(alpha + 0.1))
            else:
                frame.winfo_toplevel().attributes('-alpha', 1.0)
        frame.after(0, lambda: increase_alpha())

    def fade_transition(self, callback=None):
        def fade_out(alpha=1.0):
            if alpha > 0:
                self.root.attributes('-alpha', alpha)
                self.root.after(30, lambda: fade_out(alpha - 0.1))
            else:
                if callback:
                    callback()
                self.root.attributes('-alpha', 1.0)
        self.root.after(0, lambda: fade_out())

    def set_status(self, message):
        print(f"DEBUG: Shopping GUI Status: {message}")
        self.biometric_status_var.set(message)

    def set_progress(self, message):
        print(f"DEBUG: Shopping GUI Progress: {message}")

    def _add_tooltip(self, widget, text):
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
                x = self.widget.winfo_rootx() + 25
                y = self.widget.winfo_rooty() + self.widget.winfo_height() + 5
                self.tip_window = tw = tk.Toplevel(self.widget)
                tw.wm_overrideredirect(True)
                tw.wm_geometry(f"+{x}+{y}")
                label = tk.Label(tw, text=self.text, justify='left', background=NEUTRAL_BG,
                                 foreground=TEXT_COLOR, relief='solid', borderwidth=1, font=('Arial', 10))
                label.pack()

            def hide_tip(self, event=None):
                if self.tip_window:
                    self.tip_window.destroy()
                    self.tip_window = None
        Tooltip(widget, text)

# --- Flask Server ---
def run_flask():
    print("DEBUG: Starting Flask app on port 5000...")
    try:
        app.run(host='0.0.0.0', port=5000, debug=False, use_reloader=False)
    except Exception as e:
        print(f"ERROR: Flask app failed to start: {e}")
        if hasattr(app, 'gui') and app.gui:
            app.gui.set_status(f"❌ Flask server error: {e}")
        sys.exit(1)

# --- Main Execution ---
if __name__ == "__main__":
    GPIO.setmode(GPIO.BCM)
    root = tk.Tk()
    app.gui = None
    launcher = LauncherGUI(root)
    flask_thread = threading.Thread(target=run_flask, daemon=True)
    flask_thread.start()
    try:
        root.mainloop()
    except KeyboardInterrupt:
        print("\nExiting application due to KeyboardInterrupt.")
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
    finally:
        if biometric_server:
            biometric_server.server_close()
        GPIO.cleanup()
        print("Application terminated. GPIO cleaned up.")
