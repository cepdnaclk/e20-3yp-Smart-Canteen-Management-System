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

// Backend configuration
const char* backendUrl = "http://192.168.8.183:8081";
const String authEndpoint = "/api/biometric/authenticate";

// Web server on port 80
WebServer server(80);

// Hardware setup
HardwareSerial mySerial(1); // GPIO16 RX, GPIO17 TX
Adafruit_Fingerprint finger(&mySerial);
LiquidCrystal_I2C lcd(0x27, 16, 2);

// Auth flow variables
String currentEmail = "";
String currentToken = "";
long currentOrderId = 0;
bool isVerifying = false;
bool fingerprintVerified = false;
unsigned long verificationStartTime = 0;

const unsigned long VERIFICATION_TIMEOUT = 90000;
const unsigned long WIFI_CHECK_INTERVAL = 30000;
const unsigned long RESULT_DISPLAY_TIME = 3000;
const int MIN_CONFIDENCE = 50;
const int MAX_ATTEMPTS = 200;
const int HTTP_RETRIES = 3;
const int HTTP_TIMEOUT = 5000;

unsigned long lastWifiCheck = 0;
unsigned long resultDisplayStart = 0;
bool showingResult = false;
String resultMessage = "";
String detailMessage = "";

// Function prototypes
int getFingerprintID();
bool sendVerificationResult();
void resetVerification();
bool ensureWiFiConnection();
void showMessage(String line1, String line2 = "");
void handlePostVerification();

void initializeSensor() {
  showMessage("Init Sensor...");

  const long baudRates[] = {57600, 9600, 115200, 38400};
  for (int i = 0; i < sizeof(baudRates)/sizeof(long); i++) {
    mySerial.begin(baudRates[i], SERIAL_8N1, 16, 17);
    finger.begin(baudRates[i]);

    showMessage("Trying baud:", String(baudRates[i]));
    delay(1500);

    if (finger.verifyPassword()) {
      showMessage("Sensor Ready");
      Serial.println("Fingerprint OK at baud " + String(baudRates[i]));
      return;
    }
  }

  showMessage("Sensor Error", "Check Wiring");
  while (true) {
    delay(2000);
    showMessage("Sensor Error", "Reset Device");
    delay(2000);
  }
}

// Display helper function
void showMessage(String line1, String line2) {
  lcd.clear();
  lcd.print(line1);
  if (line2.length() > 0) {
    lcd.setCursor(0, 1);
    lcd.print(line2);
  }
}

bool ensureWiFiConnection() {
  if (WiFi.status() == WL_CONNECTED) return true;
  
  Serial.println("WiFi disconnected! Reconnecting...");
  showMessage("Reconnecting WiFi");
  
  WiFi.disconnect();
  delay(1000);
  WiFi.begin(ssid, password);
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 10) {
    delay(500);
    lcd.print(".");
    Serial.print(".");
    attempts++;
  }
  
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("\nWiFi reconnect failed");
    showMessage("WiFi Failed", "Check Connection");
    return false;
  }
  
  Serial.println("\nWiFi reconnected");
  showMessage("WiFi Connected", WiFi.localIP().toString());
  delay(1000);
  return true;
}

void setup() {
  Serial.begin(115200);
  lcd.init();
  lcd.backlight();
  showMessage("Initializing...");

  initializeSensor();
  delay(1000);

  showMessage("Connecting WiFi");
  Serial.print("Connecting to ");
  Serial.println(ssid);
  
  WiFi.begin(ssid, password);

  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    lcd.print(".");
    Serial.print(".");
    attempts++;
  }

  if (!ensureWiFiConnection()) {
    while (true) {
      delay(1000);
      lcd.noBacklight();
      delay(500);
      lcd.backlight();
    }
  }

  server.on("/verify", HTTP_POST, []() {
    if (!server.hasArg("plain")) {
      server.send(400, "text/plain", "Missing request body");
      return;
    }

    String body = server.arg("plain");
    Serial.println("Received JSON: " + body);
    DynamicJsonDocument doc(512);
    DeserializationError error = deserializeJson(doc, body);
    if (error) {
      server.send(400, "text/plain", "Invalid JSON: " + String(error.c_str()));
      return;
    }

    if (server.hasHeader("Authorization")) {
      String authHeader = server.header("Authorization");
      if (authHeader.startsWith("Bearer ")) {
        currentToken = authHeader.substring(7);
      }
    } else {
      server.send(401, "text/plain", "Missing token");
      return;
    }

    currentEmail = doc["email"].as<String>();
    currentOrderId = doc["orderId"].as<long>();

    Serial.println("Email: " + currentEmail);
    Serial.println("Order ID: " + String(currentOrderId));
    Serial.println("Token: " + currentToken);

    isVerifying = true;
    fingerprintVerified = false;
    verificationStartTime = millis();

    showMessage("Place Finger", "to Verify");
    server.send(200, "text/plain", "Verification started");
  });

  server.onNotFound([]() {
    server.send(404, "text/plain", "Not found");
  });

  server.begin();
  showMessage("Ready for Auth");
  Serial.println("ESP32 ready");
}

