compile_xcode() {
  notify "Compilando proyecto Xcode..."
  defaults write com.apple.notificationcenterui doNotDisturb -boolean true && killall NotificationCenter >/dev/null 2>&1 || true
  xcodebuild build -scheme "$(basename "$(pwd)")" -destination "platform=iOS Simulator,name=iPhone 16e,OS=26.0" 2>&1 | tee /tmp/xcode-build.log
  defaults write com.apple.notificationcenterui doNotDisturb -boolean false && killall NotificationCenter >/dev/null 2>&1 || true
  notify "Compilación finalizada"
  say_voice "Compilación completada" "${VOICE_DEFAULT:-Samantha}"
}
run_tests() {
  notify "Ejecutando tests..."
  xcodebuild test -scheme "$(basename "$(pwd)")" -destination "platform=iOS Simulator,name=iPhone 16e,OS=26.0" 2>&1 | tee /tmp/xcode-build.log
  notify "Tests finalizados"
  say_voice "Tests completados" "${VOICE_DEFAULT:-Samantha}"
}
review_code() {
  local diff=$(git diff HEAD~1 HEAD || true)
  [ -z "$diff" ] && { notify "Sin cambios recientes"; echo "Sin diff"; return 0; }
  ollama run "$MODEL" -p "Revisión técnica del siguiente diff Swift (claridad, arquitectura, rendimiento):\n$diff" | tee -a "$LOG_DIR/reviews.log"
  say_voice "Revisión de código lista" "${VOICE_DEFAULT:-Samantha}"
}
analyze_xcode_log() {
  [ -f /tmp/xcode-build.log ] || { notify "No hay build log"; echo "No /tmp/xcode-build.log"; return 1; }
  ollama run "$MODEL" -p "Analiza log de Xcode y propone fixes:\n$(cat /tmp/xcode-build.log)" | tee -a "$LOG_DIR/analyzer.log"
  say_voice "Análisis del log completado" "${VOICE_DEFAULT:-Samantha}"
}
