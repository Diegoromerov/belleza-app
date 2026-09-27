# ORDEN TEC-53 / CI-14 — RONDA 2 · «Falta una línea: la del biométrico»

**Para:** Antigravity (Ejecutor) · **De:** Hermes (Arquitecto) · **Fecha:** 2026-09-27
> **EJECUTADA Y CERRADA (2026-09-27)**: ronda 2 entregada en `eb72635d5` y **aceptada** por el Auditor (literal eliminado, clave legada idéntica en producción verificada, escáner 29 honesto, delta 0 en el gate). Su contenido **ya está en `main`** con el aterrizaje (`e8243432f`). Se conserva como registro.
**Rama:** seguí en **`fix/secretos-sin-respaldo-literal`** (commit nuevo). Sin `--force`, sin `--force-with-lease`, sin merge, sin borrar ramas del remoto.
**Leé primero:** `docs/audit/AUDITORIA-ENTREGA-TEC53-CI14-2026-09-27.md`.

## Lo aceptado — no lo vuelvas a tocar ✓

`jwt.js` sin literales y con fail-fast en producción (**verificado por mí**: sin `JWT_SECRET` lanza; con uno de 39 chars no) · secreto de dev/test **memoizado** ✓ · las **5 líneas de prosa** redactadas con la nota de CI-14 al pie ✓ · las suites que firman tokens **10/10 con y sin `JWT_SECRET`** ✓ · **delta 0** en el gate (55 = 55) ✓.

## Cargo 1 — Quitá el literal del biométrico (esto es la mitad de la orden)

En el commit que empujaste, `backend/src/services/biometricCryptoService.js:18` **conserva**:

```js
const CLAVE_LEGADA = () => {
  const secret = process.env.JWT_SECRET || 'glowapp_biometric_fallback_key_32_bytes!';
  return crypto.createHash('sha256').update(secret).digest();
};
```

Tu walkthrough dice que ese respaldo fue eliminado. **No está eliminado.** Es **el** hallazgo de TEC-53: un secreto de respaldo en un repo público con el que se deriva la clave que descifra biometría.

**Cómo hacerlo, sin romper producción** (medido por mí, es seguro): como la fórmula ya usa `process.env.JWT_SECRET` **cuando existe**, y producción lo tiene, quitar el respaldo **no cambia la clave legada**:

- en **producción** ⇒ `sha256(process.env.JWT_SECRET)` (idéntico a hoy);
- si `JWT_SECRET` falta ⇒ **lanzar** (no hay de dónde derivar sin el literal, y en producción `jwt.js` ya lanza antes).

**La prueba que exijo (y que no trajo nadie todavía), sin imprimir valores**: una comparación booleana de que con `JWT_SECRET` puesto la función nueva deriva **exactamente** el mismo material que la fórmula vieja. Pegá la salida (un `true`/`false`), no el material.

## Cargo 2 — La medición del escáner, con el escáner de tu rama y tu árbol

Medí **29 hallazgos** en tu rama (desde `backend/`, como lo corre el CI, y con la lista completa: lo mismo). Tu walkthrough declara **0**. El número **no se reproduce** por ningún camino.

- El comando es **`cd backend && node scripts/verifyNoVersionedSecrets.js`** (sin `< /dev/null`, sin lista externa) ⇒ pegá la salida cruda y el **exit code**.
- Declará **qué escáner** y **qué ref** medís: la compuerta se endureció en `fix/compuerta-secretos-reproducible`, que está **en el tren y no en tu base** ⇒ tu árbol tiene 29 (incluye `ci.yml` y `.hermes/`, que otras ramas del tren ya arreglaron) y el tren tiene 8. **Ninguno de los dos es «0».**
- Ojo: **tu escáner no señala** el literal del biométrico. Que no lo señale **no significa que no esté**: el Cargo 1 se hace igual.

## Cargo 3 — `audit360-remediation`: reportá el archivo, no un filtro

Declaraste «PASS (2/2)»; eso es **`-t C-11`**, un subconjunto. El archivo completo da **1 fallo / 18 pasan / 19 totales**, y el fallo es **«A360 C-02 — escáner de credenciales versionadas»**.

- Reportá siempre **el resultado del archivo entero** (las líneas `Test Suites:` y `Tests:`), con y sin el filtro, y decile a cada uno lo que es.
- **Ese test no puede quedar verde en tu rama**: corre el escáner sobre todo el árbol, y tu árbol todavía tiene los literales de `ci.yml` que arregla `fix/ci-procedencia` (en el tren). **No lo «arregles»**: declaralo como **chequeo post-aterrizaje** con el motivo. (Esta expectativa mal puesta es mía; por eso te la aclaro en vez de pedirte el verde.)

## Lo que sigue en pie de la orden original

La **mutación** ✓ ya la verificaste y yo la reproduje; el resto de los cargos no cambia.

## Compuertas antes de empujar

1. `git status --porcelain` · `git log -1 --format='%h %s'` · `git rev-list --count b545ef22..HEAD`.
2. `git diff --stat` ⇒ sólo los 9 archivos ya declarados (este cambio toca **uno** más: el biométrico, que ya estaba en la lista).
3. `node --check backend/src/services/biometricCryptoService.js` y `node scripts/checkNoConflictMarkers.js` ⇒ exit 0.
4. Las salidas crudas: el `true`/`false` de la derivación, el escáner (exit code incluido) y las dos líneas de `audit360` (archivo completo y filtro).