void loop() {
  server.handleClient();

  // Periodic WiFi maintenance
  if (millis() - lastWifiCheck > WIFI_CHECK_INTERVAL) {
    ensureWiFiConnection();
    lastWifiCheck = millis();
  }

  // Handle showing result screen
  if (showingResult) {
    if (millis() - resultDisplayStart > RESULT_DISPLAY_TIME) {
      resetVerification();
      showMessage("Ready for Auth");
      showingResult = false;
    }
    return;
  }

  // Handle verification process
  if (isVerifying) {
    // Handle timeout
    if (millis() - verificationStartTime > VERIFICATION_TIMEOUT) {
      showMessage("Timeout!", "Try Again");
      delay(2000);
      resetVerification();
      showMessage("Ready for Auth");
      return;
    }

    // If we haven't verified fingerprint yet
    if (!fingerprintVerified) {
      int fid = getFingerprintID();
      
      // Handle fingerprint errors
      if (fid == -2) {
        showMessage("Place Finger", "Properly");
        delay(1000);
        showMessage("Place Finger", "to Verify");
      }
      else if (fid == -3) {
        showMessage("No Match Found", "Try Again");
        delay(2000);
        showMessage("Place Finger", "to Verify");
      }
      else if (fid > 0) {
        if (finger.confidence >= MIN_CONFIDENCE) {
          fingerprintVerified = true;
          showMessage("Verified!", "Processing...");
          sendVerificationResult();
        } else {
          showMessage("Low Confidence", "Score: " + String(finger.confidence));
          delay(2000);
          showMessage("Place Finger", "to Verify");
        }
      }
    }
  }
}

int getFingerprintID() {
  int result;
  int attempts = 0;

  while (attempts < MAX_ATTEMPTS) {
    result = finger.getImage();
    if (result == FINGERPRINT_OK) break;

    if (result == FINGERPRINT_NOFINGER) {
      if (attempts % 10 == 0) {
        showMessage("Place Finger", "Properly");
      }
      delay(100);
      server.handleClient();
      attempts++;
      continue;
    }

    // Handle specific sensor errors
    switch(result) {
      case FINGERPRINT_PACKETRECIEVEERR:
        Serial.println("Communication error");
        return -2; // Special error code for placement issues
      case FINGERPRINT_IMAGEFAIL:
        Serial.println("Imaging error");
        showMessage("Scan Error", "Try Again");
        delay(1000);
        return -2;
      default:
        Serial.print("Image error: 0x");
        Serial.println(result, HEX);
        return -1;
    }
  }

  if (attempts >= MAX_ATTEMPTS) return -2; // Placement issue

  result = finger.image2Tz();
  if (result != FINGERPRINT_OK) {
    showMessage("Bad Image", "Try Again");
    delay(1000);
    return -2; // Placement issue
  }

  result = finger.fingerFastSearch();
  if (result != FINGERPRINT_OK) {
    return -3; // No match found
  }

  Serial.print("Matched ID: ");
  Serial.print(finger.fingerID);
  Serial.print(" Confidence: ");
  Serial.println(finger.confidence);

  return finger.fingerID;
}

bool sendVerificationResult() {
  int retryCount = 0;
  bool success = false;
  bool paymentSuccess = false;
  String paymentMessage = "";

  while (retryCount < HTTP_RETRIES && !success) {
    if (!ensureWiFiConnection()) {
      retryCount++;
      delay(2000);
      continue;
    }

    HTTPClient http;
    http.setTimeout(HTTP_TIMEOUT);
    String url = String(backendUrl) + authEndpoint;
    http.begin(url);
    http.addHeader("Content-Type", "application/json");
    http.addHeader("Authorization", "Bearer " + currentToken);

    DynamicJsonDocument doc(256);
    doc["email"] = currentEmail;
    doc["orderId"] = currentOrderId;
    doc["authenticated"] = true;
    doc["confidence"] = finger.confidence;
    doc["scannedId"] = finger.fingerID;

    String json;
    serializeJson(doc, json);

    Serial.println("Sending to: " + url);
    Serial.println("Payload: " + json);

    int code = http.POST(json);
    String response = http.getString();
    http.end();

    Serial.println("Response code: " + String(code));
    Serial.println("Response: " + response);

    if (code == HTTP_CODE_OK) {
      DynamicJsonDocument resDoc(256);
      DeserializationError error = deserializeJson(resDoc, response);
      
      if (!error) {
        success = true;
        paymentSuccess = resDoc["paymentCompleted"];
        paymentMessage = resDoc["message"].as<String>();
        
        // Set result messages
        if (paymentSuccess) {
          resultMessage = "Payment Success!";
        } else {
          resultMessage = "Payment Failed";
        }
        detailMessage = paymentMessage.substring(0, 16);
      } else {
        Serial.println("JSON parse error: " + String(error.c_str()));
        resultMessage = "Data Error";
        detailMessage = "Bad Response";
      }
    } else {
      retryCount++;
      Serial.println("Retry " + String(retryCount) + "/" + String(HTTP_RETRIES));
      
      // Set temporary error message
      resultMessage = "Network Error";
      detailMessage = "Retry " + String(retryCount);
      showMessage(resultMessage, detailMessage);
      
      delay(1000);
    }
  }

  if (!success) {
    resultMessage = "Backend Error";
    detailMessage = "Try Again";
  }
  
  // Show final result
  showMessage(resultMessage, detailMessage);
  showingResult = true;
  resultDisplayStart = millis();
  
  return success;
}

void resetVerification() {
  currentEmail = "";
  currentToken = "";
  currentOrderId = 0;
  isVerifying = false;
  fingerprintVerified = false;
  showingResult = false;
}