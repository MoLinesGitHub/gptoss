analyze_xcode_log() {
  LOG_PATH="/tmp/xcode-build.log"
  [[ ! -f "$LOG_PATH" ]] && notify "No se encontró el log de Xcode" && return
  notify "Analizando log con GPT-OSS..."
  ollama run "$MODEL" -p "Analiza el siguiente log de Xcode y resume errores y advertencias:\n$(cat $LOG_PATH)" | tee -a "$LOG_DIR/analyzer.log"
  notify "Análisis completado."
}
