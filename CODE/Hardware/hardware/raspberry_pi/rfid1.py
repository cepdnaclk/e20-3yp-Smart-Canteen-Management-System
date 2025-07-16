import requests

# ---- CONFIGURATION ----
springboot_url = "http://192.168.8.183:8081/api/customer/fingerprint"
esp32_url = "http://192.168.8.192/receive-fingerprint"  # Replace with actual ESP32 IP
email = "pathumdilharadissanayake@gmail.com"

# ---- FETCH FINGERPRINT ID FROM MAIN SERVER ----
try:
    print("[INFO] Fetching fingerprint ID for:", email)
    response = requests.get(springboot_url, params={"email": email})
    response.raise_for_status()

    data = response.json()
    fingerprint_id = data["fingerprintId"]
    print("[SUCCESS] Fingerprint ID fetched:", fingerprint_id)

except requests.RequestException as e:
    print("[ERROR] Failed to fetch fingerprint ID:", e)
    exit(1)

# ---- SEND FINGERPRINT ID TO ESP32 ----
try:
    payload = {"fingerprintId": fingerprint_id}
    headers = {"Content-Type": "application/json"}

    print(f"[INFO] Sending to ESP32 at {esp32_url} ...")
    response = requests.post(esp32_url, json=payload, headers=headers)
    response.raise_for_status()

    print("[SUCCESS] Sent fingerprint ID to ESP32")
    print("[ESP32 RESPONSE]:", response.text)

except requests.RequestException as e:
    print("[ERROR] Failed to send to ESP32:", e)
