#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1090
source "$SCRIPT_DIR/common.sh"

AGENT_NAME="VoiceAgent"
SCRIPT_NAME="notify"
init_runtime "$SCRIPT_NAME" "$AGENT_NAME"

usage() {
  usage_header "$(basename "$0")" "[send|voice]"
  cat <<'USAGE'
Comandos:
  send <mensaje> [titulo]   Envía una notificación del sistema
  voice <mensaje> [voz]      Reproduce un mensaje con síntesis
USAGE
}

send_notification() {
  require_permission "$AGENT_NAME" "alerts_voice"
  local message="$1"
  local title="${2:-GPT-OSS Neural Shell}"
  notify "$message" "$title"
}

voice_output() {
  require_permission "$AGENT_NAME" "tts_output"
  local message="$1"
  local voice="${2:-${VOICE_DEFAULT:-Samantha}}"
  say_voice "$message" "$voice"
}

dispatch() {
  case "${1:-help}" in
    send)
      shift
      [ -n "${1:-}" ] || fail "Debes indicar un mensaje"
      send_notification "$1" "${2:-GPT-OSS Neural Shell}"
      ;;
    voice)
      shift
      [ -n "${1:-}" ] || fail "Debes indicar un mensaje"
      voice_output "$1" "${2:-${VOICE_DEFAULT:-Samantha}}"
      ;;
    -h|--help|help)
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
