# Gunakan image Python resmi sebagai base image
FROM python:3.9-slim

# Install dependencies sistem yang diperlukan untuk OpenCV dan pustaka lainnya
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

# Install dependencies dari requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Salin semua file aplikasi ke dalam container
COPY . .

# Set environment variable untuk Flask
ENV FLASK_APP=app.py
ENV FLASK_RUN_HOST=0.0.0.0

# Expose port Flask
EXPOSE 5000

# Jalankan aplikasi Flask
CMD ["flask", "run"]
