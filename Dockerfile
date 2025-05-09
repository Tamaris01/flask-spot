FROM python:3.9-slim

# 1. Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential wget tar \
    libglib2.0-0 libsm6 libxext6 libxrender1 \
    libfontconfig1 libgl1-mesa-glx \
    ccache \
 && rm -rf /var/lib/apt/lists/*

# 2. Set working directory
WORKDIR /app

# 3. Copy requirements file and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 4. Pre-download model for PaddleOCR (optional but useful for performance)
RUN mkdir -p /root/.paddleocr/whl/rec/en/en_PP-OCRv4_rec_infer && \
    wget -qO- https://paddleocr.bj.bcebos.com/PP-OCRv4/english/en_PP-OCRv4_rec_infer.tar \
    | tar -x -C /root/.paddleocr/whl/rec/en/en_PP-OCRv4_rec_infer && \
    mkdir -p /root/.paddleocr/whl/cls/ch_ppocr_mobile_v2.0_cls_infer && \
    wget -qO- https://paddleocr.bj.bcebos.com/dygraph_v2.0/ch/ch_ppocr_mobile_v2.0_cls_infer.tar \
    | tar -x -C /root/.paddleocr/whl/cls/ch_ppocr_mobile_v2.0_cls_infer

# 5. Copy the rest of the application code
COPY . .

# 6. Expose port and set environment variable
ENV PORT=8080
EXPOSE 8080

# 7. Run Gunicorn (assuming 'app' is the Flask app file and 'app' is the Flask instance)
CMD ["gunicorn", "--workers", "2", "--preload", "--bind", "0.0.0.0:8080", "app:app"]
