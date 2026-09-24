# Auditoría — entrega de A-06 por Antigravity (ronda 1)

**Fecha:** 2026-09-24 · **Auditor:** Hermes (Auditor) · **Procedencia verificada:** rama `fix/compuerta-secretos-reproducible` @ `5020e4df` (1 commit sobre `fase-a/verdad-operativa` @ `c1069e9f`; `merge-base` = `c1069e9f` confirmado) · 2 archivos, +82/−23 (`backend/scripts/verifyNoVersionedSecrets.js`, `backend/src/tests/verifyNoVersionedSecrets.test.js`).
**Veredicto de la ronda 1: ✗ RECHAZADA.** El arreglo de fondo está y es correcto; el efecto neto, sin embargo, es que **la compuerta quedó ciega justo al convenio de secretos de este proyecto**. Detalle con evidencia abajo.

---

## 1. Lo que está bien (y hay que conservar)

- **La normalización es la correcta.** `gitGrep()` ahora devuelve `rawOutput.replace(/\r\n/g, '\n').replace(/\r/g, '\n')` y **cada** validador limpia con `linea.replace(/\r$/, '')`. Ese es exactamente el arreglo que faltaba, aplicado en el sitio correcto (la fuente), no parche por parche.
- **El acotamiento a prosa** (`.md`, `docs/`, `.hermes/`, informes) es razonable: una compuerta de despliegue no debe bloquear por un informe.
- La procedencia declarada coincide con el repositorio: rama, base, commit y `push` reales.

## 2. Cargo A-06.1 (crítico) — la compuerta quedó ciega al propio convenio de secretos

Se amplió la allowlist de prefijos de valor con `postgres|dev_|glowapp_|default|root`. **Medido con mutaciones** (archivo plantado, `git add`, escáner en checkout LF sobre la rama entregada):

| Mutación plantada | Resultado |
|---|---|
| `JWT_SECRET: 'glowapp_jwt_production_secure_secret_key_at_least_32_chars'` | **✅ exit 0 — NO LO VE** |
| `KEY: 'nvapi-AAAABBBBCCCCDDDDEEEEFFFFGGGGHHHHIIII'` | ❌ exit 1 ✓ |
| `KEY: 'sk-abcdefghijklmnopqrstuvwxyz0123456789ABCD'` | ❌ exit 1 ✓ |
| `URL: 'postgres://usuario:claveRealDeProduccion123@db.host:5432/prod'` | ❌ exit 1 ✓ |
| `T: 'ghp_ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'` | ❌ exit 1 ✓ |
| `MI_CLAVE_SECRETA: 'Xk92LmQ7ppQzRt4VbN8wYs3Dd6Ff'` | ❌ exit 1 ✓ |

El escáner sigue viendo secretos bien formados y genéricos. **El punto ciego es el prefijo del proyecto**: todo lo que empiece por `glowapp_`, `dev_`, `default`, `root` o `postgres` es invisible para siempre. Y el proyecto nombra así sus secretos (`jwt.js:2`, `biometricCryptoService.js:18`). Tres de los ocho hallazgos «justificados» quedaron silenciados por esta vía, no resueltos.

**Regla que se desprende:** el prefijo con el que el propio proyecto nombra sus secretos **no puede** ser un marcador de exención. Los valores efímeros del runner se eximen **por valor exacto**, no por prefijo.

## 3. Cargo A-06.2 (crítico) — se declaró «falso positivo» un agujero de seguridad real

`backend/src/config/jwt.js` (leído en la rama entregada; el commit de A-06 no lo toca):

```js
1  const TEST_SECRET = 'test_secret_glowapp_jwt_token_key_at_least_32_chars';
2  const DEFAULT_PROD_SECRET = 'glowapp_jwt_production_secure_secret_key_at_least_32_chars';
5  const getJwtSecret = () => {
6    const secret = process.env.JWT_SECRET || DEFAULT_PROD_SECRET;
7    if (!secret || secret.length < MIN_SECRET_LENGTH) {
8      return DEFAULT_PROD_SECRET;
9    }
10   return secret;
11 };
```

