"""Análisis de colorimetría / piel / cabello / manos desde señal de imagen.

Principios de este módulo (remediación auditoría 360):

1. Ningún valor clínico se devuelve como literal fijo: cada número sale de una
   estadística de píxeles documentada en ``services.skin_metrics`` o aquí abajo.
2. Lo que no se puede medir sin un modelo de segmentación/dermatología
   (daño capilar, tipo de onda, uñas, manchas solares, edad aparente,
   morfología del perfil) NO se estima: se declara con
   ``no_medido(campo, motivo)`` y el campo numérico simplemente no existe.
3. Una imagen corrupta, un plano uniforme o un encuadre sin piel detectable
   produce ``SkinAnalysisError`` con código HTTP 4xx (nunca un diagnóstico
   sintético con 200).

Fórmulas de subtono (imagen RGB, escala 0-255):

- ``canal_medio``  = mean(R), mean(G), mean(B)
- ``warmth_index`` = (mean(R) - mean(B)) / (mean(R) + mean(B) + 1e-6)  -> [-1, 1]
- ``subtono``      = clamp((warmth_index + 0.5) * 100, 0, 100)
  Índice normalizado de calidez cromática (0 = frío máximo, 100 = cálido máximo).
  NO es un porcentaje de certeza diagnóstica.
- ``warmth_ratio`` = mean(R) / (mean(G) + 0.01)  -> umbral de estación > 1.1
  (regla de estación existente, sin cambios).

Puertas de calidad (umbrales configurables por entorno):

- ``BEAUTY_SCAN_MIN_FACE_SKIN_RATIO`` (default 0.05): fracción mínima de píxeles
  en rango de piel YCbCr para aceptar la foto como rostro.
- ``BEAUTY_SCAN_MIN_HAND_SKIN_RATIO`` (default 0.05): igual para la foto de mano.
- ``BEAUTY_SCAN_MIN_CONTRAST`` (default 2.0): desviación mínima de luminancia
  (escala 0-100) para descartar planos uniformes / imágenes sin contenido.
"""

import base64
import binascii
import io
import os

import numpy as np
from PIL import Image, UnidentifiedImageError

from services.skin_metrics import SkinMetricsService

# --- Umbrales de calidad (heurísticos, documentados y configurables) ---
MIN_FACE_SKIN_RATIO = float(os.getenv("BEAUTY_SCAN_MIN_FACE_SKIN_RATIO", "0.05"))
MIN_HAND_SKIN_RATIO = float(os.getenv("BEAUTY_SCAN_MIN_HAND_SKIN_RATIO", "0.05"))
MIN_CONTRAST = float(os.getenv("BEAUTY_SCAN_MIN_CONTRAST", "2.0"))

# --- Paletas por estación (constantes de diseño, no métricas clínicas) ---
PALETA_OTONO_CALIDO = ["#C89D93", "#D4AF7A", "#8B5E3C", "#E8B4A0"]
PALETA_VERANO_FRESCO = ["#A0C4FF", "#BDB2FF", "#FFC6FF", "#FDFFB6"]

ALCANCE = "estadistica_pixeles_sobre_encuadre_completo_sin_segmentacion"

METODO_GLOBAL = (
    "Proxies de señal de imagen: medias de canal RGB, luminancia/saturación "
    "(L/HSV), desviación de luminancia, magnitud media del gradiente, fracción "
    "de píxeles especulares (L>=217 y S<=64) y fracción de piel en YCbCr "
    "(Cb 77-127, Cr 133-173). Sin modelo entrenado ni calibración clínica."
)

