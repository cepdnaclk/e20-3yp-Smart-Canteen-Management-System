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

// Backend configuration - UPDATE THIS TO YOUR RASPBERRY PI's IP!
const char* backendUrl = "http://192.168.8.183:8081"; // Use your Pi's IP
const String authEndpoint = "/api/biometric/authenticate";
const String orderCompleteEndpoint = "/api/orders";

// Web server on port 80
WebServer server(80);

// Fingerprint and LCD setup
HardwareSerial mySerial(1); // GPIO16 (RX), GPIO17 (TX)
Adafruit_Fingerprint finger(&mySerial);
LiquidCrystal_I2C lcd(0x27, 16, 2); // I2C address 0x27, 16x2 display

// Verification variables
String currentEmail = "";
String currentFingerprintId = "";
String currentToken = "";
long currentOrderId = 0;
bool isVerifying = false;
bool fingerprintVerified = false;
unsigned long verificationStartTime = 0;
const unsigned long VERIFICATION_TIMEOUT = 90000; // 90 seconds

// Sensor configuration
const int MIN_CONFIDENCE = 50;
const int MAX_ATTEMPTS = 200;

// Forward declarations
int getFingerprintID();
void sendVerificationResult(bool authenticated);
bool completeOrder(long orderId);
void resetVerification();

void initializeSensor() {
  lcd.clear();
  lcd.print("Init Sensor...");
  
  // Try multiple baud rates
  const long baudRates[] = {57600, 9600, 115200, 38400};
  const int numRates = sizeof(baudRates) / sizeof(baudRates[0]);
  
  for (int i = 0; i < numRates; i++) {
    mySerial.begin(baudRates[i], SERIAL_8N1, 16, 17);
    finger.begin(baudRates[i]);
    
    lcd.setCursor(0, 1);
    lcd.print("Baud: ");
    lcd.print(baudRates[i]);
    
    delay(1500);  // Give time to initialize
    
    if (finger.verifyPassword()) {
      lcd.clear();
      lcd.print("Sensor Ready");
      Serial.print("Fingerprint sensor OK at ");
      Serial.print(baudRates[i]);
      Serial.println(" baud");
      Serial.print("Template count: ");
      Serial.println(finger.getTemplateCount());
      return;
    }
  }
  
  // If we get here, all baud rates failed
  lcd.clear();
  lcd.print("Sensor Error");
  Serial.println("Fingerprint sensor not found");
  while(true) {
    lcd.setCursor(0, 1);
    lcd.print("Check Wiring");
    delay(2000);
    lcd.setCursor(0, 1);
    lcd.print("Reset Device");
    delay(2000);
  }
}

void setup() {
  Serial.begin(115200);
  delay(1000);

  lcd.init();
  lcd.backlight();
  lcd.setCursor(0, 0);
  lcd.print("Initializing...");

  // Initialize sensor FIRST before WiFi
  initializeSensor();
  delay(1000);

  // Now connect to WiFi
  lcd.clear();
  lcd.print("Connecting WiFi");
  WiFi.begin(ssid, password);
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    lcd.print(".");
    attempts++;
  }

  if (WiFi.status() != WL_CONNECTED) {
    lcd.clear();
    lcd.print("WiFi Failed");
    Serial.println("WiFi connection failed");
    
    // Show IP config details
    lcd.setCursor(0, 1);
    lcd.print("Check Credentials");
    while(true) {
      delay(1000);
      // Blink to indicate error
      lcd.noBacklight();
      delay(500);
      lcd.backlight();
    }
  }

  lcd.clear();
  lcd.print("WiFi Connected");
  lcd.setCursor(0, 1);
  lcd.print(WiFi.localIP());
  Serial.print("ESP32 IP: ");
  Serial.println(WiFi.localIP());
  delay(3000);
  

  // Set up web server endpoints
  server.on("/verify", HTTP_POST, []() {
    Serial.println("Verification request received");
    String body = server.arg("plain");
    Serial.println("Raw body: " + body);

    if (server.hasArg("plain")) {
      String body = server.arg("plain");
      DynamicJsonDocument doc(512);
      DeserializationError error = deserializeJson(doc, body);
      
      if (error) {
        server.send(400, "text/plain", "Invalid JSON: " + String(error.c_str()));
        return;
      }
      
      currentEmail = doc["email"].as<String>();
      currentFingerprintId = doc["fingerprintID"].as<String>();
      currentToken = doc["token"].as<String>();
      currentOrderId = doc.containsKey("orderId") ? doc["orderId"].as<long>() : 0;
      
      Serial.println("Verification request:");
      Serial.println("Email: " + currentEmail);
      Serial.println("Fingerprint ID: " + currentFingerprintId);
      Serial.print("Order ID: ");
      Serial.println(currentOrderId);
      Serial.print("Received token: ");
      Serial.println(currentToken);

      
      isVerifying = true;
      fingerprintVerified = false;
      verificationStartTime = millis();
      
      lcd.clear();
      lcd.print("Place Finger");
      lcd.setCursor(0, 1);
      lcd.print("to Verify");
      
      server.send(200, "text/plain", "Verification started");
    } else {
      server.send(400, "text/plain", "Missing request body");
    }
  });

  server.onNotFound([]() {
    server.send(404, "text/plain", "Endpoint not found");
  });

  server.begin();
  Serial.println("HTTP server started");

  lcd.clear();
  lcd.print("Ready for Auth");
  Serial.println("System ready");
}

