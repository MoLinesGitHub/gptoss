#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1090
source "$SCRIPT_DIR/../common.sh"

AGENT_NAME="AnalyzerAgent"
SCRIPT_NAME="analyzer_agent"
init_runtime "$SCRIPT_NAME" "$AGENT_NAME"

usage() {
  usage_header "$(basename "$0")" "[run]"
  cat <<'USAGE'
Comandos:
  run              Analiza el log de build de Xcode
USAGE
}

analyzer_from_log() {
  require_permission "$AGENT_NAME" "log_read"
  local log_file="$(get_conf BUILD_LOG)"
  [ -n "$log_file" ] || log_file="/tmp/xcode-build.log"
  [ -f "$log_file" ] || fail "No hay log disponible en $log_file"
  invoke_ai "Analiza el log y explica errores y fixes:\n$(tail -n 400 "$log_file")"
}

dispatch() {
  case "${1:-run}" in
    run)
      analyzer_from_log
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
