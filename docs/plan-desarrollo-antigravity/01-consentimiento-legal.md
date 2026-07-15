# 01 — Consentimiento Legal y Auditoría (Semana 1)

## 📌 Objetivo
Implementar la pantalla de consentimiento obligatoria (Ley 1581) con registro auditable en el backend.

---

## 📋 Tareas

### Frontend (Flutter)
- [ ] Crear `BiometricConsentScreen` (widget stateless/stateful para el control del formulario).
- [ ] Diseñar UI con:
  - Texto legal claro (puede ser estático o desde backend).
  - Checkbox "Acepto los términos".
  - Botón "ACEPTAR" habilitado solo si checkbox marcado.
  - Botón "CANCELAR" que hace pop a Ideas.
- [ ] Integrar con `biometric_service.dart` para enviar aceptación al backend.
- [ ] Manejar estado de carga (spinner) mientras se registra.

### Backend (Node.js)
- [ ] Crear tabla `biometric_consents` en PostgreSQL:
  ```sql
  CREATE TABLE biometric_consents (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      user_id UUID NOT NULL REFERENCES users(id),
      version VARCHAR(20) NOT NULL,
      accepted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
      ip INET,
      user_agent TEXT,
      revoked_at TIMESTAMP WITH TIME ZONE,
      active BOOLEAN DEFAULT TRUE
  );
  ```
- [ ] Implementar la orquestación de endpoints en el router de consentimiento.

---

## 🔒 Especificación de Endpoints

### 1. Registrar Consentimiento: `POST /api/consent`
* **Cuerpo esperado:**
  ```json
  {
    "userId": "UUID",
    "version": "1.0",
    "accepted": true
  }
  ```
* **Respuesta exitosa (201 Created):**
  ```json
  {
    "success": true,
    "consentId": "UUID-del-registro"
  }
  ```
* **Detalle técnico:** Captura la IP (`req.ip`) y el User-Agent (`req.headers['user-agent']`) y los persiste junto al registro.

### 2. Revocar Consentimiento: `POST /api/consent/revoke`
* **Propósito:** Uso futuro desde la configuración de perfil de la usuaria para cancelar el consentimiento biométrico.
* **Cuerpo esperado:**
  ```json
  {
    "userId": "UUID"
  }
  ```
* **Respuesta exitosa (200 OK):**
  ```json
  {
    "success": true,
    "message": "Consentimiento revocado con éxito."
  }
  ```
* **Detalle técnico:** Actualiza la fila activa en la base de datos colocando `active = false` y registrando el timestamp en `revoked_at = NOW()`.

### 3. Consultar Estado: `GET /api/consent/status/:userId`
* **Propósito:** Verificar si la usuaria posee un consentimiento activo antes de mostrar el onboarding.
* **Respuesta exitosa (200 OK):**
  ```json
  {
    "success": true,
    "hasActiveConsent": true,
    "version": "1.0"
  }
  ```

---

## ✅ Criterios de Aceptación
1. **Validación en Frontend:** El checkbox no puede ser omitido; el botón "ACEPTAR" debe permanecer deshabilitado hasta que esté marcado.
2. **Persistencia Auditada:** Al aceptar, se debe validar que el registro en base de datos contenga IP, User-Agent, versión del documento aceptado, ID de usuario y marca de tiempo.
3. **Flujo de Navegación Inteligente:** Si la consulta a `GET /api/consent/status/:userId` retorna `hasActiveConsent: true`, la app debe saltarse la pantalla de consentimiento directamente y navegar a `WelcomeScreen`.
4. **Cancelación Limpia:** Si la usuaria pulsa "CANCELAR", la app debe hacer pop y regresar al Hub de Ideas sin realizar llamadas a la API ni guardar registros.


