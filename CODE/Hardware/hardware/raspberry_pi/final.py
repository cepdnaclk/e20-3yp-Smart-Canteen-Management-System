import threading
import requests
from flask import Flask, request, jsonify
import tkinter as tk
import time
from mfrc522 import SimpleMFRC522
import RPi.GPIO as GPIO
import uuid 

ESP32_IP = "http://192.168.8.192"  # Replace with actual ESP32 IP
ESP32_CAPTURE_ENDPOINT = f"{ESP32_IP}/capture"
SPRING_BACKEND_URL = "http://192.168.8.183:8081/api/merchant/update-biometrics-data"

app = Flask(__name__)
rfid_reader_thread = None

temp_data = {
    'rfidCode': None,
    'fingerprintId': None,
    'customerEmail': None
}

@app.route('/api/merchant/request-biometrics', methods=['POST'])
def trigger_biometric_collection():
    data = request.get_json()
    customer_email = data.get('email')

    if not customer_email:
        return jsonify({"error": "Missing customer email"}), 400

    temp_data['customerEmail'] = customer_email
    print(f"?? Email received: {customer_email}")

    if hasattr(app, 'gui_thread'):
        app.gui_thread.set_status("?? Triggering fingerprint enrollment...")
        app.gui_thread.start_registration()

    return jsonify({"status": "Biometric collection triggered"}), 200

@app.route('/api/fingerprint/register', methods=['POST'])
def receive_fingerprint():
    data = request.get_json()
    fingerprint_id = data.get('fingerprintId')
    if not fingerprint_id:
        return jsonify({"error": "Missing fingerprintId"}), 400

    temp_data['fingerprintId'] = fingerprint_id
    print(f"?? Fingerprint Received: {fingerprint_id}")

    if temp_data['rfidCode'] is not None:
        send_to_backend()

    return jsonify({"status": "Fingerprint received"}), 200
 

def trigger_fingerprint_enroll():
    try:
        print("?? Sending capture request to ESP32...")
        response = requests.get(ESP32_CAPTURE_ENDPOINT, timeout=30)
        print(f"ESP32 response: {response.status_code} - {response.text}")
        return response.status_code == 200
    except requests.exceptions.RequestException as e:
        print(f"? ESP32 request failed: {e}")
        return False

def send_to_backend():
    if all([temp_data['rfidCode'], temp_data['fingerprintId'], temp_data['customerEmail']]):
        payload = {
            "cardID": temp_data['rfidCode'],
            "fingerprintID": temp_data['fingerprintId'],
            "email": temp_data['customerEmail']
        }
        try:
            print("?? Sending to Spring Boot backend:", payload)
            response = requests.post(SPRING_BACKEND_URL, json=payload)
            print("? Backend response:", response.text)
            if hasattr(app, 'gui_thread'):
                app.gui_thread.set_status(f"? Sent to backend: {response.status_code}")
            for key in temp_data:
                temp_data[key] = None
        except Exception as e:
            print("? Error sending to backend:", e)
            if hasattr(app, 'gui_thread'):
                app.gui_thread.set_status("? Backend error")

 # For generating a unique ID

class RFIDReader(threading.Thread):
    def __init__(self, gui):
        threading.Thread.__init__(self)
        self.gui = gui
        self.reader = SimpleMFRC522()
        self.daemon = True
        self._running = True
        self.start()

    def run(self):
        self.gui.set_status("?? Generating unique RFID ID...")
        try:
            # 1. Generate unique ID (e.g., UUID)
            unique_id = str(uuid.uuid4())[:8]  # Take only first 8 characters for brevity
            self.gui.set_status(f"?? Writing ID: {unique_id} to RFID tag...")

            # 2. Prompt user to place tag and write
            id_written = self.reader.write(unique_id)
            self.gui.set_status(f"? Written ID to tag. Now verifying...")

            # 3. Read the tag to verify
            id_read, text = self.reader.read()
            read_value = text.strip()

            temp_data['rfidCode'] = read_value
            print(f"? RFID written and read: {read_value}")
            self.gui.set_status(f"RFID stored: {read_value}")

            # 4. Trigger ESP32 fingerprint enrollment
            if trigger_fingerprint_enroll():
                self.gui.set_status("?? Enrolling fingerprint via ESP32...")
            else:
                self.gui.set_status("? Failed to trigger ESP32")

            # 5. Wait for fingerprint data from ESP32
            for _ in range(15):
                if temp_data['fingerprintId']:
                    send_to_backend()
                    break
                time.sleep(1)

        except Exception as e:
            print("? Error during RFID write/read:", e)
            self.gui.set_status("?? RFID write/read error")
        finally:
            GPIO.cleanup()
            self.stop()

    def stop(self):
        self._running = False


class AppGUI(threading.Thread):
    def __init__(self):
        threading.Thread.__init__(self)
        self.daemon = True
        self.start()

    def run(self):
        self.root = tk.Tk()
        self.root.title("Smart Canteen - Biometric Registration")
        self.root.configure(bg='black')
        self.root.geometry("400x300")

        self.status_label = tk.Label(self.root, text="Waiting for merchant...", fg="white", bg="black", font=("Helvetica", 12, "bold"), wraplength=350)
        self.status_label.pack(pady=30)

        self.start_button = tk.Button(self.root, text="Start Registration", command=self.start_registration,
                                      font=("Helvetica", 12, "bold"), bg="#007BFF", fg="white", activebackground="#0056b3", relief="raised")
        self.start_button.pack(pady=20)

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

    def start_registration(self):
        global rfid_reader_thread
        self.set_status("?? Initializing RFID scan...")
        self.start_button.config(state='disabled')
        rfid_reader_thread = RFIDReader(gui=self)

def run_flask():
    app.run(host='0.0.0.0', port=5000, debug=False, use_reloader=False)

if __name__ == "__main__":
    app.gui_thread = AppGUI()
    run_flask()

