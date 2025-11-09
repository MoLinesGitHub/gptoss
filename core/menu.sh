#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1090
source "$SCRIPT_DIR/common.sh"

AGENT_NAME="SchedulerAgent"
SCRIPT_NAME="menu"
init_runtime "$SCRIPT_NAME" "$AGENT_NAME"

usage() {
  usage_header "$(basename "$0")" "[run]"
  cat <<'USAGE'
Comandos:
  run              Muestra el menú interactivo de GPT-OSS
USAGE
}

menu_actions() {
  cat <<'ACTIONS'
Chat
Talk
Compilar
Tests
Analizar Log
Revisión de Código
Visualizer
Daemon ON
Daemon OFF
Update
Salir
ACTIONS
}

execute_choice() {
  case "$1" in
    "Chat") "$SCRIPT_DIR/chat.sh" run ;;
    "Talk") "$SCRIPT_DIR/talk.sh" run ;;
    "Compilar") "$SCRIPT_DIR/xcode.sh" build ;;
    "Tests") "$SCRIPT_DIR/xcode.sh" test ;;
    "Analizar Log") "$SCRIPT_DIR/analyzer.sh" run ;;
    "Revisión de Código") "$SCRIPT_DIR/xcode.sh" review ;;
    "Visualizer") "$SCRIPT_DIR/dashboard2.sh" run ;;
    "Daemon ON") "$SCRIPT_DIR/daemon.sh" start ;;
    "Daemon OFF") "$SCRIPT_DIR/daemon.sh" stop ;;
    "Update") "$SCRIPT_DIR/updater.sh" run ;;
    "Salir") notify "Asistente cerrado" ;;
    *) warn "Selección desconocida: $1" ;;
  esac
}

show_menu() {
  require_permission "$AGENT_NAME" "agent_spawn"
  local option=""
  if command -v osascript >/dev/null 2>&1; then
    local items
    items=$(menu_actions | awk '{printf "\"%s\",", $0}' | sed 's/,$//')
    option=$(osascript -e "choose from list {$items} with prompt \"Neural Shell v9 — elige acción:\" default items {\"Chat\"}" 2>/dev/null)
  fi
  if [ -z "$option" ]; then
    echo "Seleccione una opción:" >&2
    local choices=()
    while IFS= read -r line; do
      choices+=("$line")
    done < <(menu_actions)
    select opt in "${choices[@]}"; do
      option="$opt"
      break
    done
  fi
  [ -n "$option" ] || return 0
  execute_choice "$option"
}

dispatch() {
  case "${1:-run}" in
    run)
      show_menu
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
