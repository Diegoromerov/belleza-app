#!/usr/bin/env bash
# Guardián de estado — Belleza App / GlowApp (versionado en el repo).
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

if ! cd "$ROOT_DIR" 2>/dev/null; then
  echo "REPO NO ENCONTRADO EN $ROOT_DIR"
  exit 1
fi

S="${ESTADO_KB_SCRIPT:-}"
if [ -z "$S" ]; then
  for p in "$ROOT_DIR/backend/scripts/estadoKB.js" "$ROOT_DIR/scripts/estadoKB.js"; do
    if [ -f "$p" ]; then
      S="$p"
      break
    fi
  done
fi

NODE_CMD="$(command -v node 2>/dev/null || command -v node.exe 2>/dev/null || echo "node")"

echo "== copia inspeccionada =="
echo "ruta: $(git rev-parse --show-toplevel 2>/dev/null || echo "$ROOT_DIR")"
echo "rama: $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "(desconocida)") @ $(git rev-parse --short HEAD 2>/dev/null || echo "?")"
echo "arbol: $(git status --porcelain -uall 2>/dev/null | wc -l | tr -d ' ') entradas sin commitear"

echo "== ramas locales y commits fuera de main =="
for b in $(git for-each-ref --format='%(refname:short)' refs/heads 2>/dev/null); do
  cnt=$(git rev-list --count "main..$b" 2>/dev/null || echo "?")
  sha=$(git rev-parse --short "$b" 2>/dev/null || echo "?")
  printf '%s | %s | %s\n' "$b" "$sha" "$cnt"
done

echo "== ramas en el remoto =="
REMOTE_HEADS=$(git ls-remote --heads origin 2>/dev/null | awk '{print "  " $2}' | sed 's|refs/heads/||')
if [ -n "$REMOTE_HEADS" ]; then
  echo "$REMOTE_HEADS"
else
  echo "  NO VERIFICADO (la consulta ls-remote no respondió)"
fi

echo "== PRs abiertos =="
PR_JSON=$(curl -s -m 20 "https://api.github.com/repos/Diegoromerov/belleza-app/pulls?state=open&per_page=100" 2>/dev/null)
if [ -n "$PR_JSON" ] && echo "$PR_JSON" | grep -q '"number":'; then
  echo "$PR_JSON" | grep -oE '"number": *[0-9]+|"ref": *"[^"]+"' | paste - - 2>/dev/null || echo "  NO VERIFICADO"
else
  echo "  NO VERIFICADO (la API no respondió)"
fi

echo "== tags archive/* =="
TAG_LOC=$(git tag -l 'archive/*' 2>/dev/null | wc -l | tr -d ' ')
TAG_REM=$(git ls-remote --tags origin 2>/dev/null | grep -c 'archive/' || echo "0")
echo "  locales: $TAG_LOC | refs remotas: $TAG_REM"

echo "== guardián estadoKB --check =="
if [ -n "$S" ] && [ -f "$S" ]; then
  "$NODE_CMD" "$S" --check
  KB_EXIT=$?
  echo "exit=$KB_EXIT"
  exit $KB_EXIT
else
  echo "estadoKB.js no encontrado (NO DISPONIBLE)"
  echo "exit=no-disponible"
  exit 1
fi
