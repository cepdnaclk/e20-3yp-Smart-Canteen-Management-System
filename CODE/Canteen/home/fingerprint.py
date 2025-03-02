import paho.mqtt.client as mqtt

# Callback when message is received from MQTT broker
def on_message(client, userdata, message):
    
    # Define a list of dictionaries, not a set
    fingerprint_users = [
    {"id": 19, "name": "maleesha"},
    {"id": 20, "name": "Pathum"},
    {"id": 21, "name": "Manuja"},
    {"id": 22, "name": "Sandun"},
    ]

    try:
        # Get the user ID from the message
        user_id = message.payload.decode("utf-8")
        print(f"Received user ID: {user_id}")  # Debugging line

        # Loop through the users and match the ID
        found_user = False  # Flag to check if user is found
        for i in fingerprint_users:
            print(f"Checking user with ID: {i['id']}")  # Debugging line

            if i['id'] == int(user_id):  # Compare IDs
                print(f"User found: {i['name']}")  # Print the name of the user if found
                found_user = True
                break

        if not found_user:
            print("User not found in the list")  # If no match is found
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
