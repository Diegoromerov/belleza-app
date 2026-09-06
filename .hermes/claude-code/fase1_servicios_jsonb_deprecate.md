# PROMPT FASE 1 — Consolidar fuente única de servicios (deprecar JSONB duplicado)

============================================================
ROL
============================================================

Actúa como Backend + Flutter Architect Senior. Tu trabajo es hacer un
diagnóstico exhaustivo de uso real de datos antes de deprecar nada, y
solo después ejecutar el cambio si el diagnóstico lo confirma seguro.

============================================================
CONTEXTO
============================================================

Repositorio: Diegoromerov/belleza-app (checkout local: C:\beauty-app)

Confirmado (auditoría de código real):

- Tabla `perfiles_prestador` tiene un campo `portafolio_servicios JSONB
  DEFAULT '[]'::jsonb`.
- Tabla `services` existe de forma normalizada, con FK real
  (bookings.service_id → services.id), y es consumida activamente por
  al menos el endpoint GET /services/provider
  (serviceController.getProviderServices).
- Ambas estructuras representan conceptualmente lo mismo: los servicios
  que ofrece un proveedor. Esto es una duplicidad de fuente de verdad,
  no una separación de dominio confirmada como intencional.

============================================================
TAREA
============================================================

PASO 1 — AUDITORÍA DE USO (obligatorio, no te saltes esto):

1a. Backend: busca TODAS las referencias a `portafolio_servicios` en
    todo backend/src/ (controllers, services, routes, migrations, seeds,
    cron jobs). Para cada una, indica si es LECTURA, ESCRITURA, o solo
    definición de schema.

1b. Frontend: busca TODAS las referencias a "portafolio_servicios" o
    cualquier campo que el frontend pueda estar leyendo con ese nombre
    (revisa modelos Dart en frontend/lib/models/, especialmente
    provider_model.dart, y cualquier pantalla en
    frontend/lib/screens/provider*).

1c. Con base en 1a y 1b, clasifica el campo en una de tres categorías:
    - HUÉRFANO CONFIRMADO: nada lo lee ni escribe activamente hoy.
    - CONSUMIDO ACTIVAMENTE: algo en producción depende de él.
    - AMBIGUO: hay referencias pero no está claro si están en uso real
      (código muerto, feature flag, etc.)

PASO 2 — DECISIÓN (reporta antes de actuar):

Repórtame el resultado del Paso 1 completo ANTES de tocar código.
NO asumas automáticamente que es seguro deprecar solo porque la
auditoría previa lo sospechaba — confírmalo con evidencia de este
grep exhaustivo.

Si es HUÉRFANO CONFIRMADO → procede al Paso 3.
Si es CONSUMIDO ACTIVAMENTE o AMBIGUO → detente y espera mi decisión
sobre cómo migrar ese consumo a `services` antes de deprecar nada.

PASO 3 — DEPRECACIÓN (solo si Paso 2 confirma huérfano):

3a. NO borres la columna `portafolio_servicios` de la base de datos
    todavía. Solo:
    - Deja de escribirla en cualquier punto que la esté poblando (si lo
      hay, aunque sea legacy).
    - Agrega un comentario en el schema/migration indicando que está
      deprecada y candidata a DROP en una migración futura separada.

3b. Confirma que el frontend de servicios de proveedor
    (provider_services_screen.dart y cualquier pantalla relacionada)
    lee exclusivamente de la tabla `services` vía
    GET /services/provider, sin ningún fallback al JSONB.

3c. Si encuentras algún seed o script (railway_seed.sql, seed.sql,
    prestador-demo.sql) que siga poblando portafolio_servicios,
    actualízalo para que no lo haga, mantiendo el resto del seed intacto.

PASO 4 — DOCUMENTACIÓN:

Genera un breve documento (puede ser un comentario en el propio
schema.sql o un archivo separado) explicando: qué se deprecó, por qué,
y cuál es la fuente de verdad única a partir de ahora (`services`).

============================================================
FORMATO DE ENTREGA
============================================================

1. Reporte completo del Paso 1 (tabla de referencias encontradas,
   clasificadas).
2. Mi confirmación explícita antes de proceder al Paso 3 si el
   resultado no fue HUÉRFANO CONFIRMADO limpio.
3. Diff de los cambios (si se ejecuta el Paso 3).
4. Documento de deprecación.

============================================================
RESTRICCIONES
============================================================

- NO ejecutes ningún DROP COLUMN ni migración destructiva. Este fase
  es solo de dejar de usar el campo, no de eliminarlo físicamente.
- NO toques la tabla `services` ni su estructura.
- NO modifiques la lógica de negocio de creación/edición de servicios
  más allá de quitar la escritura al JSONB deprecado.
- Si el Paso 1 revela que algo SÍ depende del JSONB de forma no trivial,
  NO decidas tú solo cómo migrarlo — repórtalo y espera instrucción.
- NO hagas commit ni push de nada.
