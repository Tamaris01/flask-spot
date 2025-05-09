FROM python:3.9-slim

# 1. Install system dependencies (termasuk ccache)
RUN apt-get update && apt-get install -y \
    build-essential wget tar \
    libglib2.0-0 libsm6 libxext6 libxrender1 \
    libfontconfig1 libgl1-mesa-glx \
    ccache \
 && rm -rf /var/lib/apt/lists/*

# 2. Set working directory
WORKDIR /app

# 3. Copy requirements file dan install dependencies Python
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 4. Pre-download model OCR untuk PaddleOCR
RUN mkdir -p /root/.paddleocr/whl/rec/en/en_PP-OCRv4_rec_infer && \
    wget -qO- https://paddleocr.bj.bcebos.com/PP-OCRv4/english/en_PP-OCRv4_rec_infer.tar \
    | tar -x -C /root/.paddleocr/whl/rec/en/en_PP-OCRv4_rec_infer && \
    mkdir -p /root/.paddleocr/whl/cls/ch_ppocr_mobile_v2.0_cls_infer && \
    wget -qO- https://paddleocr.bj.bcebos.com/dygraph_v2.0/ch/ch_ppocr_mobile_v2.0_cls_infer.tar \
    | tar -x -C /root/.paddleocr/whl/cls/ch_ppocr_mobile_v2.0_cls_infer

# 5. Salin seluruh aplikasi
COPY . .

# 6. Konfigurasi environment dan port
ENV PORT=8080
EXPOSE 8080

# 7. Jalankan aplikasi dengan Gunicorn
CMD ["gunicorn", "--workers", "2", "--preload", "--bind", "0.0.0.0:8080", "app:app"]
