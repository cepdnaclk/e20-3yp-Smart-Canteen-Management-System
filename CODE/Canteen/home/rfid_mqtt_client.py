import threading
import paho.mqtt.client as mqtt
from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync
import webbrowser

# Example RFID user data
rfid_users = [
    {"id": 220750260546, "name": "Ali"},
    {"id": 14344990078, "name": "Zara"},
    {"id": 1003, "name": "Ahmed"},
    {"id": 1004, "name": "Sami"},
    {"id": 1005, "name": "Khalid"},
]

# Callback function for processing RFID messages
def on_rfid_message(client, userdata, message):
    try:
        rfid_id = message.payload.decode("utf-8")
        print(f"Received RFID message: {rfid_id}")

        # Find the user associated with the RFID ID
        for user in rfid_users:
            if user['id'] == int(rfid_id):
                print(f"RFID Success: {user['name']}")
                # Optionally open a new page for the user (you can remove this if you don't want it)
                webbrowser.open_new_tab(f"http://127.0.0.1:8000/fingerprintTest/{user['name']}")

                # Send the user name to the frontend via WebSocket
                channel_layer = get_channel_layer()
                async_to_sync(channel_layer.group_send)(
                    "rfid_group",  # Group name for RFID data
                    {
                        'type': 'rfid_data',  # Message type
                        'name': user['name'],  # The user's name
                    }
                )
                break

    except Exception as e:
        print(f"Error processing the RFID message: {e}")

# MQTT setup function for RFID
def setup_rfid_mqtt():
    client = mqtt.Client()
    client.on_message = on_rfid_message  # Define the callback for RFID messages

    # Connect to the MQTT broker
    client.connect("test.mosquitto.org", 1883, 60)

    # Subscribe to the RFID topic
    client.subscribe("rfid/data")

    # Start the MQTT loop to listen for messages
    client.loop_start()

# Function to start MQTT in a separate thread for RFID
def start_rfid_mqtt_in_thread():
    mqtt_thread = threading.Thread(target=setup_rfid_mqtt)
    mqtt_thread.daemon = True  # Make it a daemon thread to stop when the main process stops
    mqtt_thread.start()
