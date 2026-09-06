from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, Dict, Any
from models import ScanRequest, BiometricResult
from services.color_analysis import analyze_skin

app = FastAPI(title="GlowApp AI Worker & Aura Business Engine")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

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

@app.post("/api/v1/analyze-skin", response_model=BiometricResult)
async def analyze_skin_endpoint(request: ScanRequest):
    try:
        result = analyze_skin(request.image_base64)
        return BiometricResult(**result)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error en el análisis IA: {str(e)}")

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
