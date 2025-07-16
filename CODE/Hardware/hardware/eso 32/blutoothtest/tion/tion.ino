// Combined Code: Enrollment + Verification + Payment Status (Hybrid BLE-to-Pi & WiFi-to-Backend)

#include <WiFi.h>          // For WiFi connection to backend
#include <HTTPClient.h>    // For sending data to backend
#include <Adafruit_Fingerprint.h>
#include <HardwareSerial.h>
#include <LiquidCrystal_I2C.h>
#include <ArduinoJson.h>    // Still needed for JSON parsing/serialization

// BLE Includes
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h> // For notifications

// Uncomment this line to enable verbose Serial.print debugging
// #define DEBUG_MODE

// ======================= Global Variables and Objects =======================
// These must be declared *before* the classes that use them.

// WiFi credentials
const char* ssid = "Dialog 4G 140";
const char* password = "pathum27980";

// Backend endpoints
const char* enrollUrl = "http://192.168.8.183:8081/api/merchant/update-biometrics-data"; // <--- VERIFY IP/PORT
const char* baseVerifyUrl = "http://192.168.8.183:8081";                               // <--- VERIFY IP/PORT
const char* authEndpoint = "/api/biometric/confirm"; // Using const char* for PROGMEM potential

// Hardware setup
HardwareSerial mySerial(1); // GPIO16 RX, GPIO17 TX for fingerprint sensor
Adafruit_Fingerprint finger(&mySerial);
LiquidCrystal_I2C lcd(0x27, 16, 2); // LCD I2C address 0x27, 16 columns, 2 rows

// Enrollment variables
String customerEmail = "";
String cardID = ""; // RFID from Pi
String jwtToken = "";
int fingerprintId = 1; // Starting ID for new enrollments

// Verification variables
String currentEmail = "";
String currentToken = ""; // JWT token from Pi for authentication with backend
long currentOrderId = 0;
bool isVerifying = false;
bool waitingForPaymentStatus = false; // Still waiting for Pi to send the final status
unsigned long verificationStartTime = 0;
unsigned long paymentStatusTime = 0;

const unsigned long VERIFICATION_TIMEOUT = 90000;    // 90 seconds
const unsigned long PAYMENT_STATUS_TIMEOUT = 30000;  // 30 seconds
const unsigned long WIFI_CHECK_INTERVAL = 30000;     // Check WiFi every 30 seconds
const int MIN_CONFIDENCE = 50;                       // Minimum confidence for fingerprint match
const int MAX_ATTEMPTS = 200;                        // Max attempts to read fingerprint image (in getFingerprintID)
const int HTTP_TIMEOUT = 5000;                       // HTTP request timeout in milliseconds

unsigned long lastWifiCheck = 0;

// ======================= Forward Declarations of Functions =======================
// Needed so the compiler knows these exist when used inside classes
void resetVerification();
void enrollAndSend();
void sendVerificationResultToBackend(bool authenticated, int scannedId, int confidence);
void sendStatusToPi(String messageType, String statusMessage, long orderId = 0, int scannedId = 0, int confidence = 0);
bool ensureWiFiConnection();


// ======================= BLE Configuration =======================
#define SERVICE_UUID              "4fafc201-1fb5-459e-8fcc-c5c9c331914b" // Custom Service UUID
#define COMMAND_CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8" // Characteristic for receiving commands (e.g., RFID, trigger verify)
#define STATUS_CHARACTERISTIC_UUID  "c5c9c331-914b-4688-b7f5-ea07361b26a9" // Characteristic for sending status (Notifications to Pi)
#define DEVICE_NAME               "ESP32_Bio_Sensor" // Name for your ESP32 BLE device

BLEServer* pServer = NULL;
BLECharacteristic* pCommandCharacteristic = NULL; // For receiving commands (writes)
BLECharacteristic* pStatusCharacteristic = NULL;  // For sending status (notifications)
bool deviceConnectedToBLE = false;


// ======================= MyServerCallbacks for BLE Connection Status =======================
// This class needs access to lcd and resetVerification
class MyServerCallbacks: public BLEServerCallbacks {
public:
    LiquidCrystal_I2C& _lcd; // Reference to the global lcd object
    void (*_resetVerification)(); // Pointer to the global resetVerification function

