# Plan de integración por cortes verticales — GlowApp / Belleza App

**Fecha:** 2026-09-24
**Objetivo:** dejar de tener "mucho código bueno y desensamblado" y pasar a una app donde cada flujo atraviesa todas sus capas con evidencia ejecutable, empezando por el dinero.
**Alcance:** planificación. Este documento no ejecuta cambios.
**Unidad de estimación:** 1 día-persona = 6 h de foco de un ejecutor con acceso al repo y al entorno local (docker-compose + Postgres con esquema real).

**Diagnóstico que ordena el plan (verificado en este repo):**
1. No hay contrato ejecutable entre capas (modelo `Membership` pide `business_profile_id`; la tabla real tiene `establishment_id`).
2. El sistema fabrica éxito (fallback en memoria que devuelve filas inventadas; simuladores de pago/payout/OTP; capturadores que responden `200 {data: []}`).
3. Cuatro fuentes de esquema en conflicto (`src/models`, `backend/migrations` —el único que corre—, `src/db/migrations` —nunca corre—, DDL manual en Railway).
4. El CI está muerto (marcadores de conflicto de merge commiteados en `main`; workflow YAML inválido).
5. Duplicidad de caminos (tres implementaciones de disputas; rutas que la UI llama y la API rechaza).

---

## 1. Fases, sub-fases, entregables, criterio de aceptación y tiempo

