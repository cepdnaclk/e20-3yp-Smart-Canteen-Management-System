import threading
import requests
import json # Explicitly import json for json.dumps
from flask import Flask, request, jsonify
import tkinter as tk
import time
from mfrc522 import SimpleMFRC522
import RPi.GPIO as GPIO
import uuid
import os
import ssl # Import the ssl module
import sys # Import sys for sys.exit

# Suppress RPi.GPIO warnings, especially useful during development
GPIO.setwarnings(False)

# This command attempts to kill any process using port 5000.
# While useful for development to ensure the port is free,
# be cautious in production as it can forcefully terminate other services.
os.system("fuser -k 5000/tcp")

# --- Configuration ---
# ESP32 IP and Port for both capture and verification
ESP32_IP = os.environ.get('ESP32_IP', '192.168.1.102') # Default ESP32 IP, change if needed
ESP32_PORT = os.environ.get('ESP32_PORT', '80') # ESP32 web server usually runs on port 80

# Endpoints on the ESP32
ESP32_CAPTURE_ENDPOINT = f"http://{ESP32_IP}:{ESP32_PORT}/capture"
ESP32_VERIFY_ENDPOINT = f"http://{ESP32_IP}:{ESP32_PORT}/verify"

# Spring Boot Backend URL (for updating biometrics data after enrollment)
SPRING_BOOT_URL = "http://100.86.40.55:8081"
UPDATE_DATA_URL = f"{SPRING_BOOT_URL}/api/merchant/update-biometrics-data"

app = Flask(__name__)
rfid_reader_thread = None

# --- Global Temporary Data Storage ---
# Used to store data received from the backend for the enrollment process
temp_data = {
    'rfidCode': None,
    'customerEmail': None,
    'jwtToken': None  # Store token from incoming request
}

# --- Flask Endpoints ---

@app.route('/api/merchant/request-biometrics', methods=['POST'])
def trigger_biometric_collection():
    """
    Endpoint to start the biometric collection (enrollment) process.
    This is called by the Spring Boot backend to initiate RFID and fingerprint enrollment.
    """
    # Extract JWT token from Authorization header
    auth_header = request.headers.get('Authorization')
    if not auth_header or not auth_header.startswith('Bearer '):
        app.logger.error("Missing or invalid Authorization header for /request-biometrics.")
        return jsonify({"error": "Missing or invalid Authorization header"}), 401
    
    jwt_token = auth_header.split(' ')[1]
    temp_data['jwtToken'] = jwt_token # Store the token for later use in enrollment
    
    data = request.get_json()
    customer_email = data.get('email')

    if not customer_email:
        app.logger.error("Missing customer email in /request-biometrics request.")
        return jsonify({"error": "Missing customer email"}), 400

    temp_data['customerEmail'] = customer_email
    print(f"?? Email received: {customer_email}")
    print(f"?? JWT Token received: {jwt_token[:15]}...") # Print a snippet of the token

    # Check if gui_thread exists before trying to use it
    if hasattr(app, 'gui_thread') and app.gui_thread:
        app.gui_thread.set_status("?? Email stored. Ready for RFID/Fingerprint.")
        # Trigger the GUI to start the RFID registration process
        app.gui_thread.start_registration()

    return jsonify({"status": "Biometric collection triggered"}), 200

@app.route('/proxy-verify', methods=['POST'])
def proxy_verify():
    """
    Receives verification requests from the Spring Boot backend
    and forwards them to the ESP32. This acts as a proxy for the /verify endpoint on ESP32.
    """
    if not request.is_json:
        app.logger.error("Request from backend to /proxy-verify is not JSON.")
        return jsonify({"message": "Request must be JSON"}), 400

    # Prepare headers for forwarding to ESP32
    forward_headers = {
        'Content-Type': 'application/json',
        'Authorization': auth_header
    }

    try:
        # Forward the request to the ESP32's /verify endpoint
        # The ESP32 expects a JSON string, so we re-serialize the payload
        response_from_esp32 = requests.post(
            ESP32_VERIFY_ENDPOINT,
            data=json.dumps(backend_payload), # Send as JSON string
            headers=forward_headers,
            timeout=10 # Timeout in seconds for ESP32 response
        )
        response_from_esp32.raise_for_status() # Raise HTTPError for bad responses (4xx or 5xx)

        app.logger.info(f"Forwarded to ESP32 /verify, response status: {response_from_esp32.status_code}")
        app.logger.info(f"Response from ESP32 /verify: {response_from_esp32.text}")

        # Return the ESP32's response back to the Spring Boot backend
        # The ESP32 sends "Verification initiated. Waiting for fingerprint." as plain text
        # So we return it as plain text to the backend.
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

# --- Helper Function for ESP32 Enrollment Trigger ---

