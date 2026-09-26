# ORDEN A-07 — «El gate tiene que decir la verdad» (para el Ejecutor)

> Pegá este documento en el otro chat, tal cual. No necesitás leer la KB para empezar: lo medido va acá adentro.

**Rama:** `fix/gate-clasificado` **nacida de** `fase-a/verdad-operativa @ b545ef22` (no de `main`: `main` conserva
marcadores de conflicto en `ci.yml` y sus runs salen vacíos).
**Un worktree = un agente:** trabajá sólo en tu worktree nuevo. No toques `C:/beauty-app`, ni el worktree de la KB, ni
el de `setup_glowguide_architecture`.
**Autorización:** sos el Ejecutor de esta orden. Podés empujar tu rama; **no** mergeás (eso es del Dueño).

---

## Paso 0 — cerrar lo tuyo (5 minutos, antes de empezar)

Tu ronda 8 de O-014 fue **auditada y ACEPTADA** (`b919d45a`: corrida real `EXIT=0` con ruta nativa, 7/7 tests, y las
tres piezas resisten mutación aplicada por el Auditor con control y restauración verificada por `sha256`).
**Falta sólo empujarla** (hoy no existe en el remoto: el trabajo vive en un solo worktree local):

```bash
git -C "<tu worktree setup_glowguide_architecture>" push -u origin chore/guardian-en-el-repo
git ls-remote --heads origin chore/guardian-en-el-repo   # evidencia a pegar en el walkthrough
```

Sin reescribir historia, sin commits nuevos. Si tenés algo a medio escribir en esa rama, decilo **antes** de empujar.

---

## Contexto medido (no supuesto — sirve para que no repitas la medición)

El **paso bloqueante de tests** del CI (el que corre `npm test` excluyendo 10 patrones) hoy **no puede estar verde** por
dos causas independientes:

1. **El escáner de credenciales** (paso 7 + `audit360-remediation.test.js`): 8 hallazgos reales; su decisión está en el
   Dueño (CI-14) y en confirmar secretos en Railway (2b). **No es tu tarea.**
2. **10 suites rojas dentro del gate.** Medido por el Auditor sobre el tren integrado (8 ramas sobre `b545ef22`), en
   base limpia con credenciales que autentican y **0 errores de conexión**:

   | sin base | con base real |
   |---|---|
   | 10 de 75 suites rojas | **10 de 75** (una suite más apareció una vez: ver aviso) |

   Las 11: `adminPreciosRoutes` · `audit360-remediation` (cae por la causa 1) · `business.integration` ·
   `businessAdminDocs.integration` · `businessHardening.integration` · `businessRAG.integration` ·
   `businessSystem.integration` · `rateLimiter` · `sequelizeTenantContext` · `sprint2_agents` ·
   `ciRagEvaluation` **NO** entra: apareció roja en una corrida del tren, pero en aislamiento pasa **8/8 con y sin base** y el log dice `Test suite failed to run` (murió su worker) ⇒ **falso rojo del arnés**, no deuda. Si te aparece, repetila aislada antes de clasificarla.

### Falsos rojos medidos, no supuestos (leelo antes de clasificar)

El recuento de suites rojas **no es estable**: en 4 corridas del gate sobre el tren dio **10, 11, 11 y 12**. El **núcleo de 10 falla
con aserciones reales en las cuatro**; lo que oscila son suites que **no corren**: `● Test suite failed to run` →
`TypeError: Converting circular structure to JSON` (muere el worker de jest). Medidas dos: `ciRagEvaluation.test.js` (en aislamiento
pasa **8/8**) y `ownerMultiSalonDashboard.test.js` (**sus 4 tests pasan** y el crash ocurre después). Se probó `--maxWorkers=2` y
**no lo arregla: muda el crash a otra suite**.
⇒ **Contá sólo las que fallan con aserción.** Toda suite que aparezca como `failed to run` se repite aislada
(`npx jest --testPathPattern="<archivo>"`) antes de clasificarla: si pasa, es falso rojo del arnés y **no se arregla en esta orden**.

### Ahorro de tiempo medido (no hace falta que repitas estas corridas)

- **El mismo conjunto de 10 falla con y sin base**: el Auditor comparó las dos corridas por diferencia de conjuntos y son idénticas,
  con los mismos tests como primer fallo. ⇒ Para clasificar alcanza con correr **cada suite sola** (`npx jest --testPathPattern="<archivo>"`),
  no hace falta el gate completo de 75 suites.
