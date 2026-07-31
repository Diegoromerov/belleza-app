# Arquitectura de Carga Efímera y Procesamiento Biométrico

## 🎯 Objetivo
Garantizar la protección de privacidad e imágenes faciales sensibles del usuario mediante un flujo de procesamiento efímero con eliminación automática basada en TTL (Time-to-Live) de máximo 15 minutos.

---

## 📐 Flujo Técnico y Diagrama de Secuencia

```
[Dispositivo Móvil] ---- 1. POST /api/v1/uploads/signed-url ----> [Backend Express]
                                                                        |
                                                                  Genera Upload ID & URL Firmada (TTL: 5 min)
[Dispositivo Móvil] <--- 2. Devuelve signedUrl & uploadId <-------------|

[Dispositivo Móvil] ---- 3. PUT / (Carga Directa a Storage Cifrado) ---> [S3 / Temporary Storage]

[Dispositivo Móvil] ---- 4. POST /api/v1/uploads/process --------------> [Backend Express]
                                                                        |
                                                                  Inicia Worker de Análisis (Aura AI)
                                                                        |
                                                                  Procesa vectores de piel / malla 3D
                                                                        |
                                                                  Purga imagen original de Storage
```

---

## 🛠️ Especificación de Endpoints y Jobs

1. **`POST /api/v1/uploads/signed-url`**:
   - Requiere JWT Token de usuario.
   - Devuelve `{ uploadId, signedUrl, expiresAt }`.

2. **`POST /api/v1/uploads/process`**:
   - Body: `{ uploadId }`.
   - Ejecuta análisis facial y programa eliminación inmediata del archivo fuente.

3. **Cron Job de Purga Efímera (`cleanup-ephemeral-uploads`)**:
   - Corre cada 5 minutos para eliminar cualquier archivo sin procesar cuya antigüedad supere los 15 minutos.
