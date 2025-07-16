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
const char* enrollUrl = "http://13.229.83.22:8081/api/merchant/update-biometrics-data";
const char* baseVerifyUrl = "http://13.229.83.22:8081";
const String authEndpoint = "/api/biometric/confirm";

// Web server
WebServer server(80);

// Hardware setup
// Using HardwareSerial for the fingerprint sensor for better reliability
HardwareSerial mySerial(1); // GPIO16 RX (ESP32), GPIO17 TX (ESP32)
Adafruit_Fingerprint finger(&mySerial); // Pass the HardwareSerial object to the fingerprint library
LiquidCrystal_I2C lcd(0x27, 16, 2); // I2C address 0x27, 16 columns, 2 rows

// Enrollment variables
String customerEmail = "";
String cardID = "";
String jwtToken = "";
int fingerprintId = 1; // Starting ID for new fingerprints

// Verification variables
String currentEmail = "";
String currentToken = "";
long currentOrderId = 0;
bool isVerifying = false; // Flag to indicate if biometric verification is in progress
unsigned long verificationStartTime = 0; // Timestamp when verification started

// Constants for timeouts and thresholds
const unsigned long VERIFICATION_TIMEOUT = 90000; // 90 seconds for overall verification process
const unsigned long WIFI_CHECK_INTERVAL = 30000; // Check WiFi connection every 30 seconds
const int MIN_CONFIDENCE = 50; // Minimum confidence level for a successful fingerprint match
const int MAX_ATTEMPTS = 200; // Maximum attempts to get an image from the sensor (for getFingerprintID)
const int HTTP_RETRIES = 3; // Number of retries for HTTP requests (not fully implemented in all functions)
const int HTTP_TIMEOUT = 5000; // HTTP request timeout in milliseconds

unsigned long lastWifiCheck = 0; // Timestamp of the last WiFi check

// Forward declarations of functions
void sendVerificationResult(bool authenticated);
void resetVerification();
bool ensureWiFiConnection();
int getFingerprintID();
bool enrollFingerprint(int id);
void enrollAndSend();
void handleCapture();
void handleVerify();
void handlePaymentStatus(); // This handler is effectively unused in the current flow but kept for compilation

/**
 * @brief Initializes the ESP32, LCD, fingerprint sensor, and WiFi.
 * Sets up the web server routes.
 */
void setup() {
  Serial.begin(115200); // Start serial communication for debugging
  lcd.init();           // Initialize the LCD
  lcd.backlight();      // Turn on LCD backlight
  pinMode(25, OUTPUT);  // Set GPIO25 as output for the buzzer
  lcd.print("Initializing..."); // Initial message on LCD

  // Initialize HardwareSerial for the fingerprint sensor
  mySerial.begin(57600, SERIAL_8N1, 16, 17); // Baud rate, data bits, parity, stop bits, RX, TX pins
  finger.begin(57600); // Initialize the fingerprint sensor with its baud rate
  delay(1000); // Give sensor time to initialize

  // Verify connection to the fingerprint sensor
  if (finger.verifyPassword()) {
    lcd.clear();
    lcd.print("Sensor Ready");
  } else {
    lcd.clear();
    lcd.print("Sensor Error");
    Serial.println("Fingerprint sensor not found or password incorrect.");
    while (true) delay(1000); // Halt if sensor not found
  }

  // Connect to WiFi
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
  lcd.print(WiFi.localIP()); // Display ESP32's IP address
  delay(1000);

  // Setup web server routes
  server.on("/capture", HTTP_POST, handleCapture); // Route for fingerprint enrollment
  server.on("/verify", HTTP_POST, handleVerify);   // Route for fingerprint verification initiation
  server.on("/paymentStatus", HTTP_POST, handlePaymentStatus); // Route for payment status (now largely unused)
  server.onNotFound([]() { // Handle undefined routes
    server.send(404, "text/plain", "Not found");
  });

  server.begin(); // Start the web server
  lcd.clear();
  lcd.print("Welcome to smart canteen"); // Ready message
}

/**
 * @brief Main loop of the program.
 * Handles web server clients, checks WiFi, and manages the biometric verification flow.
 */
