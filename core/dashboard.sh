#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1090
source "$SCRIPT_DIR/common.sh"

AGENT_NAME="TelemetryAgent"
SCRIPT_NAME="dashboard"
OUTPUT_DIR="$LOG_DIR/dashboards"
init_runtime "$SCRIPT_NAME" "$AGENT_NAME"

usage() {
  usage_header "$(basename "$0")" "[run|open]"
  cat <<'USAGE'
Comandos:
  run              Genera el dashboard HTML con estadísticas recientes
  open             Abre el dashboard más reciente en el navegador
USAGE
}

ensure_output_dir() {
  mkdir -p "$OUTPUT_DIR"
}

latest_dashboard() {
  ls -t "$OUTPUT_DIR"/dashboard-*.html 2>/dev/null | head -n1
}

generate_dashboard() {
  require_permission "$AGENT_NAME" "stats_collect"
  ensure_output_dir
  local date
  date=$(date +"%Y-%m-%d")
  local build_log="$(get_conf BUILD_LOG)"
  [ -n "$build_log" ] || build_log="/tmp/xcode-build.log"
  local html="$OUTPUT_DIR/dashboard-$date.html"
  check_allowed_path "$html"
  local errors warnings success tests
  errors=$(grep -c "error:" "$build_log" 2>/dev/null || echo 0)
  warnings=$(grep -c "warning:" "$build_log" 2>/dev/null || echo 0)
  success=$(grep -c "SUCCEEDED" "$build_log" 2>/dev/null || echo 0)
  tests=$(grep -c "Test case" "$build_log" 2>/dev/null || echo 0)
  {
    echo "<!DOCTYPE html><html><head><meta charset='utf-8'><title>GPT-OSS Dashboard $date</title>"
    echo "<style>body{font-family:-apple-system;background:#111;color:#eee;padding:2em;}h1{color:${DASHBOARD_THEME:-#0ff}}table{width:100%;border-collapse:collapse;}td{padding:8px;}tr:nth-child(odd){background:#222;}a{color:${DASHBOARD_THEME:-#0ff};}</style></head><body>"
    echo "<h1>📊 Dashboard $date</h1>"
    echo "<p>Errores: <b style='color:#f55;'>$errors</b> | Warnings: <b style='color:#ff5;'>$warnings</b> | Éxitos: <b style='color:#5f5;'>$success</b> | Tests: <b>$tests</b></p>"
    echo "<p>Generado: $(date '+%H:%M:%S')</p><h2>Logs recientes:</h2><ul>"
    find "$LOG_DIR" -type f -name "session-*.md" -mtime -1 -print 2>/dev/null | while read -r file; do
      echo "<li><a href='file://$file'>$(basename "$file")</a></li>"
    done
    echo "</ul></body></html>"
  } > "$html"
  notify "Dashboard actualizado" "GPT-OSS Neural Shell"
  log_event "DASHBOARD" "Generado $html"
  echo "$html"
}

open_dashboard() {
  local file
  file=$(latest_dashboard)
  if [ -z "$file" ]; then
    warn "No hay dashboards generados aún"
    return 1
  fi
  if command -v open >/dev/null 2>&1; then
    open "$file"
  else
    echo "Dashboard disponible en: $file"
  fi
}

dispatch() {
  case "${1:-run}" in
    run)
      generate_dashboard
      ;;
    open)
      open_dashboard
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
