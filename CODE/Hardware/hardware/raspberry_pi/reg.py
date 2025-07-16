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

# Kill any process using port 5000
os.system("fuser -k 5000/tcp")

# --- Configuration ---
ESP32_IP = os.environ.get('ESP32_IP', '192.168.1.110')
ESP32_PORT = os.environ.get('ESP32_PORT', '80')

# Endpoints on the ESP32
ESP32_CAPTURE_ENDPOINT = f"http://{ESP32_IP}:{ESP32_PORT}/capture"
ESP32_VERIFY_ENDPOINT = f"http://{ESP32_IP}:{ESP32_PORT}/verify"
ESP32_STATUS_ENDPOINT = f"http://{ESP32_IP}:{ESP32_PORT}/status"

# Spring Boot Backend URL
SPRING_BOOT_URL = "http://13.229.83.22:8081"
UPDATE_DATA_URL = f"{SPRING_BOOT_URL}/api/merchant/update-biometrics-data"

app = Flask(__name__)
rfid_reader_thread = None

# --- Global Data Storage ---
temp_data = {
    'rfidCode': None,
    'customerEmail': None,
    'jwtToken': None
}

# ESP32 connection status
esp32_connection_status = {
    'connected': False,
    'last_check': 0,
    'check_interval': 10  # Check every 10 seconds
}

# --- ESP32 Connection Functions ---

def check_esp32_connection():
    """Check if ESP32 is reachable and responsive."""
    try:
        response = requests.get(ESP32_STATUS_ENDPOINT, timeout=5)
        if response.status_code == 200:
            esp32_connection_status['connected'] = True
            esp32_connection_status['last_check'] = time.time()
            return True
    except requests.exceptions.RequestException:
        pass
    
    esp32_connection_status['connected'] = False
    esp32_connection_status['last_check'] = time.time()
    return False

def get_esp32_status():
    """Get current ESP32 connection status, checking if needed."""
    current_time = time.time()
    if (current_time - esp32_connection_status['last_check']) > esp32_connection_status['check_interval']:
        check_esp32_connection()
    return esp32_connection_status['connected']

def wait_for_esp32_connection(gui=None):
    """Wait for ESP32 connection with UI feedback."""
    max_attempts = 30  # Maximum attempts (5 minutes with 10-second intervals)
    attempt = 0
    
    while attempt < max_attempts:
        if gui:
            gui.set_status(f"🔄 Connecting to fingerprint sensor... (Attempt {attempt + 1}/{max_attempts})")
            gui.set_progress("Please wait while we establish connection with the fingerprint sensor.")
        
        if check_esp32_connection():
            if gui:
                gui.set_status("✅ Connected to fingerprint sensor successfully!")
                gui.set_progress("System ready for biometric registration.")
            return True
        
        attempt += 1
        time.sleep(10)  # Wait 10 seconds between attempts
    
    if gui:
        gui.set_status("❌ Failed to connect to fingerprint sensor")
        gui.set_progress("Please check the sensor connection and try again.")
    return False

# --- Flask Endpoints ---

@app.route('/api/merchant/request-biometrics', methods=['POST'])
def trigger_biometric_collection():
    """Endpoint to start the biometric collection process."""
    # Extract JWT token from Authorization header
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
    print(f"📧 Email received: {customer_email}")
    print(f"🔑 JWT Token received: {jwt_token[:15]}...")

    # Check if gui_thread exists before trying to use it
    if hasattr(app, 'gui_thread') and app.gui_thread:
        app.gui_thread.set_customer_email(customer_email)
        app.gui_thread.enable_registration()

    return jsonify({"status": "Biometric collection triggered"}), 200

