import threading
import requests
from flask import Flask, request, jsonify
import tkinter as tk
import time
from mfrc522 import SimpleMFRC522
import RPi.GPIO as GPIO
import uuid
import os
import asyncio
from bleak import BleakClient, BleakScanner
from bleak.exc import BleakError
import logging
import datetime
import json
import http

# --- Cleanup previous Flask processes ---
os.system("fuser -k 5000/tcp")
GPIO.setwarnings(False)

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# ======================= BLE Configuration =======================
ESP32_DEVICE_NAME = "ESP32_Bio_Sensor"
SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
COMMAND_CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8"
STATUS_CHARACTERISTIC_UUID = "c5c9c331-914b-4688-b7f5-ea07361b26a9"

# ======================= Backend Configuration =======================
SPRING_BOOT_URL = "http://192.168.8.183:8081"
BACKEND_PAYMENT_FINALIZE_URL = f"{SPRING_BOOT_URL}/api/payment/finalize"
BACKEND_LOGIN_URL = f"{SPRING_BOOT_URL}/api/auth/login"

# ======================= Global State Variables =======================
app = Flask(__name__)
rfid_reader_thread = None
ble_loop = None
ble_connection_task = None
main_app_logic_task = None

current_esp32_client = None
current_jwt_token = "YOUR_STATIC_OR_DYNAMIC_JWT_TOKEN"
current_order_id_in_progress = None

import queue
rfid_event_queue = queue.Queue()

temp_data = {
    'rfidCode': None,
    'customerEmail': None,
    'jwtToken': None
}

# ======================= BLE Notification Handler =======================
def notification_handler(sender: int, data: bytearray):
    try:
        message = data.decode('utf-8').strip()
        logging.info(f"Received from ESP32: {message}")
        if hasattr(app, 'gui_thread'):
            app.gui_thread.set_status(f"ESP32: {message}")
    except Exception as e:
        logging.error(f"Error decoding BLE notification: {e}")

# ======================= Flask Endpoint =======================
@app.route('/api/merchant/request-biometrics', methods=['POST'])
def trigger_biometric_collection_flask():
    global current_jwt_token

    auth_header = request.headers.get('Authorization')
    if not auth_header or not auth_header.startswith('Bearer '):
        return jsonify({"error": "Missing or invalid Authorization header"}), 401

    current_jwt_token = auth_header.split(' ')[1]

    data = request.get_json()
    customer_email = data.get('email')

    if not customer_email:
        return jsonify({"error": "Missing customer email"}), 400

    temp_data['customerEmail'] = customer_email
    temp_data['jwtToken'] = current_jwt_token
    print(f"?? Flask: Email received: {customer_email}")
    print(f"?? Flask: JWT Token received: {current_jwt_token[:15]}...")

    if hasattr(app, 'gui_thread'):
        app.gui_thread.set_status("?? Email stored. Waiting for RFID scan...")
        app.gui_thread.start_registration()

    return jsonify({"status": "Biometric collection triggered. Awaiting RFID scan."}), 200

# ======================= RFID Reader Thread =======================
class RFIDReader(threading.Thread):
    def __init__(self, gui):
        threading.Thread.__init__(self)
        self.gui = gui
        self.reader = SimpleMFRC522()
        self.daemon = True
        self._running = True

    def run(self):
        self.gui.set_status("?? Place RFID tag to write unique ID...")
        try:
            unique_id = str(uuid.uuid4())[:8].upper()
            self.gui.set_status(f"?? Writing ID: {unique_id} to RFID tag...")
            
            id_written = self.reader.write(unique_id)
            self.gui.set_status("? RFID written. Verifying...")
            
            id_read, text = self.reader.read()
            read_value = text.strip()
            
            if read_value != unique_id:
                self.gui.set_status("? RFID Write/Verification failed! Please retry.")
                return
                
            logging.info(f"?? RFID successfully written and verified: {read_value}")
            self.gui.set_status(f"?? RFID Tag Read: {read_value}. Preparing to send to ESP32.")

            rfid_event_queue.put({
                'type': 'RFID_SCANNED',
                'rfid_code': read_value,
                'customer_email': temp_data['customerEmail'],
                'jwt_token': temp_data['jwtToken']
            })

        except Exception as e:
            logging.error(f"? RFID error in RFIDReader thread: {e}", exc_info=True)
            self.gui.set_status(f"? RFID error: {str(e)}")
        finally:
            pass 
        
        self._running = False 

    def stop(self):
        self._running = False

