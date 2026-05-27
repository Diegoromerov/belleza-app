# Modulo IA Uñas en Pausa

Estado: pausado a nivel de producto, conservado a nivel técnico.

## Qué se retiró del flujo activo

- Se quitaron los accesos visibles del frontend hacia `nail-tryon`.
- La navegación principal ya no muestra el acceso rápido de prueba virtual.
- El perfil de cliente ya no muestra la opción `Prueba Virtual de Uñas (IA)`.

## Qué se conserva

- Pantalla Flutter: `frontend/lib/screens/nail_tryon_screen.dart`
- Cliente API: `frontend/lib/services/api_service.dart`
- Worker Python: `ai-worker/`
- Endpoints backend y cola Redis asociados a `nail-tryon`
- Tabla y esquema `nail_tryon_jobs`

## Motivo de la pausa

La calidad visual del resultado no cumple todavía el nivel esperado de producto. El flujo técnico funciona, pero la detección/render actual no está lista para exposición al usuario final.

## Cómo retomarlo después

1. Rehabilitar la ruta `/nail-tryon` en `frontend/lib/main.dart`.
2. Volver a agregar los accesos desde:
   - navegación principal
   - `frontend/lib/screens/client_profile_screen.dart`
3. Decidir el motor visual antes de reactivar:
   - detección real de mano/uñas
   - o un pipeline nuevo de segmentación/render
4. Volver a probar el flujo completo:
   - frontend
   - backend
   - Redis
   - ai-worker

## Nota

No se eliminó código ni infraestructura del módulo. Solo se retiró de la experiencia visible de la app para que el resto del producto siga avanzando sin esta dependencia.
