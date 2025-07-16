#include <WiFi.h>
#include <HTTPClient.h>
#include <Adafruit_Fingerprint.h>
#include <HardwareSerial.h>
#include <LiquidCrystal_I2C.h>
#include <WebServer.h>
#include <ArduinoJson.h>

// WiFi credentials
const char* ssid = "Mobitel SSD";
const char* password = "2798028089";

// Backend endpoints
const char* enrollUrl = "http://192.168.1.101:8081/api/merchant/update-biometrics-data";
const char* baseVerifyUrl = "http://192.168.1.101:8081";
const String authEndpoint = "/api/biometric/confirm";

// Web server
WebServer server(80);

// Hardware setup
HardwareSerial mySerial(1); // Use UART 1 for ESP32 (RX: GPIO16, TX: GPIO17 by default)
Adafruit_Fingerprint finger(&mySerial);
LiquidCrystal_I2C lcd(0x27, 16, 2);

// Enrollment variables
String customerEmail = "";
String cardID = "";
String jwtToken = "";
int fingerprintId = 1;

// Verification variables
String currentEmail = "";
String currentToken = "";
long currentOrderId = 0;
bool isVerifying = false;
unsigned long verificationStartTime = 0;

// Constants
const unsigned long VERIFICATION_TIMEOUT = 90000; // 90 seconds for fingerprint scan
const unsigned long WIFI_CHECK_INTERVAL = 30000; // Check WiFi connection every 30 seconds
const int MIN_CONFIDENCE = 50;
const int MAX_ATTEMPTS_FINGER_PLACEMENT = 50; // Max loops to wait for finger image
const int HTTP_TIMEOUT = 10000; // 10 seconds for HTTP requests

unsigned long lastWifiCheck = 0;

// --- Forward declarations ---
void sendVerificationResult(bool authenticated);
void resetVerification();
bool ensureWiFiConnection();
int getFingerprintID();
bool enrollFingerprint(int id);
void enrollAndSend();
void handleCapture();
void handleVerify();
void handlePaymentStatus();
void displayWelcomeMessage();

//================================================================
// SETUP FUNCTION
//================================================================
void setup() {
  Serial.begin(115200);
  lcd.init();
  lcd.backlight();
  pinMode(25, OUTPUT); // Buzzer
  lcd.print("Initializing...");

  mySerial.begin(57600, SERIAL_8N1, 16, 17);
  finger.begin(57600);
  delay(1000);

  if (finger.verifyPassword()) {
    lcd.clear();
    lcd.print("Sensor Ready");
  } else {
    lcd.clear();
    lcd.print("Sensor Error");
    while (true) delay(1000); // Halt on sensor error
  }
  delay(1000);

  lcd.clear();
  lcd.print("Connecting WiFi");
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
    lcd.print(".");
  }

  lcd.clear();
  lcd.print("WiFi Connected");
  lcd.setCursor(0, 1);
  lcd.print(WiFi.localIP());
  delay(2000);

  // --- Web Server Endpoints ---
  server.on("/capture", HTTP_POST, handleCapture);
  server.on("/verify", HTTP_POST, handleVerify);
  server.on("/paymentStatus", HTTP_POST, handlePaymentStatus); // Unused, but kept for legacy
  server.onNotFound([]() {
    server.send(404, "text/plain", "Not found");
  });

  server.begin();
  displayWelcomeMessage(); // Initial welcome message
}

