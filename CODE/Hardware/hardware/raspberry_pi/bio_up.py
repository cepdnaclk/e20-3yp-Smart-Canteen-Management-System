import threading
import requests
from flask import Flask, request, jsonify
import tkinter as tk
import time
from mfrc522 import SimpleMFRC522
import RPi.GPIO as GPIO
import uuid
import os

os.system("fuser -k 5000/tcp")

# Configuration
ESP32_IP = "http://192.168.1.105"
SPRING_BOOT_URL = "http://192.168.1.102:8081"
ESP32_CAPTURE_ENDPOINT = f"{ESP32_IP}/capture"
UPDATE_DATA_URL = f"{SPRING_BOOT_URL}/api/merchant/update-biometrics-data"

app = Flask(__name__)
rfid_reader_thread = None

temp_data = {
    'rfidCode': None,
    'customerEmail': None,
    'jwtToken': None  # Store token from incoming request
}

@app.route('/api/merchant/request-biometrics', methods=['POST'])
def trigger_biometric_collection():
    """Endpoint to start biometric collection process"""
    # Extract JWT token from Authorization header
    auth_header = request.headers.get('Authorization')
    if not auth_header or not auth_header.startswith('Bearer '):
        return jsonify({"error": "Missing or invalid Authorization header"}), 401
    
    jwt_token = auth_header.split(' ')[1]
    temp_data['jwtToken'] = jwt_token
    
    data = request.get_json()
    customer_email = data.get('email')

    if not customer_email:
        return jsonify({"error": "Missing customer email"}), 400

    temp_data['customerEmail'] = customer_email
    print(f"?? Email received: {customer_email}")
    print(f"?? JWT Token received: {jwt_token[:15]}...")

    if hasattr(app, 'gui_thread'):
        app.gui_thread.set_status("?? Email stored")
        app.gui_thread.start_registration()

    return jsonify({"status": "Biometric collection triggered"}), 200

# ... (previous code remains the same) ...

def trigger_fingerprint_enroll(rfid_code):
    """Trigger ESP32 to capture fingerprint with JWT token"""
    if not temp_data['jwtToken']:
        print("? No JWT token available")
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
            json=payload,
            timeout=30
        )
        print(f"?? ESP32 response: {response.status_code} - {response.text}")
        return response.status_code == 200
    except requests.exceptions.RequestException as e:
        print(f"? ESP32 request failed: {e}")
        return False

# ... (RFIDReader class remains the same) ...

class RFIDReader(threading.Thread):
    def __init__(self, gui):
        threading.Thread.__init__(self)
        self.gui = gui
        self.reader = SimpleMFRC522()
        self.daemon = True
        self._running = True

    def run(self):
        self.gui.set_status("?? Generating unique RFID...")
        try:
            # Generate unique ID
            unique_id = str(uuid.uuid4())[:8].upper()
            self.gui.set_status(f"?? Writing ID: {unique_id}...")
            
            # Write to RFID tag
            id_written = self.reader.write(unique_id)
            self.gui.set_status("? RFID written. Verifying...")
            
            # Read back to verify
            id_read, text = self.reader.read()
            read_value = text.strip()
            
            if read_value != unique_id:
                self.gui.set_status("? Verification failed!")
                return
                
            temp_data['rfidCode'] = read_value
            print(f"?? RFID stored: {read_value}")
            self.gui.set_status(f"?? RFID: {read_value}")
            
            # Trigger ESP32 fingerprint enrollment with JWT
            if trigger_fingerprint_enroll(read_value):
                self.gui.set_status("?? Fingerprint enrollment started")
            else:
                self.gui.set_status("? Failed to start enrollment")
                
            # Clear temporary data
            temp_data['rfidCode'] = None
            temp_data['customerEmail'] = None
            temp_data['jwtToken'] = None  # Clear token after use

        except Exception as e:
            print(f"? RFID error: {e}")
            self.gui.set_status(f"? RFID error: {str(e)}")
            temp_data['jwtToken'] = None  # Clear token on error
        finally:
            GPIO.cleanup()
            self.stop()

    def stop(self):
        self._running = False
        GPIO.cleanup()

class AppGUI(threading.Thread):
    def __init__(self):
        threading.Thread.__init__(self)
        self.daemon = True
        self.start() # This calls run()

    def run(self):
        self.root = tk.Tk()
        self.root.title("Smart Canteen - Biometric Registration")
        self.root.configure(bg='black')
        self.root.geometry("400x300")

        self.status_label = tk.Label(self.root, text="Waiting for merchant...", fg="white", bg="black",
                                     font=("Helvetica", 12, "bold"), wraplength=350)
        self.status_label.pack(pady=30)

        # ----------------------------------------------------
        # ADD THIS BUTTON HERE
        self.start_button = tk.Button(self.root, text="Start RFID Registration", command=self._start_registration_manual)
        self.start_button.pack(pady=10)
        # ----------------------------------------------------

        self.progress_label = tk.Label(self.root, text="", fg="lightgray", bg="black", font=("Helvetica", 10))
        self.progress_label.pack(pady=10)

        self.root.mainloop()

    def set_status(self, message):
        print(f"?? GUI: {message}")
        self.status_label.config(text=message)
        self.root.update_idletasks()

    def set_progress(self, progress_msg):
        self.progress_label.config(text=progress_msg)
        self.root.update_idletasks()
    # Add a new method to be called by the button
    def _start_registration_manual(self):
        # This calls the original start_registration, but is triggered by the button
        self.start_registration()

    def start_registration(self): # This method is now called by the Flask endpoint AND the manual button
        global rfid_reader_thread
        self.set_status("?? Initializing RFID...")
        # Ensure the button exists before trying to configure it
        if hasattr(self, 'start_button'): # Add this check
            self.start_button.config(state='disabled')
        rfid_reader_thread = RFIDReader(gui=self)
        rfid_reader_thread.start()

def run_flask():
    app.run(host='0.0.0.0', port=5000, debug=False, use_reloader=False)

if __name__ == "__main__":
    app.gui_thread = AppGUI()
    run_flask()
