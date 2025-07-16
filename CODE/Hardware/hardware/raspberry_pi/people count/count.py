import cv2
import requests
import time
import os

# Java backend API endpoint
upload_url = "http://100.86.40.55:8081/api/upload"

def capture_and_upload():
    cap = cv2.VideoCapture(0)

    if not cap.isOpened():
        print("Error: Cannot access the camera.")
        return

    try:
        while True:
            ret, frame = cap.read()
            if not ret:
                print("Error: Failed to capture image.")
                break

            filename = "captured.jpg"
            cv2.imwrite(filename, frame)

            with open(filename, 'rb') as image_file:
                files = {'image': image_file}
                try:
                    response = requests.post(upload_url, files=files)
                    print("Response:", response.status_code, response.text)
                except requests.exceptions.RequestException as e:
                    print("Request failed:", e)

            time.sleep(15)

    finally:
        cap.release()
        cv2.destroyAllWindows()

if __name__ == "__main__":
    capture_and_upload()
