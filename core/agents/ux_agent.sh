#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1090
source "$SCRIPT_DIR/../common.sh"

AGENT_NAME="UXAgent"
SCRIPT_NAME="ux_agent"
init_runtime "$SCRIPT_NAME" "$AGENT_NAME"

usage() {
  usage_header "$(basename "$0")" "[run]"
  cat <<'USAGE'
Comandos:
  run              Solicita recomendaciones UX/UI para SwiftUI
USAGE
}

ux_recommend() {
  require_permission "$AGENT_NAME" "assets_read"
  invoke_ai "Sugiere mejoras de accesibilidad y animaciones en SwiftUI para este proyecto. Responde con snippets concretos." | tee -a "$LOG_DIR/ux.log"
}

dispatch() {
  case "${1:-run}" in
    run)
      ux_recommend
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
