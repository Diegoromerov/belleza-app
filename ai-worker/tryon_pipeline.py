import os
import math
import random
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageColor

# Inicializar MediaPipe de forma perezosa
_mp_hands = None
_hands_detector = None

def get_mediapipe_hands():
    global _mp_hands, _hands_detector
    if _hands_detector is None:
        try:
            import mediapipe as mp
            _mp_hands = mp.solutions.hands
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
    if not color_hex:
        return (200, 157, 147)
    hex_str = color_hex.lstrip('#')
    try:
        return tuple(int(hex_str[i:i+2], 16) for i in (0, 2, 4))
    except Exception:
        return (200, 157, 147)

def get_smooth_nail_points(center, ux, uy, px, py, shape, width, length):
    """
    Genera una lista de puntos suaves (curvas) para el contorno de la uña.
    """
    cx, cy = center
    shape = (shape or 'almond').lower()
    points = []
    
    # 1. Generar la base de la uña (cutícula/matriz) - Curva semicircular inferior
    num_base_points = 12
    for i in range(num_base_points + 1):
        theta = math.pi + (math.pi * i / num_base_points)  # De pi a 2*pi (arco inferior)
        # Atenuación en los extremos para mejor acople
        factor_w = 0.5
        factor_l = 0.35
        
        dx = (width * factor_w) * math.cos(theta)
        dy = (length * factor_l) * math.sin(theta)
        
        x = cx + px * dx + ux * dy
        y = cy + py * dx + uy * dy
        points.append((x, y))
        
    # 2. Generar la punta de la uña
    num_tip_points = 12
    if shape == 'square':
        # Rectangular con esquinas ligeramente redondeadas
        corner_r = width * 0.15
        # Esquina superior derecha
        for i in range(6):
            alpha = (math.pi * 0.5 * i / 5)  # 0 a pi/2
            dx = (width * 0.5 - corner_r) + corner_r * math.cos(alpha)
            dy = (length * 0.55 - corner_r) + corner_r * math.sin(alpha)
            points.append((cx + px * dx + ux * dy, cy + py * dx + uy * dy))
        # Esquina superior izquierda
        for i in range(6):
            alpha = (math.pi * 0.5) + (math.pi * 0.5 * i / 5)  # pi/2 to pi
            dx = (-width * 0.5 + corner_r) + corner_r * math.cos(alpha)
            dy = (length * 0.55 - corner_r) + corner_r * math.sin(alpha)
            points.append((cx + px * dx + ux * dy, cy + py * dx + uy * dy))
            
    elif shape == 'coffin':
        # Trapezoidal (punta recta pero más estrecha que la base)
        top_w = width * 0.55
        corner_r = top_w * 0.15
        # Esquina superior derecha
        for i in range(6):
            alpha = (math.pi * 0.5 * i / 5)
            dx = (top_w * 0.5 - corner_r) + corner_r * math.cos(alpha)
            dy = (length * 0.65 - corner_r) + corner_r * math.sin(alpha)
            points.append((cx + px * dx + ux * dy, cy + py * dx + uy * dy))
        # Esquina superior izquierda
        for i in range(6):
            alpha = (math.pi * 0.5) + (math.pi * 0.5 * i / 5)
            dx = (-top_w * 0.5 + corner_r) + corner_r * math.cos(alpha)
            dy = (length * 0.65 - corner_r) + corner_r * math.sin(alpha)
            points.append((cx + px * dx + ux * dy, cy + py * dx + uy * dy))
            
    elif shape == 'stiletto':
        # Punta afilada con lados curvos elegantes
        # Lado derecho curvado hacia adentro
        for i in range(6):
            t = i / 5
            dx = (width * 0.5) * (1 - t)**1.4
            dy = (length * 0.85) * t
            points.append((cx + px * dx + ux * dy, cy + py * dx + uy * dy))
        # Lado izquierdo curvado hacia la punta
        for i in range(1, 6):
            t = i / 5
            dx = -(width * 0.5) * t**1.4
            dy = (length * 0.85) * (1 - t)
            points.append((cx + px * dx + ux * dy, cy + py * dx + uy * dy))
            
    else:  # almond (almendra) u ovalada
        # Punta ovalada elegante
        for i in range(num_tip_points + 1):
            alpha = (math.pi * i / num_tip_points)  # 0 a pi
            dx = width * 0.5 * math.cos(alpha)
            dy = length * 0.72 * math.sin(alpha)**1.3
            points.append((cx + px * dx + ux * dy, cy + py * dx + uy * dy))
            
    return points

