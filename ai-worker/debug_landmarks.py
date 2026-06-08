import numpy as np
import mediapipe as mp
from PIL import Image, ImageDraw

image_path = "uploads/file-1780780114414-956783588.jpg"
original_img = Image.open(image_path).convert("RGBA")
width_px, height_px = original_img.size

mp_hands = mp.solutions.hands
hands_detector = mp_hands.Hands(
    static_image_mode=True,
    max_num_hands=2,
    min_detection_confidence=0.3
)

img_np = np.array(original_img.convert("RGB"))
results = hands_detector.process(img_np)

draw = ImageDraw.Draw(original_img)

if results.multi_hand_landmarks:
    for hand_landmarks in results.multi_hand_landmarks:
        # Draw all 21 landmarks
        for i, lm in enumerate(hand_landmarks.landmark):
            cx = int(lm.x * width_px)
            cy = int(lm.y * height_px)
            # Draw circle
            draw.ellipse([cx - 15, cy - 15, cx + 15, cy + 15], fill=(255, 0, 0, 255))
            draw.text((cx + 20, cy), str(i), fill=(255, 255, 255, 255))

original_img.convert("RGB").save("uploads/debug_landmarks.jpg", "JPEG")
print("Saved debug_landmarks.jpg")
