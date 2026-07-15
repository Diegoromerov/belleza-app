# 03 — Backend y Orquestación de APIs (Semanas 5-7)

## 📌 Objetivo
Construir el backend que recibe las imágenes, orquesta las llamadas a YouCam, Gemini y guarda el perfil en PostgreSQL y Redis con caché temporal.

---

## 📋 Tareas

### Backend (Node.js)
- [ ] Crear endpoint `POST /api/biometric/analyze`:
  - Body: `{ userId, faceImage: base64, handsImage: base64 }`
  - Limitar tamaño de imagen (máx. 1MB) para reducir latencia.
  - Respuesta: `{ success: true, profileId, results }`.
- [ ] Implementar cliente para **YouCam API**:
  - Documentación: [YouCam API](https://yce.perfectcorp.com)
  - Usar credenciales (API Key) guardadas en `.env`.
  - Enviar imagen de rostro y obtener scores.
  - Manejar errores (timeout, límite de créditos, etc.).
- [ ] Implementar cliente para **Gemini Vision** (manos):
  - Usar API Key de Gemini (`.env`).
  - Enviar imagen de manos con un prompt específico.
  - Parsear respuesta JSON.
- [ ] Implementar cliente para **Gemini Text** (recomendación):
  - Recibir resultados de YouCam y Gemini Vision.
  - Armar prompt con estructura fija.
  - Obtener recomendación en lenguaje natural.
- [ ] Guardar perfil en **PostgreSQL**:
  - Crear tabla `beauty_profiles`:
    ```sql
    CREATE TABLE beauty_profiles (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID NOT NULL REFERENCES users(id),
        face_scores JSONB,
        hands_diagnosis JSONB,
        recommendation TEXT,
        recommended_products JSONB,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );
    ```
- [ ] Implementar almacenamiento en caché con **Redis**:
  - Guardar el perfil completo bajo la clave `beauty:profile:{userId}`.
  - Configurar un TTL de 30 días (2,592,000 segundos).
- [ ] Crear endpoint `GET /api/biometric/profile/:userId`:
  - Lógica: Buscar primero en Redis. Si hay miss, consultar PostgreSQL y repoblar la caché de Redis antes de retornar.

---

## 🤖 Diseño de Prompts para Gemini

### 1. Prompt para Gemini Vision (Análisis de Manos)
```text
Eres un experto en cuidado de manos. Analiza esta imagen de manos y devuelve ÚNICAMENTE un objeto JSON con esta estructura:
{
  "manchas_solares": "leve" | "moderado" | "severo",
  "sequedad": "leve" | "moderada" | "severa",
  "cuticulas": "sanas" | "dañadas" | "inflamadas",
  "uñas": "sanas" | "estriadas" | "quebradizas",
  "edad_aparente": 35
}
No incluyas texto adicional.
```

### 2. Prompt para Gemini Text (Orquestación y Recomendaciones)
```text
Tienes los siguientes datos biométricos de una usuaria de GlowApp:

Datos del rostro (YouCam):
- Hidratación: {hydration}%
- Arrugas: {wrinkles}%
- Manchas: {spots}%
- Poros: {pores}%
- Subtono: {subtono}
- Edad biológica: {bioAge} años

Datos de manos (Gemini Vision):
- Manchas solares: {handSpots}
- Sequedad: {handDryness}
- Cutículas: {cuticles}
- Uñas: {nails}

Genera una respuesta en español con:
1. Un diagnóstico amable y claro (máximo 3 párrafos).
2. Una rutina AM de 3 pasos para el rostro.
3. Una rutina PM de 2 pasos para el rostro.
4. Una rutina de 2 pasos para las manos.
5. Lista de 3 ingredientes activos clave recomendados (ej. "ácido hialurónico", "retinol").
6. Una frase final motivadora.

Formato: Usa Markdown simple (negritas, viñetas).
No incluyas información médica ni diagnósticos clínicos.
```

---

## ✅ Criterios de Aceptación y Robustez
1. **Desempeño y Latencia:** El endpoint `/analyze` responde en menos de 6 segundos en promedio (orquestando YouCam + Gemini de forma asíncrona o paralela).
2. **Integridad de Datos:** Los datos se persisten en PostgreSQL (`beauty_profiles`) y en caché Redis (`beauty:profile:{userId}`) con un TTL de 30 días.
3. **Flujo de Caché (Miss/Hit):** La consulta del perfil biométrico recupera los datos de Redis sin tocar PostgreSQL si el registro existe en caché.
4. **Respuestas Válidas de LLM:** Los prompts aseguran salidas en formato JSON válido y parseable para evitar rupturas de ejecución.
5. **Estrategia de Fallback (Resiliencia):**
   * Si YouCam falla, se usa Gemini (con prompt adaptado) para procesar todo el diagnóstico.
   * Si Gemini o ambas APIs fallan, el backend retorna una respuesta estructurada genérica/estática por defecto basada en el subtono de piel guardado.


