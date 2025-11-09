#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1090
source "$SCRIPT_DIR/common.sh"

AGENT_NAME="SecurityAgent"
SCRIPT_NAME="security"
init_runtime "$SCRIPT_NAME" "$AGENT_NAME"

usage() {
  usage_header "$(basename "$0")" "[check <agente> <acción>]"
  cat <<'USAGE'
Comandos:
  check <agente> <acción>   Verifica permisos en security.map
USAGE
}

check_perm() {
  local agent="$1"; local action="$2"
  if require_permission "$agent" "$action"; then
    ok "$agent puede ejecutar $action"
  fi
}

dispatch() {
  case "${1:-help}" in
    check)
      shift
      [ -n "${1:-}" ] && [ -n "${2:-}" ] || fail "Debe indicar agente y acción"
      check_perm "$1" "$2"
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
