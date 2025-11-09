#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1090
source "$SCRIPT_DIR/../common.sh"

AGENT_NAME="MemoryAgent"
SCRIPT_NAME="memory_agent"
init_runtime "$SCRIPT_NAME" "$AGENT_NAME"

usage() {
  usage_header "$(basename "$0")" "[pulse <evento>]"
  cat <<'USAGE'
Comandos:
  pulse [evento]    Registra un evento en la memoria persistente
USAGE
}

memory_pulse() {
  require_permission "$AGENT_NAME" "memory_write"
  local evento="${1:-pulse}"
  "$SCRIPT_DIR/../memory.sh" update "$evento"
}

dispatch() {
  case "${1:-pulse}" in
    pulse)
      shift
      memory_pulse "$*"
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
