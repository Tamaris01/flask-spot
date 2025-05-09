# app.py
import os
import threading
import time
import base64
import cv2
import numpy as np
import requests
from flask import Flask, jsonify, request
from flask_cors import CORS
from detect_plate import detect_plate_image

app = Flask(__name__)
CORS(app)

MODEL_PATH = os.path.join(os.path.dirname(__file__), 'best.pt')
if not os.path.exists(MODEL_PATH):
    raise FileNotFoundError(f"Model tidak ditemukan: {MODEL_PATH}")

raw_frame = None
display_frame = None
result_text = "-"
lock = threading.Lock()

# Background detection thread
threading.Thread(target=lambda: (
    (time.sleep(0.1),
     lock.acquire(),
     (lambda frame:=raw_frame.copy() if raw_frame else None: (
         lock.release(),
         (lambda f=frame: (
             (lambda out_txt=detect_plate_image(f, MODEL_PATH):
                 setattr(globals(), 'display_frame', out_txt[0]) or setattr(globals(), 'result_text', out_txt[1])
             ) if f else None
         ))
     ))
    )
), daemon=True).start()

@app.route('/')
def home(): return "Plate Detection Service is up!"

@app.route('/healthz')
def healthz(): return "OK", 200

@app.route('/upload_frame', methods=['POST'])
def upload():
    global raw_frame
    data = request.get_json(silent=True)
    if not data or 'image' not in data:
        return jsonify(error="No image"), 400
    try:
        b64 = data['image'].split(',', 1)[1]
        arr = np.frombuffer(base64.b64decode(b64), np.uint8)
        f = cv2.imdecode(arr, cv2.IMREAD_COLOR)
        if f is None: raise ValueError("Decode failed")
        with lock: raw_frame = f
        return jsonify(message="OK"), 200
    except Exception as e:
        return jsonify(error=str(e)), 500

@app.route('/get_processed_frame')
def get_frame():
    with lock:
        if display_frame is None: return jsonify(error="No processed"), 400
        _, buf = cv2.imencode('.jpg', display_frame)
        return jsonify(frame="data:image/jpeg;base64," + base64.b64encode(buf).decode()), 200

@app.route('/result')
def result():
    with lock: return jsonify(plate=result_text), 200

@app.route('/check_plate/<plat>')
def check_plate(plat):
    try:
        r = requests.get(f'https://laravel-spot-production.up.railway.app/api/check_plate/{plat}', timeout=5)
        r.raise_for_status()
        return r.json(), 200
    except requests.exceptions.Timeout:
        return jsonify(error="Waktu habis", exists=False), 504
    except Exception as e:
        return jsonify(error=str(e), exists=False), 502

# Gunakan Gunicorn di Docker: gunicorn --bind 0.0.0.0:$PORT app:app
