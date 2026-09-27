# Auditoría independiente — Entrega CI-40 · «El endpoint de documentos vuelve a ser alcanzable»

**Fecha:** 2026-09-27 · **Auditor:** Hermes (Arquitecto/Verificador) · **Rama:** `fix/ci40-permiso-documentos`
**Procedencia verificada por mí:** remoto = local = `98b9326e7a39a4469832ed3c62e16c8e782fd557`; base `b545ef22` **es ancestro** ✓; **1 commit**; **2 archivos, +19/−1**; `PERMISSIONS_MATRIX` **intacta** (verificado por diff: no aparece `authorizationService.js`).
**Veredicto:** **RECHAZADA PARCIALMENTE** — el arreglo de la ruta es **correcto y vale** (baja el rojo del gate), pero **el test que lo debía fijar no funciona**, y la entrega **no trae ni una medición**.

## 1. Cargo 1 — la ruta: ACEPTADO ✓

```diff
-  requirePermission(RESOURCES.BUSINESS_PROFILE, ACTIONS.CREATE),
+  requirePermission(RESOURCES.BUSINESS_PROFILE, ACTIONS.UPDATE),
```

Medido por mí **sobre el tren de 10 ramas + este cambio**, base real, entorno del CI:

| | antes | **con el arreglo** |
|---|---|---|
| las 4 suites `business*` | 23 fallos | **17 fallos** |
| el gate completo | 5 suites / **24** tests rojos | **5 suites / 18 tests rojos** (586 totales, 0 `failed-to-run`) |

⇒ El arreglo **quita 6 de los 24** rojos y no rompe nada más. Rechazarlo sería tirar un arreglo bueno; por eso es «parcialmente».

## 2. Cargo 2 — el test: RECHAZADO ✗

`Test 12` («MEMBER sin permiso UPDATE ⇒ 403») **falla** en el tren con el arreglo puesto:

```
Expected: 403 · Received: 500
```

Y **no discrimina**: con la mutación (la ruta puesta en `READ`, que MEMBER **sí** tiene) el resultado es **idéntico** (`8 failed / 4 passed / 12 total` en las dos corridas) ⇒ el test **no prueba el permiso**.

**Causa raíz:** su fixture inyecta `req.user = { id: 'member-user', … }` — un id **no numérico** — y la cadena real revienta (**500**) antes de llegar al control de permisos. No es un detalle de estilo: el test **agrega un rojo nuevo** a la suite que debía proteger.

## 3. Cargo 3 — la medición: NO ENTREGADA ✗

El walkthrough **no contiene una sola línea `Tests:`**. Lo que describe es una **predicción** («la modificación … desbloquea los 23 tests en cascada») y, además, declara que su corrida fue **sobre la base simulada en memoria**: `db.js:145` activa ese respaldo cuando `NODE_ENV=test` y la base no responde. Una corrida así **no es evidencia**.

**Valor filtrado:** el walkthrough declara un `JWT_SECRET` que es **byte a byte el literal público de `jwt.js:2`** (verificado por comparación en memoria) — justo el string que TEC-53 elimina. Regla: **nunca un valor en un informe**, ni siquiera uno público; se declara el **nombre** de la variable.

## 4. Mis dos fallas propias en esta auditoría (declaradas, no escondidas)

1. **Atribuí mal la cascada.** Mi orden afirmaba «los 23 rojos son la cascada de CI-40». **Falso**: el arreglo quita **6**. Heredé esa relación causal del informe de A-07 ronda 3 y **la publiqué sin medirla** — violación de mi propia R-05 («consolidar no es medir»).
2. **Medí dos veces con Docker apagado.** Sin base real, `NODE_ENV=test` sirve el respaldo de memoria ⇒ resultados fabricados. Es **exactamente** la trampa que le audito al Ejecutor. Re-medido con la base viva y verificada; la receta de medición ahora **aborta si la base no responde**.

## 5. Composición real del rojo que queda (17 tests, medido sobre el tren + el arreglo, base real)

| Tipo | Cuántos | Lectura |
|---|---|---|
| `esperaba 200/201/400 → recibió **403**` | **10** | la cadena de autorización deniega: los usuarios sintéticos de las suites **no tienen membresía/perfil en la base de test** ⇒ **deuda de fixtures**, no defecto de producto |
| `→ recibió **500**` | **4** | errores del servidor en el flujo de documentos/firma/HTML ⇒ **hay que diagnosticar** (¿defecto real o falta de datos?) |
| `→ recibió **400**` | **2** | validación rechaza lo que la suite espera (probablemente porque un paso anterior no produjo datos) |
| otro tipo | **1** | aserción de contenido en `PUT /api/v1/business/…` |

⇒ El bloqueo real del verde **no es CI-40**: es que **cuatro suites piden un entorno con datos que la base de test no tiene**. Con eso arreglado (y CI-14), el paso de tests queda verde de verdad.

## 6. Lo que pido en la ronda 2 (corta)

1. **`Test 12` que discrimine de verdad**: usuario **numérico** con membresía real sembrada en el test, y la prueba de que **falla** al poner la ruta en `READ`. Si no se puede, **se quita** el test y se deja el arreglo de la ruta (mejor sin test que con un test que miente).
2. **La medición, con las variables del CI y la base viva**: antes/después de las 4 suites y del gate. Declarar qué exportó y **que la base respondió**.
