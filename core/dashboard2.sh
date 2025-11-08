generate_dashboard2() {
  mkdir -p "$LOG_DIR"
  local date=$(date +"%Y-%m-%d")
  local html="$LOG_DIR/dashboard-$date.html"
  local errors=$(grep -c "error:" /tmp/xcode-build.log 2>/dev/null || echo 0)
  local warns=$(grep -c "warning:" /tmp/xcode-build.log 2>/dev/null || echo 0)
  local ok=$(grep -c "SUCCEEDED" /tmp/xcode-build.log 2>/dev/null || echo 0)
  local tests=$(grep -c "Test case" /tmp/xcode-build.log 2>/dev/null || echo 0)
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
</style>
</head><body>
<h1>📊 Dashboard $date</h1>
<div class="card">Generado a las $(date '+%H:%M:%S')</div>
<div class="card"><canvas id="buildChart"></canvas></div>
<div class="card">
  <h2>Logs del día</h2>
  <ul>
    $(find "$LOG_DIR" -type f -name "session-*.md" -mtime -1 -exec bash -lc 'for f in "$@"; do bn=$(basename "$f"); echo "<li><a href=\"file://$f\">$bn</a></li>"; done' _ {} +)
  </ul>
</div>
<script>
const ctx=document.getElementById('buildChart');
new Chart(ctx,{type:'bar',data:{labels:['Errores','Warnings','Éxitos','Tests'],
datasets:[{label:'Conteo',data:[$errors,$warns,$ok,$tests]}]},options:{plugins:{legend:{display:false}},scales:{y:{beginAtZero:true}}});
</script>
</body></html>
HTML
  notify "Dashboard 2.0 actualizado"
  open "$html" >/dev/null 2>&1 || true
}
