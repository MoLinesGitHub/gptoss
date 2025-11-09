#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1090
source "$SCRIPT_DIR/common.sh"

AGENT_NAME="AnalyzerAgent"
SCRIPT_NAME="analyzer"
init_runtime "$SCRIPT_NAME" "$AGENT_NAME"

usage() {
  usage_header "$(basename "$0")" "[run|status]"
  cat <<'USAGE'
Comandos:
  run               Analiza el log más reciente de Xcode
  status            Muestra rutas y archivos gestionados
USAGE
}

resolve_log_path() {
  local candidate
  candidate="${1:-$(get_conf BUILD_LOG)}"
  [ -n "$candidate" ] || candidate="/tmp/xcode-build.log"
  echo "$candidate"
}

analyze_xcode_log() {
  require_permission "$AGENT_NAME" "code_audit"
  local log_path
  log_path=$(resolve_log_path "$1")
  [ -f "$log_path" ] || fail "No se encontró el log en $log_path"
  check_allowed_path "$log_path"
  notify "Analizando log con GPT-OSS..."
  local prompt
  prompt="Analiza el siguiente log de Xcode y resume errores y advertencias:\n$(tail -n 400 "$log_path")"
  if ! invoke_ai "$prompt" > >(tee -a "$LOG_DIR/analyzer.log"); then
    fail "No fue posible completar el análisis del log"
  fi
  notify "Análisis completado."
  log_event "ANALYZER" "Log analizado: $log_path"
}

show_status() {
  echo "📄 Log objetivo: $(resolve_log_path)"
  echo "🛡️  Agente: $AGENT_NAME"
  echo "📚 Registro: $LOG_DIR/analyzer.log"
}

dispatch() {
  case "${1:-run}" in
    run)
      analyze_xcode_log "$2"
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
