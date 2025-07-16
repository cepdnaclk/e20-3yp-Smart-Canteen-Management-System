#include <WiFi.h>
#include <HTTPClient.h>
#include <Adafruit_Fingerprint.h>
#include <HardwareSerial.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>

const char* ssid = "Dialog 4G 140";
const char* password = "pathum27980";

const char* serverUrl = "http://<PI_IP>:<PORT>/api/fingerprint/register";

HardwareSerial mySerial(1);  // Use UART1 for RX=16, TX=17
Adafruit_Fingerprint finger = Adafruit_Fingerprint(&mySerial);

LiquidCrystal_I2C lcd(0x27, 16, 2);

void connectToWiFi() {
  lcd.clear();
  lcd.print("Connecting WiFi");
  Serial.print("Connecting to WiFi...");
  WiFi.begin(ssid, password);
  int dots = 0;
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
    lcd.setCursor(dots++, 1);
    lcd.print(".");
    if (dots > 15) dots = 0;
  }
  Serial.println(" connected");
  lcd.clear();
  lcd.print("WiFi Connected");
  delay(1000);
  lcd.clear();
}

void setup() {
  Serial.begin(115200);
  mySerial.begin(57600, SERIAL_8N1, 16, 17);  // RX=16, TX=17
  delay(1000);

  lcd.init();
  lcd.backlight();
  lcd.print("Initializing...");

  connectToWiFi();

  finger.begin(57600);
  if (finger.verifyPassword()) {
    lcd.clear();
    lcd.print("Fingerprint OK");
    Serial.println("Fingerprint sensor found!");
  } else {
    lcd.clear();
    lcd.print("Sensor not found");
    Serial.println("Fingerprint sensor not found :(");
    while (1) { delay(1); }
  }
  delay(1000);
  lcd.clear();
}

uint16_t getAvailableFingerprintId() {
  for (int id = 1; id < 1000; id++) {
    if (finger.loadModel(id) != FINGERPRINT_OK) {
      return id;
    }
  }
  return 1000;
}

bool enrollFingerprint(uint16_t id) {
  lcd.clear();
  lcd.print("ID: ");
  lcd.print(id);
  lcd.setCursor(0, 1);
  lcd.print("Place finger");

  Serial.print("Enrolling fingerprint with ID: ");
  Serial.println(id);

  while (finger.getImage() != FINGERPRINT_OK) {
    delay(100);
  }
  if (finger.image2Tz(1) != FINGERPRINT_OK) {
    lcd.clear();
    lcd.print("Image 1 failed");
    return false;
  }

  lcd.clear();
  lcd.print("Remove finger");
  delay(2000);

  lcd.clear();
  lcd.print("Place again");

  while (finger.getImage() != FINGERPRINT_OK) {
    delay(100);
  }
  if (finger.image2Tz(2) != FINGERPRINT_OK) {
    lcd.clear();
    lcd.print("Image 2 failed");
    return false;
  }

  if (finger.createModel() != FINGERPRINT_OK) {
    lcd.clear();
    lcd.print("No match");
    return false;
  }
  if (finger.storeModel(id) != FINGERPRINT_OK) {
    lcd.clear();
    lcd.print("Store failed");
    return false;
  }

  lcd.clear();
  lcd.print("Enroll success");
  delay(1500);
  lcd.clear();

  Serial.println("Fingerprint enrolled successfully");
  return true;
}

void sendToPi(uint16_t fingerprintId) {
  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    http.begin(serverUrl);
    http.addHeader("Content-Type", "application/json");

    String json = "{\"fingerprintId\":\"" + String(fingerprintId) + "\"}";

    int httpResponseCode = http.POST(json);
    Serial.print("Response: ");
    Serial.println(httpResponseCode);

    lcd.clear();
    lcd.print("Sent to Server");
    lcd.setCursor(0, 1);
    lcd.print("Resp: ");
    lcd.print(httpResponseCode);
    delay(2000);
    lcd.clear();

    http.end();
  } else {
    Serial.println("WiFi not connected!");
    lcd.clear();
    lcd.print("WiFi NOT Conn.");
    delay(2000);
    lcd.clear();
  }
}

void loop() {
  uint16_t id = getAvailableFingerprintId();
  if (enrollFingerprint(id)) {
    sendToPi(id);
  } else {
    lcd.clear();
    lcd.print("Enroll failed");
    delay(2000);
    lcd.clear();
  }
  delay(10000);
}