void loop() {
  server.handleClient(); // Process incoming HTTP requests
  
  // Periodically check and ensure WiFi connection
  if (millis() - lastWifiCheck > WIFI_CHECK_INTERVAL) {
    ensureWiFiConnection();
    lastWifiCheck = millis();
  }

  // Biometric verification logic
  if (isVerifying && millis() - verificationStartTime < VERIFICATION_TIMEOUT) {
    int fid = getFingerprintID(); // Attempt to get a fingerprint ID
    // If a finger is found (fid > 0) and confidence is sufficient
    if (fid > 0 && finger.confidence >= MIN_CONFIDENCE) {
      lcd.clear();
      lcd.print("Finger Found!");
      lcd.setCursor(0, 1);
      lcd.print("Sending Data...");
      tone(25, 800, 100); // Short success beep
      delay(1000); // Give time to read "Finger Found!" before sending
      sendVerificationResult(true); // Send successful verification result to backend
      // isVerifying will be set to false inside sendVerificationResult after processing response
    } else if (fid == -1) { // If getFingerprintID returned -1 (critical error or timeout)
        // getFingerprintID already handles LCD messages for errors/timeouts
        // Just ensure isVerifying is reset if an unrecoverable error occurred during scan attempt
        resetVerification();
        lcd.clear();
        lcd.print("Scan Failed");
        lcd.setCursor(0,1);
        lcd.print("Retrying...");
        delay(2000);
        lcd.clear();
        lcd.print("Welcome to smart canteen");
    }
    // If fid is 0 (no match found but scan was successful), getFingerprintID handles it
    // and the loop continues, allowing more attempts within the timeout.
  } else if (isVerifying && millis() - verificationStartTime >= VERIFICATION_TIMEOUT) {
    // Overall verification process timed out
    lcd.clear();
    lcd.print("Verification Timeout");
    tone(25, 200, 1000); // Long tone for timeout
    delay(3000);
    resetVerification(); // Reset state
    lcd.clear();
    lcd.print("Welcome to smart canteen"); // Return to idle message
  }
}

/**
 * @brief Handles HTTP POST requests to the /capture endpoint for enrollment.
 * Expects JSON payload with email, rfid, and token.
 */
void handleCapture() {
  if (!server.hasArg("plain")) {
    server.send(400, "text/plain", "Missing body");
    return;
  }

  DynamicJsonDocument doc(256); // Create a JSON document to parse the request body
  DeserializationError error = deserializeJson(doc, server.arg("plain"));

  if (error) {
    Serial.print(F("deserializeJson() failed: "));
    Serial.println(error.f_str());
    server.send(400, "text/plain", "Invalid JSON payload");
    return;
  }

  // Extract data from JSON payload
  customerEmail = doc["email"].as<String>();
  cardID = doc["rfid"].as<String>();
  jwtToken = doc["token"].as<String>();

  enrollAndSend(); // Start the enrollment process
  server.send(200, "text/plain", "Enrollment started"); // Send immediate response
}

/**
 * @brief Manages the fingerprint enrollment process and sends data to the backend.
 * Finds a free ID, prompts for fingerprint, enrolls, and then sends the enrollment data.
 */
