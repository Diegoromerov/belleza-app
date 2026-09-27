# Autorización — D-001 a D-005 (ejecución de las decisiones del Dueño)

**Fecha:** 2026-09-24 · **Autoriza:** Diego (Dueño), por instrucción textual: *«genera el prompt autorizando que haga las tareas D-001 · abrir el PR de fase-a/verdad-operativa … D-002 · delete_branch_on_merge = on … D-003 · los 331 commits del fósil … Mergear esta rama»*
**Quién ejecuta:** cualquiera de los agentes del sistema (`docs/agents/SISTEMA.md`) en una sesión **con permiso efectivo**, o el Dueño desde la UI. Lo que sigue es la autorización y el procedimiento, con sus puertas y su verificación.

---

## 0. Estado real de la ejecución (por qué esto no se ejecutó solo)

| Vía intentada | Resultado |
|---|---|
| Navegador automatizado | **sin sesión de GitHub**: `https://github.com/settings/profile` redirige a `/login` |
| Almacén de credenciales del sistema (vault) | **sin entradas** (`browser_vault_list` → `items: []`) |
| Credencial del `credential.helper` de git (GCM) para llamar a la API | **bloqueado por la plataforma**: el prompt de aprobación no se pudo entregar al cliente. No se reintenta ni se sortea. |

**Consecuencia:** las cinco tareas están **autorizadas y especificadas**, y se ejecutan por cualquiera de estas dos vías:
- **(a) Dueño, en la UI** — 4 acciones, ~2 minutos en total.
- **(b) Agente, en una sesión con aprobaciones habilitadas o con el login de GitHub guardado** (`browser_vault_save_login` en la página de login, que pide la contraseña en un prompt enmascarado propio de la UI; nunca en el chat).

Lo que **no** hay que hacer: pegar un token en el chat, en un archivo o en una URL. Si una vía exige eso, se detiene y se usa la otra.

---

## D-001 · Abrir el PR de `fase-a/verdad-operativa`  ⟵ *desbloquea el sistema entero*

**Por qué es la primera:** en este repositorio **nunca se ha ejecutado un run de CI**. Sin PR no hay puerta, y sin puerta la autonomía no tiene nada que vigilar.

- **Vía UI:** `https://github.com/Diegoromerov/belleza-app/pull/new/fase-a/verdad-operativa` → pegar título y cuerpo de `docs/agents/ordenes/PR-FASE-A-cuerpo.md` → *Create pull request*.
- **Vía API** (si hay permiso): `POST /repos/Diegoromerov/belleza-app/pulls` con `{"title": "...", "head": "fase-a/verdad-operativa", "base": "main", "body": "<contenido del archivo>"}`.

