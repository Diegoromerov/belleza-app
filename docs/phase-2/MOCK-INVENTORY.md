# 🎭 Mock Inventory — Clasificación y Plan de Desacople

## Clasificación de Datos Simulados
- **Clase A (Eliminación Obligatoria):** Estados locales temporales que simulan operaciones de cobro o KYC sin persistence en base de datos.
- **Clase B (Conexión a API Real):** Mocks de listado de citas en `useBookings.ts` cuando falla la conexión de red.
- **Clase C (Fallback Permitido):** Respuestas por defecto en desarrollo local sin conexión a Redis.
- **Clase D (Válido para Testing):** Mocks utilizados exclusivamente en la suite de pruebas automatizadas E2E.