def trigger_fingerprint_enroll(rfid_code):
    """
    Triggers the ESP32 to capture a fingerprint and associates it with RFID and email.
    Includes the JWT token for authentication on the ESP32 side.
    """
    if not temp_data['jwtToken']:
        print("? No JWT token available for enrollment.")
        if hasattr(app, 'gui_thread') and app.gui_thread:
            app.gui_thread.set_status("? Error: No JWT token for enrollment.")
        return False

    try:
        print("?? Sending capture request to ESP32...")
        payload = {
            "email": temp_data['customerEmail'],
            "rfid": rfid_code,
            "token": temp_data['jwtToken']  # Pass token to ESP32
        }
        response = requests.post(
            ESP32_CAPTURE_ENDPOINT,
            json=payload, # requests library automatically sets Content-Type to application/json
            timeout=30 # Increased timeout for enrollment as it involves user interaction
        )
        print(f"?? ESP32 enrollment response: {response.status_code} - {response.text}")
        if hasattr(app, 'gui_thread') and app.gui_thread:
            if response.status_code == 200:
                app.gui_thread.set_status("?? ESP32 Enrollment triggered successfully.")
            else:
                app.gui_thread.set_status(f"? ESP32 Enrollment failed: {response.status_code}")
        return response.status_code == 200
    except requests.exceptions.RequestException as e:
        print(f"? ESP32 capture request failed: {e}")
        if hasattr(app, 'gui_thread') and app.gui_thread:
            app.gui_thread.set_status(f"? ESP32 connection error: {e}")
        return False

# --- RFID Reader Thread ---

class RFIDReader(threading.Thread):
    def __init__(self, gui):
        threading.Thread.__init__(self)
        self.gui = gui
        # Initialize GPIO and MFRC522 reader
        # GPIO.setmode(GPIO.BCM) is already set globally in the main block's cleanup.
        # It's good practice to ensure GPIO.setwarnings(False) is also handled once.
        self.reader = SimpleMFRC522()
        self.daemon = True # Allow the main program to exit even if this thread is running
        self._running = True

    def run(self):
        self.gui.set_status("?? Generating unique RFID...")
        try:
            # Generate a unique ID (e.g., 8 characters)
            unique_id = str(uuid.uuid4())[:8].upper()
            self.gui.set_status(f"?? Writing ID: {unique_id} to RFID tag...")
            
            # Write to RFID tag
            # SimpleMFRC522.write() typically writes up to 16 bytes.
            # Ensure the unique_id is padded or truncated if necessary for your tag/library version.
            # For example, to ensure 16 bytes: unique_id.ljust(16)[:16]
            self.reader.write(unique_id) 
            self.gui.set_status("?? RFID written. Verifying...")
            
            # Read back to verify
            id_read, text = self.reader.read()
            read_value = text.strip() # Remove any leading/trailing whitespace

            if read_value != unique_id:
                self.gui.set_status("? RFID Verification failed! Read value does not match written.")
                print(f"? RFID Verification failed! Written: {unique_id}, Read: {read_value}")
                return # Exit the thread if verification fails
                
            temp_data['rfidCode'] = read_value
            print(f"?? RFID stored: {read_value}")
            self.gui.set_status(f"?? RFID Tag Scanned: {read_value}")
            
            # Trigger ESP32 fingerprint enrollment with the stored JWT token
            if trigger_fingerprint_enroll(read_value):
                self.gui.set_status("?? Fingerprint enrollment process started on ESP32.")
            else:
                self.gui.set_status("? Failed to start enrollment or ESP32 error.")
                
            # Clear temporary data after successful enrollment attempt
            temp_data['rfidCode'] = None
            temp_data['customerEmail'] = None
            temp_data['jwtToken'] = None # Clear token after use

        except Exception as e:
            print(f"? RFID error: {e}")
            self.gui.set_status(f"? RFID error: {str(e)}")
            temp_data['jwtToken'] = None # Clear token on error
        finally:
            # Ensure GPIO cleanup happens when the thread finishes
            # This is important for the RFID reader specifically
            GPIO.cleanup()
            self.stop() # Ensure the RFID reader thread stops properly

    def stop(self):
        """Stops the RFID reader thread."""
        self._running = False
        # No need for GPIO.cleanup() here again, as it's in finally block of run()

# --- Tkinter GUI Thread ---

