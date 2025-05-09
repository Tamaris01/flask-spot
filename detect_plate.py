# detect_plate.py
from ultralytics import YOLO
import cv2
import re
from paddleocr import PaddleOCR
import numpy as np

# Inisialisasi OCR sekali di startup, model sudah ada di cache Docker
ocr = PaddleOCR(
    use_angle_cls=False,
    lang='en',
    show_log=False,
    rec_batch_num=1,
    cpu_threads=2,
    max_batch_size=1,
    det=True,
    rec=True,
    table=False,
    layout=False,
    formula=False,
    recovery=False
)

# Cache YOLO model
model_cache = None

def load_model(model_path: str) -> YOLO:
    global model_cache
    if model_cache is None:
        model_cache = YOLO(model_path)
    return model_cache


def preprocess_plate(plate_img: np.ndarray) -> np.ndarray:
    gray = cv2.cvtColor(plate_img, cv2.COLOR_BGR2GRAY)
    return cv2.resize(gray, None, fx=2, fy=2, interpolation=cv2.INTER_CUBIC)


def format_license_plate(text: str) -> str:
    match = re.match(r'^([A-Z]{1,2})(\d{1,4})([A-Z]{1,3})?$', text)
    if match:
        p1, p2, p3 = match.group(1), match.group(2), (match.group(3) or "")
        return f"{p1} {p2} {p3}".strip()
    return text


def extract_text_paddle(preprocessed_img: np.ndarray) -> str:
    result = ocr.ocr(preprocessed_img, cls=False)
    for line in result:
        for _, (text, _) in line:
            cleaned = ''.join(filter(str.isalnum, text.upper()))
            if re.match(r'^[A-Z]{1,2}[0-9]{1,4}[A-Z]{0,3}$', cleaned):
                return format_license_plate(cleaned)
    return None


def detect_plate_image(frame: np.ndarray, model_path: str):
    model = load_model(model_path)
    small = cv2.resize(frame, (640, 480))
    res = model.predict(source=small, conf=0.3, verbose=False)
    texts = []

    for r in res:
        for box in r.boxes:
            x1, y1, x2, y2 = map(int, box.xyxy[0])
            if (x2 - x1) < 30 or (y2 - y1) < 15:
                continue
            xs = frame.shape[1] / 640; ys = frame.shape[0] / 480
            x1, x2 = int(x1 * xs), int(x2 * xs)
            y1, y2 = int(y1 * ys), int(y2 * ys)
            cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 255, 0), 2)
            plate_img = frame[y1:y2, x1:x2]
            pp = preprocess_plate(plate_img)
            t = extract_text_paddle(pp)
            if t:
                texts.append(t)
                cv2.putText(frame, f"OCR: {t}", (x1, y2 + 25),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 0, 0), 2)
    final = ", ".join(texts) if texts else "-"
    return frame, final
