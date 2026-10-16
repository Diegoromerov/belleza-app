# Capturar la responsabilidad de IVA del prestador desde el RUT

Fecha: 2026-10-10. Estado: **diseño**, pendiente de las decisiones D1–D3 antes de implementar.
Origen: hallazgo **W13** de `.hermes/REVISAR.md`. Contexto fiscal: `.hermes/compliance/iva-colombia.md`.

---

## El problema, en una frase

Hoy `usuarios.responsable_iva` vale `true` **para todos** por decisión de negocio, no porque se haya
verificado prestador por prestador — y la responsabilidad de IVA no depende del servicio sino de los
ingresos del prestador (art. 437 par. 3 E.T.).

## Por qué no basta con «todos prestan servicios gravados»

Son dos artículos distintos y conviene no mezclarlos:

| Pregunta | Artículo | Respuesta |
|---|---|---|
| ¿Este servicio causa IVA? | 476 num. 1 lit. a) | Sí: los tratamientos de belleza están gravados al 19% |
| ¿Este prestador **cobra** IVA? | 437 par. 3 | Depende de sus ingresos (3.500 UVT) y de su RUT |

Un prestador por debajo del umbral es **no responsable**: no puede cobrar IVA ni facturarlo. Si la
plataforma discrimina IVA en su reserva, le está poniendo un impuesto encima que él no puede
sustentar. Y al contrario: si un prestador sí es responsable y no lo marcamos, la plataforma
**absorbe** ese 19%.

## Fuente de verdad

El **RUT** del prestador, casilla de responsabilidades: **código 48** = responsable de IVA,
**49** = no responsable de IVA. No se deduce del catálogo de servicios ni del tipo de negocio.

---

## Fase 1 — Datos (migración 087)

- `usuarios.rut_responsabilidad_codigo` `SMALLINT NULL` — 48 o 49, con CHECK.
- `usuarios.responsabilidad_iva_fuente` `VARCHAR(10) NULL` — `'RUT'` o `'MANUAL'`.
- `usuarios.responsabilidad_iva_verificada_at` `TIMESTAMPTZ NULL`.
- **No tocar `responsable_iva` por sí sola**: la migración sólo añade datos y los deja en NULL
  («sin verificar»), para no cambiar comportamiento de golpe.

**D1 — ¿`responsable_iva` pasa a derivarse del código, o sigue editable?**
Recomiendo **derivarlo** del código del RUT y permitir un override manual **auditado** (con fuente
`MANUAL` y fecha), para que la excepción sea visible y no silenciosa.

## Fase 2 — Backend

- `PATCH /api/providers/me/fiscal` (`authMiddleware` + rol PRESTADOR): recibe
  `{ rut_responsabilidad_codigo }` y, opcionalmente, el número de RUT.
  - Valida que el código sea 48 o 49 → si no, `400` con la lista.
  - 48 → `responsable_iva = true`; 49 → `false`.
  - Registra quién lo cambió y cuándo (auditoría).
- `GET /api/providers/me` devuelve el estado («responsable / no responsable / sin verificar») para
  que la app pueda mostrarlo y pedirlo.

**D2 — ¿se exige el número de RUT o basta la declaración?**
Exigirlo permite verificar contra el RUT en línea; no exigirlo es menos fricción pero deja el dato
como declaración sin respaldo. Recomiendo exigirlo **una vez** y guardarlo, aunque la verificación
en línea se haga después.

## Fase 3 — Flutter (onboarding del prestador)

- Paso nuevo en el onboarding: «¿Eres responsable de IVA?» con explicación en lenguaje llano
  («está en tu RUT, casilla de responsabilidades: 48 o 49») y enlace a cómo consultarlo.
- En Ajustes → Datos fiscales: editable después, mostrando el estado actual y su origen.
- Si no responde, queda el default y se marca **«sin verificar»** para que el panel lo persiga.

**D3 — ¿bloquea el onboarding?**
Bloquearlo (no puede publicar servicios hasta declararlo) garantiza el dato; dejarlo opcional con
recordatorio no frena la afiliación pero mantiene el hueco. Recomiendo: **opcional para publicar,
obligatorio para recibir pagos** de reservas con IVA.

## Fase 4 — Panel admin

- Columna «IVA» en la lista de prestadores: responsable / no responsable / **sin verificar**.
- Filtro «sin verificar» para ir a buscarlos.
- Aviso en la ficha del prestador cuando `responsable_iva` no coincide con el código del RUT.

---

## Riesgos y cómo se evitan

- **No cambiar precios con la migración.** 087 sólo añade columnas; el comportamiento se mantiene
  hasta que alguien declare.
- **No reescribir reservas pasadas.** `bookings.tarifa_iva_aplicada` ya queda **congelada** al crear
  la reserva (migración 086), así que una factura vieja se reproduce con el IVA que se causó ese día,
  no con el que resulte si el prestador cambia de condición.
- **Un cambio de condición sólo aplica hacia adelante.** Declarar 49 no «devuelve» IVA ya facturado.

## Verificación obligatoria antes de dar esto por hecho

- 087 contra Postgres real: columnas, CHECK, idempotencia y rollback (runbook en el skill
  `belleza-app-migrations`).
- Declarar la columna **en el modelo Sequelize Y en `src/config/pgMemory.js`**: si falta cualquiera
  de los dos, o se descarta en silencio o revienta con 500 — los dos fallos ya ocurrieron con 086.
- Tests: el endpoint rechaza un código distinto de 48/49; un prestador con **49** y reserva nueva →
  `iva_valor = 0` y `base = total`; con **48** → `base + IVA = total`; y cambiar la condición **no**
  altera reservas ya creadas.
- Correr la **suite completa** (no un subconjunto): los dos fallos de 086 aparecieron en suites que
  no tenían nada que ver con el cambio.

## Lo que NO entra aquí

- Emitir la factura con el formato de la DIAN (trabajo aparte; el desglose ya se persiste).
- Verificación automática contra la DIAN (requiere credenciales del prestador y su autorización).
- El IVA del GlowStore (W8: GlowStore nunca se integró a Wompi).
