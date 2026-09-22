"""Test de contrato de ``POST /api/v1/beauty-scan`` (y del legacy analyze-skin).

Verifica:
  1. Los 4 campos multipart exigidos por el proxy
     ``backend/src/routes/v1/beautyScanRoutes.js`` son aceptados
     (``face_frontal``, ``face_lateral``, ``hair``, ``hand``) + ``user_id``.
  2. La respuesta trae métricas REALMENTE derivadas de cabello y manos, con
     ``metodo`` y un campo explícito ``no_medido``.
  3. Ya no aparece ningún valor clínico fabricado (regresión de los literales
     85.5 / 40.2 que se devolvían para cualquier imagen).
  4. Una imagen corrupta devuelve 4xx (no 200 con diagnóstico sintético).
  5. Falta un archivo => 422; imagen uniforme/sin piel => 422.

Ejecutable de dos formas:
  - pytest:            ``python -m pytest ai_worker -q``
  - sin pytest:        ``python ai_worker/tests/test_beauty_scan_contract.py``
    (usa TestClient de FastAPI directamente, sin dependencias de pytest)

Este archivo no depende de pytest para importarse, por eso no lo importa en
nivel de módulo: en este entorno pytest no está instalado para el intérprete
que sí tiene fastapi/httpx/pillow/numpy.
"""

import base64
import io
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from fastapi.testclient import TestClient

# main.py importa ``models`` / ``services`` como paquetes de nivel raíz del
# worker (así corre en el contenedor: WORKDIR /app + uvicorn main:app).
AI_WORKER_DIR = Path(__file__).resolve().parents[1]
if str(AI_WORKER_DIR) not in sys.path:
    sys.path.insert(0, str(AI_WORKER_DIR))

from main import app  # noqa: E402

client = TestClient(app)

# Literales que se devolvían para CUALQUIER imagen antes de la remediación.
LITERALES_FABRICADOS = (85.5, 40.2)


def _image_bytes(rgb_base, width=96, height=96, noise=14.0, seed=7, gradient=25.0,
                 bright_ratio=0.0) -> bytes:
    """JPEG sintético: color base + ruido + gradiente horizontal.

    El ruido y el gradiente garantizan textura/contraste real para que las
    métricas de imagen (gradiente, luminancia, especulares) sean medibles.
    ``bright_ratio`` pinta una fracción de píxeles casi blancos y desaturados
    (proxy de la señal que se usa para la cobertura clara del cabello).
    """
    rng = np.random.default_rng(seed)
    h, w = height, width
    img = np.zeros((h, w, 3), dtype=np.float64)
    for canal, valor in enumerate(rgb_base):
        img[..., canal] = float(valor)
    img += rng.normal(0.0, noise, img.shape)
    ramp = np.linspace(-gradient, gradient, w)[None, :, None]
    img += ramp
    if bright_ratio > 0:
        n = int(round(bright_ratio * h * w))
        idx = rng.choice(h * w, size=n, replace=False)
        flat = img.reshape(-1, 3)
        flat[idx] = 242.0
    arr = np.clip(img, 0, 255).astype(np.uint8)
    buf = io.BytesIO()
    Image.fromarray(arr).save(buf, format="JPEG", quality=95)
    return buf.getvalue()


def _face_jpeg(seed=7) -> bytes:
    """Piel en rango YCbCr (Cb~110, Cr~154)."""
    return _image_bytes((198, 150, 130), seed=seed)


def _hand_jpeg(seed=11) -> bytes:
    return _image_bytes((205, 148, 126), seed=seed, gradient=18.0)


def _hair_jpeg(seed=13) -> bytes:
    """Cabello oscuro con zonas claras desaturadas (proxy de canas)."""
    return _image_bytes((58, 42, 34), seed=seed, noise=22.0, bright_ratio=0.18)


def _files():
    return {
        "face_frontal": ("frontal.jpg", _face_jpeg(7), "image/jpeg"),
        "face_lateral": ("lateral.jpg", _face_jpeg(17), "image/jpeg"),
        "hair": ("hair.jpg", _hair_jpeg(13), "image/jpeg"),
        "hand": ("hand.jpg", _hand_jpeg(11), "image/jpeg"),
    }


def test_beauty_scan_acepta_los_4_campos_multipart():
    response = client.post("/api/v1/beauty-scan", files=_files(), data={"user_id": "user-test-1"})
    assert response.status_code == 200, response.text
    body = response.json()
    print("  status=200 user_id=", body["user_id"], "estado=", body["estado"])
    print("  bloques:", sorted(k for k in body if k in ("face", "face_lateral", "hair", "hands")))

    for bloque in ("face", "face_lateral", "hair", "hands"):
        assert bloque in body, f"falta el bloque {bloque}"
        assert "metodo" in body[bloque], f"{bloque} sin campo metodo"

    # metricas derivadas de cabello
    hair = body["hair"]
    print("  hair.brillo_capilar=", hair["brillo_capilar"],
          "hair.cobertura_canas_estimada=", hair["cobertura_canas_estimada"],
          "hair.tono_medio_rgb=", hair["tono_medio_rgb"])
    for campo in ("brillo_capilar", "cobertura_canas_estimada", "contraste_textura"):
        assert isinstance(hair[campo], (int, float)), f"hair.{campo} no numérico"
        assert 0.0 <= hair[campo] <= 100.0, f"hair.{campo} fuera de rango: {hair[campo]}"
    assert hair["cobertura_canas_estimada"] > 0.0, (
        "las zonas claras desaturadas del JPEG de cabello deben producir "
        "cobertura clara > 0 (metrica realmente derivada de la imagen)"
    )

    # metricas derivadas de manos
    hands = body["hands"]
    print("  hands.rojez=", hands["rojez"], "hands.hidratacion_proxy=", hands["hidratacion_proxy"],
          "hands.rugosidad_textura=", hands["rugosidad_textura"], "ratio_piel=", hands["ratio_piel"])
    assert isinstance(hands["rojez"], (int, float))
    assert 0.0 <= hands["hidratacion_proxy"] <= 100.0
    assert hands["ratio_piel"] > 0.05, "la mano sintética debe caer en rango de piel"

    # no se inventan valores: se declara lo no medido, con motivo
    assert isinstance(body["no_medido"], list) and body["no_medido"], "no_medido vacío"
    for item in body["no_medido"]:
        assert item.get("campo") and item.get("motivo"), f"entrada no_medido incompleta: {item}"
    print("  no_medido:", len(body["no_medido"]), "campos declarados")
    return body