//================================================================
// MAIN LOOP
//================================================================
void loop() {
  server.handleClient();

  // Periodically check WiFi connection
  if (millis() - lastWifiCheck > WIFI_CHECK_INTERVAL) {
    ensureWiFiConnection();
    lastWifiCheck = millis();
  }

  // Handle the fingerprint verification process if it's active
  if (isVerifying) {
    if (millis() - verificationStartTime < VERIFICATION_TIMEOUT) {
      int fid = getFingerprintID();
      if (fid > 0 && finger.confidence >= MIN_CONFIDENCE) {
        lcd.clear();
        lcd.print("Finger Found!");
        lcd.setCursor(0, 1);
        lcd.print("Sending Data...");
        delay(1000);
        sendVerificationResult(true); // Found a valid finger, send result
      } else if (fid == -2) { // Finger not found (search failed)
        lcd.clear();
        lcd.print("Not Registered");
        lcd.setCursor(0, 1);
        lcd.print("User");
        tone(25, 200, 1000);
        delay(3000);
        resetVerification(); // Reset state
        displayWelcomeMessage(); // Display welcome message instead of "Ready"
      }
      // If fid is 0 or -1 (image errors or still waiting), the loop continues waiting
    } else {
      // This is the timeout for the overall verification process.
      lcd.clear();
      lcd.print("Verification");
      lcd.setCursor(0, 1);
      lcd.print("Timeout");
      tone(25, 200, 1000);
      delay(3000);
      resetVerification(); // Reset state
      displayWelcomeMessage();
    }
  }
}

//================================================================
// HELPER & DISPLAY FUNCTIONS
//================================================================

// Helper function to display the welcome message
void displayWelcomeMessage() {
    lcd.clear();
    lcd.print("Welcome to smart");
    lcd.setCursor(0, 1);
    lcd.print("     canteen");
}


//================================================================
// WEB SERVER HANDLERS
//================================================================

void handleCapture() {
  if (!server.hasArg("plain")) return server.send(400, "text/plain", "Missing body");

  DynamicJsonDocument doc(256);
  deserializeJson(doc, server.arg("plain"));

  customerEmail = doc["email"].as<String>();
  cardID = doc["rfid"].as<String>();
  jwtToken = doc["token"].as<String>();

  server.send(200, "text/plain", "Enrollment started. Place finger.");
  enrollAndSend(); // Start the enrollment process
}

void handleVerify() {
  if (!server.hasArg("plain")) {
    server.send(400, "text/plain", "Missing request body");
    return;
  }

  DynamicJsonDocument doc(512);
  DeserializationError error = deserializeJson(doc, server.arg("plain"));

  if (error) {
    Serial.print(F("deserializeJson() failed: "));
    Serial.println(error.f_str());
    server.send(400, "text/plain", "Invalid JSON");
    return;
  }

  if (server.hasHeader("Authorization")) {
    currentToken = server.header("Authorization").substring(7); // "Bearer " is 7 chars
  } else {
    server.send(401, "text/plain", "Missing token");
    return;
  }

  currentEmail = doc["email"].as<String>();
  currentOrderId = doc["orderId"].as<long>();
  isVerifying = true;
  verificationStartTime = millis();

  lcd.clear();
  lcd.print("Place Finger");
  lcd.setCursor(0, 1);
  lcd.print("to Verify");
  server.send(200, "text/plain", "Verification initiated. Waiting for fingerprint.");
}

// This function is now largely unused but kept for potential future use.
void handlePaymentStatus() {
  DynamicJsonDocument doc(256);
  deserializeJson(doc, server.arg("plain"));
  String status = doc["status"].as<String>();
  lcd.clear();
  if (status == "success") {
    lcd.print("Payment Success");
    tone(25, 1000, 300);
  } else {
    lcd.print("Payment Failed");
    tone(25, 200, 1000);
  }
  delay(3000);
  resetVerification();
  displayWelcomeMessage(); // Display welcome message instead of "Ready"
  server.send(200, "application/json", "{\"message\":\"Status received\"}");
}


//================================================================
// FINGERPRINT & ENROLLMENT FUNCTIONS
//================================================================