def apply_finish_effects(draw, points, color_rgb, finish):
    """
    Dibuja la uña con efectos estéticos fotorrealistas (sombreado 3D y reflejos).
    """
    finish = (finish or 'glossy').lower()
    
    # 1. Color base con alta opacidad para cubrir bien la uña real
    base_color = color_rgb + (235,)
    draw.polygon(points, fill=base_color)
    
    # Calcular centro y límites
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
    
    # 2. Sombreado 3D (Volumen cilíndrico): sombras en los bordes laterales y cutícula
    # Sombra del borde derecho (curva de la uña)
    draw.polygon(points[int(len(points)*0.0):int(len(points)*0.35)] + [(cx, cy)], fill=(0, 0, 0, 40))
    # Sombra del borde izquierdo
    draw.polygon(points[int(len(points)*0.65):int(len(points)*1.0)] + [(cx, cy)], fill=(0, 0, 0, 30))
    
    # Sombra de la cutícula (arco inferior)
    if len(points) >= 12:
        cuticle_pts = points[:13]
        shadow_band = []
        for p in cuticle_pts:
            dx, dy = cx - p[0], cy - p[1]
            dist = math.sqrt(dx**2 + dy**2)
            if dist > 0:
                sp = (p[0] + dx/dist * (w * 0.08), p[1] + dy/dist * (w * 0.08))
                shadow_band.append(sp)
        shadow_poly = cuticle_pts + list(reversed(shadow_band))
        draw.polygon(shadow_poly, fill=(0, 0, 0, 45))

    # 3. Efectos de Acabado
    if finish == 'glossy':
        # Brillo reflejo curvo (luz reflejada blanca en un lado de la uña)
        highlight_points = []
        # Tomar puntos a lo largo del lado izquierdo
        for i in range(int(len(points) * 0.25), int(len(points) * 0.55)):
            pt = points[i]
            hx = pt[0] + (cx - pt[0]) * 0.35
            hy = pt[1] + (cy - pt[1]) * 0.35
            highlight_points.append((hx, hy))
        if len(highlight_points) > 1:
            draw.line(highlight_points, fill=(255, 255, 255, 140), width=int(max(2, w * 0.08)))
            
            # Destello/reflejo circular en la parte superior izquierda
            glare_x = cx - w * 0.18
            glare_y = cy - h * 0.22
            glare_r = max(2, w * 0.08)
            draw.ellipse([glare_x - glare_r, glare_y - glare_r, glare_x + glare_r, glare_y + glare_r], fill=(255, 255, 255, 170))
            
    elif finish == 'chrome':
        # Acabado metálico cromado: reflejos lineales contrastantes
        # Línea de brillo principal de alta intensidad
        draw.line([(cx - w*0.18, min_y + h*0.15), (cx - w*0.12, max_y - h*0.15)], fill=(255, 255, 255, 190), width=int(max(2, w * 0.12)))
        # Línea de brillo secundaria suave
        draw.line([(cx + w*0.22, min_y + h*0.2), (cx + w*0.26, max_y - h*0.2)], fill=(255, 255, 255, 110), width=int(max(1, w * 0.06)))
        # Línea oscura de contraste metálico
        draw.line([(cx + w*0.02, min_y + h*0.15), (cx + w*0.06, max_y - h*0.15)], fill=(0, 0, 0, 50), width=int(max(1, w * 0.07)))
        
    elif finish == 'glitter':
        # Efecto escarchado: partículas de brillo dispersas con pequeñas cruces
        for _ in range(25):
            rx = random.uniform(min_x + w*0.15, max_x - w*0.15)
            ry = random.uniform(min_y + h*0.15, max_y - h*0.15)
            g_color = random.choice([
                (255, 255, 255, 230),  # Blanco puro
                (255, 220, 200, 200),  # Oro cálido
                (210, 235, 255, 210),  # Plata/Fresco
                (color_rgb[0], color_rgb[1], color_rgb[2], 255) # Tono base brillante
            ])
            r_sz = random.uniform(1.2, max(2.5, w * 0.05))
            draw.ellipse([rx - r_sz, ry - r_sz, rx + r_sz, ry + r_sz], fill=g_color)
            
            # Dibujar un destello en cruz ocasionalmente
            if random.random() < 0.15:
                draw.line([(rx - r_sz*2.2, ry), (rx + r_sz*2.2, ry)], fill=(255, 255, 255, 220), width=1)
                draw.line([(rx, ry - r_sz*2.2), (rx, ry + r_sz*2.2)], fill=(255, 255, 255, 220), width=1)

def estimate_nails_from_image(img_np):
    """
    Fallback heurístico simple si falla MediaPipe
    """
    # ... código simplificado de fallback
    h, w, _ = img_np.shape
    cx_c = w / 2
    cy_c = h / 2
    return [
        (cx_c - w * 0.23, cy_c + h * 0.04, -w * 0.06, -h * 0.06, w * 0.05, h * 0.10),
        (cx_c - w * 0.11, cy_c - h * 0.11, 0, -h * 0.09, w * 0.045, h * 0.11),
        (cx_c, cy_c - h * 0.16, 0, -h * 0.10, w * 0.048, h * 0.12),
        (cx_c + w * 0.11, cy_c - h * 0.11, 0, -h * 0.09, w * 0.045, h * 0.11),
        (cx_c + w * 0.22, cy_c - h * 0.03, w * 0.05, -h * 0.07, w * 0.04, h * 0.10),
    ]