void loop() {
  server.handleClient();

  if (isVerifying) {
    if (millis() - verificationStartTime > VERIFICATION_TIMEOUT) {
      lcd.clear();
      lcd.print("Timeout!");
      sendVerificationResult(false);
      resetVerification();
      delay(2000);
      lcd.clear();
      lcd.print("Ready for Auth");
      return;
    }

    if (!fingerprintVerified) {
      int fingerprintId = getFingerprintID();

      if (fingerprintId > 0) {
        String scannedId = String(fingerprintId);

        Serial.print("Scanned ID: ");
        Serial.print(scannedId);
        Serial.print(" Expected: ");
        Serial.println(currentFingerprintId);
        Serial.print("Confidence: ");
        Serial.println(finger.confidence);

        if (scannedId.equals(currentFingerprintId) && finger.confidence >= MIN_CONFIDENCE) {
          lcd.clear();
          lcd.print("Verified!");
          sendVerificationResult(true);
          fingerprintVerified = true;
          delay(1000);
        } else {
          lcd.clear();
          if (!scannedId.equals(currentFingerprintId)) {
            lcd.print("Wrong Finger");
            Serial.println("Wrong fingerprint detected");
          } else {
            lcd.print("Low Confidence");
            lcd.setCursor(0, 1);
            lcd.print(String(finger.confidence) + "/100");
            Serial.print("Low confidence: ");
            Serial.println(finger.confidence);
          }
          lcd.setCursor(0, 1);
          lcd.print("Try Again");
          delay(2000);
          lcd.clear();
          lcd.print("Place Finger");
        }
      }

      delay(100);
    } else {
      if (currentOrderId > 0) {
        lcd.clear();
        lcd.print("Completing Order");
        Serial.println("Completing order: " + String(currentOrderId));
        bool orderResult = completeOrder(currentOrderId);
        lcd.clear();
        if (orderResult) {
          lcd.print("Order Completed");
          Serial.println("Order marked complete");
        } else {
          lcd.print("Order Failed");
          Serial.println("Failed to complete order");
        }
        delay(2000);
      }
      resetVerification();
      lcd.clear();
      lcd.print("Ready for Auth");
    }
  }
}

// Fingerprint scan function
int getFingerprintID() {
  int result;
  int attempts = 0;

  while (attempts < MAX_ATTEMPTS) {
    result = finger.getImage();
    
    if (result == FINGERPRINT_OK) {
      break; // Got a good image
    }

    if (result == FINGERPRINT_NOFINGER) {
      if (attempts % 10 == 0) {  // Update display periodically
        lcd.clear();
        lcd.print("Place Finger");
        if (attempts > 30) {
          lcd.setCursor(0, 1);
          lcd.print("Press Firmly");
        }
      }
      server.handleClient();
      delay(100);
      attempts++;
      continue;
    }

    Serial.print("Image error: 0x");
    Serial.println(result, HEX);
    return -1;
  }

  if (attempts >= MAX_ATTEMPTS) {
    Serial.println("Max attempts reached");
    return -1;
  }

  result = finger.image2Tz();
  if (result != FINGERPRINT_OK) {
    Serial.print("Conversion error: 0x");
    Serial.println(result, HEX);
    return -1;
  }

  result = finger.fingerFastSearch();
  if (result != FINGERPRINT_OK) {
    Serial.print("Search error: 0x");
    Serial.println(result, HEX);

    if (result == FINGERPRINT_NOTFOUND) {
      lcd.clear();
      lcd.print("No Match Found");
      lcd.setCursor(0, 1);
      lcd.print("Try Again");
      delay(2000);
    }
    return -1;
  }

  Serial.print("Match found! ID: ");
  Serial.print(finger.fingerID);
  Serial.print(" Confidence: ");
  Serial.println(finger.confidence);

  return finger.fingerID;
}

// Send verification result back to backend
void sendVerificationResult(bool authenticated) {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("Can't send result - WiFi disconnected");
    return;
  }

  HTTPClient http;
  String url = String(backendUrl) + authEndpoint;
  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  http.addHeader("Authorization", "Bearer " + currentToken);

  DynamicJsonDocument doc(256);
  doc["authenticated"] = authenticated;
  doc["email"] = currentEmail;
  doc["confidence"] = finger.confidence;
  doc["scannedId"] = finger.fingerID;

  String json;
  serializeJson(doc, json);

  Serial.print("Sending verification to: ");
  Serial.println(url);
  Serial.print("Payload: ");
  Serial.println(json);

  int httpCode = http.POST(json);
  String payload = http.getString();
  
  Serial.print("Response code: ");
  Serial.println(httpCode);
  Serial.print("Response: ");
  Serial.println(payload);

  http.end();
}

// Complete the order by calling backend
bool completeOrder(long orderId) {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("WiFi not connected");
    return false;
  }

  HTTPClient http;
  String orderUrl = String(backendUrl) + orderCompleteEndpoint + "/" + String(orderId) + "/completeDirectly";
  http.begin(orderUrl);
  http.addHeader("Content-Type", "application/json");
  http.addHeader("Authorization", "Bearer " + currentToken);

  Serial.println("Completing order:");
  Serial.println(orderUrl);

  int httpCode = http.PUT("");
  String payload = http.getString();
  
  Serial.print("Order completion response: ");
  Serial.println(httpCode);
  Serial.print("Response: ");
  Serial.println(payload);
  
  http.end();

  return (httpCode == HTTP_CODE_OK);
}

// Reset all verification state
void resetVerification() {
  currentEmail = "";
  currentFingerprintId = "";
  currentToken = "";
  currentOrderId = 0;
  isVerifying = false;
  fingerprintVerified = false;
}