@app.route('/proxy-verify', methods=['POST'])
def proxy_verify():
    """Proxy verification requests to ESP32."""
    if not request.is_json:
        app.logger.error("Request from backend to /proxy-verify is not JSON.")
        return jsonify({"message": "Request must be JSON"}), 400

    # Check ESP32 connection first
    if not get_esp32_status():
        return jsonify({"message": "Fingerprint sensor not connected"}), 503

    auth_header = request.headers.get('Authorization')
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

        return response_from_esp32.text, response_from_esp32.status_code, {'Content-Type': 'text/plain'}

    except requests.exceptions.Timeout:
        app.logger.error(f"Timeout while connecting to ESP32 at {ESP32_VERIFY_ENDPOINT}")
        return jsonify({"message": "ESP32 did not respond in time"}), 504
    except requests.exceptions.ConnectionError as e:
        app.logger.error(f"Could not connect to ESP32 at {ESP32_VERIFY_ENDPOINT}: {e}")
        return jsonify({"message": f"Could not connect to ESP32: {e}"}), 503
    except requests.exceptions.RequestException as e:
        app.logger.error(f"Error forwarding request to ESP32: {e}")
        return jsonify({"message": f"Error from ESP32: {e}"}), 500
    except Exception as e:
        app.logger.error(f"An unexpected error occurred in /proxy-verify: {e}")
        return jsonify({"message": f"Internal proxy error: {e}"}), 500

# --- Helper Functions ---

def trigger_fingerprint_enroll(rfid_code):
    """Trigger ESP32 fingerprint enrollment."""
    if not temp_data['jwtToken']:
        print("❌ No JWT token available for enrollment.")
        if hasattr(app, 'gui_thread') and app.gui_thread:
            app.gui_thread.set_status("❌ Error: No JWT token for enrollment.")
        return False

    # Check ESP32 connection before attempting enrollment
    if not get_esp32_status():
        print("❌ ESP32 not connected.")
        if hasattr(app, 'gui_thread') and app.gui_thread:
            app.gui_thread.set_status("❌ Fingerprint sensor not connected.")
        return False

    try:
        print("📤 Sending capture request to ESP32...")
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
        print(f"📥 ESP32 enrollment response: {response.status_code} - {response.text}")
        
        if hasattr(app, 'gui_thread') and app.gui_thread:
            if response.status_code == 200:
                app.gui_thread.set_status("✅ Fingerprint enrollment started successfully.")
                app.gui_thread.set_progress("Please place your finger on the sensor when prompted.")
            else:
                app.gui_thread.set_status(f"❌ ESP32 Enrollment failed: {response.status_code}")
        
        return response.status_code == 200
    except requests.exceptions.RequestException as e:
        print(f"❌ ESP32 capture request failed: {e}")
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

    def run(self):
        self.gui.set_status("🔄 Generating unique RFID...")
        try:
            # Generate a unique ID
            unique_id = str(uuid.uuid4())[:8].upper()
            self.gui.set_status(f"✏️ Writing ID: {unique_id} to RFID tag...")
            self.gui.set_progress("Please place the RFID tag on the reader.")
            
            # Write to RFID tag
            self.reader.write(unique_id)
            self.gui.set_status("🔍 RFID written. Verifying...")
            
            # Read back to verify
            id_read, text = self.reader.read()
            read_value = text.strip()

            if read_value != unique_id:
                self.gui.set_status("❌ RFID Verification failed! Read value does not match written.")
                print(f"❌ RFID Verification failed! Written: {unique_id}, Read: {read_value}")
                return
                
            temp_data['rfidCode'] = read_value
            print(f"✅ RFID stored: {read_value}")
            self.gui.set_status(f"✅ RFID Tag Successfully Created: {read_value}")
            
            # Trigger ESP32 fingerprint enrollment
            if trigger_fingerprint_enroll(read_value):
                self.gui.set_status("👆 Please place your finger on the sensor for enrollment.")
                self.gui.set_progress("Follow the prompts on the fingerprint sensor.")
            else:
                self.gui.set_status("❌ Failed to start fingerprint enrollment.")
                
            # Clear temporary data after successful enrollment attempt
            temp_data['rfidCode'] = None
            temp_data['customerEmail'] = None
            temp_data['jwtToken'] = None

        except Exception as e:
            print(f"❌ RFID error: {e}")
            self.gui.set_status(f"❌ RFID error: {str(e)}")
            temp_data['jwtToken'] = None
        finally:
            GPIO.cleanup()
            self.stop()

    def stop(self):
        """Stops the RFID reader thread."""
        self._running = False

