from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from models import ScanRequest, BiometricResult
from services.color_analysis import analyze_skin

app = FastAPI(title="GlowApp AI Worker")

# Configuración CORS para permitir peticiones desde el backend Node
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # En producción, restringir al dominio de Railway/Node
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.post("/api/v1/analyze-skin", response_model=BiometricResult)
async def analyze_skin_endpoint(request: ScanRequest):
    try:
        result = analyze_skin(request.image_base64)
        return BiometricResult(**result)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error en el análisis IA: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