# Definición única de todos los campos que este worker NO puede medir hoy.
NO_MEDIDO_CAMPOS = (
    ("hair.tipo_de_onda", "Requiere segmentación de cabello y clasificación de patrón de rizo (no hay modelo en ai_worker)."),
    ("hair.danio_estructural", "Requiere modelo capilar entrenado (porosidad/cutícula); no disponible en ai_worker."),
    ("hair.densidad_folicular", "Requiere segmentación de cuero cabelludo; no disponible en ai_worker."),
    ("hands.manchas_solares", "Requiere clasificación dermatológica de lesiones; no disponible en ai_worker."),
    ("hands.cuticulas", "Requiere segmentación de cutícula/lámina ungueal; no disponible en ai_worker."),
    ("hands.unas", "Requiere segmentación y clasificación de uñas; no disponible en ai_worker."),
    ("hands.edad_aparente", "Requiere modelo de edad dermatológica; no disponible en ai_worker."),
    ("face_lateral.perfil_morfologico", "Requiere landmarks faciales/malla 3D; no disponible en ai_worker."),
    ("face.wrinkles", "Requiere modelo de arrugas (no se infiere de textura global sin segmentación por zona)."),
    ("face.spots", "Requiere detección de lesiones/manchas por zona; no disponible en ai_worker."),
    ("face.bioAge", "Requiere modelo de edad biológica facial; no disponible en ai_worker."),
)


class SkinAnalysisError(ValueError):
    """Error de entrada/calidad de imagen, mapeable a un HTTP 4xx.

    ``status_code`` va entre 400 y 422 para que el handler de FastAPI lo
    propague tal cual (nunca se convierte en un 200 con datos sintéticos).
    """

    def __init__(self, status_code: int, detail: str):
        super().__init__(detail)
        self.status_code = status_code
        self.detail = detail


def no_medido_list(regiones=None) -> list:
    """Campos no medidos por el worker (opcionalmente filtrados por prefijo)."""
    if regiones is None:
        return [{"campo": campo, "motivo": motivo} for campo, motivo in NO_MEDIDO_CAMPOS]
    prefijos = tuple(f"{r}." for r in regiones)
    return [
        {"campo": campo, "motivo": motivo}
        for campo, motivo in NO_MEDIDO_CAMPOS
        if campo.startswith(prefijos)
    ]


def decode_image_bytes(data: bytes) -> np.ndarray:
    """bytes -> np.ndarray RGB (uint8).

    Imagen vacía, truncada, no reconocible o ilegible => SkinAnalysisError(422).
    No hay fallback: la alternativa era un diagnóstico inventado con HTTP 200.
    """
    if not data:
        raise SkinAnalysisError(422, "Archivo de imagen vacío (0 bytes).")
    try:
        image = Image.open(io.BytesIO(data))
        image.load()
        image = image.convert("RGB")
    except (UnidentifiedImageError, OSError, ValueError) as exc:
        raise SkinAnalysisError(
            422,
            f"Imagen corrupta o no decodificable ({type(exc).__name__}: {exc}). "
            "Se requiere JPEG/PNG/WEBP válido.",
        ) from exc

    arr = np.asarray(image, dtype=np.uint8)
    if arr.ndim != 3 or arr.shape[2] != 3 or arr.size == 0:
        raise SkinAnalysisError(422, "Imagen decodificada sin píxeles utilizables.")
    return arr


def decode_base64_image(image_base64: str) -> np.ndarray:
    """base64 (con o sin prefijo data URI) -> np.ndarray RGB."""
    if not isinstance(image_base64, str) or not image_base64.strip():
        raise SkinAnalysisError(400, "El campo image_base64 es obligatorio y no puede estar vacío.")

    payload = image_base64.split(",", 1)[1] if "," in image_base64 else image_base64
    payload = "".join(payload.split())
    payload += "=" * (-len(payload) % 4)
    try:
        data = base64.b64decode(payload, validate=False)
    except (binascii.Error, ValueError) as exc:
        raise SkinAnalysisError(400, f"image_base64 inválido: {exc}") from exc
    return decode_image_bytes(data)


def _signals(arr: np.ndarray) -> dict:
    """Señales de imagen documentadas (delegadas a services.skin_metrics)."""
    return SkinMetricsService.raw_image_signals(Image.fromarray(arr))


