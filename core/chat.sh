#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1090
source "$SCRIPT_DIR/common.sh"

AGENT_NAME="VoiceAgent"
SCRIPT_NAME="chat"
CONTEXT_ENABLED="${AI_CONTEXT_PERSIST:-$(get_conf AI_CONTEXT_PERSIST 2>/dev/null)}"
[ -n "$CONTEXT_ENABLED" ] || CONTEXT_ENABLED="$(get_conf CONTEXT_PERSISTENCE 2>/dev/null)"
init_runtime "$SCRIPT_NAME" "$AGENT_NAME"

usage() {
  usage_header "$(basename "$0")" "[run|history]"
  cat <<'USAGE'
Comandos:
  run [texto]       Lanza una conversación rápida (GUI o stdin)
  history           Muestra la última sesión registrada
USAGE
}

session_file() {
  local timestamp="$1"
  echo "$LOG_DIR/session-$timestamp.md"
}

ensure_context_file() {
  local file="$LOG_DIR/context.dat"
  if [ "$CONTEXT_ENABLED" = "true" ] && [ ! -f "$file" ]; then
    touch "$file"
    log_event "CHAT" "Contexto inicial creado"
  fi
  echo "$file"
}

run_chat() {
  require_permission "$AGENT_NAME" "system_summary"
  local prompt="$*"
  if [ -z "$prompt" ] && command -v osascript >/dev/null 2>&1; then
    prompt=$(osascript -e 'display dialog "Pregunta a GPT-OSS:" default answer "" buttons {"Cancelar","Enviar"} default button "Enviar"' -e 'text returned of result' 2>/dev/null) || return 0
  fi
  [ -n "$prompt" ] || fail "No se proporcionó ningún mensaje"
  local timestamp
  timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
  local logfile
  logfile=$(session_file "$timestamp")
  check_allowed_path "$logfile"
  echo "### 🧠 Sesión $timestamp — Chat Neural" > "$logfile"
  local context_file
  context_file=$(ensure_context_file)
  local prompt_block="$prompt"
  if [ "$CONTEXT_ENABLED" = "true" ] && [ -s "$context_file" ]; then
    prompt_block="Contexto previo:\n$(tail -n 200 "$context_file")\n\nPregunta actual:\n$prompt"
  fi
  if ! invoke_ai "$prompt_block" > >(tee -a "$logfile"); then
    fail "No fue posible obtener respuesta"
  fi
  printf '\n' >> "$logfile"
  cp "$logfile" "$LOG_DIR/última-sesión.md" 2>/dev/null || true
  if [ "$CONTEXT_ENABLED" = "true" ]; then
    tail -n 200 "$logfile" >> "$context_file"
  fi
  notify "Respuesta generada"
  if [ "${VOICE_TALK_ENABLED}" = "true" ]; then
    local summary
    summary=$(tail -n 20 "$logfile" | tr '\n' ' ' | cut -c1-"${VOICE_CHARS:-140}")
    say_voice "$summary"
  fi
  log_event "CHAT" "Sesión generada: $logfile"
}

show_history() {
  local last="$LOG_DIR/última-sesión.md"
  if [ -f "$last" ]; then
    tail -n 40 "$last"
  else
    warn "No hay sesiones recientes"
  fi
}

dispatch() {
  case "${1:-run}" in
    run)
      shift
      run_chat "$@"
      ;;
    history)
      show_history
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
