analyzer_from_log() {
  deny_if_no_perm "AnalyzerAgent" "log_read" || return 1
  [ -f /tmp/xcode-build.log ] || { echo "No hay /tmp/xcode-build.log"; return 1; }
  ollama run "$MODEL" -p "Analiza el log y explica errores y fixes:\n$(cat /tmp/xcode-build.log)"
}
