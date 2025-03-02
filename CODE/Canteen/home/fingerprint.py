import paho.mqtt.client as mqtt

# Callback when message is received from MQTT broker
def on_message(client, userdata, message):
    
    try:
        user_id = message.payload.decode("utf-8")  # Get the user ID from the message
        print(f"Received message: {user_id}")

        # Use the user_id to fetch the data and send it via WebSocket
        # Example code to send to frontend via WebSocket or Channels layer

    except Exception as e:
        print(f"Error processing the message: {e}")

def setup_mqtt():
    client = mqtt.Client()
    client.on_message = on_message  # Define the callback for received messages

    # Connect to the MQTT broker
    client.connect("test.mosquitto.org", 1883, 60)

    # Subscribe to the topic
    client.subscribe("fingerprint/data")

    # Start the MQTT loop to listen for messages
    client.loop_forever()