void enrollAndSend() {
  fingerprintId = 1;
  // Find the next available fingerprint ID in the sensor's storage
  while (finger.loadModel(fingerprintId) == FINGERPRINT_OK) {
    fingerprintId++;
    if (fingerprintId > 127) { // Max 127 fingerprints for this sensor
      lcd.clear();
      lcd.print("Storage full");
      Serial.println("Fingerprint sensor storage is full.");
      return;
    }
  }

  // Start the enrollment process on the sensor
  if (!enrollFingerprint(fingerprintId)) {
    lcd.clear();
    lcd.print("Enroll Failed");
    tone(25, 200, 500); // Tone for failure
    delay(3000);
    lcd.clear();
    lcd.print("Ready"); // Return to idle state
    return;
  }

  // If enrollment on sensor is successful, send data to backend
  lcd.clear();
  lcd.print("Sending Data...");
  HTTPClient http;
  http.begin(enrollUrl);
  http.addHeader("Content-Type", "application/json");
  http.addHeader("Authorization", "Bearer " + jwtToken); // Add JWT token for authorization

  DynamicJsonDocument doc(256); // Create JSON payload for backend
  doc["email"] = customerEmail;
  doc["cardID"] = cardID;
  doc["fingerprintID"] = String(fingerprintId); // Send the assigned fingerprint ID

  String json;
  serializeJson(doc, json); // Serialize JSON document to string

  Serial.print("Enrollment Payload: ");
  Serial.println(json);

  int httpCode = http.POST(json); // Send POST request
  String payload = http.getString(); // Get response payload
  http.end(); // Close HTTP connection

  if (httpCode == HTTP_CODE_OK) { // Check if the backend request was successful
    lcd.clear();
    lcd.print("✅ Enrolled");
    tone(25, 1000, 200); // Success tone
  } else {
    lcd.clear();
    lcd.print("Enrollment Failed");
    lcd.setCursor(0, 1);
    lcd.print("HTTP Error: " + String(httpCode));
    Serial.println("Enrollment HTTP Error: " + String(httpCode));
    Serial.println("Response: " + payload);
    tone(25, 200, 500); // Tone for failure
  }
  delay(3000); // Display message for 3 seconds
  lcd.clear();
  lcd.print("Ready"); // Return to idle state
}

/**
 * @brief Guides the user through the fingerprint enrollment process (2 scans).
 * @param id The ID to store the fingerprint template under.
 * @return true if enrollment is successful, false otherwise.
 */
bool enrollFingerprint(int id) {
  int result = -1;
  lcd.clear();
  lcd.print("Place Finger");
  lcd.setCursor(0, 1);
  lcd.print("for Enroll (1/2)"); // Clear instruction for first scan

  // First image capture
  while (result != FINGERPRINT_OK) {
    result = finger.getImage();
    if (result == FINGERPRINT_OK) {
      break; // Image captured successfully
    } else if (result == FINGERPRINT_NOFINGER) {
      delay(500); // Increased delay to give user time to place finger
    } else {
      // Any other unexpected error during image capture
      Serial.print("Enroll image #1 capture error (unexpected): ");
      Serial.println(result);
      lcd.clear();
      lcd.print("Capture Error!");
      lcd.setCursor(0, 1);
      lcd.print("Code: " + String(result));
      tone(25, 200, 500); // Error tone
      delay(2000);
      return false; // Exit enrollment on critical error
    }
  }
  if (finger.image2Tz(1) != FINGERPRINT_OK) {
    Serial.println("Enroll image #1 to TZ conversion failed.");
    lcd.clear();
    lcd.print("Process Error");
    delay(2000);
    return false;
  }

  lcd.clear();
  lcd.print("Remove Finger");
  delay(2000); // Give user time to remove finger
  lcd.clear();
  lcd.print("Place Finger");
  lcd.setCursor(0, 1);
  lcd.print("Again (2/2)"); // Clear instruction for second scan

  // Second image capture
  result = -1;
  while (result != FINGERPRINT_OK) {
    result = finger.getImage();
    if (result == FINGERPRINT_OK) {
      break;
    } else if (result == FINGERPRINT_NOFINGER) {
      delay(500); // Increased delay to give user time to place finger
    } else {
      Serial.print("Enroll image #2 capture error (unexpected): ");
      Serial.println(result);
      lcd.clear();
      lcd.print("Capture Error!");
      lcd.setCursor(0, 1);
      lcd.print("Code: " + String(result));
      tone(25, 200, 500);
      delay(2000);
      return false;
    }
  }
  if (finger.image2Tz(2) != FINGERPRINT_OK) {
    Serial.println("Enroll image #2 to TZ conversion failed.");
    lcd.clear();
    lcd.print("Process Error");
    delay(2000);
    return false;
  }

  // Create model from two images
  lcd.clear();
  lcd.print("Creating Model...");
  if (finger.createModel() != FINGERPRINT_OK) {
    Serial.println("Create model failed.");
    lcd.clear();
    lcd.print("Model Failed");
    delay(2000);
    return false;
  }

  // Store model in sensor's flash memory
  lcd.clear();
  lcd.print("Storing Model...");
  if (finger.storeModel(id) != FINGERPRINT_OK) {
    Serial.println("Store model failed.");
    lcd.clear();
    lcd.print("Store Failed");
    delay(2000);
    return false;
  }
  Serial.println("Enrolled successfully.");
  return true;
}

