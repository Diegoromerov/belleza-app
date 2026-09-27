# Producción — verificación de variables sensibles (2026-09-26)

**Cómo se obtuvo:** Railway CLI, proyecto **grateful-harmony** · entorno **production** · servicio **belleza-app** (linkeado al clon autoritativo `C:/beauty-app`). **El `RAILWAY_TOKEN` exportado en el shell es inválido** (`Unauthorized`): hay que **desanularlo** (`unset RAILWAY_TOKEN`) y entonces responde la sesión interactiva (`diegomartinromero@gmail.com`). **Ningún valor se imprimió ni se guardó**: se procesó por *pipe* y sólo se reportan nombre, longitud y formato.

| Variable | Presencia | Longitud | Formato | ¿Qué implica? |
|---|---|---|---|---|
| `JWT_SECRET` | presente | 32 | utf8 de 32 bytes | **Producción NO depende del respaldo literal** de `jwt.js:2` ⇒ quitar el literal del código **no rompe producción** |
| `BIOMETRIC_ENCRYPTION_KEY` | presente | 64 | **hex** (`^[0-9a-f]{64}$`) | `biometricCryptoService.js:47` lo decodifica con `Buffer.from(key,'hex')` ⇒ **32 bytes ✓ NO lanza** |
| `ENCRYPTION_KEY` | presente | 64 | **hex** | mismo camino ⇒ 32 bytes ✓ |
| `DATABASE_URL` / `RAG_DATABASE_URL` | presentes | 98 / 93 | — | — |
| claves de API (`DEEPSEEK`, `GEMINI`, `NGC`, `NVIDIA`, `OPENUV`, `YOUCAM`) | presentes | 22-70 | — | rotables sin plan especial |

**Falsa alarma mía, corregida antes de publicarse:** comparé primero sólo *longitudes* y anoté «⚠ ≠32 bytes ⇒ aterrizar rompería identidad». El código de A-08 **decodifica hex**: 64 caracteres hex **son** 32 bytes ⇒ no rompe. La conclusión correcta sale de la **rama que toma el código**, no de la longitud del string.

**Consecuencias:**
1. **TEC-53** se puede arreglar **sin tocar Railway**: las tres variables están puestas y bien formadas.
2. **CI-30** deja de ser un riesgo abstracto: con las claves de producción (hex de 64) el código nuevo **no** lanza.
3. **D-003 (rotación):** `JWT_SECRET` rotable (sólo invalida sesiones) · claves de API rotables · **`BIOMETRIC_ENCRYPTION_KEY`/`ENCRYPTION_KEY` NO se rotan sin plan**: cambiar la clave **inutiliza los datos biométricos ya cifrados**; existe `backend/scripts/reencryptBiometricData.js` para el re-cifrado previo.
