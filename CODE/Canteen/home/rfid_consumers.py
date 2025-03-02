import json
from channels.generic.websocket import AsyncWebsocketConsumer

class RFIDConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.group_name = 'rfid_group'

        # Join the group
        await self.channel_layer.group_add(
            self.group_name,
            self.channel_name
        )

        await self.accept()

    async def disconnect(self, close_code):
        # Leave the group
        await self.channel_layer.group_discard(
            self.group_name,
            self.channel_name
        )

    # Receive message from the group
    async def rfid_data(self, event):
        name = event['name']

        # Send the message to WebSocket
        await self.send(text_data=json.dumps({
            'name': name
        }))