    // Constructor to pass in references to global objects/functions
    MyServerCallbacks(LiquidCrystal_I2C& l, void (*rv)()) : _lcd(l), _resetVerification(rv) {}

    void onConnect(BLEServer* pServer) {
      deviceConnectedToBLE = true;
      #ifdef DEBUG_MODE
        Serial.println("BLE Client (Pi) Connected!");
      #endif
      _lcd.clear();
      _lcd.print("Pi Connected!");
      delay(1000);
      _lcd.clear();
      // _lcd.print("Ready"); // Don't print ready yet, need WiFi (setup will handle this)
    };

    void onDisconnect(BLEServer* pServer) {
      deviceConnectedToBLE = false;
      #ifdef DEBUG_MODE
        Serial.println("BLE Client (Pi) Disconnected! Starting advertising again...");
      #endif
      _lcd.clear();
      _lcd.print("Pi Disconnected");
      delay(1000);
      pServer->startAdvertising(); // Restart advertising
      _lcd.clear();
      // _lcd.print("Ready"); // Don't print ready yet, need WiFi (setup will handle this)
      _resetVerification(); // Call the global resetVerification function
    }
};

// ======================= MyCharacteristicCallbacks for incoming BLE Commands =======================
// This class needs access to all global state variables and functions
class MyCharacteristicCallbacks: public BLECharacteristicCallbacks {
public:
    LiquidCrystal_I2C& _lcd;
    String& _customerEmail;
    String& _cardID;
    String& _jwtToken;
    String& _currentEmail;
    String& _currentToken;
    long& _currentOrderId;
    bool& _isVerifying;
    unsigned long& _verificationStartTime;
    void (*_enrollAndSend)();
    void (*_resetVerification)();

    // Constructor to pass in references to global variables/functions
    MyCharacteristicCallbacks(
        LiquidCrystal_I2C& l, String& ce, String& ci, String& jwt, String& cure,
        String& curt, long& cui, bool& iv, unsigned long& vst,
        void (*eas)(), void (*rv)()
    ) :
        _lcd(l), _customerEmail(ce), _cardID(ci), _jwtToken(jwt),
        _currentEmail(cure), _currentToken(curt), _currentOrderId(cui),
        _isVerifying(iv), _verificationStartTime(vst),
        _enrollAndSend(eas), _resetVerification(rv)
    {}

    void onWrite(BLECharacteristic *pCharacteristic) {
        // CORRECTED: Get raw data pointer and length separately
        uint8_t* payload = pCharacteristic->getData(); // Directly get the raw byte array pointer
        size_t length = pCharacteristic->getLength();  // Get the length of the received data

        String command = "";
        if (payload != nullptr && length > 0) {
            // Create a temporary char array with space for null terminator
            char tempBuffer[length + 1];
            memcpy(tempBuffer, payload, length);
            tempBuffer[length] = '\0'; // Null-terminate the string
            command = String(tempBuffer);
        }

        if (command.length() > 0) {
            #ifdef DEBUG_MODE
              Serial.print("Received BLE Command from Pi: ");
              Serial.println(command);
            #endif

            DynamicJsonDocument doc(512); // Use a decent size for incoming JSON
            DeserializationError error = deserializeJson(doc, command);

            if (error) {
                #ifdef DEBUG_MODE
                  Serial.print(F("deserializeJson() failed for BLE command: "));
                  Serial.println(error.f_str());
                #endif
                _lcd.clear();
                _lcd.print("Bad BLE Cmd");
                delay(1000);
                _lcd.clear();
                _lcd.print("Ready");
                return;
            }

            String type = doc["type"].as<String>();

            if (type == "ENROLL_REQUEST") {
                _customerEmail = doc["email"].as<String>();
                _cardID = doc["rfid"].as<String>(); // This is the RFID from Pi
                _jwtToken = doc["token"].as<String>();
                _enrollAndSend(); // Trigger enrollment process
            } else if (type == "VERIFY_REQUEST") {
                _currentEmail = doc["email"].as<String>();
                _currentOrderId = doc["orderId"].as<long>();
                _currentToken = doc["token"].as<String>(); // Get token from Pi for backend call
                _isVerifying = true;
                _verificationStartTime = millis();
                _lcd.clear();
                _lcd.print("Place Finger");
                _lcd.setCursor(0, 1);
                _lcd.print("to Verify");
                #ifdef DEBUG_MODE
                  Serial.println("Verification initiated by Pi via BLE.");
                #endif
            } else if (type == "PAYMENT_STATUS_UPDATE") {
                // This is if the Pi sends the final payment status after backend processing
                String status = doc["status"].as<String>();
                _lcd.clear();
                if (status == "success") {
                    _lcd.print("Payment Success");
                    tone(25, 1000, 300); // Success tone
                } else {
                    _lcd.print("Payment Failed");
                    tone(25, 200, 1000); // Failure tone
                }
                delay(3000);
                _resetVerification(); // Call global reset
                _lcd.clear();
                _lcd.print("Ready");
                #ifdef DEBUG_MODE
                  Serial.println("Payment status received from Pi.");
                #endif
            } else {
                #ifdef DEBUG_MODE
                  Serial.print("Unknown BLE Command Type: "); Serial.println(type);
                #endif
                _lcd.clear();
                _lcd.print("Unknown Cmd");
                delay(1000);
                _lcd.clear();
                _lcd.print("Ready");
            }
        }
    }
};


