copilot_loop() {
  notify "Copilot Neural activo. Observando cambios..."
  while true; do
    fswatch -1 -r ./Sources ./Tests >/dev/null 2>&1
    echo "⚙️  Cambios detectados. Analizando..."
    DIFF=$(git diff HEAD)
    [[ -z "$DIFF" ]] || ollama run "$MODEL" -p "Sugiere mejoras o refactorizaciones en este código Swift:\n$DIFF" | tee -a "$LOG_DIR/copilot.log"
  done
}
