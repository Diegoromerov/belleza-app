# Política de trabajo con git — belleza-app

El contrato es una sola rama de verdad: **`origin/main`**. Todo lo demás es una rama
de vida corta que existe para un PR y desaparece al mergearse. Esta política nace de
un incidente concreto: el 22-oct-2026 el repositorio tenía 58 ramas remotas —34 ya
mergeadas—, 33 ramas locales que nunca existieron en GitHub, 3 stashes de agosto y
trabajo terminado sin commitear (el motor de email y 10 plantillas) que se creía
perdido.

## 1. `main` es lo único que se publica

- Nadie hace push directo a `main`: entra por PR.
- Los clones locales solo la siguen: `git config pull.ff only` y `git pull --ff-only`.
  Un merge local que cree un commit en `main` distinto del remoto es divergencia, y la
  divergencia es la que produjo las 33 ramas huérfanas.
- `main` debe estar siempre verde. Si el gate de CI está rojo, lo primero no es la
  siguiente tarea: es devolverlo a verde.

## 2. Ramas: cortas, una por tarjeta, borradas al mergear

- Nace de `main`, se mergea por PR y **se borra**. No hay ramas "por si acaso".
- Nunca se acumulan ramas locales que no existan en el remoto: si no está publicada,
  no existe para nadie más y desaparece con el disco.
- Antes de crear una rama: `git fetch --prune` y mirar el remoto, no solo el worktree.
- Los worktrees (`git worktree`) se retiran con `git worktree remove` al terminar;
  un worktree olvidado deja la rama secuestrada y bloquea su borrado (le pasó a
  `glowapp-fix`, que ocupaba 526 MB y 32 ramas).

## 3. Nada de trabajo sin commitear

- Lo que no está commiteado no existe: no se revisa, no se prueba en CI, no se
  despliega y no se puede recuperar si se pierde el disco.
- El trabajo sin terminar se commitea en la rama del PR, aunque sea en un commit
  marcado como WIP. Se prefiere un commit feo a un archivo perdido.
- Los stashes son de horas, no de semanas: un stash de agosto es un archivo perdido
  que aún no lo sabe.

## 4. Migraciones: el número se elige mirando el remoto

- Un prefijo numérico = una migración. Se toma el **libre más alto + 1** comprobando el
  directorio **y las ramas en vuelo en el remoto** (ver `backend/migrations/REGISTRY.md`).
- Dos personas eligieron `107` el mismo día; el merge entró y el gate de numeración
  quedó rojo en `main` durante dos días. El guard hace su trabajo: hay que leerlo antes
  de mergear, no después.
- Si el número choca: se renumera la migración **no aplicada**.

## 5. Antes de pedir el merge

```bash
cd backend
node tests/migrationsNoDuplicateNumbers.test.js    # numeración
npm run openapi:check                              # contrato sincronizado
npx jest <las suites tocadas>                      # al menos lo que se tocó
```

## 6. Checklist del merge

1. `git fetch --prune` y PR contra `main` (sin push directo).
2. CI verde: `Backend Tests & Lint` y `Frontend Flutter Analyze & Build Check`.
3. Merge y **borrar la rama** (local y remota).
4. En los clones: `git pull --ff-only`.
5. Verificar el despliegue: `/api/health` debe reportar el commit nuevo.
