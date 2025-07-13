FROM python:3.10-slim

RUN apt-get update && apt-get install -y libgl1

WORKDIR /app
COPY . /app

RUN pip install --no-cache-dir -r requirements.txt

CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8080"]
