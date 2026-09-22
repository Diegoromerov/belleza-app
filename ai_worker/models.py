"""Modelos Pydantic del ai_worker.

Contrato de ``POST /api/v1/beauty-scan``
----------------------------------------
Request (``multipart/form-data``):
    - ``face_frontal``  archivo requerido (rostro de frente)
    - ``face_lateral``  archivo requerido (rostro de perfil)
    - ``hair``          archivo requerido (cabello)
    - ``hand``          archivo requerido (mano)
    - ``user_id``       texto opcional

Response 200 (``BeautyScanResponse``):
    ``face``, ``face_lateral``, ``hair``, ``hands`` con valores **derivados de
    señal de imagen** (media/desviación de canales, gradiente, proporción de
    especulares, rango de piel en YCbCr), más ``metodo`` (fórmula aplicada por
    métrica) y ``no_medido`` (campos que el worker NO puede medir, con motivo).

Errores:
    - 422 si falta alguno de los 4 archivos (validación automática de FastAPI).
    - 422 si la imagen está corrupta/no decodificable.
    - 422 si la imagen de rostro o de mano no contiene región de piel detectable.
    - 422 si la imagen es un plano uniforme (sin contenido analizable).
    - 500 solo para fallos inesperados del propio worker.

Ningún campo se rellena con constantes clínicas: lo que no se puede medir sin
modelo dermatológico/capilar se declara en ``no_medido`` en lugar de inventarse.
"""

from pydantic import BaseModel
from typing import Dict, List, Optional


class ScanRequest(BaseModel):
    """Request legacy de ``POST /api/v1/analyze-skin`` (imagen única en base64)."""

    image_base64: str


class BiometricResult(BaseModel):
    """Respuesta legacy de ``POST /api/v1/analyze-skin``.

    ``hidratacion``/``sebo``/``poros``/``elasticidad`` son PROXIES de textura
    calculados con ``services.skin_metrics`` (ver campo ``metodo``), no
    mediciones clínicas. Son ``Optional`` para poder declararlos como no
    medidos en lugar de devolver un número fabricado.
    """

    subtono: float
    estacion: str
    paleta: List[str]
    hidratacion: Optional[float] = None
    sebo: Optional[float] = None
    poros: Optional[float] = None
    elasticidad: Optional[float] = None
    warmth_ratio: Optional[float] = None
    mensaje_aura: str
    metodo: Optional[Dict[str, str]] = None
    no_medido: Optional[List["NoMedido"]] = None


class SkinMetricsResponse(BaseModel):
    """Salida de ``services.skin_metrics.SkinMetricsService.analyze_skin_metrics``.

    Scores normalizados 0.0-1.0 derivados del gradiente y la dispersión de
    luminancia de la imagen (proxies de textura, no mediciones instrumentales).
    """

    hydration_score: float
    pore_density_score: float
    sebum_balance_score: float
    elasticity_score: float
    detailed_metrics: Dict[str, float]


class NoMedido(BaseModel):
    """Campo clínico que el worker NO puede medir, con el motivo explícito."""

    campo: str
    motivo: str


class RegionSignals(BaseModel):
    """Señales de imagen medidas sobre el encuadre completo de una región."""

    tono_medio_rgb: List[int]
    luminancia_media: float
    saturacion_media: float
    contraste_luminancia: float
    temperatura_cromatica: float
    rugosidad_textura: float
    ratio_piel: float


class FaceAnalysis(RegionSignals):
    """Rostro frontal: subtono/estación + proxies de piel."""

    subtono: float
    estacion: str
    paleta: List[str]
    mensaje_aura: str
    hidratacion: float
    sebo: float
    poros: float
    elasticidad: float
    warmth_ratio: float
    metodo: Dict[str, str]


class FaceLateralAnalysis(RegionSignals):
    """Rostro lateral: solo señales de imagen (el perfil morfológico no se mide)."""

    metodo: Dict[str, str]


class HairAnalysis(RegionSignals):
    """Cabello: señales medidas sobre el encuadre completo del cabello."""

    brillo_capilar: float
    cobertura_canas_estimada: float
    contraste_textura: float
    metodo: Dict[str, str]


class HandAnalysis(RegionSignals):
    """Mano: señales medidas sobre el encuadre completo de la mano."""

    rojez: float
    hidratacion_proxy: float
    metodo: Dict[str, str]


class BeautyScanResponse(BaseModel):
    """Respuesta de ``POST /api/v1/beauty-scan`` (4 imágenes multipart)."""

    user_id: Optional[str] = None
    estado: str
    alcance: str
    face: FaceAnalysis
    face_lateral: FaceLateralAnalysis
    hair: HairAnalysis
    hands: HandAnalysis
    metodo_global: str
    no_medido: List[NoMedido]
