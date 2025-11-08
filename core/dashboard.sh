generate_dashboard() {
  mkdir -p "$LOGS"
  DATE=$(date +"%Y-%m-%d")
  HTML="$LOGS/dashboard-$DATE.html"
  ERRORS=$(grep -c "error:" /tmp/xcode-build.log 2>/dev/null)
  WARNINGS=$(grep -c "warning:" /tmp/xcode-build.log 2>/dev/null)
  SUCCESS=$(grep -c "SUCCEEDED" /tmp/xcode-build.log 2>/dev/null)
  TESTS=$(grep -c "Test case" /tmp/xcode-build.log 2>/dev/null)
  {
    echo "<!DOCTYPE html><html><head><meta charset='utf-8'><title>GPT-OSS Dashboard $DATE</title>"
    echo "<style>body{font-family:-apple-system;background:#111;color:#eee;padding:2em;}h1{color:#0ff;}table{width:100%;border-collapse:collapse;}td{padding:8px;}tr:nth-child(odd){background:#222;}a{color:#0ff;}</style></head><body>"
    echo "<h1>📊 Dashboard $DATE</h1>"
    echo "<p>Errores: <b style='color:#f55;'>$ERRORS</b> | Warnings: <b style='color:#ff5;'>$WARNINGS</b> | Éxitos: <b style='color:#5f5;'>$SUCCESS</b> | Tests: <b>$TESTS</b></p>"
    echo "<p>Generado: $(date '+%H:%M:%S')</p><h2>Logs recientes:</h2><ul>"
    find "$LOGS" -type f -name "session-*.md" -mtime -1 -exec echo "<li><a href='file://{}'>{}</a></li>" \;
    echo "</ul></body></html>"
  } > "$HTML"
  osascript -e "display notification \"Dashboard actualizado\" with title \"GPT-OSS Neural Shell\""
  open "$HTML"
}
