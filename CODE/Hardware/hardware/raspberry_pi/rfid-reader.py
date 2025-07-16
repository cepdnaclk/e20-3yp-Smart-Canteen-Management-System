import paho.mqtt.client as mqtt
import time
import RPi.GPIO as GPIO
from mfrc522 import SimpleMFRC522

GPIO.setwarnings(False)

# MQTT Configuration
#MQTT_BROKER = "test.mosquitto.org"
MQTT_PORT = 1883
MQTT_TOPIC = "rfid/data"

# Alternative broker options (uncomment if needed)
# MQTT_BROKER = "broker.hivemq.com"
MQTT_BROKER = "broker.emqx.io"

reader = SimpleMFRC522()

def on_connect(client, userdata, flags, reason_code, properties):
    if reason_code == 0:
        print("Connected to MQTT broker")
    else:
        print(f"Connection failed: {mqtt.connack_string(reason_code)}")

client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2)
client.on_connect = on_connect

try:
    print(f"Attempting connection to {MQTT_BROKER}:{MQTT_PORT}")
    client.connect_async(MQTT_BROKER, MQTT_PORT, 60)
    client.loop_start()

    # Wait up to 10 seconds for connection
    for _ in range(20):
        if client.is_connected():
            break
        time.sleep(0.5)
    else:
        raise Exception("Connection timeout after 10 seconds")

except Exception as e:
    print(f"Connection error: {e}")
    print("Possible causes:")
    print("- No internet connection")
    print("- Firewall blocking port 1883")
    print("- Broker temporarily unavailable")
    print("- Network DNS issues")
    GPIO.cleanup()
    exit()

try:
    while True:
        print("Place your card...")
        id, text = reader.read()
        print(f"Card ID: {id}")
        
        if client.is_connected():
            rc, mid = client.publish(MQTT_TOPIC, str(id))
            if rc == mqtt.MQTT_ERR_SUCCESS:
                print("Message published")
            else:
                print(f"Publish error: {mqtt.error_string(rc)}")
        else:
            print("Lost connection to broker")
            
        time.sleep(2)

except KeyboardInterrupt:
    print("\nShutting down...")
    client.loop_stop()
    client.disconnect()
    GPIO.cleanup()