| Fase | Sub-fase | Entregable | Criterio de aceptación (mutación que debe hacerla fallar) | Días |
|---|---|---|---|---|
| **A. Verdad operativa** | A1 Apagar fabricación (fallback en memoria, simuladores tras flag, capturadores que devuelven 500) | Flag explícito + sin datos fabricados fuera de dev | Derrumbar Postgres a mitad de un request ⇒ 503/500 con error real, **nunca** 200 con datos inventados | 1,0 |
| | A2 Resucitar el CI | `.github/workflows/ci.yml` y `.gitignore` sin marcadores; gates de tests activos | `yaml.safe_load(ci.yml)` sin error **y** un run verde en GitHub Actions; romper un test a propósito ⇒ run rojo | 0,5 |
| | A3 Smoke honesto por superficie | Script que recorre cada superficie y reporta rojo/verde real | Con la base caída, el script debe salir ≠0 (hoy saldría verde) | 0,5 |
| **B. Dueño único del esquema** | B1 Baseline canónico (BD real ↔ modelos ↔ migraciones) | Documento/dump baseline + lista de divergencias con dueño asignado | Las 3 divergencias conocidas (memberships, bookings, salones) están decididas: migración o retiro del modelo | 1,5 |
| | B2 `schema:verify` + un solo runner | Script de comparación base-real ↔ baseline; runners reducidos a uno; `.down.sql` fuera | Añadir una columna a mano en la BD ⇒ `schema:verify` sale ≠0 con el diff exacto | 1,0 |
| | B3 Seed de desarrollo reproducible | Seeds idempotentes; la BD de producción deja de ser el entorno de pruebas | `docker compose down -v && up` deja el mismo dataset verificable (conteos fijos) | 0,5 |
| | B4 Compuerta de esquema en CI | Job: base limpia → migraciones → `schema:verify` → suites | Quitar un `CREATE TABLE` de una migración ⇒ el job falla | 1,0 |
| **C. Corte vertical dinero (prestador)** | C1 Harness API + Postgres real + adaptadores de borde | Harness supertest con `DATABASE_URL` real; pasarela/notificación detrás de interfaces | El harness falla si se lo apunta a pg-mem o a memoria (guarda explícita) | 1,0 |
| | C2 Invariantes de dinero y estados en rojo | 8-10 casos: cadena sin pago ⇒ 409; transiciones ilegales ⇒ 409; `pendiente+disponible+en_disputa` invariante; 2 `GET /wallet` concurrentes | Cada caso falla hoy por la **mutación** descrita (no por "test no escrito") y pasa tras el fix | 1,0 |
| | C3 Puerta de pago real (pago ⇄ verificación ⇄ wallet) + máquina de estados | `confirm-otp` exige pago verificado; matriz de transiciones por rol | `PATCH status→EN_PROGRESO` + `complete` + `confirm-otp` sin pago ⇒ 409 y **0** escrituras en `provider_wallet` (verificado por conteo antes/después) | 1,5 |
| | C4 Un solo camino de disputas y congelamiento consistente | Un módulo, un vocabulario, toda resolución mueve el wallet | No existe endpoint que resuelva sin tocar `provider_wallet`; congelar sin fondos ⇒ 409 (no `GREATEST(0,…)`) | 1,0 |
| | C5 Retiro: no debitar sin dispersión confirmada + reintento | Estado reintentable + job de reintento + referencia obligatoria | Ningún `saldo_disponible` baja sin `retiros.referencia_wompi`; un payout fallido vuelve a la cola y no pierde el saldo | 1,0 |
| | C6 Demo end-to-end del corte | Flujo completo en docker-compose + E2E verde | Un comando ejecuta el flujo y lo prueba; el ejecutor puede mostrarlo sin tocar producción | 0,5 |
| **D. Inventario y priorización** (paralelizable desde día 1) | D1 Grafo de llamadas bidireccional | Lista de rutas huérfanas, pantallas sin endpoint y endpoints sin UI | El reporte nombra los 4 huérfanos conocidos (`disbursePayout`, `learningPathRoutes`, disputas duplicadas, botón `EN_DISPUTA`) | 1,0 |
| | D2 Mapa de calor de integraciones (rúbrica 8 criterios) | Tablero: integración × D1-D8 con puntaje y evidencia | Cada celda tiene `archivo:línea` o comando; ningún puntaje sin evidencia | 0,5 |
| | D3 Backlog ordenado | Cola priorizada por riesgo irreversible × visibilidad × radio | Las 5 primeras entradas son las de mayor riesgo irreversible (dinero/legal) | 0,5 |
| **E. Disciplina permanente** | E1 Regla de tres puertas + plantilla de PR con evidencia | Checklist en `AGENTS.md` + plantilla de PR | Un PR sin migración/test de frontera/fallo honesto se rechaza por la plantilla | 0,5 |
| | E2 Guardián anti-fabricación | Script en CI que falla si reaparece un simulador sin flag | Reintroducir un `return {rows: [...]}` de relleno ⇒ CI rojo | 0,5 |
| | E3 Guardián anti-duplicados | Script en CI: una sola implementación por flujo | Añadir un segundo resolver de disputas ⇒ CI rojo | 0,5 |
| **F. Pasarela real** (proyecto propio, tras C) | F1 Integración Wompi sandbox | Creación de transacción + redirect/widget real | Un pago de sandbox produce una transacción con id de Wompi (no referencia aleatoria) | 2,0 |
| | F2 Webhook al contrato real | `X-Event-Checksum` / `signature.checksum`, `rawBody` capturado, idempotencia | Firmar un evento de ejemplo de la documentación ⇒ 200; evento duplicado ⇒ ignorado; firma alterada ⇒ 401 | 1,5 |
| | F3 Conciliación diaria real + alertas | Comparación ledger interno ↔ reporte de la pasarela | Una discrepancia inyectada de $1 ⇒ alerta, no log | 2,0 |
| | F4 Go-live con rollback | Flag de pasarela real + procedimiento de reversa | Apagar el flag devuelve el sistema al modo anterior sin perder datos | 1,0 |
| **G. Cortes verticales restantes** (por demanda) | G1 Cliente: reserva y gestión (UI↔API real) | Flujo cliente con contrato verificado | 4,0 |
| | G2 Tienda/pedidos: pagado ⇄ ledger ⇄ inventario | Pedido pagado se marca PAGADO y mueve stock/caja | 5,0 |
| | G3 Academia: contenido, intentos, certificados verificables | Certificado verificable por tercero | 5,0 |
| | G4 IA/Aura: worker, RAG, caché, trazabilidad | Respuesta citada y trazable, sin alucinación de datos | 4,0 |
| | G5 Admin: métricas reales y acciones que persisten | Ningún botón sin `onClick`; métricas con origen SQL | 4,0 |
| | G6 Salón/SaaS: tenencia, membresías, RLS efectivo | RLS probado con rol no propietario | 5,0 |
| | G7 Notificaciones: canal persistente transversal | Aviso entregado con app cerrada | 3,0 |

