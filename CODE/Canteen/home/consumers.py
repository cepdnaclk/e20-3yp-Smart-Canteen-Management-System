from channels.generic.websocket import AsyncWebsocketConsumer
import json

class FingerprintConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        # Join the fingerprint group
        self.group_name = "fingerprint_group"
        await self.channel_layer.group_add(
            self.group_name,
            self.channel_name
        )
        await self.accept()

    async def disconnect(self, close_code):
        # Leave the fingerprint group
        await self.channel_layer.group_discard(
            self.group_name,
            self.channel_name
        )

    # Receive message from WebSocket
    async def receive(self, text_data):
        pass

    # Receive message from MQTT via WebSocket
    async def fingerprint_data(self, event):
        name = event['name']
        
        # Send data to WebSocket
        await self.send(text_data=json.dumps({
            'name': name,
        }))
