import os
import math
import random
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageColor

# Inicializar MediaPipe de forma perezosa para evitar consumo innecesario si no se usa.
# En entornos livianos de Docker puede no estar instalado; en ese caso
# el worker cae automáticamente al renderizado de demostración.
_mp_hands = None
_hands_detector = None

def get_mediapipe_hands():
    global _mp_hands, _hands_detector
    if _hands_detector is None:
        try:
            import mediapipe as mp
            _mp_hands = mp.solutions.hands
            # Usamos modo estático para procesamiento de imágenes individuales
            _hands_detector = _mp_hands.Hands(
                static_image_mode=True,
                max_num_hands=2,
                min_detection_confidence=0.3
            )
            print("🤖 MediaPipe Hands inicializado correctamente.")
        except Exception as e:
            print(f"⚠️ Error al inicializar MediaPipe: {e}. Se usará fallback simulado.")
    return _hands_detector

def parse_color(color_hex):
    """Convierte hex #RRGGBB o RRGGBB a tupla RGB."""
    if not color_hex:
        return (200, 157, 147) # Default rosa/nude de la app
    hex_str = color_hex.lstrip('#')
    try:
        return tuple(int(hex_str[i:i+2], 16) for i in (0, 2, 4))
    except Exception:
        return (200, 157, 147)

def get_nail_shape_points(center, vector, shape, width, length):
    """
    Calcula los puntos de un polígono de uña según la forma.
    center: (x, y) del centro de la uña
    vector: (vx, vy) vector del segmento del dedo (orientación)
    shape: 'almond' | 'square' | 'coffin' | 'stiletto'
    width: ancho base de la uña
    length: longitud de la uña (hacia la punta)
    """
    vx, vy = vector
    v_len = math.sqrt(vx**2 + vy**2)
    if v_len == 0:
        ux, uy = (0, -1)
    else:
        # Vector unitario en dirección de la punta
        ux, uy = vx / v_len, vy / v_len
    
    # Vector perpendicular unitario
    px, py = -uy, ux
    
    cx, cy = center
    shape = (shape or 'almond').lower()
    
    points = []
    
    if shape == 'stiletto':
        # Triángulo afilado
        # Base cerca del nudillo
        b1 = (cx - px * (width * 0.5) - ux * (length * 0.4), cy - py * (width * 0.5) - uy * (length * 0.4))
        b2 = (cx + px * (width * 0.5) - ux * (length * 0.4), cy + py * (width * 0.5) - uy * (length * 0.4))
        # Punta afilada
        tip = (cx + ux * (length * 0.8), cy + uy * (length * 0.8))
        points = [b1, b2, tip]
        
    elif shape == 'coffin':
        # Rectángulo trapezoidal (más ancho en la base, plano en la punta)
        b1 = (cx - px * (width * 0.5) - ux * (length * 0.4), cy - py * (width * 0.5) - uy * (length * 0.4))
        b2 = (cx + px * (width * 0.5) - ux * (length * 0.4), cy + py * (width * 0.5) - uy * (length * 0.4))
        t2 = (cx + px * (width * 0.25) + ux * (length * 0.6), cy + py * (width * 0.25) + uy * (length * 0.6))
        t1 = (cx - px * (width * 0.25) + ux * (length * 0.6), cy - py * (width * 0.25) + uy * (length * 0.6))
        points = [b1, b2, t2, t1]
        
    elif shape == 'square':
        # Rectángulo plano
        b1 = (cx - px * (width * 0.5) - ux * (length * 0.4), cy - py * (width * 0.5) - uy * (length * 0.4))
        b2 = (cx + px * (width * 0.5) - ux * (length * 0.4), cy + py * (width * 0.5) - uy * (length * 0.4))
        t2 = (cx + px * (width * 0.5) + ux * (length * 0.5), cy + py * (width * 0.5) + uy * (length * 0.5))
        t1 = (cx - px * (width * 0.5) + ux * (length * 0.5), cy - py * (width * 0.5) + uy * (length * 0.5))
        points = [b1, b2, t2, t1]
        
    else: # almond u oval
        # Curva suave. Generamos puntos de elipse/huevo
        steps = 12
        # Base semicircular
        for i in range(steps + 1):
            alpha = -math.pi/2 + (math.pi * i / steps)
            # Factor de atenuación para Almond en la punta
            factor = 0.8 if i in (0, steps) else 1.0
            if i > steps / 2:
                # Parte superior (punta) es más estrecha en almendra
                w_factor = 0.35
                l_factor = 0.65
            else:
                # Parte inferior (base)
                w_factor = 0.5
                l_factor = 0.45
            
            dx = px * (width * w_factor) * math.cos(alpha)
            dy = py * (width * w_factor) * math.cos(alpha)
            
            ex = ux * (length * l_factor) * math.sin(alpha)
            ey = uy * (length * l_factor) * math.sin(alpha)
            
            points.append((cx + dx + ex, cy + dy + ey))
            
    return points