/**
 * @brief Handles HTTP POST requests to the /verify endpoint.
 * Initiates the biometric verification process.
 * Expects JSON payload with email and orderId, and an Authorization header.
 */
void handleVerify() {
  if (!server.hasArg("plain")) {
    server.send(400, "text/plain", "Missing request body");
    return;
  }

  DynamicJsonDocument doc(512); // Increased size for potentially larger JSON
  DeserializationError error = deserializeJson(doc, server.arg("plain"));

  if (error) {
    Serial.print(F("deserializeJson() failed: "));
    Serial.println(error.f_str());
    server.send(400, "text/plain", "Invalid JSON");
    return;
  }

  // Extract JWT token from Authorization header
  if (server.hasHeader("Authorization")) {
    currentToken = server.header("Authorization").substring(7); // "Bearer " is 7 chars
  } else {
    server.send(401, "text/plain", "Missing Authorization token");
    return;
  }

  // Extract email and orderId from JSON payload
  currentEmail = doc["email"].as<String>();
  currentOrderId = doc["orderId"].as<long>();
  isVerifying = true; // Set verification flag
  verificationStartTime = millis(); // Record start time for timeout

  lcd.clear();
  lcd.print("Place Finger");
  lcd.setCursor(0, 1);
  lcd.print("to Verify"); // Prompt user for verification scan
  server.send(200, "text/plain", "Verification initiated. Waiting for fingerprint.");
}

/**
 * @brief This function is largely unused in the current flow.
 * It would be triggered if the backend sent a separate payment status update.
 * The payment status is now read directly from the /biometric/confirm response.
 */
