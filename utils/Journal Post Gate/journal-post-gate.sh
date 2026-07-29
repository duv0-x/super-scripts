#!/bin/bash
# journal-post-gate — refuses to let a generated journal post reach a public site
# if it contains anything that identifies an employer, an account, or a person.
#
#   journal-post-gate.sh <file>        check a file
#   cat post.html | journal-post-gate.sh   check stdin
#   journal-post-gate.sh --patterns    print the active ruleset and exit
#
# Exit 0 = clean, safe to publish.
# Exit 1 = blocked, prints every match with its line.
# Exit 2 = usage error.
#
# This is deliberately dumb and deterministic. The model writes the prose; this
# decides whether it ships. Never replace it with model judgement.
set -u

CONF="${JOURNAL_GATE_CONFIG:-$HOME/.config/journal-post-gate}"
EXTRA="$CONF/denylist.txt"      # términos literales, uno por línea
PATTERNS="$CONF/patterns.txt"   # reglas propias "etiqueta|regex", una por línea

# Reglas genéricas — las que valen para cualquiera. Lo específico de TU empleador
# (nombres de compañía, prefijos de repo, IDs de ticket, perfiles de nube) NO va aquí:
# va en $PATTERNS, fuera de este repositorio. Un script público que enumera los
# identificadores privados de una empresa es la misma fuga que pretende evitar.
#
# label|regex(ERE)
RULES=(
  "cuenta AWS (12 dígitos)|\\b[0-9]{12}\\b"
  "host de repositorio privado|(bitbucket\\.org|atlassian\\.net|gitlab\\.[a-z]+/)"
  "ARN de AWS|arn:aws:"
  "dirección IP|\\b[0-9]{1,3}(\\.[0-9]{1,3}){3}\\b"
  "posible secreto|(AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{20,}|sbp_[a-f0-9]{20,}|lin_api_|CCIPAT_|xox[baprs]-)"
  "ruta personal absoluta|/Users/[a-z0-9_-]+/"
  "credencial en URL|://[^/ ]+:[^@/ ]+@"
)

usage() { sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 2; }

if [ "${1:-}" = "--patterns" ]; then
  printf '%-34s %s\n' "REGLA" "PATRÓN"
  for r in "${RULES[@]}"; do printf '%-34s %s\n' "${r%%|*}" "${r#*|}"; done
  echo
  for f in "$PATTERNS:reglas privadas" "$EXTRA:términos literales"; do
    p="${f%%:*}"; d="${f#*:}"
    if [ -f "$p" ]; then echo "$d ($p): $(grep -cvE '^\s*(#|$)' "$p" 2>/dev/null)"
    else echo "$d: sin configurar — crea $p"; fi
  done
  exit 0
fi

[ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ] && usage

if [ $# -ge 1 ]; then
  [ -f "$1" ] || { echo "No existe el archivo: $1" >&2; exit 2; }
  CONTENT=$(cat "$1"); SRC="$1"
else
  CONTENT=$(cat); SRC="(stdin)"
fi

[ -n "$CONTENT" ] || { echo "Contenido vacío" >&2; exit 2; }

FOUND=0
report() {  # label, matches
  FOUND=1
  printf '\033[31m  ✘ %s\033[0m\n' "$1"
  printf '%s\n' "$2" | sed 's/^/      /'
}

# reglas privadas del usuario: mismo formato "etiqueta|regex"
if [ -f "$PATTERNS" ]; then
  while IFS= read -r line; do
    case "$line" in ''|\#*) continue ;; esac
    RULES+=("$line")
  done < "$PATTERNS"
fi

for r in "${RULES[@]}"; do
  label="${r%%|*}"; pat="${r#*|}"
  m=$(printf '%s' "$CONTENT" | grep -nEo "$pat" 2>/dev/null | sort -u | head -5)
  [ -n "$m" ] && report "$label" "$m"
done

# denylist externa: un término por línea, insensible a mayúsculas, # para comentarios
if [ -f "$EXTRA" ]; then
  while IFS= read -r term; do
    case "$term" in ''|\#*) continue ;; esac
    m=$(printf '%s' "$CONTENT" | grep -niFo "$term" 2>/dev/null | sort -u | head -3)
    [ -n "$m" ] && report "término en denylist: $term" "$m"
  done < "$EXTRA"
fi

if [ "$FOUND" -eq 1 ]; then
  echo
  echo "BLOQUEADO — $SRC no se publica."
  echo "Reescribe el post en términos genéricos: qué tipo de sistema y qué aprendiste,"
  echo "sin nombrar la cuenta, el repo, el ticket ni a la persona."
  exit 1
fi

printf '\033[32m  ✔ limpio\033[0m — %s puede publicarse\n' "$SRC"
exit 0
