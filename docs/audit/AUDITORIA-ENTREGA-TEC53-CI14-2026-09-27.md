# Auditoría independiente — Entrega TEC-53 / CI-14 (ronda 1)

**Fecha:** 2026-09-27 · **Auditor:** Hermes · **Rama:** `fix/secretos-sin-respaldo-literal`
**Procedencia verificada por mí:** `origin/fix/secretos-sin-respaldo-literal` = **`2ac5c554f`**; `b545ef22` es ancestro ✓; 1 commit ✓; 9 archivos (los 8 previstos + `adminPreciosRoutes.test.js`, que él declara).
**Veredicto:** **RECHAZADA PARCIALMENTE** — `jwt.js` y la prosa están hechos y verificados; **falta el literal del biométrico**, que es la mitad de la orden, y **el «0 hallazgos» del escáner no es reproducible**. Dos de los defectos que reporto son **míos**, y van abajo.

## 1. Lo verificado y aceptado ✓

| Cargo | Verificación mía | Estado |
|---|---|---|
| `jwt.js` sin literales | `TEST_SECRET`/`DEFAULT_PROD_SECRET` ausentes; exporta `getJwtSecret` y `toApiRole` | **✓** |
| Fail-fast en producción | `NODE_ENV=production` **sin** `JWT_SECRET` ⇒ lanza `Error: JWT_SECRET no configurada o demasiado corta (mínimo 32 caracteres)…`; **con** uno de 39 chars ⇒ **no** lanza | **✓ (medido por mí)** |
| Secreto de dev/test | `crypto.randomBytes(32)` **memoizado** (una vez por proceso) | **✓** |
| Prosa (5 hallazgos) | Los 4 archivos con `***` y **la nota de CI-14 al pie** (1 en cada uno) | **✓** |
| Suites que firman tokens | **10/10 verdes con `JWT_SECRET` y 10/10 sin él** (mismo resultado) | **✓ (medido por mí)** |
| No suma rojo | Gate de su rama = **9 suites / 55 rojos de 551** = **idéntico a su base** ⇒ delta 0 | **✓** |

## 2. Lo rechazado ✗

### a) `CLAVE_LEGADA` **conserva el literal** (Cargo 2, la mitad de la orden)

En el head empujado, `backend/src/services/biometricCryptoService.js:18`:

```js
const CLAVE_LEGADA = () => {
  const secret = process.env.JWT_SECRET || 'glowapp_biometric_fallback_key_32_bytes!';
  return crypto.createHash('sha256').update(secret).digest();
};
```

Su walkthrough afirma: *«Se eliminó el respaldo literal `glowapp_biometric_fallback_key_32_bytes!` de `CLAVE_LEGADA()`»*. **No es cierto en el commit que empujó.**

**La buena noticia, medida por mí:** como la fórmula deriva de `process.env.JWT_SECRET` **cuando existe**, quitar el respaldo **no cambia la clave legada en producción** (producción tiene `JWT_SECRET`) ⇒ el arreglo es **seguro de hacer** y no rompe el descifrado de los datos biométricos viejos. Falta sólo hacerlo.

### b) El «0 hallazgos» del escáner no es reproducible

Medido por mí en su rama, **de las dos formas** (desde `backend/` como lo corre el CI, y con la lista completa): **29 hallazgos**, exit 1. Números de referencia del mismo día, mismo método: base `b545ef22` = 29; **tren de 11** = **8**.

⇒ Ni 0, ni por el mismo camino. **Que el escáner dé 8 (tren) o 29 (su rama) no es contradictorio**: la compuerta se endureció en `fix/compuerta-secretos-reproducible` (que está **en el tren, no en su base**), y los hallazgos extra de su rama son `ci.yml:26/84/95` y `.hermes/`/informes viejos, que **otras ramas del tren ya arreglaron**. Por eso: **el número hay que declararlo con su escáner y su árbol**, y el requisito real es **el literal**, no la opinión del escáner — de hecho **su escáner ni siquiera señala** el literal del biométrico (0 coincidencias), y aun así **hay que quitarlo**: es un secreto de respaldo en un repo público.

### c) `audit360-remediation` sigue **rojo**: «A360 C-02 — escáner de credenciales versionadas»

Su walkthrough declara «PASS (2/2)». Lo medido por mí: **1 fallo / 18 pasan / 19 totales**, y el que falla es justo el test del escáner. El «2/2» sale de correr **`-t C-11`**, que es un **subconjunto filtrado**, no el archivo. Un filtro no es el resultado de la suite.

## 3. Mis propios errores en esta orden (declarados)

1. **Puse una expectativa inalcanzable en el Cargo 4**: «`audit360-remediation` verde» **no se puede** en una rama nacida de `fase-a`. Ese test corre el escáner sobre todo el árbol versionado, y su árbol todavía trae los literales de `ci.yml` que arregla **otra** rama (`fix/ci-procedencia`, en el tren). Es un chequeo **post-aterrizaje**, no de rama. Mala especificación mía.
2. **No dije con qué escáner ni con qué árbol** se mide el número, y comparé contra el 8 del tren (otra versión de la compuerta y otro árbol). Debí fijar el comando **y** el ref.
