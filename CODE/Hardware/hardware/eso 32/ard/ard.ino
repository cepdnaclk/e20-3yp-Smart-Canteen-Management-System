#include <Adafruit_Fingerprint.h>
#include <SoftwareSerial.h>

// Connect sensor TX to Arduino pin 2, RX to pin 3
SoftwareSerial mySerial(2, 3); // RX, TX
Adafruit_Fingerprint finger(&mySerial);

void setup() {
  mySerial.begin(9600);
  finger.begin(9600);
      // For fingerprint sensor

  Serial.println("Looking for fingerprint sensor...");

  finger.begin(57600);
  if (finger.verifyPassword()) {
    Serial.println("✅ Fingerprint sensor found!");
  } else {
    Serial.println("❌ Fingerprint sensor not found :(");
    while (1); // Stop here
  }
}

void loop() {
  Serial.println("Place your finger on the sensor...");
  while (finger.getImage() != FINGERPRINT_OK);

  Serial.println("Image taken");

  if (finger.image2Tz() != FINGERPRINT_OK) {
    Serial.println("❌ Couldn't convert image");
    return;
  }

  int result = finger.fingerSearch();
  if (result == FINGERPRINT_OK) {
    Serial.println("✅ Fingerprint matched!");
    Serial.print("ID: "); Serial.println(finger.fingerID);
  } else {
    Serial.println("❌ No match found");
  }

  delay(2000);
}
