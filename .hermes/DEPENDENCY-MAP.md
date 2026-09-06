# DEPENDENCY-MAP

## Dependencies for each component

### 1. Multi-tenancy (tenant_id)
- Técnicas: 
  - Esquema de base de datos (añadir tenant_id a tablas) → PENDIENTE
  - Migración de datos existentes → PENDIENTE
  - Actualización de consultas y repositorios → PENDIENTE
  - Posible implementación de RLS (Row Level Security) → PENDIENTE
- Arquitectónicas:
  - Decisión de estrategia (shared DB/separate schema) → PENDIENTE (D-001)
- Legales:
  - Aislamiento de datos entre tenants (Ley 1581) → PENDIENTE (requiere revisión legal)
- Operativas:
  - Copias de seguridad por tenant → PENDIENTE
  - Monitoreo de uso por tenant → PENDIENTE

### 2. Consent management
- Técnicas:
  - Tabla consentimientos (crear) → PENDIENTE
  - API de otorgamiento/revocación → PENDIENTE
  - Middleware de verificación → PENDIENTE
- Arquitectónicas:
  - Decisión de procedimientos (otorgamiento, revocación, evidencia, versionado) → PENDIENTE (D-015)
- Legales:
  - Base jurídica (Ley 1581 art. 7) → PENDIENTE (requiere revisión legal)
- Operativas:
  - Integración con flujos de registro y reserva → PENDIENTE
  - UI para gestión de consentimientos → PENDIENTE

### 3. Auditoría genérica
- Técnicas:
  - Tabla audit_log (crear) → PENDIENTE
  - Triggers o interceptores para capturar mutaciones → PENDIENTE
- Arquitectónicas:
  - Decisión de qué auditoría realizar → PENDIENTE (D-004 para RAG, pero auditoría general es transversal)
- Legales:
  - Base jurídica (Ley 1581 art. 16) → PENDIENTE (requiere revisión legal)
- Operativas:
  - Almacenamiento seguro de logs → PENDIENTE
  - Rotación y eliminación de logs antiguos → PENDIENTE

### 4. Documentos legales versionados
- Técnicas:
  - Tabla legal_documents (crear) → PENDIENTE
  - Endpoints de presentación y tracking de aceptación → PENDIENTE
- Arquitectónicas:
  - Decisión de qué documentos versionar y cómo → PENDIENTE (D-010 y D-014 están relacionados con fiscal adapter, pero documentos legales son separados)
- Legales:
  - Requisito de tracking de aceptación y re-aceptación → PENDIENTE (Ley 1581 art. 7 y 8)
- Operativas:
  - UI para presentación de documentos legales → PENDIENTE
  - Mecanismo de re-aceptación cuando cambie el documento → PENDIENTE

### 5. Retención y eliminación segura
- Técnicas:
  - Tabla retention_policies (crear) → PENDIENTE
  - Trabajo cron de borrado criptográfico → PENDIENTE
  - Mecanismo de legal hold → PENDIENTE
- Arquitectónicas:
  - Decisión de períodos por tipo de dato → PENDIENTE (D-009)
- Legales:
  - Base jurídica (Ley 1581 art. 8) → PENDIENTE (requiere revisión legal)
- Operativas:
  - Monitoreo de cumplimiento de retención → PENDIENTE
  - Procedimientos de eliminación segura → PENDIENTE

### 6. Servicio de pagos mejorado
- Técnicas:
  - Middleware de verificación HMAC → PENDIENTE (depende de revisión legal de HMAC)
  - Garantizar idempotencia basada en external_id → PENDIENTE (depende de revisión legal)
  - Trabajo cron de conciliación diaria → PENDIENTE
- Arquitectónicas:
  - Decisión de qué campos de pago almacenar → PENDIENTE (relacionado con D-005 y D-014)
- Legales:
  - Base jurídica para verificación HMAC, idempotencia, conciliación → PENDIENTE (Ley 527/1999, estándares de la industria)
- Operativas:
  - Integración con PSP (Wompi y otros) → PENDIENTE
  - Alertas de discrepancias en conciliación → PENDIENTE

### 7. Capa de gobernanza de IA
- Técnicas:
  - Filtrado de datos sensibles antes de enviar a LLMs → PENDIENTE
  - Registro estructurado de interacciones IA (prompt, respuesta, latencia, tokens) → PENDIENTE
- Arquitectónicas:
  - Decisión de política de uso de IA/RAG → PENDIENTE (D-012)
- Legales:
  - Base jurídica (Ley 1581 art. 10, SIC Circ. 022/2023) → PENDIENTE (requiere revisión legal)
- Operativas:
  - Auditoría de uso de IA → PENDIENTE
  - Mecanismo de opt-out de uso de datos para mejora de modelos → PENDIENTE

### 8. Middleware de seguridad básica
- Técnicas:
  - Headers CSP, HSTS, X-Frame-Options → PENDIENTE
  - CORS restrictivo → PENDIENTE
  - Rate limiting por IP/API key → PENDIENTE
- Arquitectónicas:
  - Decisión de niveles de servicio y acuerdos de disponibilidad → PENDIENTE (D-008)
- Legales:
  - Ninguna específica, pero respalda el deber de seguridad (Ley 1581 art. 10) → PENDIENTE
- Operativas:
  - Protección contra ataques comunes (XSS, CSRF, clickjacking) → PENDIENTE
  - Mitigación de fuerza bruta y fuerza lenta → PENDIENTE

### 9. Actualización de flujos de registro y reserva para requerir consentimientos específicos por finalidad
- Técnicas:
  - Añadir verificaciones de consentimiento en endpoints → PENDIENTE
- Arquitectónicas:
  - Decisión de qué flujos requieren qué consentimientos → PENDIENTE (relacionado con D-015)
- Legales:
  - Base jurídica (Ley 1581 art. 7) → PENDIENTE
- Operativas:
  - Integración con middleware de consentimiento → PENDIENTE
  - Tests de integración → PENDIENTE

### 10. Preparación del fiscal adapter
- Técnicas:
  - Crear abstraction layer inactivo → PENDIENTE
- Arquitectónicas:
  - Decisión de reglas de activación → PENDIENTE (D-006 y D-010)
- Legales:
  - Ninguna (inactivo, pero futuro requerirá habilitación DIAN) → PENDIENTE (requiere revisión legal futura)
- Operativas:
  - Ninguna (inactivo) → PENDIENTE

## Summary of Dependency Status
All dependencies are currently PENDIENTE because they depend on decisions that are still pending (D-001 through D-015, except D-013 which is APPROVED). No dependencies are RESUELTA, BLOQUEANTE, or NO DETERMINADA at this time.