import threading
import requests
import json
from flask import Flask, request, jsonify
import tkinter as tk
from tkinter import ttk
import time
from mfrc522 import SimpleMFRC522
import RPi.GPIO as GPIO
import uuid
import os
import ssl
import sys

# Suppress RPi.GPIO warnings
GPIO.setwarnings(False)

# Free port 5000 at startup
try:
    os.system("fuser -k 5000/tcp")
    print("DEBUG: Attempted to free port 5000")
except Exception as e:
    print(f"DEBUG: Error freeing port 5000: {e}")

# --- Configuration ---
ESP32_IP = os.environ.get('ESP32_IP', '192.168.1.102')
ESP32_PORT = os.environ.get('ESP32_PORT', '80')
ESP32_CAPTURE_ENDPOINT = f"http://{ESP32_IP}:{ESP32_PORT}/capture"
ESP32_VERIFY_ENDPOINT = f"http://{ESP32_IP}:{ESP32_PORT}/verify"
SPRING_BOOT_URL = "http://18.142.44.110:8081"
UPDATE_DATA_URL = f"{SPRING_BOOT_URL}/api/merchant/update-biometrics-data"

app = Flask(__name__)
rfid_reader_thread = None

# --- Color Palette ---
BACKGROUND_COLOR = "#E9D9F4"  # Light lavender
PRIMARY_ACCENT = "#6A1B9A"    # Deep purple
SECONDARY_ACCENT = "#AB47BC"  # Medium purple
TEXT_COLOR = "#2E2E2E"        # Dark gray
SUCCESS_COLOR = "#4CAF50"     # Green
ERROR_COLOR = "#D32F2F"       # Red
NEUTRAL_BG = "#F5F5F5"       # Light gray

# --- Global Temporary Data Storage ---
temp_data = {
    'rfidCode': None,
    'customerEmail': None,
    'jwtToken': None
}

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

    if hasattr(app, 'gui_thread') and app.gui_thread:
        app.gui_thread.set_status("⏳ Email stored. Ready for RFID/Fingerprint.")
        app.gui_thread.start_registration()
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
    forward_headers = {
        'Content-Type': 'application/json',
        'Authorization': auth_header
    }

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
        if hasattr(app, 'gui_thread') and app.gui_thread:
            app.gui_thread.set_status(f"✅ Verification initiated for Order {backend_payload.get('orderId', 'unknown')}")
        return response_from_esp32.text, response_from_esp32.status_code, {'Content-Type': 'text/plain'}
    except requests.exceptions.Timeout:
        app.logger.error(f"Timeout while connecting to ESP32 at {ESP32_VERIFY_ENDPOINT}")
        if hasattr(app, 'gui_thread') and app.gui_thread:
            app.gui_thread.set_status("❌ ESP32 timeout during verification.")
        return jsonify({"message": "ESP32 did not respond in time"}), 504
    except requests.exceptions.ConnectionError as e:
        app.logger.error(f"Could not connect to ESP32 at {ESP32_VERIFY_ENDPOINT}: {e}")
        if hasattr(app, 'gui_thread') and app.gui_thread:
            app.gui_thread.set_status(f"❌ ESP32 connection error: {e}")
        return jsonify({"message": f"Could not connect to ESP32: {e}"}), 503
    except requests.exceptions.RequestException as e:
        app.logger.error(f"Error forwarding request to ESP32: {e}")
        if hasattr(app, 'gui_thread') and app.gui_thread:
            app.gui_thread.set_status(f"❌ ESP32 error: {e}")
        return jsonify({"message": f"Error from ESP32: {e}"}), 500
    except Exception as e:
        app.logger.error(f"An unexpected error occurred in /proxy-verify: {e}")
        if hasattr(app, 'gui_thread') and app.gui_thread:
            app.gui_thread.set_status(f"❌ Internal error: {e}")
        return jsonify({"message": f"Internal proxy error: {e}"}), 500

