# Gunakan image Python resmi
FROM python:3.10-slim

# Install dependencies sistem yang diperlukan untuk OpenCV dan pustaka lainnya
RUN apt-get update && apt-get install -y \
    ccache \
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

# Install virtual environment dan aktivasi
RUN python -m venv /venv
ENV PATH="/venv/bin:$PATH"

# Install dependencies Python di dalam virtual environment
RUN pip install --upgrade pip && pip install -r requirements.txt && rm -rf /root/.cache

# Expose port Railway (gunakan ENV jika perlu)
ARG PORT=8080
ENV PORT=${PORT}
EXPOSE ${PORT}

# Jalankan app dengan Gunicorn, bind ke 0.0.0.0:PORT
CMD ["sh", "-c", "gunicorn app:app --bind 0.0.0.0:$PORT --workers 2 --threads 2 --timeout 120"]
