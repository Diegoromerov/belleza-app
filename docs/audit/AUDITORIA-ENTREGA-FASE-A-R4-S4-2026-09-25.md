# Auditoría — Fase A ronda 4 (S4) · `3cef7f88`

**Fecha:** 2026-09-25 · **Auditor:** Hermes
**Procedencia:** commit **`3cef7f88` dentro de `fase-a/verdad-operativa`** (sobre `9a86a902`). Worktree desechable propio sobre ese commit, servidor levantado por mí con la base muerta, rutas plantadas **por mí** con nombres distintos a los suyos.

## Veredicto: **S4 ✓ ACEPTADO** — el cargo principal está cerrado y lo medí yo

---

## C1 (el cargo grave de la ronda 3) — ✓ cerrado, medido en vivo

Planté **dos** rutas en `index.js` (líneas 226-227, antes del candado) y **no toqué** ni `smokeSurfaces.js` ni el inventario:

| Plantada | Respuesta con la base muerta | Qué hace el guardián |
|---|---|---|
| `GET /api/__hermes_probe_2` | 200 | **`❌ FAKED SUCCESS` → `exit 1`** ✓ |
| `GET /__hermes_fuera` (fuera de `/api`) | 200 | no la marca ✓ (control negativo: la regla de clase está bien acotada a `/api`) |

Salida cruda de su guardián, corriéndolo yo:

```
🔍 Descubiertas dinámicamente 310 rutas del stack vivo de Express.
📊 Estado del servidor detectado (probes inicio): IsDegraded=true, HealthStatus=503
❌ FAKED SUCCESS detectado en GET /api/__hermes_probe_2 -> HTTP 200 (respuesta 2xx engañosa en estado degradado)
📋 Resumen de Smoke Test (124 superficies probadas): Faked Success Totales: 1
❌ SMOKE TEST FALLIDO                                                        EXIT=1
```

- **310 = 308 + mis 2** ⇒ descubre del **stack vivo** (`require('../index')` con `NODE_ENV=test`, y `index.js:1813` sólo escucha fuera de test, así que no hay segundo `listen`) ✓ y **no** cayó al inventario (0 líneas de «inventario respaldado») ✓.
- Informe fresco escrito con mi corrida: `smoke-2026-09-25-degraded.json`, `server_degraded=true`, `124` probadas, `fakes=1`, `empty_like` **0 ocurrencias** ✓ (C2 y C4 de la orden).
- **C3 ✓ medido de rebote:** mi corrida roja reescribió `-degraded.json` **sin tocar** el `-ok.json` de su corrida (timestamp `04:28:54` intacto) ⇒ la conservación por sufijo funciona.
- **C6 ✓**: la declaración de alcance (dinero e identidad) **está en el cuerpo del commit**, no solo en el chat.
- **C5 ✓ por lectura + medición:** la allowlist tiene regla explícita de 2xx engañoso para `health`, `providers` y `test-db`, y `/api/test-db` ahora responde `503 status:"error"` cuando está degradado (`index.js:449`, medido).

→ **CI-15 queda CERRADA.**

## C2 (base arriba) — **no lo pude reproducir; lo declaro, no lo doy por bueno**

Dos intentos míos de levantar el backend sano desde un worktree limpio fallaron **por mi entorno**, no por su entrega:
- con `DATABASE_URL` a `127.0.0.1:5435/beauty_db`: `Error: The server does not support SSL connections` (su `getSslConfig` activa SSL por heurística; el Postgres local no lo soporta);
- con `localhost:5435`: mismo 503.
La conexión TCP en sí **sí funciona** (verificado aparte con `pg`: `{current_user: admin, current_database: beauty_db}`). El caso sano está **garantizado por construcción** —con `isServerDegraded=false` no se evalúa ninguna rama de la regla, y el candado sólo actúa si `servingFabricatedData === true || !pgAvailable`— pero eso es lectura de código, no medición mía. Su salida pegada (122 superficies, 0 fakes, `/api/products` 200 con `count:296`) sigue siendo la única evidencia del caso sano ⇒ **CI-17**.

## Observaciones (no veredictos)

1. **Respaldo al inventario si el stack vivo no carga** (`smokeSurfaces.js:124-130`): si `require('../index')` falla, `routes` queda vacío y el guardián **continúa** con el inventario estático (imprimiendo una línea de aviso). Es exactamente el estado del que venía CI-15, sólo que ahora avisa. Debería **fallar fuerte** (`exit 1`): un guardián que degrada a una lista vieja no puede pasar por verde.
2. **`✅ Migración … aplicada exitosamente` sin enlace**: en mi corrida degradada el arranque registró 18 migraciones como aplicadas mientras el pool reportaba `ECONNREFUSED …:5999 — se sirve memoria local`. El string **no está** en `backend/runMigrations.js` ni en `backend/src/config/migrationRunner.js` ⇒ no sé todavía quién lo imprime ni sobre qué conexión. **No lo publico como hallazgo** (R-05): queda como medición pendiente — localizar el emisor del string y el cliente que usa.

## Límites

- Corridas mías sobre copia desechable; el worktree se retiró al terminar y la rama no se tocó.
- Mediciones fallidas propias registradas (R-06), no borradas: (a) `NODE_PATH` apuntando a `C:/beauty-app/fase-a/backend/node_modules`, que está **vacío** ⇒ el guardián murió con `Cannot find module 'pg'` y leí por error el informe **commiteado** en vez del mío; (b) proceso en segundo plano sin la credencial (`28P01`); (c) dos intentos del caso sano con SSL (arriba).
