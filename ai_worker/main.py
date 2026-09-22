"""GlowApp AI Worker & Aura Business Engine (FastAPI).

Endpoints:

- ``POST /api/v1/beauty-scan`` — escaneo biométrico 360. Multipart con 4 archivos
  requeridos (``face_frontal``, ``face_lateral``, ``hair``, ``hand``) + ``user_id``
  opcional. Responde 200 con métricas derivadas de señal de imagen y un campo
  explícito ``no_medido``; responde 4xx ante imagen corrupta, plano uniforme o
  encuadre sin piel detectable. Documentado también en OpenAPI (docstring +
  ``responses`` + modelos de ``models.py``).
- ``POST /api/v1/analyze-skin`` — análisis de una sola imagen base64 (contrato
  legacy, mantenido). Ya no devuelve diagnósticos sintéticos: los errores de
  imagen se propagan como 4xx.
- ``POST /v1/ai/consult`` — respuestas del motor Aura (sin cambios).
"""

import logging
import os
from typing import Optional

from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from models import (
    BiometricResult,
    BeautyScanResponse,
    ScanRequest,
)
from services.color_analysis import (
    SkinAnalysisError,
    analyze_face,
    analyze_face_lateral,
    analyze_hands,
    analyze_hair,
    analyze_skin,
    build_scan_response,
    decode_image_bytes,
)

logger = logging.getLogger("ai_worker")

app = FastAPI(title="GlowApp AI Worker & Aura Business Engine")

# --- CORS ---------------------------------------------------------------------
# El navegador RECHAZA la combinación allow_origins=['*'] + allow_credentials=True.
# Se usa una lista explícita (configurable por AI_WORKER_CORS_ORIGINS, CSV) y, si
# alguien fuerza '*', se desactivan las credenciales para mantener la combinación
# válida en vez de dejar una política que el navegador descarta.
DEFAULT_ALLOWED_ORIGINS = [
    "http://localhost:3000",
    "http://localhost:8080",
    "http://127.0.0.1:3000",
    "http://127.0.0.1:8080",
    "https://glowapp.co",
    "https://app.glowapp.co",
    "https://admin.glowapp.co",
]


def _resolve_cors(raw_origins: Optional[str]):
    """Devuelve (origins, allow_credentials) garantizando una combinación válida."""
    if raw_origins:
        origins = [o.strip() for o in raw_origins.split(",") if o.strip()]
    else:
        origins = list(DEFAULT_ALLOWED_ORIGINS)

    if "*" in origins:
        logger.warning(
            "AI_WORKER_CORS_ORIGINS contiene '*': se desactiva allow_credentials "
            "(combinación '*' + credentials la rechaza el navegador)."
        )
        return origins, False
    return origins, True


