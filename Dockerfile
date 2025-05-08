# Gunakan image Python resmi
FROM python:3.10-slim

# Buat working directory
WORKDIR /app

# Copy semua file ke container
COPY . .

# Install dependencies
RUN pip install --upgrade pip && pip install -r requirements.txt

# Expose port Flask/Gunicorn
EXPOSE 5000

# Jalankan app dengan gunicorn (file app.py harus punya "app = Flask(__name__)")
CMD ["gunicorn", "app:app", "--bind", "0.0.0.0:5000", "--workers", "2", "--threads", "2", "--timeout", "120"]
