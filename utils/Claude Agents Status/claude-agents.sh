#!/bin/bash
# claude-agents — estado de la flota de agentes en background de Claude Code.
#
#   claude-agents            solo los vivos (working/blocked) + resumen
#   claude-agents -a         todos, incluidos los done
#   claude-agents -d         solo los done (candidatos a compactar)
#   claude-agents -f         ordena por tamaño de tmp/ (quién ocupa disco)
#   claude-agents -j         salida JSON
#   claude-agents <id>       detalle de una sesión concreta
#
# Un agente "abandonado" es uno bloqueado hace >7 días con <5k tokens:
# no está esperando a nadie, se colgó al arrancar.

set -u
JOBS="${CLAUDE_JOBS_DIR:-$HOME/.claude/jobs}"
JQ=/usr/bin/jq
[ -d "$JOBS" ] || { echo "No existe $JOBS"; exit 1; }

MODE=live; SORT=state; AS_JSON=0; ONE=""
while [ $# -gt 0 ]; do
  case "$1" in
    -a|--all)  MODE=all ;;
    -d|--done) MODE=done ;;
    -f|--fat)  SORT=size; MODE=all ;;
    -j|--json) AS_JSON=1; MODE=all ;;
    -h|--help) sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)         ONE="$1" ;;
  esac
  shift
done

# --- detalle de una sesion ---------------------------------------------------
if [ -n "$ONE" ]; then
  s="$JOBS/$ONE/state.json"
  [ -f "$s" ] || { echo "No encuentro la sesión '$ONE' en $JOBS"; exit 1; }
  echo "sesión:   $ONE"
  $JQ -r '"estado:   \(.state // "?")
tokens:   \(.tokens // 0)
nombre:   \(.name // .intent // "-")
detalle:  \(.detail // "-")
modelo:   \((.respawnFlags // []) | join(" "))
resultado:\((.output.result // "-") | .[0:600])"' "$s"
  echo "tmp:      $(du -sh "$JOBS/$ONE/tmp" 2>/dev/null | cut -f1 || echo '-')"
  echo "log:      $($JQ -r '.linkScanPath // "-"' "$s")"
  echo
  echo "--- últimos eventos ---"
  tail -5 "$JOBS/$ONE/timeline.jsonl" 2>/dev/null | $JQ -rc '.' 2>/dev/null | cut -c1-160
  exit 0
fi

# --- recolectar --------------------------------------------------------------
now=$(date +%s)
rows=$(
  for d in "$JOBS"/*/; do
    id=$(basename "$d"); s="$d/state.json"; [ -f "$s" ] || continue
    st=$($JQ -r '.state // "unknown"' "$s" 2>/dev/null)
    tk=$($JQ -r '.tokens // 0' "$s" 2>/dev/null)
    nm=$($JQ -r '(.name // .intent // .detail // "-")' "$s" 2>/dev/null | tr '\n' ' ' | cut -c1-46)
    age=$(( (now - $(stat -f %m "$s" 2>/dev/null || echo "$now")) / 86400 ))
    kb=$(du -sk "$d/tmp" 2>/dev/null | cut -f1); kb=${kb:-0}
    flag=""
    [ "$st" = "blocked" ] && [ "$age" -gt 7 ] && [ "$tk" -lt 5000 ] 2>/dev/null && flag="ABANDONADO?"
    [ "$st" = "done" ] && [ "$kb" -gt 10240 ] && flag="tmp pesado"
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$st" "$age" "$tk" "$kb" "$id" "$nm" "$flag"
  done
)
[ -n "$rows" ] || { echo "No hay sesiones en $JOBS"; exit 0; }

if [ "$AS_JSON" = "1" ]; then
  printf '%s\n' "$rows" | awk -F'\t' 'BEGIN{print "["; c=0}
    {if(c++)print ",";printf "  {\"state\":\"%s\",\"age_days\":%s,\"tokens\":%s,\"tmp_kb\":%s,\"id\":\"%s\",\"name\":\"%s\",\"flag\":\"%s\"}",$1,$2,$3,$4,$5,$6,$7}
    END{print "\n]"}'
  exit 0
fi

case "$MODE" in
  live) sel=$(printf '%s\n' "$rows" | awk -F'\t' '$1=="working"||$1=="blocked"||$1=="unknown"') ;;
  done) sel=$(printf '%s\n' "$rows" | awk -F'\t' '$1=="done"') ;;
  *)    sel="$rows" ;;
esac

if [ "$SORT" = "size" ]; then
  sel=$(printf '%s\n' "$sel" | sort -t$'\t' -k4,4rn)
else
  # working primero, luego blocked, luego done; dentro de cada uno, mas viejo arriba
  sel=$(printf '%s\n' "$sel" | awk -F'\t' '{o=($1=="working")?0:($1=="blocked")?1:2; print o"\t"$0}' \
        | sort -t$'\t' -k1,1n -k3,3rn | cut -f2-)
fi

printf "\033[1m%-9s %5s %9s %8s  %-10s %-46s %s\033[0m\n" ESTADO EDAD TOKENS TMP ID NOMBRE ""
printf '%s\n' "$sel" | while IFS=$'\t' read -r st age tk kb id nm flag; do
  [ -n "$st" ] || continue
  case "$st" in
    working) c="\033[32m" ;;   # verde
    blocked) c="\033[33m" ;;   # amarillo
    done)    c="\033[90m" ;;   # gris
    *)       c="\033[31m" ;;
  esac
  hum=$(awk -v k="$kb" 'BEGIN{if(k>1048576)printf "%.1fG",k/1048576; else if(k>1024)printf "%dM",k/1024; else printf "%dK",k}')
  [ -n "$flag" ] && flag="\033[31m← $flag\033[0m"
  printf "${c}%-9s %4sd %9s %8s  %-10s %-46s\033[0m ${flag}\n" "$st" "$age" "$tk" "$hum" "$id" "$nm"
done

echo
printf '%s\n' "$rows" | awk -F'\t' '
  {n[$1]++; tot+=$4; if($7!="")fl++}
  END{
    printf "  ";
    for (s in n) printf "%s: %d   ", s, n[s];
    printf "\n  disco en tmp/: %.0f MB", tot/1024;
    if (fl) printf "   ·   %d sesión(es) marcadas", fl;
    printf "\n"
  }'
