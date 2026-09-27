# ORDEN A-06 · La compuerta de credenciales no puede depender del fin de línea

**Origen:** `docs/audit/AUDITORIA-PR-16-RUN-1681-2026-09-24.md` (PR #16, run [#1681](https://github.com/Diegoromerov/belleza-app/actions/runs/36072881287))
**Rama:** `fix/compuerta-secretos-reproducible` desde `fase-a/verdad-operativa` (para que el PR #16 vuelva a correr con el arreglo encima).
**Prioridad:** **antes que A-01**. El run muere en este paso y por eso los pasos 8-11 nunca se ejercitan.

---

## GOAL (una frase)

Que `backend/scripts/verifyNoVersionedSecrets.js` dé **el mismo veredicto sobre el mismo commit** en un checkout con CRLF y en uno con LF, y que su veredicto hable de **código y configuración**, no de prosa.

## Reproducción que debes pegar (falla hoy)

```bash
# desde la raíz de tu copia del repo (rutas relativas: en Windows, /tmp no lo traduce git nativo)
git -c core.autocrlf=true  worktree add -q --detach ../ci-check-crlf origin/fase-a/verdad-operativa
git -c core.autocrlf=false worktree add -q --detach ../ci-check-lf   origin/fase-a/verdad-operativa
(cd ../ci-check-crlf/backend && node scripts/verifyNoVersionedSecrets.js); echo "CRLF EXIT=$?"
(cd ../ci-check-lf/backend   && node scripts/verifyNoVersionedSecrets.js); echo "LF   EXIT=$?"
# al terminar, retira las dos copias:
git worktree remove --force ../ci-check-crlf ../ci-check-lf
```

Medido en Windows con la rama `fase-a` @ `c1069e9f`: **CRLF → ✅ EXIT=0** · **LF → ❌ 39 EXIT=1**. Mismo commit, mismo hash de árbol (`6d9464ca1abe`), mismos 3.722 archivos trackeados, mismas 225 líneas candidatas de `git grep`. La única diferencia medida: en la copia con conversión, `git grep` devuelve cada línea **con un `\r` final**, y con ese `\r` los 39 hallazgos desaparecen.

## Qué hay que arreglar

1. **Independizarlo del fin de línea.** Normaliza antes de validar (`linea.replace(/\r$/, '')`) **o, mejor**, lee los blobs del commit en vez del árbol de trabajo (`git grep … <ref> -- .`), que es el estado que realmente se despliega. Elige una y explica por qué en el PR.
2. **Acota el alcance.** La compuerta existe para impedir que se despliegue un secreto, no para auditar prosa. Decide y aplica una regla explícita: `.md`, informes en la raíz, `.hermes/desktop-attachments/**` y `docs/**` **no bloquean** (se listan como aviso no bloqueante) — o se excluyen, declarándolo en el comentario del script.
3. **Las credenciales efímeras del runner.** `ci.yml:26,84,95` (`POSTGRES_PASSWORD: postgres`, `postgres://…:ci_only_password@localhost/glowtest`) son de una base que vive lo que vive el job. O se pasan por variable de entorno, o se declaran exentas con el motivo escrito al lado. No dejes que el workflow se auto-denuncie.
4. **Revisa los 8 literales de código, uno por uno** y declara veredicto por cada uno: `src/config/jwt.js:2` · `src/services/biometricCryptoService.js:18,39,59` · `src/config/database.js:40` · `runMigrations.js:93` · `Dockerfile.postgres:12` · `scripts/generateBaselineR5b.js:72`. Si alguno es un secreto real: se mueve a entorno, **se rota** y se registra en `DEUDA.md`.
5. **Dale a la compuerta un autotest.** Un test que construya una línea con y sin `\r` y exija el mismo veredicto. Es lo que impide que esto vuelva.

## Criterios de aceptación (falsables, con salida pegada)

| # | Criterio | Cómo se prueba |
|---|---|---|
| C1 | El mismo commit da el **mismo veredicto** en checkout CRLF y LF | el bloque de reproducción, con los dos `EXIT=` |
| C2 | Ningún archivo de prosa (`.md`, informes, adjuntos) **bloquea** | la lista de hallazgos del paso 7 no contiene `.md` ni `.hermes/` |
| C3 | El workflow no se denuncia a sí mismo | `ci.yml` fuera de los hallazgos bloqueantes |
| C4 | Los 8 literales de código tienen veredicto declarado en el PR (arreglado o justificado) | tabla en el cuerpo del PR, uno por línea |
| C5 | Existe el autotest de CRLF | test nuevo que falla si alguien quita la normalización |
| C6 | El paso 7 del CI pasa y **los pasos 8-11 se ejecutan** | URL del run nuevo, con los pasos 8-11 en `success`/`failure` real (ya no `skipped`) |

## Prohibiciones

Bajar el paso 7 a no bloqueante para que el PR salga verde · permitir todo con un `ALLOW_MARKERS` genérico que apague la regla · tocar `index.js` · resolver C6 desactivando RLS · imprimir valores de credenciales en el log (hoy el script no los imprime: **mantenlo así**).
