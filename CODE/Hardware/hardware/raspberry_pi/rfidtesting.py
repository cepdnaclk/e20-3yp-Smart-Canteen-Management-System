from mfrc522 import SimpleMFRC522

reader = SimpleMFRC522()

try:
    print("Hold tag near reader...")
    id, text = reader.read()
    print(f"ID: {id}")
    print(f"Text: {text}")
except Exception as e:
    print("Error:", e)
finally:
    import RPi.GPIO as GPIO
    GPIO.cleanup()
