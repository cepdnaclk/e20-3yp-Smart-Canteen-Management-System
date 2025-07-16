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
HardwareSerial mySerial(1); // Use UART 1 for ESP32 (RX: GPIO16, TX: GPIO17)
Adafruit_Fingerprint finger(&mySerial);
LiquidCrystal_I2C lcd(0x27, 16, 2);

// Enrollment variables
String customerEmail = "";
String cardID = "";
String jwtToken = "";
int fingerprintId = 1;

// Verification variables
struct VerificationRequest {
  String email;
  long orderId;
  String token;
};
const int QUEUE_SIZE = 5; // Max 5 queued requests
VerificationRequest verificationQueue[QUEUE_SIZE];
int queueHead = 0; // Points to the next request to process
int queueTail = 0; // Points to the next free slot
int queueCount = 0; // Number of requests in queue
bool isVerifying = false;
unsigned long verificationStartTime = 0;
VerificationRequest currentRequest;
const int MAX_RETRIES = 3; // Retry failed scans up to 3 times

// Constants
const unsigned long VERIFICATION_TIMEOUT = 90000; // 90 seconds for fingerprint scan
const unsigned long WIFI_CHECK_INTERVAL = 30000; // Check WiFi every 30 seconds
const int MIN_CONFIDENCE = 50;
const int MAX_ATTEMPTS_FINGER_PLACEMENT = 50; // Max loops for finger image
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
void processQueue();

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

  // Initialize queue
  for (int i = 0; i < QUEUE_SIZE; i++) {
    verificationQueue[i] = {"", 0, ""};
  }
  currentRequest = {"", 0, ""};

  // Web Server Endpoints
  server.on("/capture", HTTP_POST, handleCapture);
  server.on("/verify", HTTP_POST, handleVerify);
  server.on("/paymentStatus", HTTP_POST, handlePaymentStatus);
  server.onNotFound([]() {
    server.send(404, "text/plain", "Not found");
  });

  server.begin();
  displayWelcomeMessage();
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

  // Update LCD for queued requests
  if (!isVerifying && queueCount > 0) {
    lcd.clear();
    lcd.print("Waiting in queue");
    lcd.setCursor(0, 1);
    lcd.print("Queue: " + String(queueCount));
  }

  // Handle fingerprint verification if active
  if (isVerifying) {
    if (millis() - verificationStartTime < VERIFICATION_TIMEOUT) {
      static int retryCount = 0;
      int fid = getFingerprintID();
      if (fid > 0 && finger.confidence >= MIN_CONFIDENCE) {
        lcd.clear();
        lcd.print("Finger Found!");
        lcd.setCursor(0, 1);
        lcd.print("Order: " + String(currentRequest.orderId));
        delay(1000);
        sendVerificationResult(true);
        retryCount = 0;
        processQueue();
      } else if (fid == -2) { // Fingerprint not found
        retryCount++;
        if (retryCount >= MAX_RETRIES) {
          lcd.clear();
          lcd.print("Not Registered");
          lcd.setCursor(0, 1);
          lcd.print("Order: " + String(currentRequest.orderId));
          tone(25, 200, 1000);
          delay(3000);
          sendVerificationResult(false);
          retryCount = 0;
          processQueue();
        } else {
          lcd.clear();
          lcd.print("Try Again (");
          lcd.print(retryCount);
          lcd.print("/");
          lcd.print(MAX_RETRIES);
          lcd.print(")");
          lcd.setCursor(0, 1);
          lcd.print("Order: " + String(currentRequest.orderId));
          delay(1000);
        }
      }
      // If fid is 0 or -1, continue waiting
    } else {
      lcd.clear();
      lcd.print("Verification");
      lcd.setCursor(0, 1);
      lcd.print("Timeout");
      tone(25, 200, 1000);
      delay(3000);
      sendVerificationResult(false);
      processQueue();
    }
  }
}

//================================================================
// HELPER & DISPLAY FUNCTIONS
//================================================================
void displayWelcomeMessage() {
  lcd.clear();
  lcd.print("Welcome to smart");
  lcd.setCursor(0, 1);
  lcd.print("     canteen");
}

