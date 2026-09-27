# Auditoría independiente — Entrega TEC-53 / CI-14 · Ronda 2

**Fecha:** 2026-09-27 · **Auditor:** Hermes · **Rama:** `fix/secretos-sin-respaldo-literal` @ **`eb72635d5`**
**Procedencia verificada por mí:** `2ac5c554f` es ancestro ✓; **2 commits** desde `b545ef22` ✓; `git ls-remote` muestra `eb72635d5…` ✓.
**Veredicto: ACEPTADA** — los tres cargos están hechos y **los tres los reproduje yo**. Una corrección factual menor, abajo.

## Lo que verifiqué, con mis mediciones

| Qué | Medición mía |
|---|---|
| El literal desapareció | `grep` por `glowapp_biometric_fallback` en el head empujado ⇒ **0 coincidencias** ✓ |
| Sin `JWT_SECRET` lanza | `decryptWithLegacyKey` sin la variable ⇒ `Error: JWT_SECRET requerida para derivar CLAVE_LEGADA` ✓ |
| **La clave legada no cambió en producción** | Cifré con la **fórmula vieja** (`sha256(JWT_SECRET)`) y el código nuevo lo descifra ⇒ **`true`** ✓ (reproducido por mí) |
| El escáner | **29 hallazgos, exit 1** — idéntico a lo que él reportó ✓ — y **0 de los 8 objetivos de la orden** ✓ |
| `audit360-remediation` | Archivo completo: **1 fallo / 18 pasan / 19 totales**, el fallo es «A360 C-02» ✓ (reportado como el archivo, no como filtro ✓) |
| No suma rojo | Gate = **9 suites / 55 rojos de 551** = **idéntico a su base** ⇒ delta 0 ✓ |
| Compuertas | `node --check` ✓ · `checkNoConflictMarkers` exit 0 ✓ · árbol limpio ✓ |

**Su edición del test (`audit360-remediation.test.js`) es buena, no un parche:** agrega una **prueba de regresión** que cifra con la fórmula vieja y verifica que `decryptWithLegacyKey` devuelve el objeto, restaurando `JWT_SECRET` en un `finally`. Es exactamente la prueba que faltaba y que no estaba pedida como código. Entró por la puerta correcta: declarada, con `node --check` y sin falsificar el resultado del archivo.

## Corrección factual (menor) y un dato que cambia el plan

- Él atribuye los 29 hallazgos restantes a `fix/ci-procedencia`. Medido: **esa rama sola da 39** ⇒ no es ella sola. La reducción a **8** la produce **el conjunto del tren** (incluida la compuerta endurecida de `fix/compuerta-secretos-reproducible`).
- **Consecuencia importante:** el escáner del tren da **8 = 5 líneas de prosa + `jwt.js:1`, `jwt.js:2`, `biometricCryptoService.js:18`** ⇒ y **TEC-53 arregla exactamente esos 8** ⇒ **al aterrizar (tren + TEC-53) el escáner queda en 0 y el paso 7 se pone verde por primera vez**, y `A360 C-02` pasa. Ese es el chequeo post-aterrizaje que corresponde, y está ya en la §6 del runbook.

## Residuo declarado

`A360 C-02` sigue rojo **en la rama** (por hallazgos que viven en otros archivos del árbol) y no se puede poner verde ahí: es un chequeo **post-aterrizaje**. No se pide arreglarlo en la rama.
