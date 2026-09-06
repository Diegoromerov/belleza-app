# PROMPT FASE 0 — Cierre de riesgo P0 (pools de conexión) + PIN seguro

============================================================
ROL
============================================================

Actúa como Backend Architect Senior especializado en Node.js, PostgreSQL,
Sequelize y control de concurrencia en sistemas de pagos.

Tu trabajo es implementar dos fixes puntuales y quirúrgicos. NO estás
autorizado a rediseñar el flujo de booking, ni a tocar el schema de base
de datos más allá de lo estrictamente necesario, ni a introducir nuevas
dependencias sin justificación explícita.

============================================================
CONTEXTO
============================================================

Repositorio: Diegoromerov/belleza-app (checkout local: C:\beauty-app)

Ya se identificó (auditoría previa, código real verificado) que:

1. backend/src/controllers/bookingController.js usa DOS mecanismos de
   conexión a PostgreSQL distintos dentro del mismo dominio de booking:
   - La mayoría de funciones (createBooking, startService,
     updateBookingStatus, cancelBooking, payBooking) usan un pool `pg`
     crudo.
   - exports.wompiWebhook (línea ~561) usa sequelize.transaction()
     con locks FOR UPDATE sobre la tabla `productos`.

   Estos dos pools NO comparten locks entre sí. Esto es el mismo patrón
   de riesgo de overselling ya documentado y en proceso de resolución en
   el módulo Citas↔Tienda vía un `productService` compartido (T-101 del
   roadmap general de GlowApp).

2. El PIN de verificación de servicio se genera en bookingController.js
   línea 149 con:
   const pin = Math.floor(1000 + Math.random() * 9000).toString();
   Esto NO es criptográficamente seguro y es un control de acceso a un
   servicio físico (el proveedor y/o cliente lo usan para confirmar
   presencia/identidad).

============================================================
TAREA
============================================================

PASO 1 — DIAGNÓSTICO PREVIO (obligatorio antes de tocar código):

1a. Si ya existe un `productService` compartido resultado de T-101,
    localízalo y evalúa si su patrón de conexión/locking puede
    reutilizarse aquí sin modificarlo. Si existe, tu solución para el
    punto 2 (webhook) debe alinearse a ese mismo patrón — no inventes
    una solución paralela.

1b. Si T-101 todavía no está implementado o no aplica directamente a
    este caso (el lock aquí es sobre `productos` en el contexto de
    booking, no de tienda), DETENTE y repórtame:
    - qué encontraste,
    - si el patrón de productService es reutilizable o no,
    - tu recomendación de cómo proceder,
    antes de escribir ningún fix. No decidas unilateralmente crear un
    servicio nuevo sin mi confirmación.

PASO 2 — FIX DEL PIN (solo tras completar el diagnóstico anterior):

2a. Reemplaza la generación del PIN por un método criptográficamente
    seguro (crypto.randomInt(1000, 10000) de Node.js, sin dependencias
    externas nuevas).

2b. Verifica que no haya otro punto del código que regenere PIN con el
    mismo patrón inseguro (grep por "Math.random" en el contexto de
    bookings/pin) y corrígelo también si aplica.

PASO 3 — FIX DEL MISMATCH DE POOLS (según lo que confirmes en Paso 1):

3a. El objetivo final es que el webhook de Wompi y el resto del flujo de
    booking usen el MISMO mecanismo de conexión y locking sobre
    cualquier tabla compartida (especialmente `productos` si aplica a
    este flujo, y `bookings`).

3b. Prioriza la solución menos invasiva: si es viable, migra solo la
    porción crítica del webhook (el bloque con FOR UPDATE) al pool `pg`
    crudo que usa el resto de bookingController, en vez de migrar todo
    el archivo a Sequelize o viceversa. No hagas una migración masiva de
    ORM sin mi aprobación explícita.

3c. Preserva el comportamiento de manejo de errores actual: el webhook
    debe seguir devolviendo 500 en el catch (ya está bien implementado),
    y debe seguir manejando la propagación a citas hijas vinculadas
    (linked_booking_ids) exactamente como hoy.

PASO 4 — TESTING:

Escribe o adapta un test que simule dos requests concurrentes
compitiendo por el mismo registro de `productos` (uno vía flujo síncrono
de booking, otro vía webhook) y confirme que el lock los serializa
correctamente sin permitir oversell.

============================================================
FORMATO DE ENTREGA
============================================================

1. Reporte del diagnóstico del Paso 1 ANTES de cualquier cambio de
   código (espera mi confirmación si el resultado es ambiguo).
2. Diff de los archivos modificados, con comentario breve de qué cambia
   y por qué en cada bloque.
3. Test de concurrencia agregado.
4. Lista de cualquier cosa que NO tocaste porque excedía el alcance de
   este fix puntual.

============================================================
RESTRICCIONES
============================================================

- NO modifiques el schema de base de datos salvo que sea estrictamente
  necesario para el fix (y si lo es, dilo explícitamente antes de
  aplicar la migración).
- NO toques la lógica de negocio de wallet, transactions, ni ningún otro
  módulo fuera de bookingController.js y lo estrictamente relacionado.
- NO introduzcas Sequelize en funciones que hoy usan pg crudo, ni
  viceversa, salvo que sea exactamente el fix descrito en el Paso 3.
- NO renombres funciones, rutas ni cambies contratos de API existentes.
- Si encuentras otro problema de seguridad o concurrencia mientras
  trabajas, repórtalo al final — no lo arregles sin mi autorización.
- NO hagas commit ni push de nada.
