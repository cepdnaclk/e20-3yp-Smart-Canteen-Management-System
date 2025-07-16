#include <WiFi.h>
#include <WebServer.h>
#include <HTTPClient.h>
#include <Adafruit_Fingerprint.h>
#include <LiquidCrystal_I2C.h>
#include <ArduinoJson.h>

// WiFi credentials
const char* ssid = "Dialog 4G 140";
const char* password = "pathum27980";

// Backend server base URL (change to your backend)
const String backendUrl = "http://your-backend-url.com";

LiquidCrystal_I2C lcd(0x27, 16, 2); // LCD at I2C 0x27, 16 cols, 2 rows:contentReference[oaicite:0]{index=0}

WebServer server(80);

Adafruit_Fingerprint finger = Adafruit_Fingerprint(&Serial2);

int nextEnrollId = 1; // ID to assign for new fingerprint (incremental)

void setup() {
  Serial.begin(115200);
  Serial.println("Starting ESP32 Fingerprint system");
  
  // Initialize LCD
  lcd.init();                      // initialize the lcd (16x2)
  lcd.backlight();                 // turn on backlight
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("WiFi connecting");
  
  // Connect to Wi-Fi:contentReference[oaicite:1]{index=1}
  WiFi.begin(ssid, password);      // connect to WiFi
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("");
  Serial.print("WiFi connected, IP: ");
  Serial.println(WiFi.localIP());
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("WiFi connected");
  
  // Initialize fingerprint sensor (UART2 on GPIO16/17):contentReference[oaicite:2]{index=2}
  finger.begin(57600);  // set UART baud rate
  if (finger.verifyPassword()) {
    Serial.println("Fingerprint sensor found");
  } else {
    Serial.println("Fingerprint sensor not found");
    lcd.clear();
    lcd.print("Sensor not found");
    while (1) { delay(1000); } // halt
  }
  
  Serial.print("Sensor firmware ver: "); 
  Serial.println(finger.firmwareVersion());
  lcd.setCursor(0, 1);
  lcd.print("FP init done");

  delay(2000);
  
  // Set up HTTP server endpoints
  server.on("/capture", HTTP_POST, handleCapture);
  server.on("/verify", HTTP_POST, handleVerify);
  server.onNotFound([](){
    server.send(404, "text/plain", "Not Found");
  });
  
  server.begin();
  Serial.println("HTTP server started on port 80");
}

void loop() {
  server.handleClient(); // handle incoming HTTP requests
}

// Helper: Read fingerprint for enrollment (two scans)
bool enrollFingerprint(int id) {
  uint8_t p = 0;
  Serial.print("Enrolling ID "); Serial.println(id);
  
  // First scan
  lcd.clear();
  lcd.print("Place finger");
  do {
    p = finger.getImage();
  } while (p == FINGERPRINT_NOFINGER); // wait for finger
  if (p != FINGERPRINT_OK) {
    Serial.println("Failed to get image");
    return false;
  }
  lcd.clear();
  lcd.print("Image taken");
  p = finger.image2Tz(1);
  if (p != FINGERPRINT_OK) {
    Serial.println("Image conversion failed");
    return false;
  }
  
  // Ask user to remove finger
  lcd.clear();
  lcd.print("Remove finger");
  delay(2000);
  while (finger.getImage() == FINGERPRINT_OK) { delay(100); }
  
  // Second scan
  lcd.clear();
  lcd.print("Place same finger");
  do {
    p = finger.getImage();
  } while (p == FINGERPRINT_NOFINGER);
  if (p != FINGERPRINT_OK) {
    Serial.println("Failed to get second image");
    return false;
  }
  lcd.clear();
  lcd.print("Image 2 taken");
  p = finger.image2Tz(2);
  if (p != FINGERPRINT_OK) {
    Serial.println("2nd image conversion failed");
    return false;
  }
  
  // Create model (compare both)
  Serial.println("Creating model...");
  lcd.clear();
  lcd.print("Creating model");
  p = finger.createModel();
  if (p != FINGERPRINT_OK) {
    Serial.println("Could not create model");
    return false;
  }
  
  // Store model in flash
  Serial.println("Storing model");
  lcd.clear();
  lcd.print("Storing model");
  p = finger.storeModel(id);
  if (p != FINGERPRINT_OK) {
    Serial.println("Could not store model");
    return false;
  }
  
  Serial.print("Stored ID #"); Serial.println(id);
  lcd.clear();
  lcd.print("Stored ID ");
  lcd.print(id);
  return true;
}

