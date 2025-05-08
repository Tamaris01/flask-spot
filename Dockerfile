# Gunakan image Python resmi
FROM python:3.10-slim

# Install dependencies sistem yang diperlukan untuk OpenCV dan pustaka lainnya
RUN apt-get update && apt-get install -y \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender1 \
    libfontconfig1 \
    libgl1-mesa-glx \
    && rm -rf /var/lib/apt/lists/*

# Buat working directory
WORKDIR /app

# Copy semua file ke container
COPY . .

# Install dependencies Python
RUN pip install --upgrade pip && pip install -r requirements.txt && rm -rf /root/.cache

# Expose port Flask/Gunicorn
EXPOSE 5000

# Jalankan app dengan gunicorn (file app.py harus punya "app = Flask(__name__)")
CMD ["gunicorn", "app:app", "--bind", "0.0.0.0:$PORT", "--workers", "2", "--threads", "2", "--timeout", "120"]