CORS_ALLOW_ORIGINS, CORS_ALLOW_CREDENTIALS = _resolve_cors(
    os.getenv("AI_WORKER_CORS_ORIGINS")
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=CORS_ALLOW_ORIGINS,
    allow_credentials=CORS_ALLOW_CREDENTIALS,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Tamaño máximo por archivo (4 archivos por escaneo). 413 si se supera.
MAX_UPLOAD_BYTES = int(os.getenv("AI_WORKER_MAX_UPLOAD_BYTES", str(15 * 1024 * 1024)))


class BusinessContext(BaseModel):
    business_id: Optional[str] = None
    vertical_id: Optional[str] = None
    lifecycle_stage: Optional[str] = None
    current_task_id: Optional[str] = None
    domain_context: Optional[str] = None


class AIConsultRequest(BaseModel):
    user_id: str
    prompt: str
    business_context: Optional[BusinessContext] = None


class AIConsultResponse(BaseModel):
    response: str
    citation: Optional[str] = None
    domain_context: Optional[str] = None
    suggested_action: Optional[str] = None


async def _read_upload(upload: UploadFile, etiqueta: str) -> bytes:
    """Lee un archivo del multipart con errores 4xx descriptivos."""
    data = await upload.read()
    if len(data) > MAX_UPLOAD_BYTES:
        raise HTTPException(
            status_code=413,
            detail=f"[{etiqueta}] Archivo de {len(data)} bytes supera el máximo "
            f"permitido ({MAX_UPLOAD_BYTES} bytes).",
        )
    if not data:
        raise HTTPException(status_code=400, detail=f"[{etiqueta}] Archivo vacío (0 bytes).")
    return data


def _decode_region(data: bytes, etiqueta: str):
    """Decodifica un archivo de región y añade contexto de región a los 4xx."""
    try:
        return decode_image_bytes(data)
    except SkinAnalysisError as exc:
        raise SkinAnalysisError(exc.status_code, f"[{etiqueta}] {exc.detail}") from exc


@app.post(
    "/api/v1/beauty-scan",
    response_model=BeautyScanResponse,
    summary="Escaneo biométrico 360 (rostro, perfil, cabello y manos)",
    response_description="Métricas derivadas de señal de imagen + campos no medidos",
    responses={
        400: {"description": "Archivo vacío o parámetro inválido"},
        413: {"description": "Archivo más grande que AI_WORKER_MAX_UPLOAD_BYTES"},
        422: {
            "description": (
                "Falta alguno de los 4 archivos requeridos, o la imagen está corrupta, "
                "es un plano uniforme, o no contiene región de piel detectable "
                "(rostro/mano)"
            )
        },
        500: {"description": "Fallo inesperado del worker"},
    },
)
async def beauty_scan_endpoint(
    face_frontal: UploadFile = File(..., description="Rostro de frente (JPEG/PNG/WEBP)"),
    face_lateral: UploadFile = File(..., description="Rostro de perfil (JPEG/PNG/WEBP)"),
    hair: UploadFile = File(..., description="Cabello (JPEG/PNG/WEBP)"),
    hand: UploadFile = File(..., description="Mano (JPEG/PNG/WEBP)"),
    user_id: Optional[str] = Form(None, description="ID de usuario (opcional)"),
):
    """Contrato ``multipart/form-data`` del escaneo biométrico.

    **Request**: los 4 campos de archivo ``face_frontal``, ``face_lateral``,
    ``hair`` y ``hand`` (todos requeridos, ``maxCount 1`` cada uno según el proxy
    ``backend/src/routes/v1/beautyScanRoutes.js``) más ``user_id`` de texto.

    **Response 200** (``BeautyScanResponse``): ``face`` (subtono/estación/paleta +
    proxies de hidratación, sebo, poros, elasticidad), ``face_lateral``, ``hair``
    (tono medio, brillo especular, cobertura clara estimada, contraste de
    textura) y ``hands`` (rojez, rugosidad, hidratación proxy, ratio de piel).
    Cada bloque trae ``metodo`` con la fórmula usada y la respuesta trae
    ``no_medido`` con los campos clínicos que este worker NO puede medir.

    **Errores**: 422 si falta un archivo (validación FastAPI), si la imagen está
    corrupta/no decodificable, si es un plano uniforme o si no se detecta la
    región de piel esperada; 400 archivo vacío; 413 archivo demasiado grande.
    Nunca se devuelve un diagnóstico sintético con 200.
    """
    try:
        face_frontal_bytes = await _read_upload(face_frontal, "face_frontal")
        face_lateral_bytes = await _read_upload(face_lateral, "face_lateral")
        hair_bytes = await _read_upload(hair, "hair")
        hand_bytes = await _read_upload(hand, "hand")

        face = analyze_face(_decode_region(face_frontal_bytes, "face_frontal"))
        face_lateral_result = analyze_face_lateral(
            _decode_region(face_lateral_bytes, "face_lateral")
        )
        hair_result = analyze_hair(_decode_region(hair_bytes, "hair"))
        hands = analyze_hands(_decode_region(hand_bytes, "hand"))

        payload = build_scan_response(user_id, face, face_lateral_result, hair_result, hands)
        return BeautyScanResponse(**payload)

    except SkinAnalysisError as exc:
        raise HTTPException(status_code=exc.status_code, detail=exc.detail) from exc
    except HTTPException:
        raise
    except Exception as exc:  # pragma: no cover - solo fallos inesperados
        logger.exception("Fallo inesperado en /api/v1/beauty-scan")
        raise HTTPException(
            status_code=500,
            detail=f"Error inesperado en el escaneo biométrico: {exc}",
        ) from exc


@app.post(
    "/api/v1/analyze-skin",
    response_model=BiometricResult,
    summary="Análisis de una imagen facial en base64 (contrato legacy)",
    responses={
        400: {"description": "image_base64 ausente, vacío o mal formado"},
        422: {"description": "Imagen corrupta, plano uniforme o sin rostro detectable"},
        500: {"description": "Fallo inesperado del worker"},
    },
)
async def analyze_skin_endpoint(request: ScanRequest):
    """Analiza una imagen facial base64 y devuelve colorimetría + proxies de textura.

    Los errores de imagen se propagan como 4xx (antes se convertían en 500 y, en
    la capa de análisis, en un diagnóstico sintético con 200).
    """
    try:
        result = analyze_skin(request.image_base64)
        return BiometricResult(**result)
    except SkinAnalysisError as exc:
        raise HTTPException(status_code=exc.status_code, detail=exc.detail) from exc
    except Exception as exc:  # pragma: no cover - solo fallos inesperados
        logger.exception("Fallo inesperado en /api/v1/analyze-skin")
        raise HTTPException(
            status_code=500, detail=f"Error en el análisis IA: {exc}"
        ) from exc


@app.post("/v1/ai/consult", response_model=AIConsultResponse)
async def ai_consult_endpoint(request: AIConsultRequest):
    try:
        ctx = request.business_context
        prompt_lower = request.prompt.lower()

        # Contextual response resolution
        if ctx and ctx.domain_context == 'SANITARY' or 'sanitar' in prompt_lower or 'residu' in prompt_lower:
            return AIConsultResponse(
                response="Para cumplir con el protocolo sanitario en tu salón, debes implementar el plan de gestión RH1 con guardián rojo para cortopunzantes y desinfección en autoclave o glutaraldehído al 2%.",
                citation="Resolución 2827 de 2006 / Ministerio de Salud",
                domain_context="SANITARY",
                suggested_action="Generar Manual de Bioseguridad RH1"
            )
        elif ctx and ctx.domain_context == 'LABOR' or 'contrat' in prompt_lower or 'emplead' in prompt_lower:
            return AIConsultResponse(
                response="La contratación de barberos o estilistas requiere formalización con vinculación a ARL, EPS y Fondo de Pensiones para garantizar seguridad social.",
                citation="Código Sustantivo del Trabajo / Ley 1258",
                domain_context="LABOR",
                suggested_action="Generar Borrador de Contrato Laboral"
            )
        else:
            return AIConsultResponse(
                response=f"Como asistente Aura de GlowApp, he analizado tu consulta sobre '{request.prompt}'. Te sugiero avanzar al siguiente paso de tu plan de negocio.",
                citation="Guía Máster GlowApp Business Engine",
                domain_context=ctx.domain_context if ctx else "GENERAL",
                suggested_action="Revisar Tareas Pendientes"
            )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error en consulta Aura AI: {str(e)}")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
