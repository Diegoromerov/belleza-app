# Evaluación y Selección de Secret Manager

## 🎯 Objetivo
Definir la arquitectura de gestión de secretos para el ecosistema de **GlowApp Belleza Luxe** en entornos de desarrollo, staging y producción, eliminando cualquier valor sensible o clave hardcodeada en el repositorio.

---

## 🔍 Análisis Comparativo de Proveedores de Secretos

| Criterio | AWS Secrets Manager | GCP Secret Manager | Azure Key Vault | HashiCorp Vault |
| :--- | :--- | :--- | :--- | :--- |
| **Integración CI/CD** | Excelente con AWS IAM & GitHub Actions | Excelente con Workload Identity | Buena | Excelente (independiente de cloud) |
| **Rotación Automática** | Nativa mediante AWS Lambda | Soporta Pub/Sub + Cloud Functions | Nativa mediante Event Grid | Nativa con motores de secretos dinámicos |
| **Costo Base** | $0.40/secreto/mes + $0.05/10k API calls | $0.06/secreto/mes + $0.03/10k operaciones | $0.03/10k operaciones | Gratis (Self-hosted) / Pagado en HashiCorp Cloud |
| **Complejidad Ops** | Muy Baja (Servicio administrado) | Muy Baja (Servicio administrado) | Baja | Media-Alta (Requiere cluster/mantenimiento si es self-hosted) |

---

## 💡 Recomendación y Decisión de Arquitectura

**Proveedor Seleccionado**: **AWS Secrets Manager** (con fallback local/entorno controlado).

### Rationale:
1. La infraestructura cloud y el despliegue del ecosistema backend de GlowApp hace uso de integraciones compatibles con AWS / contenedores Docker.
2. Soporta políticas estricta de rotación automática para claves como `JWT_SECRET`, tokens de pasarelas de pago (`WOMPI_WEBHOOK_SECRET`) y credenciales de bases de datos.
3. Permite la integración transparente mediante una capa de abstracción en el backend (`SECRET_PROVIDER`) que soporta desarrollo local (mediante `.env` o KMS mock) y producción (mediante AWS SDK).

---

## 🛣️ Plan de Integración Tecnológica

1. **Abstracción Unificada (`backend/src/config/secrets.js`)**:
   - Crear la interfaz de lectura donde según `process.env.SECRET_PROVIDER` (`aws`, `gcp`, `vault`, `env`), el backend recupera la clave de forma asíncrona al iniciar la aplicación.
2. **Sustitución de Claves Hardcodeadas**:
   - Eliminar fallbacks inseguros en `jwt.js`, `authController.js` y `bookingController.js`.
3. **Validación de Integridad**:
   - Implementar pruebas unitarias con un `SecretProviderMock`.
