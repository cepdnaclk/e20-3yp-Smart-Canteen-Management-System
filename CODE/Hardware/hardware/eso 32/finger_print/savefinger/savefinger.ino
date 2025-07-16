#include <WiFi.h>
#include <HTTPClient.h>
#include <Adafruit_Fingerprint.h>
#include <HardwareSerial.h>
#include <LiquidCrystal_I2C.h>
#include <WebServer.h>
#include <ArduinoJson.h>

// WiFi credentials
const char* ssid = "Dialog 4G 140";
const char* password = "pathum27980";

// Backend endpoint
const char* backendUrl = "http://192.168.8.183:8081/api/merchant/update-biometrics-data";

// Web server on port 80
WebServer server(80);

// Fingerprint and LCD setup
HardwareSerial mySerial(1); // GPIO16 (RX), GPIO17 (TX)
Adafruit_Fingerprint finger(&mySerial);
LiquidCrystal_I2C lcd(0x27, 16, 2);

// Temporary variables
String customerEmail = "";
String cardID = "";
String jwtToken = "";
int fingerprintId = 1;

void setup() {
  Serial.begin(115200);
  delay(1000);

  // Initialize LCD
  lcd.init();
  lcd.backlight();
  lcd.setCursor(0, 0);
  lcd.print("Initializing...");

  // Connect to WiFi
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  lcd.clear();
  lcd.print("WiFi Connected");
  lcd.setCursor(0, 1);
  lcd.print(WiFi.localIP());
  Serial.println("\nConnected to WiFi");
  
  // Initialize fingerprint sensor
  mySerial.begin(57600, SERIAL_8N1, 16, 17);
  finger.begin(57600);
  delay(1000);

  if (finger.verifyPassword()) {
    lcd.clear();
    lcd.print("Sensor Ready");
  } else {
    lcd.print("Sensor Error");
    while (true) delay(1000);
  }

  // Web endpoint
  server.on("/capture", HTTP_POST, handleCapture);
  server.begin();
  
  delay(1000);
  lcd.clear();
  lcd.print("Ready");
}

void loop() {
  server.handleClient();
  delay(10);
}

void handleCapture() {
  // Check if request has body
  if (server.hasArg("plain")) {
    String body = server.arg("plain");
    DynamicJsonDocument doc(256);
    DeserializationError error = deserializeJson(doc, body);
    
    if (error) {
      server.send(400, "text/plain", "Invalid JSON");
      return;
    }
    
    // Extract parameters
    customerEmail = doc["email"].as<String>();
    cardID = doc["rfid"].as<String>();
    jwtToken = doc["token"].as<String>();
    
    Serial.println("Received params:");
    Serial.println("Email: " + customerEmail);
    Serial.println("Card ID: " + cardID);
    Serial.println("Token: " + jwtToken.substring(0, 15) + "...");
    
    // Skip RFID verification
    lcd.clear();
    lcd.print("Starting Enrollment");
    
    // Start fingerprint enrollment
    enrollAndSend();
    server.send(200, "text/plain", "Enrollment started");
  } else {
    server.send(400, "text/plain", "Missing body");
  }
}

void enrollAndSend() {
  // Find next available fingerprint ID
  fingerprintId = 1;
  while (finger.loadModel(fingerprintId) == FINGERPRINT_OK) {
    fingerprintId++;
    if (fingerprintId > 127) {
      lcd.clear();
      lcd.print("Storage full");
      return;
    }
  }

  lcd.clear();
  lcd.print("Place Finger");
  
  if (!enrollFingerprint(fingerprintId)) {
    lcd.clear();
    lcd.print("Enroll Failed");
    return;
  }

  lcd.clear();
  lcd.print("Sending Data...");
  sendToBackend();
}

bool enrollFingerprint(int id) {
  int result = -1;
  
  // First scan
  while (result != FINGERPRINT_OK) {
    result = finger.getImage();
    delay(100);
  }
  result = finger.image2Tz(1);
  if (result != FINGERPRINT_OK) return false;
  
  lcd.clear();
  lcd.print("Remove Finger");
  delay(2000);
  
  lcd.clear();
  lcd.print("Place Again");
  
  // Second scan
  result = -1;
  while (result != FINGERPRINT_OK) {
    result = finger.getImage();
    delay(100);
  }
  result = finger.image2Tz(2);
  if (result != FINGERPRINT_OK) return false;
  
  // Create model
  result = finger.createModel();
  if (result != FINGERPRINT_OK) return false;
  
  // Store model
  result = finger.storeModel(id);
  return (result == FINGERPRINT_OK);
}

void sendToBackend() {
  if (WiFi.status() != WL_CONNECTED || jwtToken == "") {
    lcd.clear();
    lcd.print("Comms Error");
    return;
  }

  HTTPClient http;
  http.begin(backendUrl);
  http.addHeader("Content-Type", "application/json");
  http.addHeader("Authorization", "Bearer " + jwtToken);
  
  // Create JSON payload
  DynamicJsonDocument doc(256);
  doc["email"] = customerEmail;
  doc["cardID"] = cardID;
  doc["fingerprintID"] = String(fingerprintId);
  
  String json;
  serializeJson(doc, json);
  
  int httpCode = http.POST(json);
  
  lcd.clear();
  if (httpCode == HTTP_CODE_OK) {
    lcd.print("✅ Success");
  } else {
    lcd.print("❌ Backend Error");
  }
  
  http.end();
  
  // Clear sensitive data
  jwtToken = "";
  customerEmail = "";
  cardID = "";
  
  delay(3000);
  lcd.clear();
  lcd.print("Ready");
}