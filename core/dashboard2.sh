#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1090
source "$SCRIPT_DIR/common.sh"

AGENT_NAME="TelemetryAgent"
SCRIPT_NAME="dashboard2"
OUTPUT_DIR="$LOG_DIR/dashboards"
init_runtime "$SCRIPT_NAME" "$AGENT_NAME"

usage() {
  usage_header "$(basename "$0")" "[run|open]"
  cat <<'USAGE'
Comandos:
  run              Genera el dashboard avanzado con gráficas
  open             Abre el último dashboard generado
USAGE
}

ensure_output_dir() {
  mkdir -p "$OUTPUT_DIR"
}

latest_dashboard() {
  ls -t "$OUTPUT_DIR"/dashboard-*.html 2>/dev/null | head -n1
}

generate_dashboard2() {
  require_permission "$AGENT_NAME" "stats_collect"
  ensure_output_dir
  local date=$(date +"%Y-%m-%d")
  local html="$OUTPUT_DIR/dashboard-$date.html"
  check_allowed_path "$html"
  local build_log="$(get_conf BUILD_LOG)"
  [ -n "$build_log" ] || build_log="/tmp/xcode-build.log"
  local errors=$(grep -c "error:" "$build_log" 2>/dev/null || echo 0)
  local warns=$(grep -c "warning:" "$build_log" 2>/dev/null || echo 0)
  local ok=$(grep -c "SUCCEEDED" "$build_log" 2>/dev/null || echo 0)
  local tests=$(grep -c "Test case" "$build_log" 2>/dev/null || echo 0)
  local log_list=""
  while IFS= read -r file; do
    log_list+="<li><a href='file://$file'>$(basename "$file")</a></li>\n"
  done < <(find "$LOG_DIR" -type f -name "session-*.md" -mtime -1 -print 2>/dev/null)
  cat > "$html" <<HTML
<!doctype html><html><head><meta charset="utf-8"/>
<title>GPT-OSS Dashboard $date</title>
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
<style>
 body{font-family:-apple-system;background:#111;color:#eee;padding:24px}
 h1{color:${DASHBOARD_THEME:-#0ff}}
 .card{background:#1b1b1b;border-radius:12px;padding:16px;margin-bottom:12px}
 canvas{background:#161616;border-radius:12px;padding:12px}
 a{color:${DASHBOARD_THEME:-#0ff}}
 ul{list-style:disc;margin-left:24px}
</style>
</head><body>
<h1>📊 Dashboard $date</h1>
<div class="card">Generado a las $(date '+%H:%M:%S')</div>
<div class="card"><canvas id="buildChart"></canvas></div>
 <div class="card">
  <h2>Logs del día</h2>
  <ul>
  $log_list
  </ul>
 </div>
<script>
const buildCtx=document.getElementById('buildChart');
const gradient=buildCtx.getContext('2d').createLinearGradient(0,0,0,200);
gradient.addColorStop(0,'rgba(0,255,255,0.8)');
gradient.addColorStop(1,'rgba(0,0,0,0.1)');
new Chart(buildCtx,{type:'bar',data:{labels:['Errores','Warnings','Éxitos','Tests'],datasets:[{label:'Conteo',data:[$errors,$warns,$ok,$tests],backgroundColor:gradient,borderColor:'#0ff',borderWidth:1}]},options:{plugins:{legend:{labels:{color:'#eee'}}},scales:{x:{ticks:{color:'#eee'}},y:{ticks:{color:'#eee'},beginAtZero:true}}}});
</script>
</body></html>
HTML
  notify "Dashboard avanzado actualizado" "GPT-OSS Neural Shell"
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
      generate_dashboard2
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