//================================================================
// QUEUE MANAGEMENT
//================================================================
void enqueueRequest(String email, long orderId, String token) {
  if (queueCount >= QUEUE_SIZE) {
    Serial.println("Queue full, rejecting request for email=" + email + ", orderId=" + String(orderId));
    server.send(503, "text/plain", "Queue full, try again later");
    return;
  }
  verificationQueue[queueTail] = {email, orderId, token};
  queueTail = (queueTail + 1) % QUEUE_SIZE;
  queueCount++;
  Serial.println("Enqueued request: email=" + email + ", orderId=" + String(orderId) + ", queueCount=" + String(queueCount));
  server.send(200, "text/plain", "Verification request queued. Waiting for fingerprint.");
}

void processQueue() {
  Serial.println("Processing queue: queueCount=" + String(queueCount));
  resetVerification();
  if (queueCount == 0) {
    Serial.println("Queue empty, returning to welcome screen");
    displayWelcomeMessage();
    return;
  }
  // Dequeue the next request
  currentRequest = verificationQueue[queueHead];
  verificationQueue[queueHead] = {"", 0, ""}; // Clear the slot
  queueHead = (queueHead + 1) % QUEUE_SIZE;
  queueCount--;
  Serial.println("Dequeued request: email=" + currentRequest.email + ", orderId=" + String(currentRequest.orderId) + ", queueCount=" + String(queueCount));
  isVerifying = true;
  verificationStartTime = millis();
  lcd.clear();
  lcd.print("Place Finger");
  lcd.setCursor(0, 1);
  lcd.print("Order: " + String(currentRequest.orderId));
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

  Serial.println("Starting enrollment for email=" + customerEmail + ", cardID=" + cardID);
  server.send(200, "text/plain", "Enrollment started. Place finger.");
  enrollAndSend();
}

void handleVerify() {
  if (!server.hasArg("plain")) {
    Serial.println("Missing request body");
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

  if (!server.hasHeader("Authorization")) {
    Serial.println("Missing Authorization header");
    server.send(401, "text/plain", "Missing token");
    return;
  }

  String email = doc["email"].as<String>();
  long orderId = doc["orderId"].as<long>();
  String token = server.header("Authorization").substring(7); // Remove "Bearer "

  Serial.println("Received /verify: email=" + email + ", orderId=" + String(orderId));

  if (!isVerifying) {
    // Process immediately
    currentRequest = {email, orderId, token};
    isVerifying = true;
    verificationStartTime = millis();
    lcd.clear();
    lcd.print("Place Finger");
    lcd.setCursor(0, 1);
    lcd.print("Order: " + String(orderId));
    Serial.println("Starting verification for email=" + email + ", orderId=" + String(orderId));
    server.send(200, "text/plain", "Verification initiated. Waiting for fingerprint.");
  } else {
    // Enqueue the request
    enqueueRequest(email, orderId, token);
  }
}

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
  processQueue();
  server.send(200, "application/json", "{\"message\":\"Status received\"}");
}

