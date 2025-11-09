#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1090
source "$SCRIPT_DIR/common.sh"

AGENT_NAME="TelemetryAgent"
SCRIPT_NAME="visualizer"
init_runtime "$SCRIPT_NAME" "$AGENT_NAME"

usage() {
  usage_header "$(basename "$0")" "[run]"
  cat <<'USAGE'
Comandos:
  run              Muestra un resumen rápido del último build
USAGE
}

visualize_stats() {
  require_permission "$AGENT_NAME" "stats_collect"
  local build_log="$(get_conf BUILD_LOG)"
  [ -n "$build_log" ] || build_log="/tmp/xcode-build.log"
  local errors=$(grep -c "error:" "$build_log" 2>/dev/null || echo 0)
  local warns=$(grep -c "warning:" "$build_log" 2>/dev/null || echo 0)
  local ok=$(grep -c "SUCCEEDED" "$build_log" 2>/dev/null || echo 0)
  notify "Generando gráfico de errores..."
  if command -v osascript >/dev/null 2>&1; then
    osascript -e "display dialog \"📊 Resultados del último build:\\n\\nErrores: $errors\\nWarnings: $warns\\nÉxitos: $ok\" buttons {\"OK\"} default button \"OK\"" || true
  else
    echo "Errores: $errors | Warnings: $warns | Éxitos: $ok"
  fi
  log_event "VISUALIZER" "Resumen mostrado"
}

dispatch() {
  case "${1:-run}" in
    run)
      visualize_stats
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