# --- Helper Function for ESP32 Enrollment Trigger ---
def trigger_fingerprint_enroll(rfid_code):
    if not temp_data['jwtToken']:
        print("DEBUG: No JWT token available for enrollment.")
        if hasattr(app, 'gui_thread') and app.gui_thread:
            app.gui_thread.set_status("❌ Error: No JWT token for enrollment.")
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
        if hasattr(app, 'gui_thread') and app.gui_thread:
            if response.status_code == 200:
                app.gui_thread.set_status("✅ Fingerprint enrollment triggered. Scan finger on ESP32.")
                app.gui_thread.start_timer(30)  # Start 30s timer for fingerprint scan
            else:
                app.gui_thread.set_status(f"❌ ESP32 enrollment failed: HTTP {response.status_code}")
        return response.status_code == 200
    except requests.exceptions.RequestException as e:
        print(f"DEBUG: ESP32 capture request failed: {e}")
        if hasattr(app, 'gui_thread') and app.gui_thread:
            app.gui_thread.set_status(f"❌ ESP32 connection error: {e}")
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

# --- Tkinter GUI Thread ---
class AppGUI(threading.Thread):
    def __init__(self):
        threading.Thread.__init__(self)
        self.daemon = True
        self.root = None
        self.status_label = None
        self.progress_label = None
        self.start_button = None
        self.cancel_button = None
        self.progress_bar = None
        self.cancelled = False
        self.start()

    def run(self):
        self.root = tk.Tk()
        self.timer_var = tk.StringVar(value="")
        self.root.title("Smart Canteen - Biometric Registration")
        self.root.geometry("400x300")
        self.root.configure(bg=BACKGROUND_COLOR)
        self.root.resizable(False, False)

        # Style configuration
        style = ttk.Style()
        style.theme_use('clam')
        style.configure('Custom.TButton', background=PRIMARY_ACCENT, foreground='#FFFFFF', font=('Arial', 10, 'bold'), padding=10)
        style.map('Custom.TButton', background=[('active', SECONDARY_ACCENT)], foreground=[('active', '#FFFFFF')])
        style.configure('Custom.TProgressbar', troughcolor=BACKGROUND_COLOR, background=SUCCESS_COLOR, bordercolor=PRIMARY_ACCENT)
        style.layout('Custom.TProgressbar', [
            ('Horizontal.Progressbar.trough', {
                'children': [('Horizontal.Progressbar.pbar', {'side': 'left', 'sticky': 'ns'})],
                'sticky': 'nswe'
            })
        ])

        # Main frame
        main_frame = tk.Frame(self.root, bg=BACKGROUND_COLOR)
        main_frame.pack(expand=True, fill='both', padx=20, pady=20)

        # Status Label
        self.status_label = tk.Label(main_frame, text="? Waiting for merchant...", fg=TEXT_COLOR, bg=BACKGROUND_COLOR,
                                     font=('Noto Color Emoji', 12, 'bold'), wraplength=350, justify="center")
        self.status_label.pack(pady=20)

        # Progress Bar
        self.progress_bar = ttk.Progressbar(main_frame, style='Custom.TProgressbar', mode='indeterminate', length=200)
        
        # Timer Label
        self.timer_label = tk.Label(main_frame, textvariable=self.timer_var, fg=SECONDARY_ACCENT, bg=BACKGROUND_COLOR,
                                    font=('Arial', 10), wraplength=350, justify="center")
        self.timer_label.pack(pady=10)

        # Buttons Frame
        buttons_frame = tk.Frame(main_frame, bg=BACKGROUND_COLOR)
        buttons_frame.pack(pady=10)

        # Start Button
        self.start_button = ttk.Button(buttons_frame, text="Start RFID Registration", command=self._start_registration_manual,
                                       style='Custom.TButton')
        self.start_button.pack(side='left', padx=5)
        self.start_button.config(state='disabled')
        self._add_tooltip(self.start_button, "Manually start RFID enrollment")

        # Cancel Button
        self.cancel_button = ttk.Button(buttons_frame, text="? Cancel", command=self._cancel_operation,
                                        style='Custom.TButton')
        self.cancel_button.pack(side='left', padx=5)
        self.cancel_button.config(state='disabled')
        self._add_tooltip(self.cancel_button, "Cancel the current operation")

        # Progress/Hint Label
        self.progress_label = tk.Label(main_frame, text="", fg=TEXT_COLOR, bg=BACKGROUND_COLOR,
                                       font=('Noto Color Emoji', 10), wraplength=350, justify="center")
        self.progress_label.pack(pady=10)

        self.root.mainloop()

        # Main frame
        main_frame = tk.Frame(self.root, bg=BACKGROUND_COLOR)
        main_frame.pack(expand=True, fill='both', padx=20, pady=20)

        # Status Label
        self.status_label = tk.Label(main_frame, text="⏳ Waiting for merchant...", fg=TEXT_COLOR, bg=BACKGROUND_COLOR,
                                     font=('Noto Color Emoji', 'Arial', 12, 'bold'), wraplength=350, justify="center")
        self.status_label.pack(pady=20)

        # Progress Bar
        self.progress_bar = ttk.Progressbar(main_frame, style='Custom.TProgressbar', mode='indeterminate', length=200)
        
        # Timer Label
        self.timer_label = tk.Label(main_frame, textvariable=self.timer_var, fg=SECONDARY_ACCENT, bg=BACKGROUND_COLOR,
                                    font=('Arial', 10), wraplength=350, justify="center")
        self.timer_label.pack(pady=10)

        # Buttons Frame
        buttons_frame = tk.Frame(main_frame, bg=BACKGROUND_COLOR)
        buttons_frame.pack(pady=10)

        # Start Button
        self.start_button = ttk.Button(buttons_frame, text="Start RFID Registration", command=self._start_registration_manual,
                                       style='Custom.TButton')
        self.start_button.pack(side='left', padx=5)
        self.start_button.config(state='disabled')
        self._add_tooltip(self.start_button, "Manually start RFID enrollment")

        # Cancel Button
        self.cancel_button = ttk.Button(buttons_frame, text="❌ Cancel", command=self._cancel_operation,
                                        style='Custom.TButton')
        self.cancel_button.pack(side='left', padx=5)
        self.cancel_button.config(state='disabled')
        self._add_tooltip(self.cancel_button, "Cancel the current operation")

        # Progress/Hint Label
        self.progress_label = tk.Label(main_frame, text="", fg=TEXT_COLOR, bg=BACKGROUND_COLOR,
                                       font=('Noto Color Emoji', 'Arial', 10), wraplength=350, justify="center")
        self.progress_label.pack(pady=10)

        self.root.mainloop()

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
                x, y, _, _ = self.widget.bbox("insert") or (0, 0, 0, 0)
                x += self.widget.winfo_rootx() + 25
                y += self.widget.winfo_rooty() + 25
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

    def set_status(self, message):
        print(f"DEBUG: GUI Status: {message}")
        if self.root and self.status_label:
            self.root.after(0, lambda: self.status_label.config(text=message))

    def set_progress(self, message):
        print(f"DEBUG: GUI Progress: {message}")
        if self.root and self.progress_label:
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
            self.progress_bar.pack(pady=10)
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
            self.progress_bar.pack(pady=10)
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

