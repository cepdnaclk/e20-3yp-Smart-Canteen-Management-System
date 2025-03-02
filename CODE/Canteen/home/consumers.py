# consumers.py
import json
from channels.generic.websocket import AsyncWebsocketConsumer

class FingerprintConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        # Perform the WebSocket connection
        self.room_group_name = 'fingerprint_data'
        await self.channel_layer.group_add(
            self.room_group_name,
            self.channel_name
        )
        await self.accept()

    async def disconnect(self, close_code):
        # Leave the group
        await self.channel_layer.group_discard(
            self.room_group_name,
            self.channel_name
        )

    async def receive(self, text_data):
        # Logic to handle messages from frontend if needed
        pass

    # Method to send MQTT data to the WebSocket
    async def send_fingerprint_data(self, user_id):
        await self.send(text_data=json.dumps({
            'user_id': user_id,
            'name': 'Name Placeholder',
            'email': 'email@domain.com',
        }))
