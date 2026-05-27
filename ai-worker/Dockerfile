FROM python:3.10-slim

WORKDIR /app

# Instalar dependencias del sistema requeridas por MediaPipe y OpenCV
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 \
    libglib2.0-0 \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --default-timeout=1000 --no-cache-dir -r requirements.txt

# Crear directorio para almacenar las imágenes (mapeado por volumen)
RUN mkdir -p /app/uploads

COPY . .

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
