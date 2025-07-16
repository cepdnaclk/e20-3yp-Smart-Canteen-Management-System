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
const char* enrollUrl = "http://18.142.44.110:8081/api/merchant/update-biometrics-data";
const char* baseVerifyUrl = "http://18.142.44.110:8081";
const String authEndpoint = "/api/biometric/confirm";

// Web server
WebServer server(80);

// Hardware setup
HardwareSerial mySerial(1); // GPIO16 RX, GPIO17 TX
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
// Removed waitingForPaymentStatus and paymentStatusTime as they are no longer needed for this approach
unsigned long verificationStartTime = 0;

const unsigned long VERIFICATION_TIMEOUT = 90000;
// PAYMENT_STATUS_TIMEOUT is no longer strictly needed for this logic, but can remain if you want to keep it as a general reset timeout.
// I'll keep it for the general reset logic for `isVerifying`.
const unsigned long PAYMENT_STATUS_TIMEOUT = 30000;
const unsigned long WIFI_CHECK_INTERVAL = 30000;
const int MIN_CONFIDENCE = 50;
const int MAX_ATTEMPTS = 200;
const int HTTP_RETRIES = 3;
const int HTTP_TIMEOUT = 5000;

unsigned long lastWifiCheck = 0;

// Forward declarations
void sendVerificationResult(bool authenticated);
void resetVerification();
bool ensureWiFiConnection();
int getFingerprintID();
bool enrollFingerprint(int id);
void enrollAndSend();
void handleCapture();
void handleVerify();
void handlePaymentStatus(); // This handler will effectively become unused but kept for compilation

void setup() {
  Serial.begin(115200);
  lcd.init();
  lcd.backlight();
  pinMode(25, OUTPUT); // buzzer
  lcd.print("Initializing...");

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

  lcd.clear();
  lcd.print("Connecting WiFi");
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  lcd.clear();
  lcd.print("WiFi Connected");
  lcd.setCursor(0, 1);
  lcd.print(WiFi.localIP());
  delay(1000);

  server.on("/capture", HTTP_POST, handleCapture);
  server.on("/verify", HTTP_POST, handleVerify);
  // The /paymentStatus endpoint and its handler will effectively become unused
  // as the payment status is now read directly from the /biometric/confirm response.
  server.on("/paymentStatus", HTTP_POST, handlePaymentStatus);
  server.onNotFound([]() {
    server.send(404, "text/plain", "Not found");
  });

  server.begin();
  lcd.clear();
  lcd.print("Welcome to smart ");
  lcd.setCursor(0, 1);
  lcd.print("canteen");

}

void loop() {
  server.handleClient();
  if (millis() - lastWifiCheck > WIFI_CHECK_INTERVAL) {
    ensureWiFiConnection();
    lastWifiCheck = millis();
  }

  // The logic for waitingForPaymentStatus and paymentStatusTime is removed here.
  // The display update for payment success/failure now happens immediately after
  // sendVerificationResult receives its response.
if (isVerifying && millis() - verificationStartTime < VERIFICATION_TIMEOUT) {
    int fid = getFingerprintID();
    if (fid > 0 && finger.confidence >= MIN_CONFIDENCE) {
        lcd.clear();
        lcd.print("Finger Found!");
        lcd.setCursor(0, 1);
        lcd.print("Sending Data...");
        delay(1000);
        sendVerificationResult(true);
    } else if (fid == -1) {
        lcd.clear();
        lcd.print("Not Registered");
        lcd.setCursor(0, 1);
        lcd.print("User");
        tone(25, 200, 1000);
        delay(3000);
        resetVerification();
        lcd.clear();
        lcd.print("Ready");
    } else if (isVerifying && millis() - verificationStartTime >= VERIFICATION_TIMEOUT) {
    // This is the timeout for the overall verification process (fingerprint scan).
    lcd.clear();
    lcd.print("Verification Timeout");
    tone(25, 200, 1000);
    delay(3000);
    resetVerification();
    lcd.clear();
    lcd.print("Welcome to smart canteen");
  }
}


void handleCapture() {
  if (!server.hasArg("plain")) return server.send(400, "text/plain", "Missing body");

  DynamicJsonDocument doc(256);
  deserializeJson(doc, server.arg("plain"));

  customerEmail = doc["email"].as<String>();
  cardID = doc["rfid"].as<String>();
  jwtToken = doc["token"].as<String>();

  enrollAndSend();
  server.send(200, "text/plain", "Enrollment started");
}

void enrollAndSend() {
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
    tone(25, 200, 500); // Tone for failure
    delay(3000);
    lcd.clear();
    lcd.print("Ready");
    return;
  }

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

  if (httpCode == HTTP_CODE_OK) { // Check if the request was successful
    lcd.clear();
    lcd.print("✅ Enrolled");
    tone(25, 1000, 200); // Tone for success
  } else {
    lcd.clear();
    lcd.print("Enrollment Failed");
    lcd.setCursor(0, 1);
    lcd.print("HTTP Error: " + String(httpCode));
    Serial.println("Enrollment HTTP Error: " + String(httpCode));
    Serial.println("Response: " + payload);
    tone(25, 200, 500); // Tone for failure
  }
  delay(3000);
  lcd.clear();
  lcd.print("Ready");
}

