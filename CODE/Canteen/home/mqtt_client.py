import paho.mqtt.client as mqtt

# Callback when message is received from MQTT broker
# mqtt_client.py
from channels.layers import get_channel_layer

def on_message(client, userdata, message):
    try:
        user_id = message.payload.decode("utf-8")  # Get the user ID from the message

        # Get the channel layer
        channel_layer = get_channel_layer()

        # Send the user ID to the WebSocket group
        channel_layer.group_send(
            'fingerprint_data',  # This should match the room group name
            {
                'type': 'send_fingerprint_data',
                'user_id': user_id,
            }
        )

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