// ======================= Helper Functions =======================

void resetVerification() {
  currentEmail = "";
  currentToken = "";
  currentOrderId = 0;
  isVerifying = false;
  waitingForPaymentStatus = false;
  paymentStatusTime = 0;
  #ifdef DEBUG_MODE
    Serial.println("Verification state reset.");
  #endif
}

// Function to send status messages back to Raspberry Pi via BLE Notifications
void sendStatusToPi(String messageType, String statusMessage, long orderId, int scannedId, int confidence) {
  if (deviceConnectedToBLE && pStatusCharacteristic) { // Ensure characteristic is initialized
    DynamicJsonDocument doc(256);
    doc["type"] = messageType;
    doc["message"] = statusMessage;
    if (orderId != 0) doc["orderId"] = orderId;
    if (scannedId != 0) doc["scannedId"] = scannedId;
    if (confidence != 0) doc["confidence"] = confidence;

    String jsonResult;
    serializeJson(doc, jsonResult);
    pStatusCharacteristic->setValue(jsonResult.c_str());
    pStatusCharacteristic->notify();
    #ifdef DEBUG_MODE
      Serial.print("Sent BLE Status to Pi ("); Serial.print(messageType); Serial.print("): "); Serial.println(jsonResult);
    #endif
  } else {
    #ifdef DEBUG_MODE
      Serial.print("BLE Client not connected or characteristic not ready, cannot send status: "); Serial.println(statusMessage);
    #endif
  }
}


int getFingerprintID() {
  int result;
  int attempts = 0;
  while (attempts < MAX_ATTEMPTS) {
    result = finger.getImage();
    if (result == FINGERPRINT_OK) {
      #ifdef DEBUG_MODE
        Serial.println("Image taken");
      #endif
      break;
    }
    if (result == FINGERPRINT_NOFINGER) {
      delay(100);
      attempts++;
      continue;
    }
    #ifdef DEBUG_MODE
      Serial.print("Fingerprint getImage error: "); Serial.println(result);
    #endif
    return -1;
  }
  if (attempts >= MAX_ATTEMPTS) {
    #ifdef DEBUG_MODE
      Serial.println("Max attempts reached, no finger detected.");
    #endif
    return FINGERPRINT_NOFINGER;
  }

  result = finger.image2Tz();
  if (result != FINGERPRINT_OK) {
    #ifdef DEBUG_MODE
      Serial.print("Fingerprint image2Tz error: "); Serial.println(result);
    #endif
    return -1;
  }

  result = finger.fingerFastSearch();
  if (result == FINGERPRINT_OK) {
    #ifdef DEBUG_MODE
      Serial.print("Found ID #"); Serial.print(finger.fingerID);
      Serial.print(" with confidence of "); Serial.println(finger.confidence);
    #endif
    return finger.fingerID;
  }
  if (result == FINGERPRINT_NOMATCH) {
    #ifdef DEBUG_MODE
      Serial.println("No match found.");
    #endif
    return FINGERPRINT_NOMATCH;
  }

  #ifdef DEBUG_MODE
    Serial.print("Fingerprint fingerFastSearch error: "); Serial.println(result);
  #endif
  return -1;
}

