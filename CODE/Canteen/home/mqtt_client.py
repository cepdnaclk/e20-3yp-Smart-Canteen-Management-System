# import paho.mqtt.client as mqtt

# # Callback when message is received from MQTT broker
# # mqtt_client.py
# from channels.layers import get_channel_layer

# def on_message(client, userdata, message):
#     try:
#         user_id = message.payload.decode("utf-8")  # Get the user ID from the message

#         # Get the channel layer
#         channel_layer = get_channel_layer()

#         # Send the user ID to the WebSocket group
#         channel_layer.group_send(
#             'fingerprint_data',  # This should match the room group name
#             {
#                 'type': 'send_fingerprint_data',
#                 'user_id': user_id,
#             }
#         )

#     except Exception as e:
#         print(f"Error processing the message: {e}")


# def setup_mqtt():
#     client = mqtt.Client()
#     client.on_message = on_message  # Define the callback for received messages

#     # Connect to the MQTT broker
#     client.connect("test.mosquitto.org", 1883, 60)

#     # Subscribe to the topic
#     client.subscribe("fingerprint/data")

#     # Start the MQTT loop to listen for messages
#     client.loop_forever()

import threading
import paho.mqtt.client as mqtt

# Callback when message is received from MQTT broker
def on_message(client, userdata, message):
    try:
        user_id = message.payload.decode("utf-8")  # Get the user ID from the message
        print(f"Received message: {user_id}")
        
        # Use the user_id to fetch data or send it to the frontend
        # Example code to send to frontend or save in DB

    except Exception as e:
        print(f"Error processing the message: {e}")

# MQTT setup function that runs in a separate thread
def setup_mqtt():
    client = mqtt.Client()
    client.on_message = on_message  # Define the callback for received messages

    # Connect to the MQTT broker
    client.connect("test.mosquitto.org", 1883, 60)

    # Subscribe to the topic
    client.subscribe("fingerprint/data")

    # Start the MQTT loop to listen for messages
    client.loop_start()  # Use loop_start to avoid blocking

# Start MQTT in a separate thread to avoid blocking the server
def start_mqtt_in_thread():
    mqtt_thread = threading.Thread(target=setup_mqtt)
    mqtt_thread.daemon = True  # Make it a daemon thread so it stops when the main process stops
    mqtt_thread.start()
