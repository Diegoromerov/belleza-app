import os
import json
import time
import threading
import httpx
from urllib.parse import urlparse
from fastapi import FastAPI
import redis

from tryon_pipeline import process_nail_tryon

app = FastAPI(title="Belleza App AI Worker", version="1.0.0")

# Cargar configuración desde variables de entorno
REDIS_HOST = os.getenv("REDIS_HOST", "localhost")
REDIS_PORT = int(os.getenv("REDIS_PORT", 6379))
REDIS_QUEUE = "nail_tryon_queue"

# Determinar directorio de salida (uploads compartido con backend)
# En Docker se monta en /app/uploads, en local se puede usar ../backend/uploads
OUTPUT_DIR = os.getenv("OUTPUT_DIR", "/app/uploads")
if not os.path.exists(OUTPUT_DIR):
    # Intentar fallback local
    OUTPUT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "backend", "uploads"))
    os.makedirs(OUTPUT_DIR, exist_ok=True)

print(f"📁 Directorio de salida configurado en: {OUTPUT_DIR}")

# Instancia global del cliente de Redis
r_client = None

def get_redis_client():
    global r_client
    if r_client is None:
        try:
            r_client = redis.Redis(host=REDIS_HOST, port=REDIS_PORT, db=0, socket_timeout=15)
            # Validar conexión
            r_client.ping()
            print(f"🔌 Conectado a Redis en {REDIS_HOST}:{REDIS_PORT} exitosamente.")
        except Exception as e:
            print(f"⚠️ Error conectando a Redis en {REDIS_HOST}:{REDIS_PORT}: {e}")
            r_client = None
    return r_client

def resolve_backend_url(original_url: str) -> str:
    """
    Si el worker corre dentro de Docker, reemplaza localhost/127.0.0.1 
    con host.docker.internal para poder descargar la imagen desde el host.
    """
    parsed = urlparse(original_url)
    netloc = parsed.netloc
    
    # Si corre en docker y apunta a localhost, mapearlo al host
    if "localhost" in netloc or "127.0.0.1" in netloc:
        new_netloc = netloc.replace("localhost", "host.docker.internal").replace("127.0.0.1", "host.docker.internal")
        resolved = original_url.replace(netloc, new_netloc)
        print(f"🔄 URL del backend redirigida de {original_url} a {resolved}")
        return resolved
    return original_url

def get_callback_url(original_url: str, job_id: str) -> str:
    """Construye la URL del webhook de finalización."""
    resolved_url = resolve_backend_url(original_url)
    parsed = urlparse(resolved_url)
    base_url = f"{parsed.scheme}://{parsed.netloc}"
    return f"{base_url}/api/nail-tryon/{job_id}/complete"

def process_job(job_data: dict):
    job_id = job_data.get("job_id")
    user_id = job_data.get("user_id")
    original_image_url = job_data.get("original_image_url")
    # Compatibilidad con ambos formatos:
    # 1. {"params": {...}} y 2. payload plano desde Redis.
    params = job_data.get("params")
    if not isinstance(params, dict):
        params = {
            "color_hex": job_data.get("color_hex"),
            "shape": job_data.get("shape"),
            "finish": job_data.get("finish"),
            "decoration_style": job_data.get("decoration_style"),
        }
    
    print(f"⏳ Procesando trabajo {job_id} para usuario {user_id}...")
    
    temp_input = f"input_{job_id}.png"
    output_filename = f"tryon_{job_id}.jpg"
    temp_output = os.path.join(OUTPUT_DIR, output_filename)
    
    callback_url = get_callback_url(original_image_url, job_id)
    
    try:
        # 1. Descargar la imagen original
        resolved_download_url = resolve_backend_url(original_image_url)
        print(f"⬇️ Descargando imagen original desde {resolved_download_url}...")
        
        with httpx.Client(timeout=15.0) as client:
            response = client.get(resolved_download_url)
            if response.status_code != 200:
                raise Exception(f"Error descargando imagen. Código HTTP: {response.status_code}")
            
            with open(temp_input, "wb") as f:
                f.write(response.content)
        
        # 2. Ejecutar la segmentación y renderizado estético
        print(f"🧠 Ejecutando pipeline estético para parámetros: {params}")
        success = process_nail_tryon(temp_input, temp_output, params)
        
        if success and os.path.exists(temp_output):
            # Construir la URL de visualización pública
            # Se usa el host original que el cliente web/móvil proporcionó
            parsed_orig = urlparse(original_image_url)
            preview_url = f"{parsed_orig.scheme}://{parsed_orig.netloc}/uploads/{output_filename}"
            
            print(f"✅ Trabajo completado con éxito. URL del preview: {preview_url}")
            
            # 3. Notificar al backend del éxito
            with httpx.Client(timeout=10.0) as client:
                res = client.post(callback_url, json={
                    "status": "completed",
                    "preview_url": preview_url
                })
                print(f"📡 Webhook completado enviado. Respuesta backend: {res.status_code}")
        else:
            raise Exception("El pipeline de procesamiento falló o no generó el archivo de salida.")
            
    except Exception as e:
        error_msg = str(e)
        print(f"❌ Error procesando el trabajo {job_id}: {error_msg}")
        
        # Intentar notificar la falla al backend
        try:
            with httpx.Client(timeout=5.0) as client:
                res = client.post(callback_url, json={
                    "status": "failed",
                    "error_message": error_msg
                })
                print(f"📡 Webhook de falla enviado. Respuesta backend: {res.status_code}")
        except Exception as callback_err:
            print(f"⚠️ No se pudo enviar el reporte de falla al backend: {callback_err}")
            
    finally:
        # Limpieza de archivo temporal local
        if os.path.exists(temp_input):
            try:
                os.remove(temp_input)
            except Exception as fe:
                print(f"Error removiendo temporal {temp_input}: {fe}")

def queue_consumer_loop():
    """Loop infinito que consume trabajos de la cola Redis (BLPOP)."""
    print("🚀 Iniciando loop de consumo de colas de Redis en segundo plano...")
    
    while True:
        try:
            client = get_redis_client()
            if client is None:
                # Reintentar conexión tras un breve retraso
                time.sleep(4)
                continue
                
            # BLPOP retorna una tupla (nombre_cola, valor)
            # Bloquea por 5 segundos si está vacía
            raw_job = client.blpop(REDIS_QUEUE, timeout=5)
            
            if raw_job:
                _, payload_bytes = raw_job
                payload_str = payload_bytes.decode("utf-8")
                job_data = json.loads(payload_str)
                
                # Procesar trabajo de forma síncrona en el hilo del consumidor
                # (o asíncrona si se quiere procesar en paralelo, pero síncrona evita sobrecarga de CPU)
                process_job(job_data)
                
        except redis.ConnectionError:
            print("⚠️ Conexión perdida con Redis. Reintentando...")
            time.sleep(2)
        except Exception as e:
            print(f"⚠️ Excepción no controlada en el loop de consumo: {e}")
            time.sleep(2)

@app.get("/health")
def health_check():
    redis_ok = False
    try:
        client = get_redis_client()
        if client and client.ping():
            redis_ok = True
    except Exception:
        pass
        
    return {
        "status": "OK",
        "redis_connected": redis_ok,
        "service": "beauty-ai-worker",
        "output_directory": OUTPUT_DIR
    }

# Iniciar el hilo consumidor al arrancar el servidor
@app.on_event("startup")
def startup_event():
    consumer_thread = threading.Thread(target=queue_consumer_loop, daemon=True)
    consumer_thread.start()
    print("🧵 Hilo consumidor de Redis iniciado.")