bool enrollFingerprint(int id) {
  int result = -1;
  lcd.clear();
  lcd.print("Enroll ID:"); lcd.print(id);
  lcd.setCursor(0,1);
  lcd.print("Place Finger");
  #ifdef DEBUG_MODE
    Serial.println("Place finger for enrollment (1st scan)...");
  #endif
  unsigned long startTime = millis();
  while (result != FINGERPRINT_OK && (millis() - startTime < VERIFICATION_TIMEOUT)) { // Add timeout for enrollment scan
    result = finger.getImage();
    if (result != FINGERPRINT_NOFINGER) {
      #ifdef DEBUG_MODE
        Serial.print(".");
      #endif
    }
    delay(50);
  }
  if (result != FINGERPRINT_OK) { // If first scan failed or timed out
    #ifdef DEBUG_MODE
      Serial.println("\nFirst fingerprint scan failed or timed out.");
    #endif
    return false;
  }
  if (finger.image2Tz(1) != FINGERPRINT_OK) {
    #ifdef DEBUG_MODE
      Serial.println("First image to template conversion failed.");
    #endif
    return false;
  }

  lcd.clear();
  lcd.print("Remove Finger");
  #ifdef DEBUG_MODE
    Serial.println("Remove finger...");
  #endif
  delay(2000);

  lcd.clear();
  lcd.print("Place Again");
  #ifdef DEBUG_MODE
    Serial.println("Place same finger again (2nd scan)...");
  #endif
  result = -1;
  startTime = millis();
  while (result != FINGERPRINT_OK && (millis() - startTime < VERIFICATION_TIMEOUT)) { // Add timeout for enrollment scan
    result = finger.getImage();
    if (result != FINGERPRINT_NOFINGER) {
      #ifdef DEBUG_MODE
        Serial.print(".");
      #endif
    }
    delay(50);
  }
  if (result != FINGERPRINT_OK) { // If second scan failed or timed out
    #ifdef DEBUG_MODE
      Serial.println("\nSecond fingerprint scan failed or timed out.");
    #endif
    return false;
  }
  if (finger.image2Tz(2) != FINGERPRINT_OK) {
    #ifdef DEBUG_MODE
      Serial.println("Second image to template conversion failed.");
    #endif
    return false;
  }

  lcd.clear();
  lcd.print("Processing...");
  #ifdef DEBUG_MODE
    Serial.println("\nCreating model...");
  #endif
  if (finger.createModel() != FINGERPRINT_OK) {
    #ifdef DEBUG_MODE
      Serial.println("Create Model failed.");
    #endif
    return false;
  }

  lcd.clear();
  lcd.print("Storing...");
  #ifdef DEBUG_MODE
    Serial.print("Storing model ID "); Serial.print(id); Serial.println("...");
  #endif
  if (finger.storeModel(id) != FINGERPRINT_OK) {
    #ifdef DEBUG_MODE
      Serial.println("Store Model failed.");
    #endif
    return false;
  }
  #ifdef DEBUG_MODE
    Serial.println("Enrollment successful!");
  #endif
  return true;
}

// ======================= Functions that interact with Backend =======================