---

## 2. Totales

| Bloque | Días-persona |
|---|---|
| A. Verdad operativa | 2,0 |
| B. Dueño único del esquema | 4,0 |
| C. Corte vertical dinero | 6,0 |
| D. Inventario y priorización (paralelo) | 2,0 |
| E. Disciplina permanente | 1,5 |
| **Espina dorsal (A + B + C + D + E)** | **15,5** |
| F. Pasarela real | 6,5 |
| G. Cortes restantes (7 superficies) | 30,0 |
| **Total del programa** | **52,0** |

Ruta crítica hasta la primera demo honesta de dinero (**A+B+C = 12 días-persona**): 2,4 semanas con un ejecutor; ~1,5–2 semanas si D y E corren en paralelo con un segundo ejecutor (D no bloquea a nadie; E se escribe una vez).

---

## 3. Calendario sugerido (1 ejecutor a jornada completa)

| Semana | Contenido | Hito verificable |
|---|---|---|
| 1 (d 1-5) | A1-A3, B1-B3, arranque de D1-D2 en paralelo | La app dice la verdad: CI verde real, base reproducible, avisos de fabricación silenciados |
| 2 (d 6-10) | B4, C1-C2, cierre de D3 | Compuerta de esquema en CI + 10 invariantes de dinero en rojo documentados |
| 3 (d 11-15) | C3-C4 + E1 | El corte ya no permite acreditar dinero sin cobro; matriz de estados y disputas únicas |
| 4 (d 16-20) | C5-C6, E2-E3, arranque de F1 | Demo end-to-end del prestador con pasarela stub + guardianes en CI |
| 5-6 (d 21-30) | F1-F4 | Wompi sandbox con webhook del contrato real y conciliación con alerta |
| 7+ | G por prioridad del backlog (D3) | Un corte vertical cerrado por semana |

---

## 4. Supuestos y riesgos de la estimación

- **Supuesto:** el entorno local puede levantar Postgres + backend (ya existe contenedor con el esquema). Si la BD de producción no se puede clonar para desarrollo (B3), B sube ~1 día.
- **Riesgo 1 — Antigravity edita el mismo working tree.** El plan asigna una rama por sub-fase y prohíbe `git switch main`; los archivos de terceros se commitean aparte con su autoría declarada.
- **Riesgo 2 — el alcance real de F.** La integración de pasarela suele traer requisitos legales (contrato de comercio, PCI) que pueden añadir días fuera de código. Se confirma antes de iniciar F.
- **Riesgo 3 — el "buen código aislado" engaña.** Al apagar la fabricación (A1) van a aparecer rojos nuevos en superficies que hoy parecían sanas: el calendario prevé que A sea disruptivo y no lo mezcla con C.
- **Fuera de alcance de las estimaciones:** refactor de `index.js` (1.671 líneas), rediseño de UI, y migración de datos históricos. Se evalúan después de que exista la espina dorsal, porque hoy no se puede medir su impacto.

---

## 5. Definición de terminado (a nivel programa)

Un flujo está *terminado* cuando: atraviesa todas sus capas en el entorno local con un comando, tiene un test que cruza cada frontera sin mockear al otro lado, falla en voz alta cuando una dependencia no está, tiene una sola implementación, está en CI, y su estado es observable en producción.