//================================================================
// FINGERPRINT & ENROLLMENT FUNCTIONS
//================================================================
void enrollAndSend() {
  fingerprintId = 1;
  while (finger.loadModel(fingerprintId) == FINGERPRINT_OK) {
    fingerprintId++;
    if (fingerprintId > 127) {
      lcd.clear();
      lcd.print("Storage full");
      Serial.println("Fingerprint storage full");
      delay(3000);
      displayWelcomeMessage();
      return;
    }
  }

  lcd.clear();
  lcd.print("Place Finger");

  if (!enrollFingerprint(fingerprintId)) {
    lcd.clear();
    lcd.print("Enroll Failed");
    tone(25, 200, 500);
    Serial.println("Enrollment failed for email=" + customerEmail);
    delay(3000);
    displayWelcomeMessage();
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
  Serial.println("Enrollment payload: " + json);

  int httpCode = http.POST(json);
  String payload = http.getString();
  http.end();

  if (httpCode == HTTP_CODE_OK) {
    lcd.clear();
    lcd.print("Successfully");
    lcd.setCursor(0, 1);
    lcd.print("Activated");
    tone(25, 1000, 200);
    Serial.println("Enrollment successful for email=" + customerEmail + ", fingerprintId=" + String(fingerprintId));
  } else {
    lcd.clear();
    lcd.print("Enroll Failed");
    lcd.setCursor(0, 1);
    lcd.print("HTTP Error: " + String(httpCode));
    Serial.println("Enrollment HTTP Error: " + String(httpCode));
    Serial.println("Response: " + payload);
    tone(25, 200, 500);
    finger.deleteModel(fingerprintId);
  }
  delay(3000);
  displayWelcomeMessage();
}

bool enrollFingerprint(int id) {
  int result = -1;
  lcd.clear();
  lcd.print("Place finger");
  while (finger.getImage() != FINGERPRINT_OK);
  if (finger.image2Tz(1) != FINGERPRINT_OK) {
    lcd.clear();
    lcd.print("Image #1 Error");
    Serial.println("Image #1 error during enrollment");
    return false;
  }
  lcd.clear();
  lcd.print("Image taken");
  tone(25, 800, 100);

  lcd.clear();
  lcd.print("Remove Finger");
  delay(500);
  while (finger.getImage() != FINGERPRINT_NOFINGER);
  delay(500);

  lcd.clear();
  lcd.print("Place finger");
  lcd.setCursor(0, 1);
  lcd.print("again");
  while (finger.getImage() != FINGERPRINT_OK);
  if (finger.image2Tz(2) != FINGERPRINT_OK) {
    lcd.clear();
    lcd.print("Image #2 Error");
    Serial.println("Image #2 error during enrollment");
    return false;
  }
  lcd.clear();
  lcd.print("Image taken");
  tone(25, 800, 100);

  lcd.clear();
  lcd.print("Creating Model...");
  if (finger.createModel() != FINGERPRINT_OK) {
    lcd.clear();
    lcd.print("Model Error");
    Serial.println("Model creation error during enrollment");
    return false;
  }

  lcd.clear();
  lcd.print("Storing Model...");
  if (finger.storeModel(id) != FINGERPRINT_OK) {
    lcd.clear();
    lcd.print("Storage Error");
    Serial.println("Storage error during enrollment");
    return false;
  }
  Serial.println("Enrolled successfully with ID: " + String(id));
  return true;
}

int getFingerprintID() {
  if (finger.getImage() != FINGERPRINT_OK) {
    return 0; // Still waiting
  }

  if (finger.image2Tz() != FINGERPRINT_OK) {
    Serial.println("Image to TZ conversion failed for email=" + currentRequest.email + ", orderId=" + String(currentRequest.orderId));
    return -1; // Conversion error
  }

  if (finger.fingerFastSearch() != FINGERPRINT_OK) {
    Serial.println("Fingerprint not found in database for email=" + currentRequest.email + ", orderId=" + String(currentRequest.orderId));
    return -2; // Not found error
  }

  Serial.print("Matched ID: ");
  Serial.print(finger.fingerID);
  Serial.print(" Confidence: ");
  Serial.println(finger.confidence);
  return finger.fingerID;
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
  http.addHeader("Authorization", "Bearer " + currentRequest.token);

  DynamicJsonDocument doc(256);
  doc["authenticated"] = authenticated;
  doc["email"] = currentRequest.email;
  doc["confidence"] = authenticated ? finger.confidence : 0;
  doc["scannedId"] = authenticated ? finger.fingerID : 0;
  doc["orderId"] = currentRequest.orderId;

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
        lcd.setCursor(0, 1);
        lcd.print("Order: " + String(currentRequest.orderId));
        tone(25, 1000, 300);
      } else if (orderStatus == "FAILED" || orderStatus == "PENDING" || orderStatus == "CANCELED") {
        lcd.print("Payment Failed");
        lcd.setCursor(0, 1);
        lcd.print("Order: " + String(currentRequest.orderId));
        tone(25, 200, 1000);
      } else {
        lcd.print("Unknown Status");
        lcd.setCursor(0, 1);
        lcd.print(orderStatus);
        tone(25, 500, 500);
      }
    } else {
      Serial.print(F("deserializeJson() failed on response: "));
      Serial.println(error.f_str());
      lcd.print("Server Error");
      lcd.setCursor(0, 1);
      lcd.print("Bad Response");
      tone(25, 200, 1000);
    }
  } else {
    lcd.print("Server Error");
    lcd.setCursor(0, 1);
    lcd.print("HTTP " + String(httpCode));
    tone(25, 200, 1000);
  }

  http.end();
  delay(3000);
}

void resetVerification() {
  Serial.println("Resetting verification state");
  currentRequest = {"", 0, ""};
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
    if (queueCount > 0) {
      lcd.clear();
      lcd.print("Waiting in queue");
      lcd.setCursor(0, 1);
      lcd.print("Queue: " + String(queueCount));
    } else {
      displayWelcomeMessage();
    }
    return true;
  } else {
    Serial.println("\nWiFi Reconnection Failed.");
    lcd.clear();
    lcd.print("WiFi Failed!");
    delay(3000);
    return false;
  }
}