void enrollAndSend() {
  fingerprintId = 1; // Start searching for the next available ID from 1
  while (finger.loadModel(fingerprintId) == FINGERPRINT_OK) { // Find an empty ID slot
    fingerprintId++;
    if (fingerprintId > 127) { // Max IDs supported by R307 module
      lcd.clear();
      lcd.print("Storage full");
      #ifdef DEBUG_MODE
        Serial.println("Fingerprint storage is full!");
      #endif
      sendStatusToPi("ENROLL_STATUS", "Storage full. Enrollment failed.");
      return;
    }
  }

  lcd.clear();
  lcd.print("Place Finger");

  if (!enrollFingerprint(fingerprintId)) {
    lcd.clear();
    lcd.print("Enroll Failed");
    #ifdef DEBUG_MODE
      Serial.println("Fingerprint enrollment failed.");
    #endif
    sendStatusToPi("ENROLL_STATUS", "Fingerprint enrollment failed.");
    return;
  }

  lcd.clear();
  lcd.print("Sending Data...");
  #ifdef DEBUG_MODE
    Serial.println("Sending enrollment data to backend...");
  #endif

  HTTPClient http;
  http.begin(enrollUrl);
  http.addHeader("Content-Type", "application/json");
  http.addHeader("Authorization", "Bearer " + jwtToken); // Use JWT from Pi

  DynamicJsonDocument doc(256);
  doc["email"] = customerEmail;
  doc["cardID"] = cardID; // RFID from Pi
  doc["fingerprintID"] = String(fingerprintId);

  String json;
  serializeJson(doc, json);

  int httpCode = http.POST(json);
  String payload = http.getString();
  http.end();

  if (httpCode == 200) {
    lcd.clear();
    lcd.print("✅ Enrolled");
    #ifdef DEBUG_MODE
      Serial.println("Enrollment data sent to backend successfully.");
    #endif
    sendStatusToPi("ENROLL_STATUS", "Enrollment successful.", 0, fingerprintId); // Notify Pi
  } else {
    lcd.clear();
    lcd.print("Enroll Failed");
    #ifdef DEBUG_MODE
      Serial.print("Failed to send enrollment data, HTTP code: "); Serial.println(httpCode);
      Serial.println(payload);
    #endif
    sendStatusToPi("ENROLL_STATUS", "Failed to send to backend. HTTP Error.", 0, 0, httpCode); // Notify Pi
  }
  delay(3000);
  lcd.clear();
  lcd.print("Ready");
}

void sendVerificationResultToBackend(bool authenticated, int scannedId, int confidence) {
  HTTPClient http;
  http.setTimeout(HTTP_TIMEOUT);
  http.begin(String(baseVerifyUrl) + String(authEndpoint)); // Concatenate using String for URL
  http.addHeader("Content-Type", "application/json");
  http.addHeader("Authorization", "Bearer " + currentToken); // Use JWT from Pi

  DynamicJsonDocument doc(256);
  doc["authenticated"] = authenticated;
  doc["email"] = currentEmail;     // Email from Pi
  doc["confidence"] = confidence;
  doc["scannedId"] = scannedId;
  doc["orderId"] = currentOrderId; // Order ID from Pi
  doc["cardID"] = cardID;          // RFID from Pi - make sure it's updated when needed!

  String json;
  serializeJson(doc, json);
  #ifdef DEBUG_MODE
    Serial.print("Sending verification result to backend: "); Serial.println(json);
  #endif

  int httpCode = http.POST(json);
  String payload = http.getString();
  http.end();

  if (httpCode == 200) {
    #ifdef DEBUG_MODE
      Serial.println("Verification result sent to backend successfully.");
    #endif
    sendStatusToPi("VERIFICATION_BACKEND_ACK", "Backend received verification result.", currentOrderId);
    // Backend will eventually send payment status via Pi to ESP32 (PAYMENT_STATUS_UPDATE command)
  } else {
    #ifdef DEBUG_MODE
      Serial.print("Failed to send verification result to backend, HTTP code: "); Serial.println(httpCode);
      Serial.println(payload);
    #endif
    sendStatusToPi("VERIFICATION_BACKEND_ERROR", "Failed to send verification result to backend.", currentOrderId, 0, httpCode);
    // If backend communication fails, treat as payment failed immediately
    lcd.clear();
    lcd.print("Backend Comms");
    lcd.setCursor(0,1);
    lcd.print("Failed");
    tone(25, 200, 1000); // Error tone
    delay(3000);
    resetVerification();
    lcd.clear();
    lcd.print("Ready");
  }
}


