# Gunakan image Python resmi sebagai base image
FROM python:3.9-slim

# Install dependencies sistem (untuk OpenCV, PaddleOCR, dsb)
RUN apt-get update && apt-get install -y \
    build-essential \
    ccache \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender1 \
    libfontconfig1 \
    libgl1-mesa-glx \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Salin file requirements.txt ke container
COPY requirements.txt .

# Install dependencies Python
RUN pip install --no-cache-dir -r requirements.txt

# Salin semua file aplikasi ke dalam container
COPY . .

# Set environment variable fallback (kalau run local)
ENV PORT=8000

# Expose port default (Railway akan override dengan PORT env)
EXPOSE 8000

# Jalankan Gunicorn dengan bind ke $PORT
CMD ["gunicorn", "--bind", "0.0.0.0:${PORT}", "app:app"]