void enrollAndSend() {
  fingerprintId = 1;
  // Find the next available ID in the sensor's memory
  while (finger.loadModel(fingerprintId) == FINGERPRINT_OK) {
    fingerprintId++;
    if (fingerprintId > 127) { // Max templates for this sensor
      lcd.clear();
      lcd.print("Storage full");
      delay(3000);
      displayWelcomeMessage(); // Display welcome message instead of "Ready"
      return;
    }
  }

  lcd.clear();
  lcd.print("Place Finger");

  if (!enrollFingerprint(fingerprintId)) {
    lcd.clear();
    lcd.print("Enroll Failed");
    tone(25, 200, 500); // Failure tone
    delay(3000);
    displayWelcomeMessage(); // Display welcome message instead of "Ready"
    return;
  }

  // --- Send enrolled data to backend ---
  lcd.clear();
  lcd.print("Sending Data...");
  HTTPClient http;
  http.begin(enrollUrl);
  http.addHeader("Content-Type", "application/json");
  http.addHeader("Authorization", "Bearer " + jwtToken);

  DynamicJsonDocument doc(256);
  doc["email"] = customerEmail;
  doc["cardID"] = cardID;
  doc["fingerprintID"] = String(fingerprintId);

  String json;
  serializeJson(doc, json);

  int httpCode = http.POST(json);
  String payload = http.getString();
  http.end();

  if (httpCode == HTTP_CODE_OK) {
    lcd.clear();
    lcd.print("succsesfully ");
    lcd.setCursor(0, 1);
    lcd.print("activated");
    tone(25, 1000, 200); // Success tone
  } else {
    lcd.clear();
    lcd.print("Enroll Failed");
    lcd.setCursor(0, 1);
    lcd.print("HTTP Error: " + String(httpCode));
    Serial.println("Enrollment HTTP Error: " + String(httpCode));
    Serial.println("Response: " + payload);
    tone(25, 200, 500); // Failure tone
    // Attempt to delete the stored model if the server failed
    finger.deleteModel(fingerprintId);
  }
  delay(3000);
  displayWelcomeMessage(); // Display welcome message instead of "Ready"
}

bool enrollFingerprint(int id) {
  int result = -1;
  // --- First Image ---
  lcd.clear();
  lcd.print("Place finger");
  while (finger.getImage() != FINGERPRINT_OK); // Wait for a finger
  if (finger.image2Tz(1) != FINGERPRINT_OK) {
    lcd.clear();
    lcd.print("Image #1 Error");
    return false;
  }
  lcd.clear();
  lcd.print("Image taken");
  tone(25, 800, 100);

  // --- Remove Finger ---
  lcd.clear();
  lcd.print("Remove Finger");
  delay(500);
  while (finger.getImage() != FINGERPRINT_NOFINGER);
  delay(500);

  // --- Second Image ---
  lcd.clear();
  lcd.print("Place finger");
  lcd.setCursor(0,1);
  lcd.print("again");
  while (finger.getImage() != FINGERPRINT_OK);
  if (finger.image2Tz(2) != FINGERPRINT_OK) {
    lcd.clear();
    lcd.print("Image #2 Error");
    return false;
  }
  lcd.clear();
  lcd.print("Image taken");
  tone(25, 800, 100);

  // --- Create & Store Model ---
  lcd.clear();
  lcd.print("Creating Model...");
  if (finger.createModel() != FINGERPRINT_OK) {
    lcd.clear();
    lcd.print("Model Error");
    return false;
  }

  lcd.clear();
  lcd.print("Storing Model...");
  if (finger.storeModel(id) != FINGERPRINT_OK) {
    lcd.clear();
    lcd.print("Storage Error");
    return false;
  }
  Serial.println("Enrolled successfully with ID: " + String(id));
  return true;
}

int getFingerprintID() {
  if (finger.getImage() != FINGERPRINT_OK) {
    return 0; // Still waiting for a finger, not an error.
  }

  if (finger.image2Tz() != FINGERPRINT_OK) {
    Serial.println("Image to TZ conversion failed.");
    return -1; // Conversion error
  }

  if (finger.fingerFastSearch() != FINGERPRINT_OK) {
    Serial.println("Fingerprint not found in database.");
    return -2; // Not found error
  }

  // Found a match
  Serial.print("Matched ID: ");
  Serial.print(finger.fingerID);
  Serial.print(" Confidence: ");
  Serial.println(finger.confidence);
  return finger.fingerID; // Return the matched ID
}