void handlePaymentStatus() {
  // This block will theoretically never be reached if the backend is not
  // sending a separate POST to /paymentStatus.
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

/**
 * @brief Attempts to get a fingerprint image and match it against stored templates.
 * @return The matched fingerprint ID (1-127) if successful, 0 if no match, -1 on critical error or timeout.
 */
int getFingerprintID() {
  int result;
  int attempts = 0;
  // LCD messages are set in handleVerify() before calling this, but can be updated here for clarity during scanning.
  // lcd.clear();
  // lcd.print("Place Finger");
  // lcd.setCursor(0, 1);
  // lcd.print("to Verify");

  while (attempts < MAX_ATTEMPTS) {
    result = finger.getImage(); // Try to capture an image
    if (result == FINGERPRINT_OK) {
      break; // Image captured successfully, exit loop
    } else if (result == FINGERPRINT_NOFINGER) {
      delay(500); // Increased delay to give user time to place finger
      attempts++;
    } else {
      // This block handles any other actual error code from getImage()
      Serial.print("Get image error (unexpected): ");
      Serial.println(result);
      lcd.clear();
      lcd.print("Scan Error!");
      lcd.setCursor(0, 1);
      lcd.print("Code: " + String(result));
      tone(25, 200, 500); // Error tone
      delay(2000);
      return -1; // Exit on critical error during image capture
    }
  }

  if (attempts >= MAX_ATTEMPTS) {
    Serial.println("Max attempts reached for finger placement.");
    lcd.clear();
    lcd.print("Scan Timeout!");
    tone(25, 200, 1000); // Timeout tone
    delay(3000);
    return -1; // Indicate timeout
  }
  
  // Convert image to template
  if (finger.image2Tz() != FINGERPRINT_OK) {
    Serial.println("Image to TZ conversion failed.");
    lcd.clear();
    lcd.print("Process Error");
    delay(2000);
    return -1;
  }
  
  // Search for the template in the sensor's database
  if (finger.fingerFastSearch() != FINGERPRINT_OK) {
    Serial.println("Fingerprint search failed (no match or error).");
    // If no match is found, finger.fingerID will be 0 and confidence will be low.
    // This is not a critical error, just no match.
    lcd.clear();
    lcd.print("No Match Found");
    delay(2000);
    // Return 0 to indicate no match, allowing the loop in `loop()` to continue for more attempts.
    return 0; 
  }
  
  // Fingerprint matched
  Serial.print("Matched ID: ");
  Serial.print(finger.fingerID);
  Serial.print(" Confidence: ");
  Serial.println(finger.confidence);
  return finger.fingerID; // Return the matched ID
}

/**
 * @brief Sends the biometric verification result to the backend.
 * Handles the HTTP request and processes the backend's response for payment status.
 * @param authenticated True if fingerprint was successfully matched, false otherwise.
 */
void sendVerificationResult(bool authenticated) {
  HTTPClient http;
  http.setTimeout(HTTP_TIMEOUT);
  String fullUrl = baseVerifyUrl + authEndpoint;
  Serial.print("Sending result to: ");
  Serial.println(fullUrl);
  http.begin(fullUrl);
  http.addHeader("Content-Type", "application/json");
  http.addHeader("Authorization", "Bearer " + currentToken); // Use the token received from UI Client

  DynamicJsonDocument doc(256); // Create JSON payload for backend
  doc["authenticated"] = authenticated;
  doc["email"] = currentEmail;
  doc["confidence"] = finger.confidence; // Send confidence level
  doc["scannedId"] = finger.fingerID;     // Send matched ID (0 if no match)
  doc["orderId"] = currentOrderId;        // Send the order ID

  String json;
  serializeJson(doc, json); // Serialize JSON document to string
  Serial.print("Payload: ");
  Serial.println(json);

  int httpCode = http.POST(json); // Send POST request
  String payload = http.getString(); // Get response payload
  Serial.print("Response code: ");
  Serial.println(httpCode);
  Serial.print("Response: ");
  Serial.println(payload);

  lcd.clear(); // Clear LCD before displaying response
  if (httpCode == HTTP_CODE_OK) {
    DynamicJsonDocument responseDoc(512); // Increased size for response JSON
    DeserializationError error = deserializeJson(responseDoc, payload);

    if (!error) {
      String orderStatus = responseDoc["orderStatus"].as<String>();
      if (orderStatus == "COMPLETED") {
        lcd.print("Payment Success ✅");
        tone(25, 1000, 300); // Success tone
      } else if (orderStatus == "FAILED" || orderStatus == "PENDING" || orderStatus == "CANCELED") {
        // Handle various failure/non-completed statuses from backend
        lcd.print("Payment Failed ❌");
        tone(25, 200, 1000); // Failure tone
      } else {
        lcd.print("Unknown Status ❓");
        lcd.setCursor(0, 1);
        lcd.print(orderStatus);
        tone(25, 500, 500); // General notification tone
      }
    } else {
      Serial.print(F("deserializeJson() failed on response: "));
      Serial.println(error.f_str());
      lcd.print("Server Error ⚠️");
      lcd.setCursor(0, 1);
      lcd.print("Bad Response");
      tone(25, 200, 1000); // Error tone
    }
  } else {
    // HTTP request itself failed or returned a non-200 status
    lcd.print("Server Error ⚠️");
    lcd.setCursor(0, 1);
    lcd.print("HTTP " + String(httpCode));
    tone(25, 200, 1000); // Error tone
  }

  http.end(); // Close HTTP connection
  delay(3000); // Display message for 3 seconds
  resetVerification(); // Reset state for next operation
  lcd.clear();
  lcd.print("Ready"); // Return to idle message
}

/**
 * @brief Resets all global variables related to biometric verification.
 * Prepares the system for a new transaction.
 */
void resetVerification() {
  currentEmail = "";
  currentToken = "";
  currentOrderId = 0;
  isVerifying = false;
}

/**
 * @brief Ensures the WiFi connection is active. Reconnects if necessary.
 * @return true if WiFi is connected, false otherwise.
 */
bool ensureWiFiConnection() {
  if (WiFi.status() == WL_CONNECTED) return true;
  Serial.println("Reconnecting WiFi...");
  lcd.clear();
  lcd.print("Reconnecting WiFi");
  WiFi.disconnect(); // Disconnect before reconnecting for a clean start
  WiFi.begin(ssid, password);
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) { // Max 20 attempts (10 seconds)
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
    lcd.print("WiFi Failed! ❌");
    delay(3000);
    return false;
  }
}