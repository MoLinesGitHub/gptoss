#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1090
source "$SCRIPT_DIR/common.sh"

AGENT_NAME="NetworkAgent"
SCRIPT_NAME="updater"
init_runtime "$SCRIPT_NAME" "$AGENT_NAME"

usage() {
  usage_header "$(basename "$0")" "[run]"
  cat <<'USAGE'
Comandos:
  run              Descarga y prepara actualizaciones del repositorio remoto
USAGE
}

neural_update() {
  require_permission "$AGENT_NAME" "sync_remote"
  local repo="$(get_conf REPO_URL)"
  [ -n "$repo" ] || fail "REPO_URL no definido en la configuración"
  local branch="${GIT_BRANCH:-$(get_conf GIT_BRANCH)}"
  local temp
  temp=$(mktemp -d)
  log_event "UPDATER" "Clonando $repo en $temp"
  git clone --depth=1 --branch "$branch" "$repo" "$temp" || fail "git clone falló"
  if [ "${AUTO_BACKUP:-$(get_conf AUTO_BACKUP 2>/dev/null)}" = "true" ]; then
    log_event "UPDATER" "AUTO_BACKUP activo; se recomienda snapshot previo"
  fi
  rsync -a --exclude='.git' "$temp/" "$ROOT_DIR/" || fail "Sincronización fallida"
  log_event "UPDATER" "Repositorio sincronizado"
  notify "Actualización aplicada" "GPT-OSS Updater"
}

dispatch() {
  case "${1:-run}" in
    run)
      neural_update
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