# ======================= GUI Thread =======================
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

        self.status_label = tk.Label(self.root, text="Starting...", fg="white", bg="black",
                                     font=("Helvetica", 12, "bold"), wraplength=350)
        self.status_label.pack(pady=30)

        self.start_button = tk.Button(self.root, text="Start RFID Registration (Manual)", command=self._start_registration_manual)
        self.start_button.pack(pady=10)
        self.start_button.config(state='disabled')

        self.progress_label = tk.Label(self.root, text="", fg="lightgray", bg="black", font=("Helvetica", 10))
        self.progress_label.pack(pady=10)

        self.root.after(100, self._check_for_updates)
        self.root.mainloop()

    def _check_for_updates(self):
        self.root.after(100, self._check_for_updates)

    def set_status(self, message):
        self.root.after(0, lambda: self.status_label.config(text=message))
        logging.info(f"?? GUI: {message}")

    def set_progress(self, progress_msg):
        self.root.after(0, lambda: self.progress_label.config(text=progress_msg))

    def enable_start_button(self):
        self.root.after(0, lambda: self.start_button.config(state='normal'))

    def disable_start_button(self):
        self.root.after(0, lambda: self.start_button.config(state='disabled'))

    def _start_registration_manual(self):
        global current_jwt_token

        if not temp_data['customerEmail']:
            temp_data['customerEmail'] = "manual_test@example.com"
        if not current_jwt_token or current_jwt_token == "YOUR_STATIC_OR_DYNAMIC_JWT_TOKEN":
            current_jwt_token = "dummy.jwt.token.for.manual.test"
            temp_data['jwtToken'] = current_jwt_token

        self.start_registration()

    def start_registration(self):
        global rfid_reader_thread
        if rfid_reader_thread and rfid_reader_thread.is_alive():
            self.set_status("RFID reader already active. Please wait.")
            return

        self.set_status("?? Initializing RFID...")
        self.disable_start_button()
        rfid_reader_thread = RFIDReader(gui=self)
        rfid_reader_thread.start()

# ======================= Main Application Logic (Asyncio) =======================
async def main_application_logic():
    global ble_loop

    while True:
        try:
            rfid_event = rfid_event_queue.get_nowait()
            if rfid_event['type'] == 'RFID_SCANNED':
                rfid_code = rfid_event['rfid_code']
                customer_email = rfid_event['customer_email']
                jwt_token_from_event = rfid_event['jwt_token']

                logging.info(f"\n--- RFID Scanned: {rfid_code}. Triggering BLE Enrollment ---")
                if current_esp32_client and current_esp32_client.is_connected:
                    if customer_email and rfid_code and jwt_token_from_event:
                        await send_enroll_request(customer_email, rfid_code, jwt_token_from_event)
                    else:
                        logging.warning("Missing email, RFID, or token for BLE enrollment request.")
                        if hasattr(app, 'gui_thread'):
                            app.gui_thread.set_status("Missing data for enrollment. Check Flask input.")
                else:
                    logging.warning("ESP32 not connected. Cannot send enrollment command via BLE.")
                    if hasattr(app, 'gui_thread'):
                        app.gui_thread.set_status("ESP32 not connected. Enrollment failed.")
                    app.gui_thread.enable_start_button()

        except queue.Empty:
            pass
        except Exception as e:
            logging.error(f"Error in main application logic processing RFID event: {e}", exc_info=True)

        await asyncio.sleep(0.1)

# ======================= BLE Command Sending =======================
async def send_enroll_request(customer_email, rfid_code, jwt_token):
    global current_esp32_client

    if not current_esp32_client or not current_esp32_client.is_connected:
        logging.error("Cannot send enrollment request: ESP32 not connected.")
        if hasattr(app, 'gui_thread'):
            app.gui_thread.set_status("ESP32 not connected. Cannot enroll.")
        return

    command = {
        "command": "enroll",
        "email": customer_email,
        "rfid": rfid_code,
        "token": jwt_token
    }
    json_command = json.dumps(command) + "\n"

    try:
        command_char = current_esp32_client.services.get_characteristic(COMMAND_CHARACTERISTIC_UUID)
        if not command_char:
            logging.error("Command characteristic not found.")
            return

        await current_esp32_client.write_gatt_char(COMMAND_CHARACTERISTIC_UUID, json_command.encode('utf-8'), response=True)
        logging.info(f"Sent enrollment command: {json_command}")
        if hasattr(app, 'gui_thread'):
            app.gui_thread.set_status(f"Sent enrollment command to ESP32.")
    except BleakError as e:
        logging.error(f"Failed to send command: {e}")

# ======================= Main Asyncio Entry Point =======================
async def run_ble_and_app_logic():
    global ble_loop, ble_connection_task, main_app_logic_task
    ble_loop = asyncio.get_event_loop()

    ble_connection_task = ble_loop.create_task(connect_to_esp32())
    main_app_logic_task = ble_loop.create_task(main_application_logic())

    await asyncio.gather(ble_connection_task, main_app_logic_task)