// Handle /capture: register fingerprint
void handleCapture() {
  Serial.println("Received /capture");
  // Parse JSON body for email, rfid
  String body = server.arg("plain");
  DynamicJsonDocument doc(256);
  DeserializationError error = deserializeJson(doc, body);
  if (error) {
    server.send(400, "text/plain", "Invalid JSON");
    return;
  }
  String email = doc["email"];
  String rfid = doc["rfid"];
  String token = server.header("token"); // token header
  Serial.print("Email: "); Serial.println(email);
  Serial.print("RFID: "); Serial.println(rfid);
  
  // Guide user via LCD
  lcd.clear();
  lcd.print("Registering:");
  lcd.setCursor(0,1);
  lcd.print(email);
  
  delay(2000);
  bool success = enrollFingerprint(nextEnrollId);
  if (!success) {
    server.send(500, "text/plain", "Enrollment failed");
    return;
  }
  int enrolledId = nextEnrollId;
  nextEnrollId++;
  
  // Send data to backend
  HTTPClient http;
  String url = backendUrl + "/capture";
  http.begin(url); //:contentReference[oaicite:3]{index=3} HTTPClient POST example
  http.addHeader("Content-Type", "application/json");
  http.addHeader("Authorization", token);
  String payload = "{\"email\":\"" + email + "\",\"rfid\":\"" + rfid + "\",\"fingerprintId\":" + String(enrolledId) + "}";
  Serial.print("Sending to backend: "); Serial.println(payload);
  int httpCode = http.POST(payload);
  if (httpCode > 0) {
    Serial.print("Backend response: ");
    Serial.println(httpCode);
    String resp = http.getString();
    Serial.println(resp);
  } else {
    Serial.println("Error on HTTP request");
  }
  http.end();
  
  server.send(200, "application/json", "{\"status\":\"registered\",\"id\":" + String(enrolledId) + "}");
}

// Handle /verify: authenticate fingerprint
void handleVerify() {
  Serial.println("Received /verify");
  // Parse JSON for email and orderId
  String body = server.arg("plain");
  DynamicJsonDocument doc(256);
  DeserializationError error = deserializeJson(doc, body);
  if (error) {
    server.send(400, "text/plain", "Invalid JSON");
    return;
  }
  String email = doc["email"];
  String orderId = doc["orderId"];
  String token = server.header("Authorization"); // Authorization header
  if (token == "") {
    token = server.header("token"); // fallback
  }
  Serial.print("Email: "); Serial.println(email);
  Serial.print("OrderId: "); Serial.println(orderId);
  
  // Prompt for fingerprint on LCD
  lcd.clear();
  lcd.print("Verify order:");
  lcd.setCursor(0,1);
  lcd.print(orderId);
  delay(2000);
  
  // Capture and search fingerprint
  lcd.clear();
  lcd.print("Place finger");
  uint8_t p = finger.getImage();
  if (p != FINGERPRINT_OK) {
    Serial.println("No finger detected");
    server.send(400, "text/plain", "No fingerprint");
    return;
  }
  lcd.clear();
  lcd.print("Image taken");
  Serial.println("Image captured for verify");
  
  p = finger.image2Tz();
  if (p != FINGERPRINT_OK) {
    Serial.println("Image conversion failed");
    server.send(500, "text/plain", "Conversion failed");
    return;
  }
  p = finger.fingerFastSearch();
  if (p != FINGERPRINT_OK) {
    Serial.println("No match found");
    lcd.clear();
    lcd.print("Not verified");
    // send result to backend (failure)
    HTTPClient http;
    String url = backendUrl + "/verify";
    http.begin(url);
    http.addHeader("Content-Type", "application/json");
    http.addHeader("Authorization", token);
    String payload = "{\"email\":\"" + email + "\",\"orderId\":\"" + orderId + "\",\"match\":false}";
    http.POST(payload);
    http.end();
    server.send(200, "application/json", "{\"verified\":false}");
    return;
  }
  // Match found
  int foundId = finger.fingerID;
  int confidence = finger.confidence;
  Serial.print("Found ID "); Serial.print(foundId);
  Serial.print(" with confidence "); Serial.println(confidence);
  lcd.clear();
  lcd.print("Verified ID ");
  lcd.print(foundId);
  
  // Send verification result to backend
  HTTPClient http;
  String url = backendUrl + "/verify";
  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  http.addHeader("Authorization", token);
  String payload = "{\"email\":\"" + email + "\",\"orderId\":\"" + orderId + "\",\"match\":true,\"fingerprintId\":" + String(foundId) + ",\"confidence\":" + String(confidence) + "}";
  Serial.print("Sending verify result: "); Serial.println(payload);
  http.POST(payload);
  http.end();
  
  // Call order complete if success
  HTTPClient http2;
  String completeUrl = backendUrl + "/orders/" + orderId + "/completeDirectly";
  http2.begin(completeUrl);
  http2.addHeader("Authorization", token);
  int code2 = http2.POST("");
  Serial.print("Order completeDirectly call code: "); Serial.println(code2);
  http2.end();
  
  server.send(200, "application/json", "{\"verified\":true}");
}
