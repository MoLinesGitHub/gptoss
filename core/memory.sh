#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1090
source "$SCRIPT_DIR/common.sh"

AGENT_NAME="MemoryAgent"
SCRIPT_NAME="memory"
MEMORY_FILE="$(get_conf MEMORY_FILE)"
[ -n "$MEMORY_FILE" ] || MEMORY_FILE="$ROOT_DIR/data/memory.json"
MEMORY_KEY="$(get_conf MEMORY_ENCRYPTION_KEY)"
init_runtime "$SCRIPT_NAME" "$AGENT_NAME"

usage() {
  usage_header "$(basename "$0")" "[init|update|load|status]"
  cat <<'USAGE'
Comandos:
  init             Crea el archivo de memoria si no existe
  update <evento>  Registra un evento en la memoria
  load             Muestra el contenido de la memoria
  status           Información sobre la memoria persistente
USAGE
}

ensure_memory_file() {
  mkdir -p "$(dirname "$MEMORY_FILE")"
  check_allowed_path "$MEMORY_FILE"
}

encrypt_required() {
  local encrypt="${ENCRYPT_MEMORY:-$(get_conf ENCRYPT_MEMORY 2>/dev/null)}"
  [ "$encrypt" = "true" ] && [ -n "$MEMORY_KEY" ]
}

memory_init() {
  require_permission "$AGENT_NAME" "memory_write"
  ensure_memory_file
  if [ ! -f "$MEMORY_FILE" ]; then
    echo '{"events":[]}' > "$MEMORY_FILE"
    log_event "MEMORY" "Archivo creado en $MEMORY_FILE"
  fi
  if encrypt_required; then
    log_event "MEMORY" "Cifrado habilitado para la memoria"
  else
    warn "Memoria sin cifrado activo"
  fi
  ok "Memoria preparada"
}

memory_update() {
  require_permission "$AGENT_NAME" "memory_write"
  local event="$1"
  [ -n "$event" ] || fail "Debes indicar un evento"
  ensure_memory_file
  [ -f "$MEMORY_FILE" ] || memory_init
  local project=$(basename "$(pwd)")
  local when=$(date +"%F %T")
  if command -v jq >/dev/null 2>&1; then
    local tmp
    tmp=$(mktemp)
    if ! jq -Mc --arg p "$project" --arg w "$when" --arg e "$event" '
      .events += [{"project":$p,"when":$w,"event":$e}]' "$MEMORY_FILE" > "$tmp" 2>/dev/null; then
      echo '{"events":[]}' > "$tmp"
      jq -Mc --arg p "$project" --arg w "$when" --arg e "$event" '
        .events += [{"project":$p,"when":$w,"event":$e}]' "$tmp" > "$MEMORY_FILE"
      rm -f "$tmp"
      log_event "MEMORY" "Evento registrado: $event"
      return
    fi
    mv "$tmp" "$MEMORY_FILE"
  else
    printf '{"events":[{"project":"%s","when":"%s","event":"%s"}]}' "$project" "$when" "$event" > "$MEMORY_FILE"
  fi
  log_event "MEMORY" "Evento registrado: $event"
}

memory_load() {
  require_permission "$AGENT_NAME" "memory_read"
  [ -f "$MEMORY_FILE" ] || fail "No existe archivo de memoria"
  cat "$MEMORY_FILE"
}

memory_status() {
  echo "📦 Archivo: $MEMORY_FILE"
  if [ -f "$MEMORY_FILE" ]; then
    echo "📄 Tamaño: $(stat -c%s "$MEMORY_FILE" 2>/dev/null || stat -f%z "$MEMORY_FILE" 2>/dev/null) bytes"
    if encrypt_required; then
      echo "🔐 Cifrado requerido: sí"
    else
      echo "🔐 Cifrado requerido: no"
    fi
  else
    warn "Memoria no inicializada"
  fi
}

dispatch() {
  case "${1:-status}" in
    init)
      memory_init
      ;;
    update)
      shift
      memory_update "$*"
      ;;
    load)
      memory_load
      ;;
    status)
      memory_status
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