bool ensureWiFiConnection() {
  if (WiFi.status() == WL_CONNECTED) return true;

  WiFi.disconnect(); // Disconnect before reconnecting
  #ifdef DEBUG_MODE
    Serial.println("Attempting to reconnect WiFi...");
  #endif
  lcd.clear();
  lcd.print("Reconnecting WiFi");
  WiFi.begin(ssid, password);
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) { // Increased attempts for robustness
    delay(500);
    #ifdef DEBUG_MODE
      Serial.print(".");
    #endif
    lcd.setCursor(0, 1);
    lcd.print("Attempts: "); lcd.print(attempts);
    attempts++;
  }
  if (WiFi.status() == WL_CONNECTED) {
    lcd.clear();
    lcd.print("WiFi Connected");
    lcd.setCursor(0, 1);
    lcd.print(WiFi.localIP());
    #ifdef DEBUG_MODE
      Serial.print("WiFi Reconnected. IP: "); Serial.println(WiFi.localIP());
    #endif
    delay(1000);
    return true;
  } else {
    lcd.clear();
    lcd.print("WiFi Failed");
    #ifdef DEBUG_MODE
      Serial.println("Failed to reconnect WiFi.");
    #endif
    tone(25, 200, 2000); // Long beep for WiFi failure
    delay(3000);
    return false;
  }
}

// ======================= Setup Function =======================
void setup() {
  Serial.begin(115200); // Initialize Serial communication for debugging
  lcd.init();           // Initialize LCD
  lcd.backlight();      // Turn on LCD backlight
  pinMode(25, OUTPUT);  // Set GPIO 25 as output for the buzzer
  lcd.print("Initializing...");
  #ifdef DEBUG_MODE
    Serial.println("Starting ESP32 Biometric system...");
  #endif

  // Initialize Fingerprint Sensor
  // mySerial.begin(baud_rate, config, rx_pin, tx_pin)
  mySerial.begin(57600, SERIAL_8N1, 16, 17); // GPIO16 RX, GPIO17 TX for fingerprint sensor
  finger.begin(57600); // Initialize fingerprint sensor communication
  delay(1000);

  if (finger.verifyPassword()) { // Check if sensor is connected and responsive
    lcd.clear();
    lcd.print("Sensor Ready");
    #ifdef DEBUG_MODE
      Serial.println("Fingerprint sensor found!");
    #endif
  } else {
    lcd.clear();
    lcd.print("Sensor Error");
    #ifdef DEBUG_MODE
      Serial.println("Did not find fingerprint sensor :(");
    #endif
    while (true) { // Halt if sensor not found, as it's critical
      delay(1000);
      #ifdef DEBUG_MODE
        Serial.println("Sensor not found, halting.");
      #endif
    }
  }
  delay(1000);

  // Connect to WiFi (needed for backend communication)
  lcd.clear();
  lcd.print("Connecting WiFi");
  if (!ensureWiFiConnection()) {
    lcd.clear();
    lcd.print("Fatal: No WiFi");
    #ifdef DEBUG_MODE
      Serial.println("Fatal: Could not connect to WiFi. Halting.");
    #endif
    while(true) delay(1000); // Halt if initial WiFi fails
  }

  // Set up BLE
  BLEDevice::init(DEVICE_NAME); // Initialize BLE with a device name
  pServer = BLEDevice::createServer(); // Create the BLE Server
  // Pass reference to lcd and function pointer to resetVerification to the server callbacks
  pServer->setCallbacks(new MyServerCallbacks(lcd, resetVerification));

  BLEService *pService = pServer->createService(SERVICE_UUID); // Create the BLE Service

  // Characteristic for receiving commands from Pi (Writes)
  pCommandCharacteristic = pService->createCharacteristic(
                          COMMAND_CHARACTERISTIC_UUID,
                          BLECharacteristic::PROPERTY_WRITE |
                          BLECharacteristic::PROPERTY_WRITE_NR // WRITE_NR for "write without response"
                        );
  // Pass all required global references and function pointers to MyCharacteristicCallbacks constructor
  pCommandCharacteristic->setCallbacks(new MyCharacteristicCallbacks(
      lcd, customerEmail, cardID, jwtToken, currentEmail,
      currentToken, currentOrderId, isVerifying, verificationStartTime,
      enrollAndSend, resetVerification // Function pointers
  ));

  // Characteristic for sending status back to Pi (Notifications)
  pStatusCharacteristic = pService->createCharacteristic(
                          STATUS_CHARACTERISTIC_UUID,
                          BLECharacteristic::PROPERTY_READ |
                          BLECharacteristic::PROPERTY_NOTIFY
                        );
  pStatusCharacteristic->addDescriptor(new BLE2902()); // Standard descriptor for notifications

  pService->start(); // Start the service

  // Start advertising so clients can find it
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID); // Advertise the service UUID
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);  // Helps with faster connections
  pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();
  #ifdef DEBUG_MODE
    Serial.println("BLE advertising started. Waiting for Pi to connect...");
  #endif
  lcd.clear();
  lcd.print("Ready (WiFi/BLE)");
}