# --- Flask Server ---
def run_flask():
    print("DEBUG: Starting Flask app over HTTP...")
    try:
        app.run(host='0.0.0.0', port=5000, debug=False, use_reloader=False)
    except Exception as e:
        print(f"ERROR: Flask app failed to start: {e}")
        if hasattr(app, 'gui_thread') and app.gui_thread:
            app.gui_thread.set_status(f"❌ Flask server error: {e}")
        sys.exit(1)

# --- Main Execution Block ---
if __name__ == "__main__":
    GPIO.setmode(GPIO.BCM)
    app.gui_thread = AppGUI()
    max_gui_wait_time = 5
    start_wait = time.time()
    while not app.gui_thread.root and (time.time() - start_wait < max_gui_wait_time):
        time.sleep(0.1)
    if not app.gui_thread.root:
        print("ERROR: Tkinter GUI failed to initialize within expected time. Exiting.")
        GPIO.cleanup()
        sys.exit(1)
    flask_thread = threading.Thread(target=run_flask, daemon=True)
    flask_thread.start()
    try:
        app.gui_thread.join()
    except KeyboardInterrupt:
        print("\nExiting application due to KeyboardInterrupt.")
    except Exception as e:
        print(f"An unexpected error occurred in the main thread: {e}")
    finally:
        GPIO.cleanup()
        print("Application terminated. GPIO cleaned up.")