# --- Enhanced Tkinter GUI Thread ---

class AppGUI(threading.Thread):
    def __init__(self):
        threading.Thread.__init__(self)
        self.daemon = True
        self.root = None
        self.status_label = None
        self.progress_label = None
        self.customer_label = None
        self.connection_label = None
        self.start_button = None
        self.connection_indicator = None
        self.esp32_connected = False
        self.start()

    def run(self):
        self.root = tk.Tk()
        self.root.title("Smart Canteen - Biometric Registration")
        self.root.configure(bg='#1e1e1e')
        self.root.geometry("500x400")
        self.root.resizable(False, False)

        # Title
        title_label = tk.Label(self.root, text="Smart Canteen", 
                              fg="#4CAF50", bg="#1e1e1e",
                              font=("Helvetica", 20, "bold"))
        title_label.pack(pady=10)

        subtitle_label = tk.Label(self.root, text="Biometric Registration System", 
                                 fg="white", bg="#1e1e1e",
                                 font=("Helvetica", 12))
        subtitle_label.pack(pady=5)

        # Connection Status Frame
        conn_frame = tk.Frame(self.root, bg="#1e1e1e")
        conn_frame.pack(pady=10, padx=20, fill='x')

        self.connection_indicator = tk.Label(conn_frame, text="●", 
                                           fg="red", bg="#1e1e1e",
                                           font=("Helvetica", 16))
        self.connection_indicator.pack(side='left')

        self.connection_label = tk.Label(conn_frame, text="Connecting to fingerprint sensor...", 
                                       fg="white", bg="#1e1e1e",
                                       font=("Helvetica", 10))
        self.connection_label.pack(side='left', padx=10)

        # Customer Info
        self.customer_label = tk.Label(self.root, text="No customer selected", 
                                      fg="#FFD700", bg="#1e1e1e",
                                      font=("Helvetica", 10, "italic"))
        self.customer_label.pack(pady=5)

        # Main Status Label
        self.status_label = tk.Label(self.root, text="Initializing system...", 
                                    fg="white", bg="#1e1e1e",
                                    font=("Helvetica", 12, "bold"), 
                                    wraplength=450, justify="center")
        self.status_label.pack(pady=20, padx=20)

        # Progress Label
        self.progress_label = tk.Label(self.root, text="", 
                                     fg="lightgray", bg="#1e1e1e", 
                                     font=("Helvetica", 10),
                                     wraplength=450, justify="center")
        self.progress_label.pack(pady=10, padx=20)

        # Start Button
        self.start_button = tk.Button(self.root, text="Start Registration Process",
                                     command=self._start_registration_manual,
                                     font=("Helvetica", 12, "bold"), 
                                     bg="#4CAF50", fg="white",
                                     activebackground="#45a049", 
                                     relief="raised", bd=3,
                                     padx=20, pady=10)
        self.start_button.pack(pady=20)
        self.start_button.config(state='disabled')

        # Start ESP32 connection check in background
        self.check_esp32_connection_periodically()

        self.root.mainloop()

    def check_esp32_connection_periodically(self):
        """Periodically check ESP32 connection status."""
        def check_connection():
            connected = check_esp32_connection()
            self.update_connection_status(connected)
            
            # Schedule next check
            self.root.after(10000, check_connection)  # Check every 10 seconds
        
        # Start the first check after 1 second
        self.root.after(1000, check_connection)

    def update_connection_status(self, connected):
        """Update the connection status indicator."""
        if connected:
            self.connection_indicator.config(fg="#4CAF50")
            self.connection_label.config(text="Fingerprint sensor connected")
            self.esp32_connected = True
            # If we have a customer email, enable the button
            if temp_data['customerEmail']:
                self.enable_registration()
        else:
            self.connection_indicator.config(fg="red")
            self.connection_label.config(text="Fingerprint sensor disconnected")
            self.esp32_connected = False
            self.start_button.config(state='disabled')

    def set_status(self, message):
        """Safely updates the main status label."""
        print(f"📱 GUI Status: {message}")
        if self.root and self.status_label:
            self.root.after(0, lambda: self.status_label.config(text=message))

    def set_progress(self, progress_msg):
        """Safely updates the progress label."""
        print(f"📊 GUI Progress: {progress_msg}")
        if self.root and self.progress_label:
            self.root.after(0, lambda: self.progress_label.config(text=progress_msg))

    def set_customer_email(self, email):
        """Display customer email."""
        if self.root and self.customer_label:
            self.root.after(0, lambda: self.customer_label.config(text=f"Customer: {email}"))

    def enable_registration(self):
        """Enable the registration button when conditions are met."""
        if self.esp32_connected and temp_data['customerEmail']:
            self.start_button.config(state='normal')
            self.set_status("✅ System ready for biometric registration")
            self.set_progress("Click 'Start Registration Process' to begin.")

    def _start_registration_manual(self):
        """Manual trigger for registration."""
        if not self.esp32_connected:
            self.set_status("❌ Cannot start: Fingerprint sensor not connected")
            return
        
        if not temp_data['customerEmail']:
            self.set_status("❌ Cannot start: No customer email provided")
            return
        
        self.start_button.config(state='disabled')
        self.start_registration()

    def start_registration(self):
        """Initiate the RFID reading process."""
        global rfid_reader_thread
        
        if not self.esp32_connected:
            self.set_status("❌ Cannot start: Fingerprint sensor not connected")
            return
        
        self.set_status("🔄 Initializing RFID Reader...")
        self.set_progress("Please wait while we prepare the RFID system.")
        
        if rfid_reader_thread and rfid_reader_thread.is_alive():
            self.set_status("⚠️ RFID registration already in progress.")
            return

        rfid_reader_thread = RFIDReader(gui=self)
        rfid_reader_thread.start()

