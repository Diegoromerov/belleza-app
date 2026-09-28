# Orden — CI-58: el test del guardián no corre en Linux (rojo nuevo en `main`)

**Para**: Antigravity (Ejecutor) · **De**: Arquitecto/Auditor · **Fecha**: 2026-09-28
**Rama**: `fix/ci58-guardian-portable` (desde `main` @ `38a1defa4` o el tip que veas)
**Prohibido**: mergear. Terminás con la rama empujada y su PR **sin mergear**.

## 0. Qué pasó — medido por el Auditor, no supuesto

El merge de `chore/guardian-en-el-repo` (`cb0dc0e94`) **movió el baseline del gate**:

| | Suites | Tests |
|---|---|---|
| `main` antes (tras la KB) | `4 failed, 75 passed, 79 total` | `23 failed, 1 skipped, 580 passed, 604 total` |
| `main` después (tras el guardián) | **`5 failed, 76 passed, 81 total`** | **`24 failed, 1 skipped, 586 passed, 611 total`** |

El rojo nuevo, **nombrado por la anotación que publica el propio CI** (run sobre `38a1defa4`, job
`Backend Tests & Lint`):

```
> 35 |     expect(res.stdout).toMatch(/ruta: [A-Za-z]:[/\\]/);
 34 |     expect(res.stdout).toContain("== guardián estadoKB --check ==");
 33 |     expect(res.stdout).not.toContain("Cannot find module");
exit=1
Resumen: ramas=1 · muertas-vivas=0 · sin-pr-ni-tag=0 · worktrees=1 · desalineaciones=2
```

**Dos causas, las dos de haber escrito el test en Windows y no correrlo nunca en Linux:**

1. La aserción de la línea 35 exige una ruta con **letra de unidad de Windows**; en el runner la
   ruta es `/home/runner/...`.
2. El script devuelve `exit=1` con **`desalineaciones=2`**: la regla de frescura (R4) se dispara en
   un checkout limpio, sin partes en `docs/agents/partes/`.

El test se aceptó el 2026-09-26 con **7/7 en la máquina local (Windows)** y **jamás corrió en el CI**:
hasta hoy el paso de tests del runner no ejecutaba ninguna suite (CI-46/CI-54). Este es el primer rojo
que el CI le cobra a un test nacido local.

## 1. Qué se pide (sólo esto)

1. **La aserción de ruta**: que valide la ruta que el script produce **en la plataforma actual**, no
   la de Windows. **No la relajes hasta volverla vacua**: esa aserción existe para probar que el
   script resuelve una ruta **nativa** (era el Cargo 1 de O-014, CI-25). Probala en los dos sentidos:
   una ruta con letra de unidad debe satisfacerla en Windows; una ruta POSIX, en Linux.
2. **La expectativa de frescura**: decidí **con evidencia** si en un checkout limpio (sin partes)
   `desalineaciones` debe ser `2` o `0`, y dejá escrito en el test **por qué** ese número es el
   correcto. Si la regla R4 es correcta tal como está, el test debe esperar las desalineaciones y
   asertar la **causa**, no el número pelado.

## 2. Prohibido

- Tocar `ci.yml` o las exclusiones del gate.
- Borrar, saltear o marcar `skip` el test. Un test borrado no es un test arreglado.
- Bajar el umbral de frescura para que el test pase. Si el umbral está mal, **decilo en el informe** y
  no lo cambies.
- Compensar con otro cambio "para que el gate quede en 4 rojos".

## 3. Entrega

- El nombre del test que era rojo y las **dos líneas del gate** del run de su PR.
- Baseline que espero si el arreglo es correcto: **`4 failed, 77 passed, 81 total` ·
  `Tests: 23 failed, 1 skipped, 587 passed, 611 total`** (una suite pasa de roja a verde; el total de
  611 tests y 81 suites no baja).
- Si el número legítimamente cambia, explicá por qué con la medición, no con el razonamiento.

## 4. Criterio de aceptación

Un run en GitHub cuyo gate reemita `4 failed, … 81 total` con la suite del guardián **verde**, y el
número total de tests **≥ 611**.
