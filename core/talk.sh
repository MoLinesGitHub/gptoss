# talk.sh — Neural Talk mode (stdin to ollama)
talk_mode() {
  local sid
  sid=$(date +"%Y%m%d-%H%M%S")
  local slog="$LOG_DIR/talk-$sid.md"
  echo "### 💬 Neural Talk Session $sid" > "$slog"
  notify "Sesión TALK iniciada"

  while true; do
    local PROMPT
    PROMPT=$(osascript -e 'display dialog "Neural Talk — escribe tu mensaje (Cancelar para salir):" default answer "" buttons {"Cancelar","Enviar"} default button "Enviar"' -e 'text returned of result' 2>/dev/null) || break
    [ -z "$PROMPT" ] && continue

    echo -e "\n**Tú:** $PROMPT" >> "$slog"

    local CTX RESP FULLPROMPT
    CTX=$(tail -n 60 "$slog" 2>/dev/null | sed 's/"/\\"/g')
    FULLPROMPT=$'Contexto reciente (markdown):\n'"$CTX"$'\n\nResponde en español técnico y conciso:\n'"$PROMPT"

    RESP=$(printf "%s" "$FULLPROMPT" | ollama run "$MODEL" 2>/dev/null)

    echo -e "\n**GPT-OSS:**\n$RESP" | tee -a "$slog"

    if [ "${VOICE_TALK_ENABLED}" = "true" ]; then
      local summary
      summary=$(printf "%s" "$RESP" | tr '\n' ' ' | sed 's/  */ /g' | sed 's/\.\s.*$//')
      if [ -z "$summary" ] || [ "${#summary}" -gt "${VOICE_CHARS:-140}" ]; then
        summary=$(printf "%s" "$RESP" | tr '\n' ' ' | cut -c1-"${VOICE_CHARS:-140}")
      fi
      say_voice "$summary"
    fi
  done

  cp "$slog" "$LOG_DIR/última-sesión.md" 2>/dev/null || true
  notify "Sesión TALK finalizada"
}
