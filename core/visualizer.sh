visualize_stats() {
  notify "Generando gráfico de errores..."
  ERRORS=$(grep -c "error:" /tmp/xcode-build.log 2>/dev/null)
  WARNINGS=$(grep -c "warning:" /tmp/xcode-build.log 2>/dev/null)
  SUCCESS=$(grep -c "SUCCEEDED" /tmp/xcode-build.log 2>/dev/null)
  osascript -e "display dialog \"📊 Resultados del último build:\n\nErrores: $ERRORS\nWarnings: $WARNINGS\nÉxitos: $SUCCESS\" buttons {\"OK\"} default button \"OK\""
}
