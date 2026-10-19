# Decisiones sobre deuda técnica — 2026-10-09

Contratos que estaban en disputa entre el código y sus tests. Fijados por Diego (producto/seguridad).
Cada uno dice **qué lado es la verdad** y por tanto **qué se toca**. Los tests NO se adaptan al
comportamiento actual: eso oculta el defecto en vez de arreglarlo.

## 1. Clave biométrica de longitud inválida — HECHO

**Decisión: RECHAZAR (fail-closed) en todos los entornos.**

`biometricCryptoService.js:53-58` hasheaba la clave y la aceptaba en silencio fuera de `NODE_ENV=test`.
Una clave de cifrado mal formada degradaba a un hash en vez de impedir el arranque: fail-open, lo
contrario de `isStrictEnvironment()` en `backend/src/config/db.js` y del endurecimiento T-A0.

Arreglado en el servicio (no en el test). `biometricCryptoService.test.js`: 17/17.

## 2. Conjunto canónico de herramientas AURA — son 8

**Decisión: el conjunto canónico son las 8 que se declaran al modelo.**

Estado: `auraToolExecutor.js` define **11 declaraciones (10 nombres únicos)** y `geminiService`
declara **8** al LLM. Tres herramientas existen en el ejecutor pero el modelo no puede invocarlas
porque no las conoce.

A ejecutar: alinear el ejecutor a las 8 canónicas. Antes de tocar, comparar nombre por nombre las 8
declaradas por `geminiService` contra las 10 únicas del ejecutor — la intersección es 7:
`check_provider_availability`, `evaluate_user_rebooking`, `query_user_biometric_profile`,
`recommend_glowstore_products`, `search_beauty_knowledge_rag`, `search_nearby_services`,
`trigger_ui_redirection`. La octava que pide el test, `get_provider_b2b_insights`, **no existe** en el
ejecutor; y sobran `get_business_profile_summary`, `get_business_tasks` y
`search_regulatory_knowledge_rag`. Confirmar con Diego si esas tres se retiran o se renombran antes de
borrar nada: son funcionalidad, no solo nombres.

## 3. Orden de middleware en biometría — Zod antes del veto

**Decisión: cambia qué middleware va antes en la cadena. Zod primero.**

Estado: `/api/biometric/analyze` con error de validación Zod responde **403** (el veto de
consentimiento corre antes) donde el test espera **400**.

A ejecutar: mover la validación Zod delante del guard de consentimiento en la cadena de
`backend/src/routes/biometricRoutes.js`. Criterio: un cuerpo mal formado es un error del cliente y
debe reportarse como 400 antes de evaluar autorización; el 403 queda para el caso bien formado sin
consentimiento válido.

## 4. Ruta duplicada — 404

**Decisión: 404.**

`/api/admin/precios/precios` responde **400** y debe responder **404**: una ruta que no corresponde a
ningún endpoint es inexistente, no una petición mal formada.

A ejecutar: corregir el enrutado (el test ya aserta el valor correcto, así que el cambio va en el
router, no en la aserción).

## 5. Pendiente de decisión — el 503 de `degradedLockBehavior`

Diagnóstico vigente: Expected 503 / Received 500. El candado libera la petición por su propia regla de
memoria de test (`degradedLock.js:264`, `:138-144`) y el 500 lo produce `productController.js:59` por
`ColumnNotFound: column "p.descripcion" does not exist` de pg-mem: el esquema en memoria
(`pgMemory.js:251-258`) no tiene `descripcion`, `imagen_url`, `tag_especialidad` ni
`tipo_visibilidad`, que la consulta sí pide.

**No se adapta `productController` al esquema fantasma.** Es decisión de producto y sigue abierta.

## Sin decisión necesaria (arnés) — medidas y pendientes

- `api.cors` (2 rojos): `/api/health` devuelve 503 donde el test espera 200. Falta distinguir si el
  handler responde 503 al estar degradada la base (entonces el test de CORS no debe depender del
  código de estado) o si la exención del candado no funciona (defecto real).
- `orchestrator.resilience` (1 rojo): el test mockea `analyzeFace`/`analyzeHands` para que resuelvan y
  el orquestador lanza `BIOMETRIC_ANALYSIS_UNAVAILABLE` igual. Falta distinguir identidad de módulo
  (arnés) de contrato endurecido (fail-closed).

## Deuda conocida, sin recuento y sin corregir

`geminiFallback.test.js:154` — `test.skip` que documenta un bug de producción: *"bug en
geminiService.js scope parsedUserId"*. No está en `docs/audit/DEUDA-TECNICA-GITHUB-2026-10-08.md`. Un
skip es un sitio donde la deuda se esconde del recuento.
