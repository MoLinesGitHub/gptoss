#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1090
source "$SCRIPT_DIR/../common.sh"

AGENT_NAME="BuilderAgent"
SCRIPT_NAME="builder_agent"
init_runtime "$SCRIPT_NAME" "$AGENT_NAME"

usage() {
  usage_header "$(basename "$0")" "[build|test]"
  cat <<'USAGE'
Comandos:
  build             Ejecuta xcodebuild build
  test              Ejecuta xcodebuild test
USAGE
}

xcode_build() {
  local action="$1"
  require_permission "$AGENT_NAME" "$action"
  local xcode="$(get_conf XCODE_PATH)"
  local project="$(get_conf DEFAULT_PROJECT_PATH)"
  local scheme="$(get_conf DEFAULT_SCHEME)"
  local simulator="$(get_conf DEFAULT_SIMULATOR)"
  check_allowed_path "$project"
  local dest="platform=iOS Simulator,name=${simulator}"
  (cd "$project" && "${xcode:-xcodebuild}" "$action" -scheme "$scheme" -destination "$dest" 2>&1 | tee "$BUILD_LOG")
}

dispatch() {
  case "${1:-build}" in
    build)
      xcode_build build
      ;;
    test)
      xcode_build test
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