- Clasificadas por **cómo** falla cada una (leído del log, no supuesto): **10 con aserción real** (`FALLÓ`) y la 11ª
  (`ciRagEvaluation`) **no corrió** (`Test suite failed to run`).
- Primer test que cae en cada una (punto de partida, verificalo): `adminPreciosRoutes` → «Rechaza peticiones de rol client o provider con 403» ·
  `audit360-remediation` → «no hay credenciales en archivos trackeados» (causa 1) · `business.integration` → «3. POST /api/v1/…» ·
  `businessAdminDocs.integration` → GOAL 06 Admin UI · `businessHardening.integration` → GAP 01: Provider · `businessRAG.integration` → GOAL 05 Aura + RAG ·
  `businessSystem.integration` → Goal 08 · `rateLimiter` → TIER_LIMITS por tier · `sequelizeTenantContext` → contexto de inquilino en el pool ·
  `sprint2_agents` → Agente HERMES.

⇒ Aun cerrando la causa 1, el CI seguirá rojo por estas 10 suites. **Eso es esta orden.**

---

## Cargos

### Cargo 1 — Clasificar, sin arreglar nada (obligatorio)

Una tabla, **una fila por suite de las 11**, con:

1. el **comando exacto** que la corre;
2. la **primera línea del error real**, copiada (no parafraseada);
3. la **causa** que declarás;
4. su **clase**, una sola de estas cuatro:
   - **ENV** — necesita un entorno que el CI sí tiene (base real, roles, datos sembrados) ⇒ si cae en el CI, hay que arreglarla;
   - **DEFECTO** — el código miente (respuesta 2xx con datos falsos, estado inventado, cálculo mal);
   - **OBSOLETA** — el test prueba algo que el producto ya no hace;
   - **FUERA DE FASE A** — pertenece a otra fase o a C-01/C-02/C-03 (OTP, cobro, wallet, disputas).

**Regla:** una suite que no clasificaste con evidencia propia queda como `NO MEDIDO`, no como «pendiente».

### Cargo 2 — Arreglar sólo lo que esté en el alcance de Fase A

Alcance: honestidad del arranque y del estado, routing, contratos, compuertas. **Una por una**, y por cada fix:

- test que **primero falla** (RED) por la causa que declaraste;
- fix en el código (no en el test);
- GREEN + la regresión del camino real que toques;
- **mutación pegada** (rompé el fix a propósito): tiene que caer el test, y el archivo vuelve idéntico (`sha256`).

No arregles las `FUERA DE FASE A` ni las `OBSOLETA`: se documentan.

### Cargo 3 — Documentar el resto como deuda

Una fila por suite no arreglada, con la razón exacta y el comando que la muestra. Nada de «pendiente» genérico.

---

## Prohibiciones (una infracción invalida la entrega)

- No toques C-01/C-02/C-03 (OTP, cobro, wallet, disputas), migraciones, `backend/public` ni `index.js` fuera de lo pedido.
- **No borres ni saltes tests para poner el gate verde.** Si una suite es OBSOLETA se retira con justificación escrita, y queda registrada.
- Sin `--force` ni `--force-with-lease`. No mergees. No borres ramas del remoto.
- No inventes números: si no lo mediste, escribí `NO MEDIDO`.

## Evidencia de entrega (walkthrough)

- Procedencia: rama + SHA + `git status --porcelain`.
- Tabla del Cargo 1 **completa** (las 11 filas) y tabla del Cargo 3.
- Por cada fix del Cargo 2: RED (salida real) → fix → GREEN, y la mutación con su control.
- **Antes/después del gate**, mismo comando, mismo entorno: `NODE_ENV=test npx jest --testPathIgnorePatterns="<los 10 patrones de ci.yml:98>" --silent --ci`.

## Cómo correr con base real en local (si la necesitás para clasificar)

El `trust` de `pg_hba` **no aplica** a las conexiones que entran por el NAT de Docker: hace falta una credencial que
autentique. El Auditor dejó, con autorización del Dueño, **contraseñas temporales** para los roles locales
`app_owner`/`app_rls_user` sobre la base `glowtest_gate` (el valor está sólo en
`AppData/Local/hermes/cache/scratch/gate/pw.txt`, no en el repo). **Nunca** pegues credenciales en el walkthrough.
