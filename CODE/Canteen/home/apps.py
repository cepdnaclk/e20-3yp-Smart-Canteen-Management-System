from django.apps import AppConfig


class HomeConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "home"
    
    def ready(self):
        # Import and run the MQTT setup when Django starts
        from .mqtt_client import setup_mqtt
        setup_mqtt()