# --- Flask Runner ---

def run_flask():
    """Starts the Flask web server."""
    print("🚀 Starting Flask app over HTTP...")
    try:
        app.run(host='0.0.0.0',
                port=5000,
                debug=False,
                use_reloader=False)
    except Exception as e:
        print(f"\n❌ ERROR: Flask app failed to start: {e}")
        sys.exit(1)

# --- Main Execution ---

if __name__ == "__main__":
    # Initialize GPIO settings
    GPIO.setmode(GPIO.BCM)

    # Initialize the GUI thread
    app.gui_thread = AppGUI()
    
    # Wait for GUI to initialize
    max_gui_wait_time = 5
    start_wait = time.time()
    while not app.gui_thread.root and (time.time() - start_wait < max_gui_wait_time):
        time.sleep(0.1)
    
    if not app.gui_thread.root:
        print("❌ ERROR: Tkinter GUI failed to initialize within expected time. Exiting.")
        GPIO.cleanup()
        sys.exit(1)

    # Start Flask server in separate thread
    flask_thread = threading.Thread(target=run_flask, daemon=True)
    flask_thread.start()

    # Wait for GUI thread to complete
    try:
        app.gui_thread.join()
    except KeyboardInterrupt:
        print("\n👋 Exiting application due to KeyboardInterrupt.")
    except Exception as e:
        print(f"\n❌ An unexpected error occurred in the main thread: {e}")
    finally:
        GPIO.cleanup()
        print("✅ Application terminated. GPIO cleaned up.")