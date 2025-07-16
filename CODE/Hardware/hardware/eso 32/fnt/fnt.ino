#include <Adafruit_Fingerprint.h>
#include <HardwareSerial.h>

// Change pins if needed
HardwareSerial mySerial(1); // Use UART1 for ESP32: pins 16 (RX), 17 (TX) default
Adafruit_Fingerprint finger(&mySerial);

String readLine() {
  String input = "";
  while (true) {
    if (Serial.available() > 0) {
      char c = Serial.read();
      if (c == '\n' || c == '\r') {
        if (input.length() > 0) break; // end of line
      } else {
        input += c;
      }
    }
  }
  return input;
}

void setup() {
  Serial.begin(115200);
  while (!Serial); // wait for Serial

  Serial.println("\n\n🔓 Fingerprint sensor example");

  mySerial.begin(57600, SERIAL_8N1, 16, 17); // RX, TX pins for ESP32, change if needed

  finger.begin(57600);
  if (finger.verifyPassword()) {
    Serial.println("✅ Found fingerprint sensor!");
  } else {
    Serial.println("🚫 Could not find fingerprint sensor :(");
    while (1) delay(1);
  }
}

void loop() {
  Serial.println("\nType 'e' to enroll a fingerprint");
  Serial.println("Type 's' to search fingerprint");
  Serial.println("Type 'd' to delete fingerprint");
  Serial.println("Type 'q' to quit");

  String cmd = readLine();
  cmd.trim();

  if (cmd == "e") {
    enrollFingerprint();
  } else if (cmd == "s") {
    searchFingerprint();
  } else if (cmd == "d") {
    deleteFingerprint();
  } else if (cmd == "q") {
    Serial.println("Exiting...");
    while (true) delay(1000);
  } else {
    Serial.println("Unknown command, try again.");
  }
}

void enrollFingerprint() {
  Serial.println("Enter ID to enroll (1-127): ");
  while (true) {
    String idStr = readLine();
    idStr.trim();
    int id = idStr.toInt();
    if (id >= 1 && id <= 127) {
      Serial.print("Enrolling ID #");
      Serial.println(id);
      enrollAtID(id);
      break;
    } else {
      Serial.println("Invalid ID, please enter a number between 1 and 127:");
    }
  }
}

void enrollAtID(int id) {
  int p = -1;

  Serial.println("👉 Place your finger on the sensor...");
  while ((p = finger.getImage()) != FINGERPRINT_OK) {
    if (p == FINGERPRINT_NOFINGER) continue;
    Serial.println("Error capturing image");
    return;
  }

  p = finger.image2Tz(1);
  if (p != FINGERPRINT_OK) {
    Serial.println("🚫 Could not convert image");
    return;
  }

  Serial.println("👍 Remove your finger");
  delay(2000);
  while (finger.getImage() != FINGERPRINT_NOFINGER);

  Serial.println("👉 Place the same finger again...");
  while ((p = finger.getImage()) != FINGERPRINT_OK) {
    if (p == FINGERPRINT_NOFINGER) continue;
    Serial.println("Error capturing second image");
    return;
  }

  p = finger.image2Tz(2);
  if (p != FINGERPRINT_OK) {
    Serial.println("🚫 Could not convert second image");
    return;
  }

  p = finger.createModel();
  if (p != FINGERPRINT_OK) {
    Serial.println("🚫 Could not create fingerprint model");
    return;
  }

  p = finger.storeModel(id);
  if (p == FINGERPRINT_OK) {
    Serial.print("✅ Enrolled successfully to ID #");
    Serial.println(id);
  } else {
    Serial.println("🚫 Failed to store the fingerprint model");
  }
}

void searchFingerprint() {
  Serial.println("👉 Place your finger to search...");
  int p = -1;

  while ((p = finger.getImage()) != FINGERPRINT_OK) {
    if (p == FINGERPRINT_NOFINGER) continue;
    Serial.println("Error capturing image");
    return;
  }

  p = finger.image2Tz();
  if (p != FINGERPRINT_OK) {
    Serial.println("🚫 Could not convert image");
    return;
  }

  p = finger.fingerSearch();
  if (p == FINGERPRINT_OK) {
    Serial.println("✅ Found a match!");
    Serial.print("Fingerprint ID: ");
    Serial.println(finger.fingerID);
    Serial.print("Confidence: ");
    Serial.println(finger.confidence);
  } else {
    Serial.println("❌ No match found.");
  }
}

void deleteFingerprint() {
  Serial.println("Enter ID to delete (1-127): ");
  while (true) {
    String idStr = readLine();
    idStr.trim();
    int id = idStr.toInt();
    if (id >= 1 && id <= 127) {
      Serial.print("Deleting fingerprint ID #");
      Serial.println(id);
      int p = finger.deleteModel(id);
      if (p == FINGERPRINT_OK) {
        Serial.println("✅ Deleted successfully.");
      } else {
        Serial.println("🚫 Failed to delete fingerprint.");
      }
      break;
    } else {
      Serial.println("Invalid ID, please enter a number between 1 and 127:");
    }
  }
}
