#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1090
source "$SCRIPT_DIR/common.sh"

AGENT_NAME="SwiftExpert"
SCRIPT_NAME="copilot"
init_runtime "$SCRIPT_NAME" "$AGENT_NAME"

usage() {
  usage_header "$(basename "$0")" "[run|once|status]"
  cat <<'USAGE'
Comandos:
  run              Observa el repositorio y sugiere mejoras
  once             Analiza el diff actual una sola vez
  status           Muestra configuración de vigilancia
USAGE
}

watch_paths() {
  local project="$(get_conf DEFAULT_PROJECT_PATH)"
  check_allowed_path "$project"
  printf "%s\n" "$project/Sources" "$project/Tests"
}

analyze_diff() {
  require_permission "$AGENT_NAME" "code_read"
  local project="$(get_conf DEFAULT_PROJECT_PATH)"
  check_allowed_path "$project"
  local diff
  diff=$(cd "$project" && git diff HEAD)
  if [ -z "$diff" ]; then
    warn "Sin cambios detectados para analizar"
    return 0
  fi
  local prompt="Sugiere mejoras o refactorizaciones en este código Swift:\n$diff"
  invoke_ai "$prompt" > >(tee -a "$LOG_DIR/copilot.log")
  log_event "COPILOT" "Diff analizado"
}

copilot_loop() {
  notify "Copilot Neural activo. Observando cambios..."
  local paths=()
  while IFS= read -r line; do
    paths+=("$line")
  done < <(watch_paths)
  if ! command -v fswatch >/dev/null 2>&1; then
    fail "fswatch no está disponible en el sistema"
  fi
  while true; do
    fswatch -1 -r "${paths[@]}" >/dev/null 2>&1
    echo "⚙️  Cambios detectados. Analizando..."
    analyze_diff
    sleep 1
  done
}

show_status() {
  echo "📂 Vigilando rutas:"
  while IFS= read -r line; do
    echo "   • $line"
  done < <(watch_paths)
  echo "🛡️  Agente: $AGENT_NAME"
  echo "📝 Log: $LOG_DIR/copilot.log"
}

dispatch() {
  case "${1:-run}" in
    run)
      copilot_loop
      ;;
    once)
      analyze_diff
      ;;
    status)
      show_status
      ;;
    -h|--help)
      usage
      ;;
    *)
      usage
      fail "Comando desconocido: $1"
      ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  dispatch "$@"
fi
