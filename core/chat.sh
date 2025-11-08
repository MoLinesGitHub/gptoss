# chat.sh — One-shot chat (stdin to ollama)
chat_mode() {
  PROMPT=$(osascript -e 'display dialog "Pregunta a GPT-OSS:" default answer "" buttons {"Cancelar","Enviar"} default button "Enviar"' -e 'text returned of result' 2>/dev/null) || return
  TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
  SESSION_LOG="$LOG_DIR/session-$TIMESTAMP.md"
  echo "### 🧠 Sesión $TIMESTAMP — Chat Neural" > "$SESSION_LOG"
  printf "%s" "$PROMPT" | ollama run "$MODEL" 2>&1 | tee -a "$SESSION_LOG"
  cp "$SESSION_LOG" "$LOG_DIR/última-sesión.md" || true
  notify "Respuesta generada"
  if [ "${VOICE_TALK_ENABLED}" = "true" ]; then
    say_voice "$(tail -n 20 "$SESSION_LOG" | tr '\n' ' ' | cut -c1-"${VOICE_CHARS:-140}")"
  fi
}
