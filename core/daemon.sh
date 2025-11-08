daemon_start() {
  notify "Daemon cognitivo ON"
  nohup bash -c '
    FAILS=0
    while true; do
      # Observa cambios en el build.log
      if [ -f /tmp/xcode-build.log ]; then
        NEW=$(cksum /tmp/xcode-build.log | cut -d" " -f1)
      else
        NEW=""
      fi
      [ "$NEW" != "$OLD" ] && {
        OLD="$NEW"
        # Heurística: si hay errores, analiza
        if grep -q "error:" /tmp/xcode-build.log 2>/dev/null; then
          FAILS=$((FAILS+1))
          osascript -e "display notification \"Fallo de build ($FAILS) — analizando\" with title \"Neural Daemon\"" || true
          ollama run "$MODEL" -p "Analiza el log de Xcode y explica errores:\n$(cat /tmp/xcode-build.log 2>/dev/null)" >> "$LOG_DIR/analyzer.log" 2>/dev/null
          if [ $FAILS -ge 3 ]; then
            defaults write com.apple.notificationcenterui doNotDisturb -boolean true && killall NotificationCenter >/dev/null 2>&1
            osascript -e "display notification \"Focus Mode activado (3 fallos seguidos)\" with title \"Neural Daemon\"" || true
          fi
        else
          [ $FAILS -gt 0 ] && FAILS=0
        fi
        # Genera dashboard al cambiar
        bash "$HOME/Documents/Scripts/gptoss/core/dashboard2.sh" generate_dashboard2 >/dev/null 2>&1 || true
      fi
      sleep 2
    done
  ' >/tmp/gptoss-daemon.log 2>&1 &
}
daemon_stop() {
  pkill -f "gptoss/core/dashboard2.sh" >/dev/null 2>&1 || true
  pkill -f "Neural Daemon" >/dev/null 2>&1 || true
  pkill -f "gptoss.*daemon" >/dev/null 2>&1 || true
  notify "Daemon cognitivo OFF"
}
