#!/bin/bash
# daily-journal-post — once a day, turn yesterday's journal entry into a draft post PR.
#
#   ./daily-journal-post.sh              yesterday's entry
#   ./daily-journal-post.sh 2026-07-23   a specific date
#   ./daily-journal-post.sh --dry-run    generate and gate, but open no PR
#
# Does NOT publish. It opens a pull request and stops. Pushing to master publishes the
# site immediately, and a leak that reaches a public site cannot be unpublished.
set -uo pipefail

JOURNAL_DIR="$HOME/Documents/Personal/Repositories/personal-kb/journal"
SITE="$HOME/Documents/Personal/Repositories/duv0-x.github.io"
GATE="$(cd "$(dirname "$0")" && pwd)/journal-post-gate.sh"
MODEL="${JOURNAL_POST_MODEL:-ollama-cloud/deepseek-v4-pro}"
LOG="$HOME/.claude/logs/daily-journal-post.log"
mkdir -p "$(dirname "$LOG")"

DRY=0; DATE=""
for a in "$@"; do
  case "$a" in
    --dry-run) DRY=1 ;;
    -h|--help) sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) DATE="$a" ;;
  esac
done
[ -n "$DATE" ] || DATE=$(date -v-1d +%F 2>/dev/null || date -d yesterday +%F)

say() { printf '[%s] %s\n' "$(date +%H:%M:%S)" "$*" | tee -a "$LOG"; }

ENTRY="$JOURNAL_DIR/$DATE.md"
[ -f "$ENTRY" ] || { say "sin entrada de journal para $DATE — nada que publicar"; exit 0; }

# ¿ya hay un post de esa fecha?
if grep -q "data-date=\"$DATE\"" "$SITE/index.html" 2>/dev/null; then
  say "ya existe un post con fecha $DATE — nada que hacer"; exit 0
fi

say "generando post para $DATE con $MODEL"

PROMPT="Sigue la skill 'journal-a-post' al pie de la letra.

Entrada del journal a convertir: $ENTRY
Fecha del post: $DATE

Genera UN solo bloque <article class=\"post-card\">, con el formato y la sangría exactos que
define la skill, y pásalo por el gate obligatorio antes de continuar. Si el gate lo rechaza,
reescribe en términos más genéricos y vuelve a pasarlo — nunca edites el gate.
Si el día no da para un post publicable, dilo y no generes nada.
Termina abriendo el pull request con la rama post/$DATE. NO hagas push a master."

if [ "$DRY" -eq 1 ]; then
  say "dry-run: no se abrirá PR"
  PROMPT="$PROMPT

MODO DRY-RUN: genera el <article> y pásalo por el gate, pero NO toques el repositorio del sitio."
fi

opencode run --pure -m "$MODEL" --dangerously-skip-permissions "$PROMPT" 2>&1 | tee -a "$LOG"
RC=${PIPESTATUS[0]}

if [ "$RC" -ne 0 ]; then
  say "opencode terminó con código $RC — revisa $LOG"
  exit "$RC"
fi

say "listo. Si se abrió PR, revísalo antes de mergear:  gh pr list -R duv0-x/duv0-x.github.io"
