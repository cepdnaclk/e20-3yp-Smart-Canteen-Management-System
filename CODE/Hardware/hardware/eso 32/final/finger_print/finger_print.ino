#include <WiFi.h>
#include <HTTPClient.h>
#include <Adafruit_Fingerprint.h>
#include <HardwareSerial.h>
#include <LiquidCrystal_I2C.h>
#include <WebServer.h>

// WiFi credentials
const char* ssid = "Dialog 4G 140";
const char* password = "pathum27980";

// Backend endpoint to send fingerprint data
const char* backendUrl = "http://192.168.8.183:8080/api/fingerprint/register";

// Web server on port 80
WebServer server(80);

// Fingerprint and LCD setup
HardwareSerial mySerial(1); // UART1 on GPIO16 (RX), GPIO17 (TX)
Adafruit_Fingerprint finger(&mySerial);
LiquidCrystal_I2C lcd(0x27, 16, 2);

int userId = 1;
int fingerprintId = 1;

void setup() {
  Serial.begin(115200);
  delay(1000);

  lcd.init();
  lcd.backlight();
  lcd.setCursor(0, 0);
  lcd.print("Connecting WiFi");

  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  lcd.clear();
  lcd.print("WiFi Connected");
  Serial.println("\nConnected to WiFi");

  // Display IP address
  delay(1000);
  lcd.clear();
  lcd.print("IP:");
  lcd.setCursor(0, 1);
  lcd.print(WiFi.localIP());
  Serial.print("ESP32 IP Address: ");
  Serial.println(WiFi.localIP());
  delay(3000);
  lcd.clear();

  // Init fingerprint sensor
  mySerial.begin(57600, SERIAL_8N1, 16, 17);
  finger.begin(57600);
  delay(1000);

  lcd.setCursor(0, 1);
  if (finger.verifyPassword()) {
    lcd.print("Sensor Ready");
    Serial.println("Fingerprint sensor found.");
  } else {
    lcd.print("Sensor Fail");
    Serial.println("Fingerprint sensor not found.");
    while (true) delay(1);
  }

  lcd.clear();

  // Register capture endpoint
  server.on("/capture", HTTP_GET, []() {
    enrollAndSend();
    server.send(200, "text/plain", "Capture triggered");
  });

  server.begin();
  Serial.println("HTTP server started");
}

void loop() {
  server.handleClient();  // Handle incoming HTTP requests
}

// ========== Enrollment & Sending Logic ==========

void enrollAndSend() {
  lcd.print("Enroll Finger");

  while (finger.loadModel(fingerprintId) == FINGERPRINT_OK) {
    fingerprintId++;
  }

  if (!getFingerprintEnroll(fingerprintId)) {
    lcd.clear();
    lcd.print("Enroll Failed");
    Serial.println("Enrollment failed");
    return;
  }

  lcd.clear();
  lcd.print("Sending Data");
  sendToBackend(userId, fingerprintId);
}

bool getFingerprintEnroll(int id) {
  int p = -1;
  lcd.clear();
  lcd.print("Place Finger");

  while (p != FINGERPRINT_OK) {
    p = finger.getImage();
  }

  p = finger.image2Tz(1);
  if (p != FINGERPRINT_OK) return false;

  lcd.clear();
  lcd.print("Remove Finger");
  delay(2000);

  lcd.clear();
  lcd.print("Again Finger");
  p = -1;
  while (p != FINGERPRINT_OK) {
    p = finger.getImage();
  }

  p = finger.image2Tz(2);
  if (p != FINGERPRINT_OK) return false;

  p = finger.createModel();
  if (p != FINGERPRINT_OK) return false;

  p = finger.storeModel(id);
  return (p == FINGERPRINT_OK);
}

void sendToBackend(int userId, int fingerprintId) {
  if (WiFi.status() != WL_CONNECTED) {
    lcd.clear();
    lcd.print("WiFi Error");
    Serial.println("WiFi not connected.");
    return;
  }

  HTTPClient http;
  http.begin(backendUrl);
  http.addHeader("Content-Type", "application/json");

  String json = "{\"userId\": " + String(userId) + ", \"fingerprintID\": \"" + String(fingerprintId) + "\"}";
  int responseCode = http.POST(json);

  lcd.clear();
  if (responseCode > 0) {
    lcd.print("Sent Success");
    Serial.println("Response: " + http.getString());
  } else {
    lcd.print("HTTP Fail");
    Serial.printf("HTTP error: %s\n", http.errorToString(responseCode).c_str());
  }

  http.end();
}
