# 06 — QA, Hardening y Despliegue (Semanas 11-12)

## 📌 Objetivo
Garantizar la calidad, seguridad y estabilidad del módulo antes del lanzamiento.

---

## 📋 Tareas

### Pruebas (QA)
- [ ] Pruebas de integración: flujo completo de extremo a extremo (`ConsentScreen` ➡️ `CaptureScreen` ➡️ `ResultsScreen`).
- [ ] Pruebas de mitigación de sesgo: probar la detección y análisis facial con diferentes tonos de piel en la escala Fitzpatrick (I-VI) y rangos de edad.
- [ ] Pruebas de estrés y concurrencia: simular múltiples solicitudes simultáneas al backend.
- [ ] Pruebas de resiliencia y fallback: simular caídas de las APIs de YouCam, Gemini y Open Beauty Facts para verificar respuestas estructuradas por defecto.
- [ ] Pruebas de UX: entrevistas con usuarios reales para validar la claridad y velocidad de las instrucciones del overlay de captura.

### Hardening
- [ ] Control de errores frontend: presentar diálogos informativos si falla el hardware de la cámara, los permisos de red o los timeouts de la API.
- [ ] Logs estructurados: configurar `Winston` en backend con logs estructurados en JSON para trazabilidad y monitoreo.
- [ ] Rate limiting: limitar el endpoint `/analyze` para mitigar ataques DoS y controlar costos de consumo de tokens.
- [ ] Configuración CORS: restringir el acceso a la API exclusivamente desde el dominio oficial de la aplicación móvil y portal web.
- [ ] Cifrado y Privacidad: asegurar que la transmisión viaje bajo TLS 1.3 y los datos biométricos/consentimientos se guarden en reposo utilizando cifrado AES-256.

### Despliegue
- [ ] Actualizar `docker-compose.yml` para incorporar el contenedor local de Redis.
- [ ] Cargar y configurar las variables de entorno oficiales (YouCam API Key, Gemini API Key) en la consola de Railway/AWS.
- [ ] Realizar despliegue en el entorno de Staging y verificar el flujo end‑to‑end de analítica.
- [ ] Compilar y desplegar compilaciones móviles al canal interno de TestFlight (iOS) y Google Play Console Internal Track (Android).
- [ ] Redactar la documentación operativa para soporte de primer nivel.

---

## ✅ Criterios de Aceptación
1. **Flujo de Extremo a Extremo Exitoso:** El flujo de consentimiento y captura corre libre de errores en los dispositivos iOS y Android de prueba.
2. **Latencia Óptima:** El tiempo de respuesta de la API orquestada se mantiene bajo los 6 segundos bajo condiciones normales.
3. **Equidad en Inferencias:** El motor de detección no discrimina por edad ni tono de piel (pruebas Fitzpatrick I-VI aprobadas).
4. **Logs Informativos:** Los errores críticos y fallas en la conexión con las APIs de terceros quedan documentados.
5. **Auditoría del Consentimiento:** La base de datos guarda correctamente el timestamp de aceptación y la revocabilidad del mismo.

---

## ⏱️ Estimación
* **QA:** 1 semana.
* **Hardening + Despliegue:** 1 semana.
* **Total:** 2 semanas.

