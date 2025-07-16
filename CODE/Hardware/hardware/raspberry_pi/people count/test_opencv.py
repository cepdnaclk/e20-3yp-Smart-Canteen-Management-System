import cv2
import numpy as np

# Initialize camera with reduced resolution
cap = cv2.VideoCapture(0)
cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)

# Initialize background subtractor with optimized parameters
fgbg = cv2.createBackgroundSubtractorMOG2(
    history=100,
    varThreshold=100,
    detectShadows=False  # Disable shadow detection for better performance
)

# Morphological kernel for noise removal
kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (3, 3))

# Counting parameters
min_area = 1500  # Minimum contour area to consider as a person
people_count = 0

try:
    while True:
        ret, frame = cap.read()
        if not ret:
            print("Failed to grab frame")
            break
        
        # Resize frame for faster processing
        frame = cv2.resize(frame, (320, 240))
        
        # Apply background subtraction
        fgmask = fgbg.apply(frame)
        
        # Apply morphological operations to reduce noise
        fgmask = cv2.morphologyEx(fgmask, cv2.MORPH_OPEN, kernel)
        fgmask = cv2.morphologyEx(fgmask, cv2.MORPH_CLOSE, kernel, iterations=2)
        
        # Find contours
        contours, _ = cv2.findContours(fgmask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        
        current_count = 0  # Reset count for this frame
        
        for contour in contours:
            area = cv2.contourArea(contour)
            if area > min_area:
                current_count += 1
                # Draw bounding box
                x, y, w, h = cv2.boundingRect(contour)
                cv2.rectangle(frame, (x, y), (x+w, y+h), (0, 255, 0), 2)
        
        # Update people count with current frame's count
        people_count = current_count
        
        # Display count
        cv2.putText(frame, f"People: {people_count}", (10, 30), 
                   cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 255), 2)
        
        # Show frame
        cv2.imshow("People Counter", frame)
        
        # Exit on 'q' press
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

except KeyboardInterrupt:
    print("Program stopped by user")

finally:
    cap.release()
    cv2.destroyAllWindows()