def _require_analizable(arr: np.ndarray, etiqueta: str) -> dict:
    """Rechaza planos uniformes (sin contenido) — 422."""
    signals = _signals(arr)
    if signals["contraste_luminancia"] < MIN_CONTRAST:
        raise SkinAnalysisError(
            422,
            f"La imagen de {etiqueta} no tiene contenido analizable "
            f"(contraste de luminancia {signals['contraste_luminancia']} < mínimo {MIN_CONTRAST}).",
        )
    return signals


def _require_piel(signals: dict, etiqueta: str, minimo: float) -> None:
    """Rechaza encuadres sin región de piel detectable — 422."""
    if signals["ratio_piel"] < minimo:
        raise SkinAnalysisError(
            422,
            f"No se detecta {etiqueta} en la imagen: proporción de píxeles en rango "
            f"de piel {signals['ratio_piel']} < mínimo exigido {minimo}. Recapture la foto "
            "con el rostro/mano centrado y buena iluminación.",
        )


def _base_signals_out(signals: dict) -> dict:
    return {
        "tono_medio_rgb": signals["tono_medio_rgb"],
        "luminancia_media": signals["luminancia_media"],
        "saturacion_media": signals["saturacion_media"],
        "contraste_luminancia": signals["contraste_luminancia"],
        "temperatura_cromatica": signals["temperatura_cromatica"],
        "rugosidad_textura": signals["rugosidad_textura"],
        "ratio_piel": signals["ratio_piel"],
    }


def analyze_face(arr: np.ndarray) -> dict:
    """Rostro frontal: subtono/estación (colorimetría) + proxies de textura.

    ``hidratacion``/``sebo``/``poros``/``elasticidad`` vienen de
    ``SkinMetricsService.analyze_skin_metrics`` (ver docstring de las fórmulas);
    antes eran literales fijos (85.5 / 40.2) iguales para toda imagen.
    """
    signals = _require_analizable(arr, "rostro")
    _require_piel(signals, "rostro", MIN_FACE_SKIN_RATIO)

    imagen = Image.fromarray(arr)
    metricas = SkinMetricsService.analyze_skin_metrics(imagen)

    r, g, b = [float(v) for v in signals["tono_medio_rgb"]]
    warmth_index = (r - b) / (r + b + 1e-6)
    subtono = min(max((warmth_index + 0.5) * 100.0, 0.0), 100.0)
    warmth_ratio = r / (g + 0.01)

    if warmth_ratio > 1.1:
        estacion = "Otoño Cálido"
        paleta = PALETA_OTONO_CALIDO
        mensaje = "Tu piel irradia la calidez de los Andes al atardecer."
    else:
        estacion = "Verano Fresco"
        paleta = PALETA_VERANO_FRESCO
        mensaje = "Tu piel tiene la luminosidad suave de la mañana bogotana."

    out = _base_signals_out(signals)
    out.update(
        {
            "subtono": round(subtono, 1),
            "estacion": estacion,
            "paleta": paleta,
            "mensaje_aura": mensaje,
            # proxies de textura escalados a 0-100 (bandas definidas en skin_metrics)
            "hidratacion": round(metricas.hydration_score * 100.0, 1),
            "sebo": round(metricas.sebum_balance_score * 100.0, 1),
            "poros": round(metricas.pore_density_score * 100.0, 1),
            "elasticidad": round(metricas.elasticity_score * 100.0, 1),
            "warmth_ratio": round(warmth_ratio, 4),
            "metodo": {
                "subtono": "clamp(((mean(R)-mean(B))/(mean(R)+mean(B)))+0.5)*100, 0, 100) sobre el encuadre",
                "warmth_ratio": "mean(R)/(mean(G)+0.01); >1.1 => Otoño Cálido, si no Verano Fresco",
                "hidratacion": "100 * clamp(1 - mean(|grad L|)/35, 0.60, 0.95) [proxy de micro-relieve]",
                "sebo": "100 * clamp(0.75 + std(L)/250, 0.50, 0.92) [proxy de dispersión de luminancia]",
                "poros": "100 * clamp(mean(|grad L|)/25, 0.10, 0.85) [proxy de rugosidad]",
                "elasticidad": "100 * clamp(0.6*hidratacion + 0.4*sebo, 0.70, 0.96)",
            },
        }
    )
    return out