//================================================================
// UTILITY & HELPER FUNCTIONS
//================================================================

void sendVerificationResult(bool authenticated) {
  HTTPClient http;
  http.setTimeout(HTTP_TIMEOUT);
  String fullUrl = baseVerifyUrl + authEndpoint;
  Serial.print("Sending result to: ");
  Serial.println(fullUrl);

  http.begin(fullUrl);
  http.addHeader("Content-Type", "application/json");
  http.addHeader("Authorization", "Bearer " + currentToken);

  DynamicJsonDocument doc(256);
  doc["authenticated"] = authenticated;
  doc["email"] = currentEmail;
  doc["confidence"] = authenticated ? finger.confidence : 0;
  doc["scannedId"] = authenticated ? finger.fingerID : 0;
  doc["orderId"] = currentOrderId;

  String json;
  serializeJson(doc, json);
  Serial.print("Payload: ");
  Serial.println(json);

  int httpCode = http.POST(json);
  String payload = http.getString();
  Serial.print("Response code: ");
  Serial.println(httpCode);
  Serial.print("Response: ");
  Serial.println(payload);

  lcd.clear();
  if (httpCode == HTTP_CODE_OK) {
    DynamicJsonDocument responseDoc(512);
    DeserializationError error = deserializeJson(responseDoc, payload);

    if (!error) {
      String orderStatus = responseDoc["orderStatus"].as<String>();
      if (orderStatus == "COMPLETED") {
        lcd.print("Payment Success");
        tone(25, 1000, 300); // Success tone
      } else if (orderStatus == "FAILED" || orderStatus == "PENDING" || orderStatus == "CANCELED") {
        lcd.print("Payment Failed");
        tone(25, 200, 1000); // Failure tone
      } else {
        lcd.print("Unknown Status");
        lcd.setCursor(0, 1);
        lcd.print(orderStatus);
        tone(25, 500, 500); // General notification tone
      }
    } else {
      Serial.print(F("deserializeJson() failed on response: "));
      Serial.println(error.f_str());
      lcd.print("Server Error");
      lcd.setCursor(0, 1);
      lcd.print("Bad Response");
      tone(25, 200, 1000); // Error tone
    }
  } else {
    lcd.print("Server Error");
    lcd.setCursor(0, 1);
    lcd.print("HTTP " + String(httpCode));
    tone(25, 200, 1000); // Error tone
  }

  http.end();
  delay(3000); // Display message for 3 seconds
  resetVerification(); // Reset for next operation
  displayWelcomeMessage(); // Display welcome message instead of "Ready"
}

void resetVerification() {
  currentEmail = "";
  currentToken = "";
  currentOrderId = 0;
  isVerifying = false;
  verificationStartTime = 0;
}

bool ensureWiFiConnection() {
  if (WiFi.status() == WL_CONNECTED) return true;

  Serial.println("Reconnecting WiFi...");
  lcd.clear();
  lcd.print("Reconnecting WiFi");
  WiFi.disconnect();
  delay(100);
  WiFi.begin(ssid, password);
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    Serial.print(".");
    attempts++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\nWiFi Reconnected.");
    lcd.clear();
    lcd.print("WiFi Connected");
    lcd.setCursor(0, 1);
    lcd.print(WiFi.localIP());
    delay(1000);
    displayWelcomeMessage(); // Display welcome message instead of "Ready"
    return true;
  } else {
    Serial.println("\nWiFi Reconnection Failed.");
    lcd.clear();
    lcd.print("WiFi Failed!");
    delay(3000);
    return false;
  }
}