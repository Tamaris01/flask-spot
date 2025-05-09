from ultralytics import YOLO
import cv2
import re
from paddleocr import PaddleOCR
import time

# Inisialisasi OCR ringan sekali di startup
ocr = PaddleOCR(
    use_angle_cls=False,  # matikan angle classification
    lang='en',
    det_model_dir='https://paddleocr.bj.bcebos.com/dygraph_v2.0/ppocr/en_det_prune_infer',
    rec_model_dir='https://paddleocr.bj.bcebos.com/dygraph_v2.0/ppocr/en_rec_infer',
    show_log=False,
    rec_batch_num=1,
    cpu_threads=2,
    max_batch_size=1,
    det=True, rec=True,
    table=False, layout=False, formula=False, recovery=False
)

# Caching YOLO model
model_cache = None
def load_model(model_path):
    global model_cache
    if model_cache is None:
        model_cache = YOLO(model_path)
    return model_cache

def preprocess_plate(plate_img):
    gray = cv2.cvtColor(plate_img, cv2.COLOR_BGR2GRAY)
    resized = cv2.resize(gray, None, fx=2, fy=2, interpolation=cv2.INTER_CUBIC)
    return resized

def format_license_plate(text):
    match = re.match(r'^([A-Z]{1,2})(\d{1,4})([A-Z]{1,3})?$', text)
    if match:
        part1 = match.group(1)
        part2 = match.group(2)
        part3 = match.group(3) or ""
        return f"{part1} {part2} {part3}".strip()
    return text

def extract_text_paddle(preprocessed_img):
    # Hanya deteksi & recognition
    result = ocr.ocr(preprocessed_img, cls=False)
    for line in result:
        for box, (text, conf) in line:
            cleaned = ''.join(filter(str.isalnum, text.upper()))
            if re.match(r'^[A-Z]{1,2}[0-9]{1,4}[A-Z]{0,3}$', cleaned):
                return format_license_plate(cleaned)
    return None

def detect_plate_image(frame, model_path):
    model = load_model(model_path)

    # Resize frame untuk deteksi lebih cepat
    small_frame = cv2.resize(frame, (640, 480))
    results = model.predict(source=small_frame, conf=0.3, verbose=False)

    ocr_texts = []
    for r in results:
        for box in r.boxes:
            x1, y1, x2, y2 = map(int, box.xyxy[0])
            conf = float(box.conf[0])

            # Skip kotak terlalu kecil
            if (x2 - x1) < 30 or (y2 - y1) < 15:
                continue

            # Skala kembali koordinat ke frame asli
            x_scale = frame.shape[1] / 640
            y_scale = frame.shape[0] / 480
            x1, x2 = int(x1 * x_scale), int(x2 * x_scale)
            y1, y2 = int(y1 * y_scale), int(y2 * y_scale)

            # Gambar bounding box & label
            cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 255, 0), 2)
            cv2.putText(frame, f"Plate ({conf:.2f})", (x1, y1 - 10),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 255, 0), 2)

            # Crop & preprocess plat
            plate_img = frame[y1:y2, x1:x2]
            preprocessed_img = preprocess_plate(plate_img)

            # OCR
            text = extract_text_paddle(preprocessed_img)
            if text:
                ocr_texts.append(text)
                cv2.putText(frame, f"OCR: {text}", (x1, y2 + 25),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 0, 0), 2)

    final_ocr = ', '.join(ocr_texts) if ocr_texts else "-"
    return frame, final_ocr