# ======================= BLE Connection =======================
async def connect_to_esp32():
    global current_esp32_client
    logging.info(f"Scanning for BLE device: {ESP32_DEVICE_NAME}...")

    while True:
        try:
            device = await BleakScanner.find_device_by_name(ESP32_DEVICE_NAME, timeout=10.0)
            if not device:
                logging.warning(f"Could not find device: {ESP32_DEVICE_NAME}. Retrying in 10 seconds...")
                if hasattr(app, 'gui_thread'):
                    app.gui_thread.set_status(f"Searching for ESP32: {ESP32_DEVICE_NAME}...")
                await asyncio.sleep(10)
                continue

            logging.info(f"Found {ESP32_DEVICE_NAME} at address: {device.address}. Attempting to connect...")
            if hasattr(app, 'gui_thread'):
                app.gui_thread.set_status(f"Found ESP32. Connecting...")

            client = BleakClient(device.address, services=[SERVICE_UUID])
            await client.connect()

            if client.is_connected:
                current_esp32_client = client
                logging.info(f"Successfully connected to {device.name} ({device.address})")
                if hasattr(app, 'gui_thread'):
                    app.gui_thread.set_status(f"Connected to ESP32: {device.name}. Waiting for merchant...")
                    app.gui_thread.enable_start_button()  # Enable manual button

                status_char = client.services.get_characteristic(STATUS_CHARACTERISTIC_UUID)
                if not status_char:
                    logging.error(f"Status characteristic {STATUS_CHARACTERISTIC_UUID} not found. Disconnecting.")
                    await client.disconnect()
                    current_esp32_client = None
                    continue

                command_char = client.services.get_characteristic(COMMAND_CHARACTERISTIC_UUID)
                if not command_char:
                    logging.error(f"Command characteristic {COMMAND_CHARACTERISTIC_UUID} not found. Disconnecting.")
                    await client.disconnect()
                    current_esp32_client = None
                    continue

                await client.start_notify(STATUS_CHARACTERISTIC_UUID, notification_handler)
                logging.info(f"Subscribed to characteristic {STATUS_CHARACTERISTIC_UUID}. Waiting for data...")
                return True
            else:
                logging.error(f"Failed to connect to {device.name}. Retrying in 5 seconds...")
                if hasattr(app, 'gui_thread'):
                    app.gui_thread.set_status(f"Failed to connect to ESP32. Retrying...")
                await asyncio.sleep(5)

        except BleakError as e:
            logging.error(f"BLE error during connection/scan: {e}. Retrying in 10 seconds...")
            if hasattr(app, 'gui_thread'):
                app.gui_thread.set_status(f"BLE Error. Retrying connection...")
            if current_esp32_client and current_esp32_client.is_connected:
                await current_esp32_client.disconnect()
            current_esp32_client = None
            await asyncio.sleep(10)
        except Exception as e:
            logging.error(f"An unexpected error occurred during BLE connection: {e}. Retrying in 10 seconds...", exc_info=True)
            if hasattr(app, 'gui_thread'):
                app.gui_thread.set_status(f"Unexpected Error. Retrying connection...")
            if current_esp32_client and current_esp32_client.is_connected:
                await current_esp32_client.disconnect()
            current_esp32_client = None
            await asyncio.sleep(10)

async def disconnect_esp32():
    global current_esp32_client
    if current_esp32_client and current_esp32_client.is_connected:
        logging.info("Disconnecting from ESP32...")
        try:
            await current_esp32_client.stop_notify(STATUS_CHARACTERISTIC_UUID)
            await current_esp32_client.disconnect()
            logging.info("Disconnected from ESP32.")
            if hasattr(app, 'gui_thread'):
                app.gui_thread.set_status("Disconnected from ESP32. Reconnecting...")
        except BleakError as e:
            logging.warning(f"Error during BLE disconnect: {e}")
        finally:
            current_esp32_client = None
    elif current_esp32_client:
        logging.info("Client object exists but not connected, clearing.")
        current_esp32_client = None

# ======================= Flask Server Setup =======================
def run_flask_server():
    app.run(host='0.0.0.0', port=5000, debug=False, use_reloader=False)

# ======================= Main Program Entry Point =======================
if __name__ == "__main__":
    GPIO.cleanup()

    app.gui_thread = AppGUI()

    ble_thread = threading.Thread(target=lambda: asyncio.run(run_ble_and_app_logic()), daemon=True)
    ble_thread.start()

    try:
        logging.info("Starting Flask server...")
        run_flask_server()
    except KeyboardInterrupt:
        logging.info("Flask server stopped by user (Ctrl+C).")
    except Exception as e:
        logging.critical(f"A critical error occurred in Flask server: {e}", exc_info=True)
    finally:
        logging.info("Application exiting. Cleaning up GPIO.")
        GPIO.cleanup()
        if current_esp32_client and current_esp32_client.is_connected:
            asyncio.run_coroutine_threadsafe(disconnect_esp32(), ble_loop).result(timeout=5)
        if hasattr(app.gui_thread, 'root'):
            app.gui_thread.root.quit()
        logging.info("Cleanup complete.")

