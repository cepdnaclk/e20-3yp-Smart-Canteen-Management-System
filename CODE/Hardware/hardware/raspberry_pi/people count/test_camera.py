import cv2
cap = cv2.VideoCapture(0, cv2.CAP_V4L2)
if not cap.isOpened():
    print("Error: Could not open camera.")
else:
    ret, frame = cap.read()
    if ret:
        cv2.imwrite("test_image.jpg", frame)
        print("Camera test successful!")
    else:
        print("Failed to grab frame")
cap.release()