def test_beauty_scan_no_devuelve_los_literales_fabricados():
    body = test_beauty_scan_acepta_los_4_campos_multipart()
    hidratacion = body["face"]["hidratacion"]
    sebo = body["face"]["sebo"]
    print("  face.hidratacion=", hidratacion, "face.sebo=", sebo,
          "face.subtono=", body["face"]["subtono"])
    for valor in (hidratacion, sebo):
        assert valor not in LITERALES_FABRICADOS, (
            f"valor clínico fabricado reintroducido: {valor}"
        )
    # dos imágenes distintas deben producir métricas distintas (no constantes)
    body_b = client.post(
        "/api/v1/beauty-scan",
        files={
            "face_frontal": ("frontal2.jpg", _image_bytes((170, 132, 120), noise=6.0, seed=3), "image/jpeg"),
            "face_lateral": ("lateral2.jpg", _face_jpeg(19), "image/jpeg"),
            "hair": ("hair2.jpg", _hair_jpeg(23), "image/jpeg"),
            "hand": ("hand2.jpg", _hand_jpeg(29), "image/jpeg"),
        },
    ).json()
    print("  hidratacion imagen A=", hidratacion, "imagen B=", body_b["face"]["hidratacion"])
    assert body_b["face"]["hidratacion"] != hidratacion or body_b["face"]["subtono"] != body["face"]["subtono"], (
        "dos imagenes distintas produjeron exactamente las mismas metricas"
    )


def test_beauty_scan_imagen_corrupta_devuelve_4xx():
    files = _files()
    files["hair"] = ("hair.jpg", b"esto-no-es-una-imagen", "image/jpeg")
    response = client.post("/api/v1/beauty-scan", files=files)
    print("  status=", response.status_code, "detail=", response.json().get("detail"))
    assert 400 <= response.status_code < 500, f"se esperaba 4xx, se obtuvo {response.status_code}"
    assert "[hair]" in response.json().get("detail", ""), "el error no identifica la region"


def test_beauty_scan_imagen_sin_rostro_devuelve_4xx():
    plano = _image_bytes((128, 128, 128), noise=0.0, gradient=0.0, seed=5)  # plano uniforme
    files = _files()
    files["face_frontal"] = ("frontal.jpg", plano, "image/jpeg")
    response = client.post("/api/v1/beauty-scan", files=files)
    print("  status=", response.status_code, "detail=", response.json().get("detail"))
    assert 400 <= response.status_code < 500, f"se esperaba 4xx, se obtuvo {response.status_code}"

    sin_piel = _image_bytes((40, 90, 60), noise=10.0, seed=9)  # verde vegetacion: no es piel
    files["face_frontal"] = ("frontal.jpg", sin_piel, "image/jpeg")
    response2 = client.post("/api/v1/beauty-scan", files=files)
    print("  status sin_piel=", response2.status_code, "detail=", response2.json().get("detail"))
    assert 400 <= response2.status_code < 500


def test_beauty_scan_falta_un_archivo_devuelve_422():
    files = _files()
    files.pop("hand")
    response = client.post("/api/v1/beauty-scan", files=files)
    print("  status=", response.status_code)
    assert response.status_code == 422, f"se esperaba 422, se obtuvo {response.status_code}"


def test_analyze_skin_legacy_sigue_funcionando():
    payload = base64.b64encode(_face_jpeg(31)).decode("ascii")
    response = client.post("/api/v1/analyze-skin", json={"image_base64": payload})
    print("  status=", response.status_code, "body=", response.json())
    assert response.status_code == 200, response.text
    body = response.json()
    assert body["estacion"] in ("Otoño Cálido", "Verano Fresco")
    assert body["hidratacion"] not in LITERALES_FABRICADOS
    assert body["sebo"] not in LITERALES_FABRICADOS
    assert body["metodo"], "falta el campo metodo con las formulas aplicadas"
    assert body["no_medido"], "falta el campo explicito de no medido"


def test_analyze_skin_corrupto_devuelve_4xx():
    payload = base64.b64encode(b"no-soy-una-imagen").decode("ascii")
    response = client.post("/api/v1/analyze-skin", json={"image_base64": payload})
    print("  status=", response.status_code, "detail=", response.json().get("detail"))
    assert 400 <= response.status_code < 500
    assert response.json().get("detail")


if __name__ == "__main__":
    import traceback

    tests = [(n, f) for n, f in sorted(globals().items())
             if n.startswith("test_") and callable(f)]
    fallos = 0
    for nombre, fn in tests:
        print(f"--- {nombre}")
        try:
            fn()
            print(f"PASS {nombre}")
        except Exception:
            fallos += 1
            print(f"FAIL {nombre}")
            traceback.print_exc()
    print(f"RESULTADO: {len(tests) - fallos}/{len(tests)} tests OK")
    raise SystemExit(1 if fallos else 0)
