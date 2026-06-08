import numpy as np
import mediapipe as mp
import math
from PIL import Image

image_path = "uploads/file-1780780114414-956783588.jpg"
original_img = Image.open(image_path)
width_px, height_px = original_img.size
print("Image size:", width_px, "x", height_px)

mp_hands = mp.solutions.hands
hands_detector = mp_hands.Hands(
    static_image_mode=True,
    max_num_hands=2,
    min_detection_confidence=0.3
)

img_np = np.array(original_img.convert("RGB"))
results = hands_detector.process(img_np)

if results.multi_hand_landmarks:
    for idx, hand_landmarks in enumerate(results.multi_hand_landmarks):
        lm5 = hand_landmarks.landmark[5]
        lm17 = hand_landmarks.landmark[17]
        dx = (lm5.x - lm17.x) * width_px
        dy = (lm5.y - lm17.y) * height_px
        hand_scale = math.sqrt(dx**2 + dy**2)
        print(f"Hand {idx} scale: {hand_scale:.2f}")
        
        # Check index finger (tip 8, joint 7)
        tip_lm = hand_landmarks.landmark[8]
        joint_lm = hand_landmarks.landmark[7]
        tx, ty = tip_lm.x * width_px, tip_lm.y * height_px
        jx, jy = joint_lm.x * width_px, joint_lm.y * height_px
        
        vx, vy = tx - jx, ty - jy
        v_len = math.sqrt(vx**2 + vy**2)
        print(f"Index v_len: {v_len:.2f}")
        
        # Our new code logic
        nail_w = hand_scale * 0.09
        nail_l = hand_scale * 0.13
        print(f"Calculated nail_w: {nail_w:.2f}, nail_l: {nail_l:.2f}")
        
        # Calculate actual center
        ux, uy = (vx / v_len, vy / v_len) if v_len > 0 else (0, -1)
        cx = tx - ux * (nail_l * 0.42)
        cy = ty - uy * (nail_l * 0.42)
        print(f"Index nail center: ({cx:.2f}, {cy:.2f})")
else:
    print("No hand detected!")
