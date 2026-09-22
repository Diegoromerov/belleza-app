"""Métricas de piel/región derivadas de señal de imagen.

Todas las cifras de este módulo son PROXIES calculados con estadística de
píxeles (magnitud media del gradiente, desviación de luminancia, proporción de
píxeles especulares). NO son mediciones clínicas ni dermatológicas: no hay
modelo entrenado ni calibración instrumentada. Las fórmulas están documentadas
en cada método para que cualquiera pueda auditar de dónde sale cada número.
"""

import numpy as np
from PIL import Image
from models import SkinMetricsResponse


class SkinMetricsService:
    @staticmethod
    def raw_image_signals(image: Image.Image) -> dict:
        """Señales crudas de imagen (una sola pasada, reutilizables por región).

        Fórmulas (todas sobre la imagen convertida a RGB/L/HSV, escala 0-255):

        - ``tono_medio_rgb``  = media por canal:  mean(R), mean(G), mean(B)
        - ``luminancia_media`` = 100 * mean(L) / 255
        - ``saturacion_media`` = 100 * mean(S) / 255
        - ``contraste_luminancia`` = 100 * std(L) / 255
        - ``temperatura_cromatica`` = mean(R) / (mean(B) + 1e-6)   (>1 = cálido)
        - ``rugosidad_textura`` = mean( sqrt(dL/dx^2 + dL/dy^2) )  (gradiente de L)
        - ``especular_ratio`` = fracción de píxeles con L >= 0.85*255 y S <= 0.25*255
          (proxy de brillo/superficie especular)
        - ``claro_neutro_ratio`` = fracción de píxeles con L >= 0.65*255 y S <= 0.20*255
          (proxy de zonas claras desaturadas, p. ej. canas o despigmentación)
        - ``ratio_piel`` = fracción de píxeles dentro del rango de piel en YCbCr:
          Cb en [77, 127] y Cr en [133, 173], con
          Cb = 128 - 0.168736*R - 0.331264*G + 0.5*B,
          Cr = 128 + 0.5*R - 0.418688*G - 0.081312*B
          (regla estándar de detección de piel; se usa como puerta de calidad,
          no como diagnóstico).
        """
        rgb = np.asarray(image.convert("RGB"), dtype=np.float64)
        if rgb.ndim != 3 or rgb.shape[2] != 3 or rgb.size == 0:
            raise ValueError("Imagen RGB vacía o con dimensiones inesperadas.")

        gray = np.asarray(image.convert("L"), dtype=np.float64)
        sat = np.asarray(image.convert("HSV"), dtype=np.float64)[..., 1]

        gy, gx = np.gradient(gray)
        grad_magnitude = np.sqrt(gx ** 2 + gy ** 2)

        r_ch = rgb[..., 0]
        g_ch = rgb[..., 1]
        b_ch = rgb[..., 2]

        luma_norm = gray / 255.0
        sat_norm = sat / 255.0

        especular = (luma_norm >= 0.85) & (sat_norm <= 0.25)
        claro_neutro = (luma_norm >= 0.65) & (sat_norm <= 0.20)

        cb = 128.0 - 0.168736 * r_ch - 0.331264 * g_ch + 0.5 * b_ch
        cr = 128.0 + 0.5 * r_ch - 0.418688 * g_ch - 0.081312 * b_ch
        piel = (cb >= 77.0) & (cb <= 127.0) & (cr >= 133.0) & (cr <= 173.0)

        return {
            "tono_medio_rgb": [int(round(float(rgb[..., i].mean()))) for i in range(3)],
            "luminancia_media": round(float(luma_norm.mean()) * 100.0, 2),
            "saturacion_media": round(float(sat_norm.mean()) * 100.0, 2),
            "contraste_luminancia": round(float(luma_norm.std()) * 100.0, 2),
            "temperatura_cromatica": round(
                float(r_ch.mean()) / (float(b_ch.mean()) + 1e-6), 4
            ),
            "rugosidad_textura": round(float(grad_magnitude.mean()), 4),
            "especular_ratio": round(float(especular.mean()), 4),
            "claro_neutro_ratio": round(float(claro_neutro.mean()), 4),
            "ratio_piel": round(float(piel.mean()), 4),
        }

    @staticmethod
    def analyze_skin_metrics(image: Image.Image) -> SkinMetricsResponse:
        """
        Calcula métricas de textura, densidad de poros e hidratación a partir de
        análisis de gradiente de la imagen.

        Proxies (imagen en grises L, gradiente g = |grad L|, textura = mean(g),
        dispersion = std(L)):

        - ``pore_density_score``     = clamp(textura / 25.0, 0.10, 0.85)
        - ``hydration_score``        = clamp(1.0 - textura / 35.0, 0.60, 0.95)
          (menos micro-relieve => aspecto más liso/hidratado; banda acotada por diseño)
        - ``sebum_balance_score``    = clamp(0.75 + std(L) / 250.0, 0.50, 0.92)
        - ``elasticity_score``       = clamp(0.6*hidratación + 0.4*sebo, 0.70, 0.96)

        Son estimaciones de textura sobre la señal disponible, no mediciones
        instrumentales de hidratación/sebo.
        """
        img_gray = np.array(image.convert("L"))
        if img_gray.size == 0:
            raise ValueError("Imagen vacía: no se pueden calcular métricas de piel.")

        # Calcular varianza del laplaciano para textura/poros
        gradient_x, gradient_y = np.gradient(img_gray.astype(float))
        gradient_magnitude = np.sqrt(gradient_x**2 + gradient_y**2)
        mean_texture = np.mean(gradient_magnitude)

        # Normalización de puntajes entre 0.0 y 1.0
        pore_density = min(max(mean_texture / 25.0, 0.10), 0.85)
        hydration = min(max(1.0 - (mean_texture / 35.0), 0.60), 0.95)
        sebum_balance = min(max(0.75 + (np.std(img_gray) / 250.0), 0.50), 0.92)
        elasticity = min(max((hydration * 0.6) + (sebum_balance * 0.4), 0.70), 0.96)

        return SkinMetricsResponse(
            hydration_score=round(float(hydration), 2),
            pore_density_score=round(float(pore_density), 2),
            sebum_balance_score=round(float(sebum_balance), 2),
            elasticity_score=round(float(elasticity), 2),
            detailed_metrics={
                "poros": round(float(pore_density), 2),
                "hidratacion": round(float(hydration), 2),
                "sebo": round(float(sebum_balance), 2),
                "elasticidad": round(float(elasticity), 2),
            },
        )
