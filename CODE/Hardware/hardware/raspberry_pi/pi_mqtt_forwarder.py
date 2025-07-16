import paho.mqtt.client as mqtt
import requests
import json

# MQTT Settings
MQTT_BROKER = "localhost"
MQTT_PORT = 1883
MQTT_USER = "backend_user"
MQTT_PASSWORD = "1234"  # Replace with actual password
MQTT_TOPIC = "biometric/commands"

# ESP32 Settings
ESP32_IP = "192.168.1.100"  # Update with ESP32 IP
ESP32_PORT = 80

def on_connect(client, userdata, flags, rc):
    print(f"Connected to MQTT broker with code {rc}")
    client.subscribe(MQTT_TOPIC)

def on_message(client, userdata, msg):
    try:
        payload = json.loads(msg.payload.decode())
        command = payload["command"]
        user_id = payload.get("user_id", "")
        
        print(f"Received command: {command} for user: {user_id}")
        
        # Forward to ESP32
        response = requests.post(
            f"http://{ESP32_IP}:{ESP32_PORT}/fingerprint",
            json={"command": command, "user_id": user_id},
            timeout=5
        )
        
        print(f"ESP32 response: {response.status_code} - {response.text}")
        
    except Exception as e:
        print(f"Error processing message: {str(e)}")

client = mqtt.Client()
client.username_pw_set(MQTT_USER, MQTT_PASSWORD)
client.on_connect = on_connect
client.on_message = on_message

client.connect(MQTT_BROKER, MQTT_PORT, 60)
print("Listening for MQTT messages...")
client.loop_forever()
