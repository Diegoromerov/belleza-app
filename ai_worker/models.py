from pydantic import BaseModel
from typing import List

class ScanRequest(BaseModel):
    image_base64: str

class BiometricResult(BaseModel):
    subtono: float
    estacion: str
    paleta: List[str]
    hidratacion: float
    sebo: float
    mensaje_aura: str
