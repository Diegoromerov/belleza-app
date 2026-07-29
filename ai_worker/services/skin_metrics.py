import numpy as np
from PIL import Image
from models import SkinMetricsResponse

class SkinMetricsService:
    @staticmethod
    def analyze_skin_metrics(image: Image.Image) -> SkinMetricsResponse:
        """
        Calcula métricas de textura, densidad de poros e hidratación a partir de análisis de gradiente de la imagen.
        """
        img_gray = np.array(image.convert("L"))
        
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