def apply_finish_effects(draw, points, color_rgb, finish):
    """Dibuja la uña con efectos estéticos basados en el acabado."""
    finish = (finish or 'glossy').lower()
    
    # 1. Dibujar el color base con opacidad
    base_color = color_rgb + (200,) # Alpha 200/255 para fusión natural
    draw.polygon(points, fill=base_color)
    
    # Calcular centro y límites del polígono para efectos visuales
    xs = [p[0] for p in points]
    ys = [p[1] for p in points]
    if not xs or not ys:
        return
        
    min_x, max_x = min(xs), max(xs)
    min_y, max_y = min(ys), max(ys)
    cx = sum(xs) / len(points)
    cy = sum(ys) / len(points)
    w = max_x - min_x
    h = max_y - min_y
    
    if finish == 'glossy':
        # Brillo reflejo: una línea blanca curvada a un lado de la uña
        highlight_points = []
        for i in range(len(points) // 3):
            # Tomar puntos del lado izquierdo/superior
            pt = points[i]
            # Desplazar ligeramente hacia adentro
            hx = pt[0] + (cx - pt[0]) * 0.25
            hy = pt[1] + (cy - pt[1]) * 0.25
            highlight_points.append((hx, hy))
        if len(highlight_points) > 1:
            draw.line(highlight_points, fill=(255, 255, 255, 120), width=int(max(2, w * 0.12)))
            # Destello puntual en la punta
            draw.ellipse([cx - w*0.1, cy - h*0.3, cx + w*0.1, cy - h*0.1], fill=(255, 255, 255, 150))
            
    elif finish == 'chrome':
        # Efecto metálico cromado: degradado metálico simulado con múltiples bandas
        draw.polygon(points, fill=color_rgb + (160,))
        # Línea de brillo de alta intensidad central
        draw.line([(min_x + w*0.3, min_y + h*0.2), (min_x + w*0.4, max_y - h*0.2)], fill=(255, 255, 255, 180), width=int(max(1, w * 0.08)))
        draw.line([(min_x + w*0.6, min_y + h*0.2), (min_x + w*0.7, max_y - h*0.2)], fill=(255, 255, 255, 90), width=int(max(1, w * 0.05)))
        
    elif finish == 'glitter':
        # Destellos pequeños blancos y plateados esparcidos
        for _ in range(30):
            rx = random.uniform(min_x + w*0.15, max_x - w*0.15)
            ry = random.uniform(min_y + h*0.15, max_y - h*0.15)
            # Comprobar si el punto aleatorio está dentro del polígono (aproximado)
            # Para simplificar, pintamos círculos muy pequeños
            g_color = random.choice([(255, 255, 255, 220), (230, 240, 255, 180), (255, 220, 200, 200)])
            r_sz = random.uniform(1, max(2, w * 0.06))
            draw.ellipse([rx - r_sz, ry - r_sz, rx + r_sz, ry + r_sz], fill=g_color)

def _refine_binary_mask(mask, rounds=2):
    """Suaviza una máscara booleana con mayoría local 3x3."""
    refined = mask.copy()
    for _ in range(rounds):
        neighbors = refined.astype(np.uint8)
        for dy in (-1, 0, 1):
            for dx in (-1, 0, 1):
                if dx == 0 and dy == 0:
                    continue
                neighbors += np.roll(np.roll(refined, dy, axis=0), dx, axis=1).astype(np.uint8)
        refined = neighbors >= 5
        refined[0, :] = False
        refined[-1, :] = False
        refined[:, 0] = False
        refined[:, -1] = False
    return refined

def _largest_component(mask):
    """Conserva solo el componente conectado más grande."""
    h, w = mask.shape
    visited = np.zeros((h, w), dtype=bool)
    largest = []

    for y in range(h):
        for x in range(w):
            if not mask[y, x] or visited[y, x]:
                continue

            stack = [(y, x)]
            visited[y, x] = True
            component = []

            while stack:
                cy, cx = stack.pop()
                component.append((cy, cx))
                for ny, nx in ((cy - 1, cx), (cy + 1, cx), (cy, cx - 1), (cy, cx + 1)):
                    if 0 <= ny < h and 0 <= nx < w and mask[ny, nx] and not visited[ny, nx]:
                        visited[ny, nx] = True
                        stack.append((ny, nx))

            if len(component) > len(largest):
                largest = component

    result = np.zeros_like(mask, dtype=bool)
    for y, x in largest:
        result[y, x] = True
    return result

def estimate_nails_from_image(img_np):
    """
    Estima posiciones de uñas a partir de una máscara de piel simple.
    Devuelve una lista de tuplas (cx, cy, vx, vy, nail_w, nail_l).
    """
    r = img_np[:, :, 0].astype(np.int16)
    g = img_np[:, :, 1].astype(np.int16)
    b = img_np[:, :, 2].astype(np.int16)

    skin_mask = (
        (r > 55) &
        (g > 35) &
        (b > 15) &
        ((np.maximum.reduce([r, g, b]) - np.minimum.reduce([r, g, b])) > 15) &
        (np.abs(r - g) > 8) &
        (r > g) &
        (r > b)
    )

    skin_mask = _refine_binary_mask(skin_mask, rounds=2)
    skin_mask = _largest_component(skin_mask)

    ys, xs = np.where(skin_mask)
    if len(xs) < 400:
        return []

    min_x, max_x = xs.min(), xs.max()
    min_y, max_y = ys.min(), ys.max()
    box_w = max_x - min_x
    box_h = max_y - min_y
    if box_w < 40 or box_h < 60:
        return []

    top_profile = np.full(img_np.shape[1], max_y, dtype=np.int32)
    for x in range(min_x, max_x + 1):
        col = np.where(skin_mask[:, x])[0]
        if len(col) > 0:
            top_profile[x] = col.min()

    nails = []
    finger_centers = [0.24, 0.40, 0.56, 0.72]
    finger_widths = [0.16, 0.14, 0.14, 0.12]

    for rel_center, rel_width in zip(finger_centers, finger_widths):
        seg_start = int(min_x + box_w * max(0.0, rel_center - rel_width / 2))
        seg_end = int(min_x + box_w * min(1.0, rel_center + rel_width / 2))
        seg = top_profile[seg_start:seg_end + 1]
        valid = np.where(seg < max_y)[0]
        if len(valid) == 0:
            continue

        local_min = seg[valid].min()
        peak_positions = valid[seg[valid] <= local_min + max(3, int(box_h * 0.02))]
        tip_x = seg_start + int(np.median(peak_positions))
        tip_y = int(local_min)

        joint_y = min(max_y, int(tip_y + box_h * 0.22))
        joint_x = tip_x + int((tip_x - (min_x + max_x) / 2) * 0.08)
        vx = tip_x - joint_x
        vy = tip_y - joint_y
        nail_w = max(10, box_w * rel_width * 0.42)
        nail_l = max(14, box_h * 0.16)
        cx = tip_x - vx * 0.18
        cy = tip_y - vy * 0.18
        nails.append((cx, cy, vx, vy, nail_w, nail_l))

    lower_half = skin_mask[int(min_y + box_h * 0.35):max_y + 1, min_x:max_x + 1]
    left_mass = int(lower_half[:, :max(1, lower_half.shape[1] // 3)].sum())
    right_mass = int(lower_half[:, -max(1, lower_half.shape[1] // 3):].sum())
    thumb_on_left = left_mass > right_mass

    thumb_cx = min_x + box_w * (0.10 if thumb_on_left else 0.90)
    thumb_cy = min_y + box_h * 0.62
    thumb_vx = -box_w * 0.12 if thumb_on_left else box_w * 0.12
    thumb_vy = -box_h * 0.14
    thumb_w = max(12, box_w * 0.12)
    thumb_l = max(14, box_h * 0.13)
    nails.insert(0, (thumb_cx, thumb_cy, thumb_vx, thumb_vy, thumb_w, thumb_l))

    return nails[:5]

def process_nail_tryon(image_path, output_path, params):
    """
    Procesa la prueba virtual de uñas.
    image_path: Ruta a la imagen de origen.
    output_path: Ruta donde guardar el resultado.
    params: Dict con color_hex, shape, finish, decoration_style.
    """
    try:
        color_hex = params.get('color_hex', '#FF0055')
        shape = params.get('shape', 'almond')
        finish = params.get('finish', 'glossy')
        decoration = params.get('decoration_style', 'solid')
        
        color_rgb = parse_color(color_hex)
        
        # Cargar imagen original
        if not os.path.exists(image_path):
            raise FileNotFoundError(f"No existe la imagen de origen en {image_path}")
            
        original_img = Image.open(image_path).convert("RGBA")
        width_px, height_px = original_img.size
        
        # Crear capa transparente para las uñas
        nail_layer = Image.new("RGBA", original_img.size, (0, 0, 0, 0))
        draw = ImageDraw.Draw(nail_layer)
        
        # Intentar inicializar y correr MediaPipe
        detector = get_mediapipe_hands()
        hands_detected = False
        
        if detector is not None:
            # MediaPipe requiere numpy array
            img_np = np.array(original_img.convert("RGB"))
            results = detector.process(img_np)
            
            if results.multi_hand_landmarks:
                hands_detected = True
                print(f"👋 Mano detectada. Procesando landmarks...")
                for hand_landmarks in results.multi_hand_landmarks:
                    # Definición de dedos: (Tip, Joint)
                    # 8 = Index Tip, 7 = Index DIP
                    # 12 = Middle Tip, 11 = Middle DIP
                    # 16 = Ring Tip, 15 = Ring DIP
                    # 20 = Pinky Tip, 19 = Pinky DIP
                    # 4 = Thumb Tip, 3 = Thumb IP
                    fingers = [
                        (4, 3, 0.28, 0.35),   # Thumb: Tip, Joint, width_factor, length_factor
                        (8, 7, 0.22, 0.38),   # Index
                        (12, 11, 0.22, 0.38), # Middle
                        (16, 15, 0.22, 0.38), # Ring
                        (20, 19, 0.18, 0.34)  # Pinky
                    ]
                    
                    for tip_idx, joint_idx, w_f, l_f in fingers:
                        # Obtener coordenadas relativas y pasarlas a píxeles
                        tip_lm = hand_landmarks.landmark[tip_idx]
                        joint_lm = hand_landmarks.landmark[joint_idx]
                        
                        tx, ty = tip_lm.x * width_px, tip_lm.y * height_px
                        jx, jy = joint_lm.x * width_px, joint_lm.y * height_px
                        
                        # Vector de orientación
                        vx, vy = tx - jx, ty - jy
                        v_len = math.sqrt(vx**2 + vy**2)
                        
                        # Estimar centro de la uña (ligeramente detrás del fingertip real)
                        # Dependiendo de la inclinación, desplazamos
                        cx = tx - vx * 0.1
                        cy = ty - vy * 0.1
                        
                        # Dimensiones proporcionales al tamaño de la mano detectada
                        nail_w = v_len * w_f
                        nail_l = v_len * l_f
                        
                        # Generar puntos de la forma
                        pts = get_nail_shape_points((cx, cy), (vx, vy), shape, nail_w, nail_l)
                        
                        # Aplicar dibujo con efectos de acabado
                        apply_finish_effects(draw, pts, color_rgb, finish)
                        
        if not hands_detected:
            print("⚠️ Mano no detectada por MediaPipe. Aplicando heurística de contorno.")
            estimated_nails = estimate_nails_from_image(np.array(original_img.convert("RGB")))

            if not estimated_nails:
                print("⚠️ Heurística sin suficiente confianza. Usando plantilla centrada.")
                cx_c = width_px / 2
                cy_c = height_px / 2
                estimated_nails = [
                    (cx_c - width_px * 0.23, cy_c + height_px * 0.04, -width_px * 0.06, -height_px * 0.06, width_px * 0.05, height_px * 0.10),
                    (cx_c - width_px * 0.11, cy_c - height_px * 0.11, 0, -height_px * 0.09, width_px * 0.045, height_px * 0.11),
                    (cx_c, cy_c - height_px * 0.16, 0, -height_px * 0.10, width_px * 0.048, height_px * 0.12),
                    (cx_c + width_px * 0.11, cy_c - height_px * 0.11, 0, -height_px * 0.09, width_px * 0.045, height_px * 0.11),
                    (cx_c + width_px * 0.22, cy_c - height_px * 0.03, width_px * 0.05, -height_px * 0.07, width_px * 0.04, height_px * 0.10),
                ]

            for cx, cy, vx, vy, nw, nl in estimated_nails:
                pts = get_nail_shape_points((cx, cy), (vx, vy), shape, nw, nl)
                apply_finish_effects(draw, pts, color_rgb, finish)
        
        # Suavizar un poco los bordes de la capa de uñas usando desenfoque gaussiano leve
        # para que la pintura se fusione mejor con la piel
        nail_layer_blurred = nail_layer.filter(ImageFilter.GaussianBlur(radius=0.4))
        
        # Combinar imagen original y capa de uñas
        final_img = Image.alpha_composite(original_img, nail_layer_blurred)
        
        # Guardar en formato JPEG para optimizar tamaño
        final_img.convert("RGB").save(output_path, "JPEG", quality=85)
        print(f"✅ Prueba virtual completada con éxito. Archivo guardado en {output_path}")
        return True
        
    except Exception as e:
        print(f"❌ Error en process_nail_tryon: {e}")
        import traceback
        traceback.print_exc()
        raise e
