#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1090
source "$SCRIPT_DIR/../common.sh"

AGENT_NAME="SwiftExpert"
SCRIPT_NAME="swift_expert"
init_runtime "$SCRIPT_NAME" "$AGENT_NAME"

usage() {
  usage_header "$(basename "$0")" "[run]"
  cat <<'USAGE'
Comandos:
  run              Solicita una revisión de cambios Swift
USAGE
}

swift_expert_review() {
  require_permission "$AGENT_NAME" "code_read"
  local project="$(get_conf DEFAULT_PROJECT_PATH)"
  check_allowed_path "$project"
  local diff=$(cd "$project" && (git diff --cached || git diff) || true)
  [ -z "$diff" ] && { echo "ℹ️  No hay cambios para revisar"; return 0; }
  invoke_ai "Como experto Swift, propone mejoras y refactors para este diff:\n$diff" | tee -a "$LOG_DIR/reviews.log"
}

dispatch() {
  case "${1:-run}" in
    run)
      swift_expert_review
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
