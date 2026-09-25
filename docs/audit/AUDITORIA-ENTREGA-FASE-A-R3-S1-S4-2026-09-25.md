# Auditoría — Fase A ronda 3 (S1 + S4) · `9a86a902`

**Fecha:** 2026-09-25 · **Auditor:** Hermes
**Procedencia:** commit **`9a86a902` dentro de `fase-a/verdad-operativa`** (lo permitía el C8 de la orden: «PR contra `main` **o** el commit dentro de `fase-a`»). 6 archivos, +1.154 / −18. Worktrees desechables retirados al terminar (3).

## Veredicto: **S1 ✓ ACEPTADO** · **S4 ⚠ ACEPTADO EN PARTE** — su C4 no se sostiene

---

## S1 — candado de degradación: verificado corriendo el servidor con la base muerta

Servidor en `:8099` con `DATABASE_URL` a un puerto muerto. El propio log confirma el estado:
`⚠️ [DB] Sin enlace con PostgreSQL (ECONNREFUSED 127.0.0.1:5999) — se sirve memoria local`.

| Superficie | Respuesta medida |
|---|---|
| `/api/products` | **503** + `X-GlowApp-Degraded: memory-fallback` ✓ |
| `/api/health` | 503 ✓ (allowlist, su propia semántica) |
| `/api/providers` | 503 ✓ (allowlist) |
| `/` (raíz, estáticos) | **200** ✓ el candado no la alcanza |

- **Montaje correcto:** `index.js:227`, **antes** de los routers (`391+`). Si estuviera después, no bloquearía nada.
- **Estado vivo:** `getDbStatus()` se lee **por petición** (`degradedLock.js:21`), no cacheado al arranque.
- **Allowlist:** tres rutas **exactas**, cada una con su motivo, **sin comodines** ✓ (C7).
- **Alcance que hay que declarar (no es defecto, es decisión):** con la base muerta el candado también responde 503 en superficies de **C-01/C-02/C-03** — medido: `/api/payments/wompi-webhook` (POST incluido) 503, `/api/disputes` 503, `/api/tickets` 503, `/api/auth/login` 503, `/api/admin/metrics` 503. Que el webhook reciba 503 y Wompi reintente es defendible, **pero es una decisión de dinero** y va al registro del Dueño, no dentro de un middleware global sin decirlo → **CI-16**.

## S4 — el guardián: la regla está bien, la cobertura no

**Lo que sí:**
- Regla **de clase** (`smokeSurfaces.js:96-102`): cualquier 2xx bajo `/api` no exento estando degradado ⇒ `faked_success`.
- Estado capturado **una vez al inicio** con **dos sondas** (`:55-64`, health + test-db), no derivado de un solo endpoint que puede mentir.
- `wrote_to_db: false` hardcodeado **eliminado** de los resultados.
- Informe escrito y **commiteado** (`docs/audit/smoke-2026-09-25.json`, 984 líneas) y **sin datos sensibles** (0 `eyJ`, 0 correos, 0 `password`/`token`).

**C4 ✗ — medido, y es el cargo principal:** planté **mi** ruta `GET /api/__hermes_fake` (responde 200 con la base muerta; registrada antes del candado) y corrí su guardián **sin tocar una línea de su código**:

```
📊 Estado del servidor detectado (probes inicio): IsDegraded=true, HealthStatus=503
📋 Resumen de Smoke Test (122 superficies probadas): Faked Success Totales: 0
✅ SMOKE TEST EXITOSO                                        EXIT=0
```

Mi ruta **no aparece** ni en la salida ni en el informe. Motivo, medido: el guardián recorre el **inventario commiteado** (`docs/audit/routes-2026-09-24.json`), que tiene **308** rutas y **0** ocurrencias de la mía. Su corrida roja declaró **123** superficies ⇒ **regeneraron el inventario** antes de correr. Es decir: el guardián ve lo que dice el inventario, **no lo que tiene la app** — exactamente la clase de defecto que S4 venía a cerrar → **CI-15**.

**Otros tres residuos:**
- `empty_like` sigue **calculado y sin decidir** (`:80` cálculo, `:115` guardado). La orden pedía que decidiera o se eliminara; con la regla de clase es redundante ⇒ **elimínalo**.
- **El informe rojo se pierde:** un único nombre `smoke-<fecha>.json`, y la corrida verde lo sobrescribió. Lo commiteado es el **verde**; la evidencia roja es solo consola.
- La rama de allowlist **exime de todo** a cualquier ruta exenta que no sea `health`/`providers` (hoy `/api/test-db`): si respondiera 200 degradada, no se marcaría.

## Límites de esta auditoría

- No corrí la suite completa. El candado **no afecta al CI** (allí la base está arriba ⇒ inactivo) y no toca estáticos.
- Comprobé que el log `✅ [REDIS STATUS] ENABLED / CONNECTED` **es verdadero**: `beauty-redis` escuchando en `6379`. No hay mentira ahí.
- `providerController.js` cambia `getDbStatus` desestructurado por `db.getDbStatus()`: funcionalmente equivalente (la función lee estado vivo en ambos casos). Lo anoto como refactor inocuo, no como defecto.