def process_nail_tryon(image_path, output_path, params):
    try:
        color_hex = params.get('color_hex', '#FF0055')
        shape = params.get('shape', 'almond')
        finish = params.get('finish', 'glossy')
        
        color_rgb = parse_color(color_hex)
        
        if not os.path.exists(image_path):
            raise FileNotFoundError(f"No existe la imagen de origen en {image_path}")
            
        original_img = Image.open(image_path).convert("RGBA")
        width_px, height_px = original_img.size
        
        nail_layer = Image.new("RGBA", original_img.size, (0, 0, 0, 0))
        draw = ImageDraw.Draw(nail_layer)
        
        detector = get_mediapipe_hands()
        hands_detected = False
        
        if detector is not None:
            img_np = np.array(original_img.convert("RGB"))
            results = detector.process(img_np)
            
            if results.multi_hand_landmarks:
                hands_detected = True
                print(f"👋 Mano detectada. Procesando landmarks con auto-escala estable...")
                for hand_landmarks in results.multi_hand_landmarks:
                    # 1. Calcular escala estable KNUCKLE-TO-KNUCKLE (Landmarks 5 a 17)
                    lm5 = hand_landmarks.landmark[5]
                    lm17 = hand_landmarks.landmark[17]
                    dx = (lm5.x - lm17.x) * width_px
                    dy = (lm5.y - lm17.y) * height_px
                    hand_scale = math.sqrt(dx**2 + dy**2)
                    
                    # Sanity check para hand_scale
                    if hand_scale < 50:
                        hand_scale = min(width_px, height_px) * 0.25
                        
                    # Factores de proporción de uñas estables respecto a la escala de la mano
                    # (Tip, Joint, width_factor, length_factor)
                    fingers = [
                        (4, 3, 0.26, 0.34),   # Pulgar
                        (8, 7, 0.20, 0.26),   # Índice
                        (12, 11, 0.21, 0.28), # Medio
                        (16, 15, 0.20, 0.26),  # Anular
                        (20, 19, 0.16, 0.21)  # Meñique
                    ]
                    
                    for tip_idx, joint_idx, w_f, l_f in fingers:
                        tip_lm = hand_landmarks.landmark[tip_idx]
                        joint_lm = hand_landmarks.landmark[joint_idx]
                        
                        tx, ty = tip_lm.x * width_px, tip_lm.y * height_px
                        jx, jy = joint_lm.x * width_px, joint_lm.y * height_px
                        
                        # Vector de orientación
                        vx, vy = tx - jx, ty - jy
                        v_len = math.sqrt(vx**2 + vy**2)
                        
                        if v_len == 0:
                            ux, uy = (0, -1)
                        else:
                            ux, uy = vx / v_len, vy / v_len
                        
                        px, py = -uy, ux  # Vector perpendicular
                        
                        # Corrección de escorzo (foreshortening) 3D basado en la flexión del dedo
                        flatness = v_len / hand_scale
                        foreshortening_factor = min(1.0, 0.35 + flatness * 1.5)
                        
                        # Dimensiones estables basadas en la escala general de la mano
                        nail_w = hand_scale * w_f
                        nail_l = hand_scale * l_f * foreshortening_factor
                        
                        # Desplazamiento dinámico hacia atrás de la uña (más flexión = menos desplazamiento)
                        shift_ratio = min(0.42, flatness * 0.75)
                        cx = tx - ux * (nail_l * shift_ratio)
                        cy = ty - uy * (nail_l * shift_ratio)
                        
                        # Generar puntos del contorno suave
                        pts = get_smooth_nail_points((cx, cy), ux, uy, px, py, shape, nail_w, nail_l)
                        
                        # Dibujar uña con efectos 3D
                        apply_finish_effects(draw, pts, color_rgb, finish)
                        
        if not hands_detected:
            print("⚠️ Mano no detectada por MediaPipe. Aplicando plantilla centrada.")
            estimated_nails = estimate_nails_from_image(np.array(original_img.convert("RGB")))
            for cx, cy, vx, vy, nw, nl in estimated_nails:
                v_len = math.sqrt(vx**2 + vy**2)
                ux, uy = (vx / v_len, vy / v_len) if v_len > 0 else (0, -1)
                px, py = -uy, ux
                pts = get_smooth_nail_points((cx, cy), ux, uy, px, py, shape, nw, nl)
                apply_finish_effects(draw, pts, color_rgb, finish)
        
        # Suavizar levemente los bordes de la capa de pintura para un fundido natural
        nail_layer_blurred = nail_layer.filter(ImageFilter.GaussianBlur(radius=0.5))
        
        # Combinar
        final_img = Image.alpha_composite(original_img, nail_layer_blurred)
        
        # Guardar resultado final
        final_img.convert("RGB").save(output_path, "JPEG", quality=85)
        print(f"✅ Prueba virtual completada con éxito. Archivo guardado en {output_path}")
        return True
        
    except Exception as e:
        print(f"❌ Error en process_nail_tryon: {e}")
        import traceback
        traceback.print_exc()
        raise e