**Puertas antes de pulsar** (ya verificadas el 2026-09-24):
| Puerta | Valor medido |
|---|---|
| La rama existe en el remoto | `c1069e9f` = local = `origin/fase-a/verdad-operativa` |
| Commits fuera de `main` | 6 |
| PR previo de esa rama | ninguno (15 PRs en la historia, 2 abiertos: #10 y #12) |
| Árbol de la rama | limpio |

**Criterio de aceptación:** existe un run de CI en el PR y su resultado está pegado en la conversación (checks + URL).
**Qué hay que leer de ese run:** el paso bloqueante saldrá verde **por exclusión** — 10 patrones de suite quedan fuera (`geminiService|geminiFallback|auraToolExecutor|contract|biometric|resilience|contextCompressor|fase5|authRoutes|api.cors`) y corren en el paso no bloqueante. **Verde ≠ verificado**: queda **S3 = ✗** hasta que se ejecute O-005 (mutación) y **S1/S4 = ✗**.
**Rollback:** cerrar el PR. Nada más se modifica.

---

## D-002 · `delete_branch_on_merge = on`

- **Vía UI:** `https://github.com/Diegoromerov/belleza-app/settings` → *General* → *Pull Requests* → marcar **“Automatically delete head branches”**.
- **Vía API:** `PATCH /repos/Diegoromerov/belleza-app` con `{"delete_branch_on_merge": true}`.

**Verificación:** leer de vuelta el ajuste (`GET /repos/...` → `delete_branch_on_merge: true`) o comprobar que al mergear el siguiente PR su rama desaparece sola. Sin esa lectura de vuelta, no se declara hecho.
**Rollback:** desmarcar. No afecta a ramas existentes.

---

## D-003 · Los 331 commits del fósil — **criterio técnico: NO publicar. Rotar los secretos.**

Revisé técnicamente las 5 ramas con nombres sensibles (`feature/implement-encryption-at-rest`, `feature/implement-privacy-endpoints`, `feature/integrate-secret-manager`, `feature/migrate-env-to-secrets`, `feature/secret-manager-selection`). Todas son del **2026-07-31** (la misma tanda de trabajo de secret manager + cifrado en reposo) y **todas arrastran los mismos dos archivos de entorno**, con coincidencias de patrón de credencial en 8 archivos:

```
backend/.env.example · backend/.env.production
backend/scratch/make_pg_dump.js · backend/scratch/verify_after_deploy.js · backend/scratch/verify_real_railway.js
backend/src/services/geminiService.js · backend/tests/auth.integration.test.js · backend/tests/payment.test.js
```

**El repositorio es público** (la API responde 200 sin token). Publicar esas ramas = publicar `backend/.env.production`.
**Decisión técnica:** el valor de ese trabajo (una abstracción de Secret Manager para AWS) **no justifica** publicar credenciales de producción. El bundle de 319 MB se queda donde está (`auditorias/belleza-app/rescates/`), sin publicar, como archivo muerto consultable.

**Y el hallazgo que importa más que la decisión:** `backend/.env.production` **ya está en el historial de `main`** (2 commits lo tocan, aunque hoy no esté en el árbol). Ocultarlo no sirve de nada: **los secretos hay que rotarlos**.
Acciones del Dueño (en el proveedor, no en el repo):
1. Rotar `JWT_SECRET`, `ENCRYPTION_KEY`, `DATABASE_URL`, `GEMINI_API_KEY`, `YOCAM_API_KEY`, `OPENUV_API_KEY` y la clave de NVIDIA.
2. Después de rotar, decidir si el bundle se destruye (entonces sí: la copia local deja de tener valor) o se archiva cifrado.
3. Registrar el cierre en `docs/knowledge/DEUDA.md` → fila **SEG-04** (dueño: D), que hoy sigue en `parcial (ronda 2)`.

**Verificación:** `git log --oneline --all -- backend/.env.production | wc -l` sigue dando 2, pero los valores ya no sirven porque están rotados. La evidencia del cierre es la rotación, no el borrado del historial.

---

## D-004 · Mergear `docs/sistema-agentes` (sistema de agentes + base de conocimiento)

- **Vía UI:** `https://github.com/Diegoromerov/belleza-app/pull/new/docs/sistema-agentes` (la rama ya está publicada: `e6d038ab`).
- **Vía API:** `POST /repos/.../pulls` y después `PUT /repos/.../pulls/<n>/merge` con `{"merge_method":"squash"}`.

**Puerta de despliegue — verificada:** el único workflow con paso de deploy (`rag-evaluation.yml`, que hace `curl -X POST $RAILWAY_DEPLOY_HOOK`) se dispara por `paths:` limitados a `backend/src/services/ragEvaluator.js`, `backend/src/config/qualityGates.js`, `backend/src/data/eval/**`, `backend/scripts/evaluateRag.js`, `backend/scripts/ciRagEvaluation.sh`. **`docs/**` no está en esa lista** ⇒ este merge no dispara ese workflow. El repo no contiene ningún otro workflow de deploy.
**Riesgo residual que el Dueño debe confirmar:** si Railway tiene integración nativa que despliega en cada push a `main`, este push redesplegaría el servicio. Confirmarlo antes si esa integración existe; si no, el merge es inocuo.
**Criterio de aceptación:** `main` contiene `docs/agents/SISTEMA.md`, `docs/knowledge/` y `backend/scripts/estadoKB.js`; y `node backend/scripts/estadoKB.js --check` corre en un checkout de `main` con exit 0.
**Después del merge:** `node backend/scripts/estadoKB.js --write` para dejar el bloque máquina fresco en `main`, y borrar la rama (con D-002 activo, GitHub lo hace solo).

---

## D-005 · Mergear los PRs #10 y #12 (decisión aparte, no autorizada aquí)

Siguen abiertos y **no** forman parte de esta autorización: #12 trae el CSV de precios de GlowShop (base acordada del catálogo). Se mergean cuando el Dueño lo decida, con el CI en verde y la exclusión declarada.

---

## Puertas comunes (aplican a las cinco)

1. **Antes de cualquier acción:** `git ls-remote` de la rama, `rev-list --count main..<rama>` y `git status --porcelain` — pegados, no narrados.
2. **Después de cualquier acción:** lectura de vuelta del efecto (el run existe, el ajuste cambió, el merge está en `main`).
3. **Ninguna afirmación de éxito sin lectura de vuelta.** Un `201 Created` no es «el PR está bien»; el run de CI lo es.
4. **Prohibido:** pegar tokens en el chat, commitear credenciales, `push --force`, tocar `main` sin PR, borrar ramas sin tag verificado.
5. **Si algo falla:** se reporta el error crudo y se para. No se reintenta con variantes hasta que salga.
