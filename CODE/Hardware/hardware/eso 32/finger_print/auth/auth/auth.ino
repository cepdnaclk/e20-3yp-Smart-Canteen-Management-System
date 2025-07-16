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
bool isVerifying = false;
unsigned long verificationStartTime = 0;
const unsigned long VERIFICATION_TIMEOUT = 90000; // 90 seconds

// Sensor configuration
const int MIN_CONFIDENCE = 50; // Lower confidence threshold
const int MAX_ATTEMPTS = 200; // Increased attempt limit

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
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    lcd.print(".");
    attempts++;
  }

  if (WiFi.status() != WL_CONNECTED) {
    lcd.clear();
    lcd.print("WiFi Failed");
    while(true) delay(1000);
  }

  lcd.clear();
  lcd.print("WiFi Connected");
  lcd.setCursor(0, 1);
  lcd.print(WiFi.localIP());
  Serial.print("ESP32 IP: ");
  Serial.println(WiFi.localIP());
  delay(3000);

  // Initialize fingerprint sensor
  mySerial.begin(57600, SERIAL_8N1, 16, 17);
  finger.begin(57600);
  delay(1000);

  if (finger.verifyPassword()) {
    lcd.clear();
    lcd.print("Sensor Ready");
    Serial.println("Fingerprint sensor OK");
    
    // Print sensor info
    Serial.print("Template count: ");
    Serial.println(finger.getTemplateCount());
  } else {
    lcd.clear();
    lcd.print("Sensor Error");
    Serial.println("Fingerprint sensor not found");
    while(true) delay(1000);
  }

  // Configure verification endpoint
  server.on("/verify", HTTP_POST, handleVerify);
  server.onNotFound(handleNotFound);
  
  server.begin();
  Serial.println("HTTP server started");
  
  lcd.clear();
  lcd.print("Ready for Auth");
  Serial.println("System ready");
}

void loop() {
  server.handleClient();
  
  // Handle verification timeout
  if (isVerifying && millis() - verificationStartTime > VERIFICATION_TIMEOUT) {
    lcd.clear();
    lcd.print("Timeout!");
    sendVerificationResult(false);
    resetVerification();
    delay(2000);
    lcd.clear();
    lcd.print("Ready for Auth");
  }
  
  // Process fingerprint scan during verification
  if (isVerifying) {
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
        resetVerification();
        delay(2000);
        lcd.clear();
        lcd.print("Ready for Auth");
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
    delay(100); // Reduce CPU usage
  }
}

void handleVerify() {
  Serial.println("Verification request received");
  if (server.hasArg("plain")) {
    String body = server.arg("plain");
    DynamicJsonDocument doc(256);
    DeserializationError error = deserializeJson(doc, body);
    
    if (error) {
      server.send(400, "text/plain", "Invalid JSON");
      return;
    }
    
    currentEmail = doc["email"].as<String>();
    currentFingerprintId = doc["fingerprintID"].as<String>();
    currentToken = doc["token"].as<String>();
    
    Serial.println("Verification request:");
    Serial.println("Email: " + currentEmail);
    Serial.println("Fingerprint ID: " + currentFingerprintId);
    
    // Start verification process
    isVerifying = true;
    verificationStartTime = millis();
    
    lcd.clear();
    lcd.print("Place Finger");
    lcd.setCursor(0, 1);
    lcd.print("to Verify");
    
    server.send(200, "text/plain", "Verification started");
  } else {
    server.send(400, "text/plain", "Missing body");
  }
}

void handleNotFound() {
  server.send(404, "text/plain", "Endpoint not found");
}

// UPDATED: Fingerprint scanning without unsupported methods
int getFingerprintID() {
  int result;
  int attempts = 0;
  
  while (attempts < MAX_ATTEMPTS) {
    result = finger.getImage();
    attempts++;
    
    if (result == FINGERPRINT_OK) {
      break; // Got a good image
    }
    
    if (result == FINGERPRINT_NOFINGER) {
      // Show placement guidance after 5 seconds
      if (attempts > 50) {
        lcd.clear();
        lcd.print("Press Firmly");
        lcd.setCursor(0, 1);
        lcd.print("Center Finger");
      }
      server.handleClient();
      delay(100);
      continue;
    }
    
    Serial.print("Image error: ");
    Serial.println(result);
    return -1;
  }

  if (attempts >= MAX_ATTEMPTS) {
    Serial.println("Max attempts reached");
    return -1;
  }

  result = finger.image2Tz();
  if (result != FINGERPRINT_OK) {
    Serial.print("Conversion error: ");
    Serial.println(result);
    return -1;
  }

  result = finger.fingerFastSearch();
  if (result != FINGERPRINT_OK) {
    Serial.print("Search error: ");
    Serial.println(result);
    
    // Provide specific feedback
    if (result == FINGERPRINT_NOTFOUND) {
      lcd.clear();
      lcd.print("No Match Found");
      lcd.setCursor(0, 1);
      lcd.print("Try Again");
      delay(2000);
    }
    return -1;
  }

  // Found a match!
  Serial.print("Match found! ID: ");
  Serial.print(finger.fingerID);
  Serial.print(" Confidence: ");
  Serial.println(finger.confidence);
  
  return finger.fingerID;
}

void sendVerificationResult(bool authenticated) {
  // Prepare response for Spring Boot
  DynamicJsonDocument doc(256);
  doc["authenticated"] = authenticated;
  doc["email"] = currentEmail;
  
  // Add debug info
  doc["confidence"] = finger.confidence;
  doc["scannedId"] = finger.fingerID;
  
  String json;
  serializeJson(doc, json);
  
  Serial.print("Verification result: ");
  Serial.println(json);
}

void resetVerification() {
  currentEmail = "";
  currentFingerprintId = "";
  currentToken = "";
  isVerifying = false;
}