def analyze_face_lateral(arr: np.ndarray) -> dict:
    """Rostro lateral: se miden señales de imagen; la morfología NO se mide."""
    signals = _require_analizable(arr, "rostro lateral")
    _require_piel(signals, "rostro lateral", MIN_FACE_SKIN_RATIO)

    out = _base_signals_out(signals)
    out["metodo"] = {
        "señales": "medias de canal, luminancia/saturación (L/HSV), std(L), gradiente medio y fracción de piel YCbCr sobre el encuadre",
        "perfil_morfologico": "no medido: requiere landmarks faciales/malla 3D",
    }
    return out


def analyze_hair(arr: np.ndarray) -> dict:
    """Cabello: brillo, cobertura clara (proxy de canas) y contraste de textura.

    El alcance es el encuadre completo (sin segmentación de cabello), por lo que
    cada valor se etiqueta como proxy del encuadre, no como medición capilar.
    """
    signals = _require_analizable(arr, "cabello")

    out = _base_signals_out(signals)
    out.update(
        {
            "brillo_capilar": round(signals["especular_ratio"] * 100.0, 2),
            "cobertura_canas_estimada": round(signals["claro_neutro_ratio"] * 100.0, 2),
            "contraste_textura": signals["contraste_luminancia"],
            "metodo": {
                "brillo_capilar": "100 * fracción de píxeles con L>=0.85*255 y S<=0.25*255 (especulares)",
                "cobertura_canas_estimada": "100 * fracción de píxeles con L>=0.65*255 y S<=0.20*255 (zonas claras desaturadas; proxy del encuadre, no conteo de cabellos blancos)",
                "contraste_textura": "100 * std(L)/255",
                "tono_medio_rgb": "media por canal RGB sobre el encuadre",
                "alcance": ALCANCE,
            },
        }
    )
    return out


def analyze_hands(arr: np.ndarray) -> dict:
    """Mano: rugosidad, rojez y proxy de hidratación sobre el encuadre."""
    signals = _require_analizable(arr, "mano")
    _require_piel(signals, "mano", MIN_HAND_SKIN_RATIO)

    metricas = SkinMetricsService.analyze_skin_metrics(Image.fromarray(arr))
    r = float(signals["tono_medio_rgb"][0])
    g = float(signals["tono_medio_rgb"][1])

    out = _base_signals_out(signals)
    out.update(
        {
            "rojez": round(r - g, 2),
            "hidratacion_proxy": round(metricas.hydration_score * 100.0, 1),
            "metodo": {
                "rojez": "mean(R) - mean(G) sobre el encuadre",
                "hidratacion_proxy": "100 * clamp(1 - mean(|grad L|)/35, 0.60, 0.95) [proxy de micro-relieve]",
                "rugosidad_textura": "mean(sqrt((dL/dx)^2+(dL/dy)^2))",
                "ratio_piel": "fracción de píxeles con Cb en [77,127] y Cr en [133,173]",
                "alcance": ALCANCE,
            },
        }
    )
    return out


def analyze_skin(image_base64: str) -> dict:
    """Compatibilidad legacy: ``POST /api/v1/analyze-skin`` (1 imagen base64).

    Devuelve el mismo bloque que ``analyze_face`` (incluye ``metodo`` y los
    proxies), y lanza ``SkinAnalysisError`` (4xx) si la imagen no es utilizable.
    """
    arr = decode_base64_image(image_base64)
    result = analyze_face(arr)
    result["no_medido"] = no_medido_list(["face"])
    return result


def build_scan_response(user_id, face, face_lateral, hair, hands) -> dict:
    """Ensambla la respuesta de ``POST /api/v1/beauty-scan``."""
    return {
        "user_id": str(user_id) if user_id is not None else None,
        "estado": "procesado",
        "alcance": ALCANCE,
        "face": face,
        "face_lateral": face_lateral,
        "hair": hair,
        "hands": hands,
        "metodo_global": METODO_GLOBAL,
        "no_medido": no_medido_list(),
    }