bool enrollFingerprint(int id) {
  int result = -1;
  lcd.clear();
  lcd.print("Enter your finger print");
  while (result != FINGERPRINT_OK) {
    result = finger.getImage();
    if (result == FINGERPRINT_NOFINGER) {
      delay(50); // Small delay to prevent busy-waiting
    } else if (result != FINGERPRINT_OK) {
      Serial.print("Enroll image #1 error: ");
      Serial.println(result);
      return false;
    }
  }
  if (finger.image2Tz(1) != FINGERPRINT_OK) return false;

  lcd.clear();
  lcd.print("Remove Finger");
  delay(2000);
  lcd.clear();
  lcd.print("Enter your finger print again");

  result = -1;
  while (result != FINGERPRINT_OK) {
    result = finger.getImage();
    if (result == FINGERPRINT_NOFINGER) {
      delay(50);
    } else if (result != FINGERPRINT_OK) {
      Serial.print("Enroll image #2 error: ");
      Serial.println(result);
      return false;
    }
  }
  if (finger.image2Tz(2) != FINGERPRINT_OK) return false;

  lcd.clear();
  lcd.print("Creating Model...");
  if (finger.createModel() != FINGERPRINT_OK) {
    Serial.println("Create model failed.");
    return false;
  }
  
  lcd.clear();
  lcd.print("Storing Model...");
  if (finger.storeModel(id) != FINGERPRINT_OK) {
    Serial.println("Store model failed.");
    return false;
  }
  Serial.println("Enrolled");
  return true;
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
    currentToken = server.header("Authorization").substring(7);
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

// This function now becomes largely unused in this new flow.
// It's kept for compilation but won't be triggered by backend.
void handlePaymentStatus() {
  // This block will theoretically never be reached if the backend is not
  // sending a separate POST to /paymentStatus.
  // However, keeping it for robustness or if you decide to revert later.
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
  lcd.clear();
  lcd.print("Ready");
  server.send(200, "application/json", "{\"message\":\"Status received\"}");
}

int getFingerprintID() {
  int result;
  int attempts = 0;
  // Increase MAX_ATTEMPTS if you want more tries for finger placement
  while (attempts < MAX_ATTEMPTS) {
    result = finger.getImage();
    if (result == FINGERPRINT_OK) break; // Finger found
    if (result == FINGERPRINT_NOFINGER) {
      delay(100); // Short delay if no finger
      attempts++;
      continue;
    }
    // Any other error
    Serial.print("Get image error: ");
    Serial.println(result);
    return -1;
  }
  if (attempts >= MAX_ATTEMPTS) {
    Serial.println("Max attempts reached for finger placement.");
    return -1;
  }
  
  if (finger.image2Tz() != FINGERPRINT_OK) {
    Serial.println("Image to TZ conversion failed.");
    return -1;
  }
  
  if (finger.fingerFastSearch() != FINGERPRINT_OK) {
    Serial.println("Fingerprint search failed.");
    return -1;
  }
  
  Serial.print("Matched ID: ");
  Serial.print(finger.fingerID);
  Serial.print(" Confidence: ");
  Serial.println(finger.confidence);
  return finger.fingerID;
}

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
  doc["confidence"] = finger.confidence;
  doc["scannedId"] = finger.fingerID;
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
    DynamicJsonDocument responseDoc(512); // Increased size for response
    DeserializationError error = deserializeJson(responseDoc, payload);

    if (!error) {
      String orderStatus = responseDoc["orderStatus"].as<String>();
      if (orderStatus == "COMPLETED") {
        lcd.print("Payment Success");
        tone(25, 1000, 300); // Success tone
      } else if (orderStatus == "FAILED" || orderStatus == "PENDING" || orderStatus == "CANCELED") {
        // You might want to refine these conditions based on your backend's exact statuses
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
  lcd.clear();
  lcd.print("Ready");
}

void resetVerification() {
  currentEmail = "";
  currentToken = "";
  currentOrderId = 0;
  isVerifying = false;
  // Removed waitingForPaymentStatus reset
  // paymentStatusTime reset no longer needed
}

bool ensureWiFiConnection() {
  if (WiFi.status() == WL_CONNECTED) return true;
  Serial.println("Reconnecting WiFi...");
  lcd.clear();
  lcd.print("Reconnecting WiFi");
  WiFi.disconnect();
  WiFi.begin(ssid, password);
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) { // Increased attempts for robustness
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
    lcd.clear();
    lcd.print("Ready");
    return true;
  } else {
    Serial.println("\nWiFi Reconnection Failed.");
    lcd.clear();
    lcd.print("WiFi Failed!");
    delay(3000);
    return false;
  }
}