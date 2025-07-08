from fastapi import FastAPI, File, UploadFile
import torch
import cv2
import numpy as np

app = FastAPI()
model = torch.hub.load('ultralytics/yolov5', 'yolov5s', pretrained=True)

@app.post("/detect")
async def detect_people(image: UploadFile = File(...)):
    content = await image.read()
    img_array = np.frombuffer(content, np.uint8)
    img = cv2.imdecode(img_array, cv2.IMREAD_COLOR)
    results = model(img)
    df = results.pandas().xyxy[0]
    people_count = len(df[df['name'] == 'person'])
    return {"people_count": people_count}