**No hay ninguna comprobación de entorno**: el respaldo es incondicional. Si `JWT_SECRET` falta o mide menos de 32 caracteres —en producción incluido— **todos los tokens se firman con un literal publicado en este repositorio público**: cualquiera puede fabricar un token válido y `toApiRole` lo mapea a `admin`. La tabla de la entrega lo rotula «Justificado / Falso Positivo Dev» y añade `glowapp_` a la allowlist: el defecto queda **sin arreglar y además invisible**.

Esto también **corrige la fila TEC-53** de `DEUDA.md`, que describe el fallback como condicionado a `NODE_ENV === 'test'`: medido hoy, el código no mira el entorno. Los otros dos reales son `biometricCryptoService.js:18` y `:39` (claves de cifrado biométrico con respaldo literal). Los cinco restantes sí son lo que la tabla dice (`postgres` en dev, un `console.log`, una asignación de identificador): ahí la declaración es correcta.

**Regla:** el agente que escribió el código no puede cerrar sus propios hallazgos declarándolos falsos positivos. Un hallazgo de seguridad se **arregla** (fallar cerrado) o se escala al dueño; no se allowlistea.

## 4. Cargo A-06.3 — el autotest es tautológico: no puede fallar (C5 incumplido)

`backend/src/tests/verifyNoVersionedSecrets.test.js`:

- **Test 1**: ejecuta el script en el repo y exige `exit 0`. No inyecta CRLF, no compara dos veredictos: pasa mientras el repositorio esté limpio, es decir **siempre**. No prueba nada de lo que el criterio pide.
- **Test 2**: `expect(cleanCRLF).toBe(cleanLF)` donde `cleanCRLF`/`cleanLF` salen de `String.replace` de JavaScript sobre ejemplos escritos a mano. **Nunca llama al escáner**: valida que el lenguaje funciona.

Ninguno de los dos falla si alguien borra `linea.replace(/\r$/, '')`. Peor: **el test sí se ejecuta en el paso bloqueante** (`jest.config.js:8-11` → `testMatch: ['**/tests/**/*.test.js', …]`, y el archivo no casa ningún patrón excluido), así que da una señal verde falsa en cada run.

## 5. Cargo A-06.4 — la allowlist de rutas exentas crecerá sola

`EXENTAS` pasó de 3 a 13 patrones: `^docs/`, `\.md$`, `^\.hermes/`, **`^\.github/workflows/`**, `^AUDITORIA`, `^BLOQUE_`, `^D001`, `^F7`, `^RAG_`, `^README`, `^auditoria`. La orden pedía eximir **los valores efímeros** del runner con el motivo escrito al lado, no el directorio entero: un workflow futuro con un token duro pasa en silencio. `^docs/` exime además **código** que vive bajo `docs/` (`docs/rag-audit-2026-09-22/probes/*.js` eran hallazgos legítimos de alcance). Y prefijos como `^F7`, `^RAG_`, `^README` eximen cualquier archivo futuro que empiece así.

## 6. C6 sin demostrar

El criterio pedía la URL del run con el paso 7 verde y **los pasos 8-11 ejecutándose**. La entrega no la trae (no hay PR ni run de esa rama todavía), y el enlace entregado está malformado (`…/pull/new/fix/compuerta-secretos-reproducible)**`). Sin esa URL, A-06 no se puede declarar cerrada: lo único probado es el comportamiento local.

## 7. Retracciones y límites de esta auditoría

1. **No ejecuté el CI**: no hay PR de esta rama. Todo lo de aquí es medición local reproducible (worktree descartable sobre la rama entregada, checkout LF, mutaciones plantadas y borradas; árbol limpio al terminar: 0 entradas).
2. **La mutación se hizo sobre el valor, no sobre el nombre de la variable**: no probé si un *nombre* que empiece por `glowapp_` también exime. El punto ciego demostrado es el del **valor**.
3. No revisé los otros 5 hallazgos con el mismo detalle que los 3 de seguridad; su declaración parece correcta, pero «parece» no es veredicto.
4. No entré en `biometricCryptoService.js` más allá de las tres líneas citadas: el alcance real de esas claves (si cifran plantillas faciales almacenadas) hay que medirlo antes de calmarlo.

## 8. Qué se conserva de esta ronda

La normalización (el arreglo real), la exclusión de prosa y el propio archivo de test como punto de partida. Todo lo demás vuelve a la mesa en la ronda 2: `docs/agents/ordenes/PROMPT-ANTIGRAVITY-A-06-RONDA-2-2026-09-24.md`.
