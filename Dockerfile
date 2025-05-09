FROM python:3.9-slim

# 1. Install system deps
RUN apt-get update && apt-get install -y \
        build-essential wget tar \
        libglib2.0-0 libsm6 libxext6 libxrender1 \
        libfontconfig1 libgl1-mesa-glx \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 2. Copy requirements & install
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 3. Pre-download OCR model ke cache PaddleOCR
#    (sesuaikan URL sesuai versi tar yang diperlukan)
RUN mkdir -p /root/.paddleocr/whl/rec/en/en_PP-OCRv4_rec_infer && \
    wget -qO- https://paddleocr.bj.bcebos.com/PP-OCRv4/english/en_PP-OCRv4_rec_infer.tar \
      | tar -x -C /root/.paddleocr/whl/rec/en/en_PP-OCRv4_rec_infer && \
    mkdir -p /root/.paddleocr/whl/cls/ch_ppocr_mobile_v2.0_cls_infer && \
    wget -qO- https://paddleocr.bj.bcebos.com/dygraph_v2.0/ch/ch_ppocr_mobile_v2.0_cls_infer.tar \
      | tar -x -C /root/.paddleocr/whl/cls/ch_ppocr_mobile_v2.0_cls_infer

# 4. Copy aplikasi
COPY . .

ENV PORT=8080
EXPOSE 8080

# 5. Jalankan dengan Gunicorn
CMD exec gunicorn --workers 2 --preload --bind 0.0.0.0:${PORT} app:app
