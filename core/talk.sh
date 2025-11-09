#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1090
source "$SCRIPT_DIR/common.sh"

AGENT_NAME="VoiceAgent"
SCRIPT_NAME="talk"
init_runtime "$SCRIPT_NAME" "$AGENT_NAME"

usage() {
  usage_header "$(basename "$0")" "[run]"
  cat <<'USAGE'
Comandos:
  run              Inicia una sesión interactiva tipo Talk
USAGE
}

create_session_log() {
  local sid=$(date +"%Y%m%d-%H%M%S")
  local slog="$LOG_DIR/talk-$sid.md"
  echo "### 💬 Neural Talk Session $sid" > "$slog"
  echo "$slog"
}

talk_mode() {
  require_permission "$AGENT_NAME" "system_summary"
  local slog
  slog=$(create_session_log)
  notify "Sesión TALK iniciada"
  while true; do
    local prompt
    if command -v osascript >/dev/null 2>&1; then
      prompt=$(osascript -e 'display dialog "Neural Talk — escribe tu mensaje (Cancelar para salir):" default answer "" buttons {"Cancelar","Enviar"} default button "Enviar"' -e 'text returned of result' 2>/dev/null) || break
    else
      read -rp "Tú> " prompt || break
    fi
    [ -z "$prompt" ] && continue
    echo -e "\n**Tú:** $prompt" >> "$slog"
    local ctx
    ctx=$(tail -n 80 "$slog" 2>/dev/null)
    local full_prompt="Contexto reciente (markdown):\n$ctx\n\nResponde en español técnico y conciso:\n$prompt"
    local resp
    if ! resp=$(invoke_ai "$full_prompt"); then
      warn "No se pudo obtener respuesta"
      continue
    fi
    echo -e "\n**GPT-OSS:**\n$resp" | tee -a "$slog"
    if [ "${VOICE_TALK_ENABLED}" = "true" ]; then
      local summary
      summary=$(printf "%s" "$resp" | tr '\n' ' ' | sed 's/  */ /g' | cut -c1-"${VOICE_CHARS:-140}")
      say_voice "$summary"
    fi
  done
  cp "$slog" "$LOG_DIR/última-sesión.md" 2>/dev/null || true
  notify "Sesión TALK finalizada"
  log_event "TALK" "Sesión registrada en $slog"
}

dispatch() {
  case "${1:-run}" in
    run)
      talk_mode
      ;;
    -h|--help)
      usage
      ;;
    *)
      usage
      fail "Comando desconocido: $1"
      ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  dispatch "$@"
fi