// ======================= Loop Function =======================
void loop() {
  // Periodically check WiFi connection
  if (millis() - lastWifiCheck > WIFI_CHECK_INTERVAL) {
    if (!ensureWiFiConnection()) {
        // If WiFi fails, display error and potentially try to reset or alert
        lcd.clear();
        lcd.print("WiFi Down!");
        // Consider a more robust error handling, e.g., restarting ESP32
    }
    lastWifiCheck = millis();
  }

  // Check for verification timeout
  if (isVerifying && millis() - verificationStartTime > VERIFICATION_TIMEOUT) {
    lcd.clear();
    lcd.print("Verif Timeout");
    tone(25, 200, 1000); // Timeout tone
    delay(3000);
    resetVerification();
    lcd.clear();
    lcd.print("Ready");
    #ifdef DEBUG_MODE
      Serial.println("Verification timed out.");
    #endif
    sendStatusToPi("VERIFICATION_STATUS", "Timeout during fingerprint scan.", currentOrderId);
  }

  // Check for payment status timeout (if Pi hasn't sent back status after successful verification)
  if (waitingForPaymentStatus && millis() - paymentStatusTime > PAYMENT_STATUS_TIMEOUT) {
    lcd.clear();
    lcd.print("Pay Timeout");
    tone(25, 200, 1000); // Timeout tone
    delay(3000);
    resetVerification();
    lcd.clear();
    lcd.print("Ready");
    #ifdef DEBUG_MODE
      Serial.println("Waiting for payment status timed out.");
    #endif
    sendStatusToPi("PAYMENT_STATUS_FROM_PI", "Timeout waiting for payment status from Pi.", currentOrderId);
  }

  // If in verification mode, try to get a fingerprint
  if (isVerifying && millis() - verificationStartTime < VERIFICATION_TIMEOUT) {
    int fid = getFingerprintID();
    if (fid > 0 && finger.confidence >= MIN_CONFIDENCE) {
      // Fingerprint matched and confidence is good
      lcd.clear();
      lcd.print("Verified!");
      #ifdef DEBUG_MODE
        Serial.print("Fingerprint Verified! ID: "); Serial.print(fid); Serial.print(", Confidence: "); Serial.println(finger.confidence);
      #endif

      // Now send the combined data to the backend
      sendVerificationResultToBackend(true, fid, finger.confidence);

      waitingForPaymentStatus = true; // Now wait for payment status from Pi (which gets it from backend)
      paymentStatusTime = millis(); // Start payment status timeout
      isVerifying = false; // Stop active verification scanning
      delay(2000);
      lcd.clear();
      lcd.print("Waiting Pay...");
    } else if (fid == FINGERPRINT_NOMATCH) {
      // No match found for the fingerprint
      #ifdef DEBUG_MODE
        Serial.println("No fingerprint match found.");
      #endif
      lcd.clear();
      lcd.print("No Match");
      tone(25, 500, 200); // Short beep for no match
      delay(1500);
      lcd.clear();
      lcd.print("Place Finger");
      lcd.setCursor(0, 1);
      lcd.print("to Verify");
      // ESP32 continues to scan until timeout or match
    } else if (fid == FINGERPRINT_NOFINGER) {
        // No finger detected, just continue loop
    } else { // Any other error from getFingerprintID
      lcd.clear();
      lcd.print("Scan Error");
      tone(25, 200, 500); // Error tone
      delay(2000);
      lcd.clear();
      lcd.print("Place Finger");
      lcd.setCursor(0, 1);
      lcd.print("to Verify");
      #ifdef DEBUG_MODE
        Serial.print("Fingerprint scan error, result: "); Serial.println(fid);
      #endif
      sendStatusToPi("VERIFICATION_STATUS", "Fingerprint scan error.", currentOrderId, fid);
    }
  }
  delay(10); // Small delay to prevent busy loop, allows BLE and other tasks to run
}