class AppGUI(threading.Thread):
    def __init__(self):
        threading.Thread.__init__(self)
        self.daemon = True
        self.root = None # Initialize root to None
        self.status_label = None
        self.progress_label = None
        self.start_button = None
        self.start() # This calls the run() method of the thread

    def run(self):
        self.root = tk.Tk()
        self.root.title("Smart Canteen - Biometric Registration")
        self.root.configure(bg='black')
        self.root.geometry("400x300")
        self.root.resizable(False, False) # Prevent resizing

        # Status Label
        self.status_label = tk.Label(self.root, text="Waiting for merchant...", fg="white", bg="black",
                                     font=("Helvetica", 12, "bold"), wraplength=350, justify="center")
        self.status_label.pack(pady=30, padx=10)

        # Start RFID Registration Button (manual trigger for testing/fallback)
        self.start_button = tk.Button(self.root, text="Start RFID Registration (Manual)",
                                      command=self._start_registration_manual,
                                      font=("Helvetica", 10), bg="#4CAF50", fg="white",
                                      activebackground="#45a049", relief="raised", bd=3)
        self.start_button.pack(pady=10)
        self.start_button.config(state='disabled') # Initially disabled, enabled when email is received

        # Progress/Hint Label
        self.progress_label = tk.Label(self.root, text="", fg="lightgray", bg="black", font=("Helvetica", 10))
        self.progress_label.pack(pady=10, padx=10)

        self.root.mainloop() # This call blocks and keeps the GUI thread alive

    def set_status(self, message):
        """Safely updates the main status label in the GUI."""
        print(f"?? GUI Status: {message}")
        if self.root and self.status_label: # Ensure widgets exist before updating
            self.root.after(0, lambda: self.status_label.config(text=message))
            # self.root.update_idletasks() # Not strictly necessary with after(0) but can help immediate refresh

    def set_progress(self, progress_msg):
        """Safely updates the progress/hint label in the GUI."""
        print(f"?? GUI Progress: {progress_msg}")
        if self.root and self.progress_label: # Ensure widgets exist before updating
            self.root.after(0, lambda: self.progress_label.config(text=progress_msg))
            # self.root.update_idletasks()

    def _start_registration_manual(self):
        """Manual trigger for RFID registration (e.g., via button click)."""
        if self.start_button:
            self.start_button.config(state='disabled') # Disable button immediately to prevent multiple clicks
        self.start_registration()

    def start_registration(self):
        """
        Initiates the RFID reading process in a separate thread.
        Called either manually or by the Flask endpoint.
        """
        global rfid_reader_thread
        self.set_status("?? Initializing RFID Reader...")
        
        # Ensure the button is disabled during the process
        if self.start_button:
            self.start_button.config(state='disabled')
            
        # Ensure only one RFID reader thread is active
        if rfid_reader_thread and rfid_reader_thread.is_alive():
            self.set_status("? RFID registration already in progress.")
            return

        rfid_reader_thread = RFIDReader(gui=self)
        rfid_reader_thread.start()
        self.set_progress("Place RFID tag on the reader.")


# --- Main Execution Block ---

# ... (rest of your imports and code) ...

def run_flask():
    """Starts the Flask web server without SSL."""
    print("?? Starting Flask app over HTTP...")
    try:
        # Flask's run() method for development server.
        # Listen on 0.0.0.0 to accept connections from Tailscale IP.
        # No ssl_context for HTTP.
        app.run(host='0.0.0.0',
                port=5000, # Your desired port
                debug=False,
                use_reloader=False) # Important for threading
    except Exception as e:
        print(f"\nERROR: Flask app failed to start: {e}")
        sys.exit(1) # Exit on Flask startup errors

# ... (rest of your main execution block) ...

if __name__ == "__main__":
    # Initialize GPIO settings once for the entire application
    GPIO.setmode(GPIO.BCM) # Use BCM numbering for GPIO pins

    # Initialize the GUI thread first
    app.gui_thread = AppGUI()
    
    # Wait for the GUI thread to actually start its mainloop and create widgets.
    # This is a more robust check than a fixed sleep, preventing race conditions.
    max_gui_wait_time = 5 # seconds
    start_wait = time.time()
    while not app.gui_thread.root and (time.time() - start_wait < max_gui_wait_time):
        time.sleep(0.1)
    
    if not app.gui_thread.root:
        print("? ERROR: Tkinter GUI failed to initialize within expected time. Exiting.")
        GPIO.cleanup() # Clean up GPIO before exiting
        sys.exit(1) # Exit if GUI is mandatory and fails to start

    # Start the Flask server in a separate thread
    flask_thread = threading.Thread(target=run_flask, daemon=True)
    flask_thread.start()

    # The main thread now explicitly waits for the GUI thread to complete.
    # The AppGUI thread's run() method contains self.root.mainloop(),
    # which is a blocking call. So, this join() will effectively keep the
    # main process alive as long as the GUI window is open.
    try:
        app.gui_thread.join() # Wait for the GUI thread to finish
    except KeyboardInterrupt:
        print("\nExiting application due to KeyboardInterrupt.")
    except Exception as e:
        print(f"\nAn unexpected error occurred in the main thread: {e}")
    finally:
        # Perform final GPIO cleanup when the entire application is shutting down.
        # This ensures cleanup even if the GUI is closed manually or an error occurs.
        GPIO.cleanup()
        print("Application terminated. GPIO cleaned up.")


            

