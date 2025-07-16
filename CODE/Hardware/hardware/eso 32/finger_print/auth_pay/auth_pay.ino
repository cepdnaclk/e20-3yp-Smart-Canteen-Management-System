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
const String orderCompleteEndpoint = "/api/orders";

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

  const long baudRates[] = {57600, 9600, 115200, 38400};
  for (int i = 0; i < sizeof(baudRates)/sizeof(long); i++) {
    mySerial.begin(baudRates[i], SERIAL_8N1, 16, 17);
    finger.begin(baudRates[i]);

    lcd.setCursor(0, 1);
    lcd.print("Baud: ");
    lcd.print(baudRates[i]);
    delay(1500);

    if (finger.verifyPassword()) {
      lcd.clear();
      lcd.print("Sensor Ready");
      Serial.println("Fingerprint OK at baud " + String(baudRates[i]));
      return;
    }
  }

  lcd.clear();
  lcd.print("Sensor Error");
  while (true) {
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
  lcd.init();
  lcd.backlight();
  lcd.setCursor(0, 0);
  lcd.print("Initializing...");

  initializeSensor();
  delay(1000);

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
    while (true) {
      delay(1000);
      lcd.noBacklight();
      delay(500);
      lcd.backlight();
    }
  }

  lcd.clear();
  lcd.print("WiFi Connected");
  lcd.setCursor(0, 1);
  lcd.print(WiFi.localIP());
  delay(2000);

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
    Serial.print("Has Authorization header? ");
Serial.println(server.hasHeader("Authorization") ? "Yes" : "No");

if (server.hasHeader("Authorization")) {
  String authHeader = server.header("Authorization");
  Serial.print("Authorization header: ");
  Serial.println(authHeader);
  
  if (authHeader.startsWith("Bearer ")) {
    currentToken = authHeader.substring(7);
  }
}
Serial.print("Extracted token: ");
Serial.println(currentToken);


    isVerifying = true;
    fingerprintVerified = false;
    verificationStartTime = millis();

    lcd.clear();
    lcd.print("Place Finger");
    lcd.setCursor(0, 1);
    lcd.print("to Verify");

    server.send(200, "text/plain", "Verification started");
  });

  server.onNotFound([]() {
    server.send(404, "text/plain", "Not found");
  });

  server.begin();
  lcd.clear();
  lcd.print("Ready for Auth");
  Serial.println("ESP32 ready");
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
      int fid = getFingerprintID();
      if (fid > 0) {
        if (finger.confidence >= MIN_CONFIDENCE) {
          lcd.clear();
          lcd.print("Verified!");
          sendVerificationResult(true);
          fingerprintVerified = true;
          delay(1000);
        } else {
          lcd.clear();
          lcd.print("Low Confidence");
          lcd.setCursor(0, 1);
          lcd.print(String(finger.confidence));
          delay(2000);
          lcd.clear();
          lcd.print("Place Finger");
        }
      }
      delay(100);
    } else {
      if (currentOrderId > 0) {
        lcd.clear();
        lcd.print("Completing...");
        bool result = completeOrder(currentOrderId);
        lcd.clear();
        lcd.print(result ? "Order Done" : "Order Fail");
        delay(2000);
      }
      resetVerification();
      lcd.clear();
      lcd.print("Ready for Auth");
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
        lcd.clear();
        lcd.print("Place Finger");
      }
      delay(100);
      server.handleClient();
      attempts++;
      continue;
    }

    Serial.print("Image error: 0x");
    Serial.println(result, HEX);
    return -1;
  }

  if (attempts >= MAX_ATTEMPTS) return -1;

  result = finger.image2Tz();
  if (result != FINGERPRINT_OK) return -1;

  result = finger.fingerFastSearch();
  if (result != FINGERPRINT_OK) {
    lcd.clear();
    lcd.print("No Match");
    delay(2000);
    return -1;
  }

  Serial.print("Matched ID: ");
  Serial.print(finger.fingerID);
  Serial.print(" Confidence: ");
  Serial.println(finger.confidence);

  return finger.fingerID;
}

void sendVerificationResult(bool authenticated) {
  if (WiFi.status() != WL_CONNECTED) return;

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
  doc["orderId"] = currentOrderId;

  String json;
  serializeJson(doc, json);

  Serial.println("Sending result to: " + url);
  Serial.println("Payload: " + json);

  int code = http.POST(json);
  Serial.println("Response code: " + String(code));
  Serial.println("Response: " + http.getString());
  http.end();
}

bool completeOrder(long orderId) {
  if (WiFi.status() != WL_CONNECTED) return false;

  HTTPClient http;
  String url = String(backendUrl) + orderCompleteEndpoint + "/" + String(orderId) + "/completeDirectly";
  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  http.addHeader("Authorization", "Bearer " + currentToken);

  int code = http.PUT("");
  String resp = http.getString();
  Serial.println("Complete order HTTP: " + String(code));
  Serial.println("Resp: " + resp);
  http.end();
  return (code == HTTP_CODE_OK);
}

void resetVerification() {
  currentEmail = "";
  currentToken = "";
  currentOrderId = 0;
  isVerifying = false;
  fingerprintVerified = false;
}
