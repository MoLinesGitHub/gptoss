#!/bin/bash
# ============================================================
#  GPT-OSS Shared Runtime (v9 Advanced)
# ============================================================
set -o pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)

CONFIG_DEFAULT="$ROOT_DIR/config/gptoss.conf"
SECURITY_MAP_DEFAULT="$ROOT_DIR/config/security.map"

CONFIG="${CONFIG_PATH_OVERRIDE:-${CONFIG:-$CONFIG_DEFAULT}}"
SECURITY_MAP="${SECURITY_MAP_OVERRIDE:-${SECURITY_MAP:-$SECURITY_MAP_DEFAULT}}"

if [ ! -f "$CONFIG" ]; then
  echo "✗ Configuración avanzada no encontrada: $CONFIG" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$CONFIG"

get_conf() {
  local key="$1"
  local raw
  raw=$(grep -E "^${key}=" "$CONFIG" | tail -n 1 | cut -d'=' -f2-)
  raw=${raw%\r}
  raw=${raw%\n}
  raw=${raw#\"}
  raw=${raw%\"}
  echo "$raw"
}

COLOR_OK="${COLOR_OK:-$(get_conf COLOR_OK 2>/dev/null || echo '\033[92m')}"
COLOR_WARN="${COLOR_WARN:-$(get_conf COLOR_WARN 2>/dev/null || echo '\033[33m')}"
COLOR_ERR="${COLOR_ERROR:-$(get_conf COLOR_ERROR 2>/dev/null || echo '\033[31m')}"
NC="\033[0m"

ok()  { echo -e "${COLOR_OK}✓${NC} $1"; }
warn(){ echo -e "${COLOR_WARN}⚠️  $1${NC}"; }
fail(){ echo -e "${COLOR_ERR}✗ $1${NC}"; exit 1; }

SAFE_MODE="${SAFE_MODE:-$(get_conf SAFE_MODE)}"
LOG_DIR="${LOG_DIR:-$(get_conf LOG_DIR)}"
[ -n "$LOG_DIR" ] || LOG_DIR="$ROOT_DIR/logs"
BACKUP_DIR="${BACKUP_DIR:-$(get_conf BACKUP_DIR)}"
[ -n "$BACKUP_DIR" ] || BACKUP_DIR="$ROOT_DIR/backups"
BUILD_LOG="${BUILD_LOG:-$(get_conf BUILD_LOG)}"
[ -n "$BUILD_LOG" ] || BUILD_LOG="$LOG_DIR/build.log"
LOG_ROTATE_SIZE="${LOG_ROTATE_SIZE:-$(get_conf LOG_ROTATE_SIZE 2>/dev/null)}"
[ -n "$LOG_ROTATE_SIZE" ] || LOG_ROTATE_SIZE=$((5*1024*1024))
BACKUP_RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-$(get_conf BACKUP_RETENTION_DAYS 2>/dev/null)}"
[ -n "$BACKUP_RETENTION_DAYS" ] || BACKUP_RETENTION_DAYS=14

mkdir -p "$LOG_DIR" "$BACKUP_DIR"

rotate_log() {
  local file="$1"
  [ -f "$file" ] || return 0
  local size
  size=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null || echo 0)
  if [ "$size" -ge "$LOG_ROTATE_SIZE" ]; then
    local timestamp
    timestamp=$(date +"%Y%m%d-%H%M%S")
    mv "$file" "${file}.${timestamp}"
    touch "$file"
  fi
}

CURRENT_LOG=""
log_init() {
  local name="$1"
  CURRENT_LOG="$LOG_DIR/${name}.log"
  touch "$CURRENT_LOG"
  rotate_log "$CURRENT_LOG"
}

log_event() {
  local level="$1"; shift
  local msg="$*"
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$timestamp] [$level] $msg" >> "$CURRENT_LOG"
}

safe_prompt() {
  local cmd="$1"
  if [ "$SAFE_MODE" = "on" ]; then
    echo "SAFE_MODE activo — comando: $cmd"
    read -r -p "¿Deseas continuar? [y/N] " reply
    [[ "$reply" =~ ^[Yy]$ ]] || return 1
  fi
  return 0
}

is_destructive_command() {
  case "$1" in
    *"rm -rf"*|*"shutdown"*|*"reboot"*|*"halt"*|*"mkfs"*) return 0 ;;
  esac
  return 1
}

run_guarded() {
  local description="$1"; shift
  local cmd=("$@")
  local joined="$*"
  if is_destructive_command "$joined"; then
    safe_prompt "$joined" || { warn "Operación cancelada (${description})"; return 1; }
  fi
  "${cmd[@]}"
  return $?
}

require_file() {
  local path="$1"; local message="$2"
  [ -e "$path" ] || fail "$message"
}

require_permission() {
  local agent="$1"; local action="$2"
  require_file "$SECURITY_MAP" "security.map no encontrado en $SECURITY_MAP"
  local rule
  rule=$(grep -E "^${agent}[[:space:]]+${action}[[:space:]]+" "$SECURITY_MAP" | tail -n1)
  if [ -z "$rule" ]; then
    fail "Permiso no definido para ${agent}/${action}"
  fi
  local decision
  decision=$(echo "$rule" | awk '{print $3}')
  case "$decision" in
    yes|true|allow)
      return 0
      ;;
    sandbox|manual|smart)
      warn "${agent}/${action} requiere supervisión (${decision})."
      fail "Acción abortada por política de seguridad"
      ;;
    *)
      fail "Acción denegada por seguridad (${agent}/${action} → ${decision})"
      ;;
  esac
}

validate_security_state() {
  local checksum="${CHECKSUM_VERIFY:-$(get_conf CHECKSUM_VERIFY 2>/dev/null)}"
  local encrypt="${ENCRYPT_MEMORY:-$(get_conf ENCRYPT_MEMORY 2>/dev/null)}"
  local signed="${SIGNED_MODULES_ONLY:-$(get_conf SIGNED_MODULES_ONLY 2>/dev/null)}"
  for pair in "CHECKSUM_VERIFY:$checksum" "ENCRYPT_MEMORY:$encrypt" "SIGNED_MODULES_ONLY:$signed"; do
    local key="${pair%%:*}"; local val="${pair##*:}"
    case "$val" in
      true|on|yes) ;;
      *) warn "$key está desactivado. Funcionalidad limitada." ;;
    esac
  done
}

ensure_retention() {
  find "$BACKUP_DIR" -type f -mtime +"$BACKUP_RETENTION_DAYS" -delete 2>/dev/null || true
}

create_backup() {
  local source="$1"
  [ -f "$source" ] || { warn "No se puede respaldar $source"; return 1; }
  local ts=$(date +"%Y%m%d-%H%M%S")
  local target="$BACKUP_DIR/$(basename "$source").$ts.bak"
  cp "$source" "$target"
  ensure_retention
  log_event "BACKUP" "Copia de seguridad creada: $target"
}

AI_TIMEOUT="${AI_TIMEOUT:-${API_TIMEOUT:-60}}"
OLLAMA_MODELS_DIR="${OLLAMA_MODELS_DIR:-$(get_conf OLLAMA_MODELS_DIR 2>/dev/null)}"
OLLAMA_DEFAULT_MODEL="${OLLAMA_DEFAULT_MODEL:-$(get_conf OLLAMA_DEFAULT_MODEL 2>/dev/null)}"
OLLAMA_FALLBACK_MODEL="${OLLAMA_FALLBACK_MODEL:-$(get_conf FALLBACK_MODEL 2>/dev/null)}"
ENABLE_LOCAL_AI="${ENABLE_LOCAL_AI:-$(get_conf ENABLE_LOCAL_AI 2>/dev/null)}"
ENABLE_API_AI="${ENABLE_API_AI:-$(get_conf ENABLE_API_AI 2>/dev/null)}"
API_FAILOVER_ORDER="${API_FAILOVER_ORDER:-$(get_conf API_FAILOVER_ORDER 2>/dev/null)}"

invoke_ai() {
  local prompt="$1"; local explicit_model="$2"
  local model="${explicit_model:-$OLLAMA_DEFAULT_MODEL}"
  log_event "AI" "Solicitud al modelo ${model}"
  if [ "${ENABLE_LOCAL_AI}" = "true" ] && command -v ollama >/dev/null 2>&1; then
    OLLAMA_MODELS_DIR="$OLLAMA_MODELS_DIR" ollama run "$model" -p "$prompt"
    return $?
  fi
  if [ "${ENABLE_API_AI}" = "true" ]; then
    warn "Invocación API remota no implementada en entorno offline"
    return 1
  fi
  fail "No hay motor de IA disponible"
}

load_plugins() {
  local enabled="${ENABLE_PLUGINS:-$(get_conf ENABLE_PLUGINS 2>/dev/null)}"
  [ "$enabled" = "true" ] || return 0
  local plugin_dir="${PLUGIN_DIR:-$(get_conf PLUGIN_DIR 2>/dev/null)}"
  [ -n "$plugin_dir" ] || return 0
  [ -d "$plugin_dir" ] || { warn "PLUGIN_DIR $plugin_dir no existe"; return 0; }
  local level="${PLUGIN_SECURITY_LEVEL:-$(get_conf PLUGIN_SECURITY_LEVEL 2>/dev/null)}"
  for plugin in "$plugin_dir"/*.sh; do
    [ -f "$plugin" ] || continue
    case "$level" in
      strict)
        grep -q "SIGNED" "$plugin" 2>/dev/null || { warn "Plugin $plugin no firmado (nivel strict)"; continue; }
        ;;
      medium|lenient|"")
        ;;
      *) warn "Nivel de seguridad de plugins desconocido: $level" ;;
    esac
    # shellcheck disable=SC1090
    source "$plugin"
    log_event "PLUGIN" "Plugin cargado: $plugin"
  done
}

check_allowed_path() {
  local path="$1"
  local allowed=("$ROOT_DIR" "$(get_conf DEFAULT_PROJECT_PATH 2>/dev/null)" "$LOG_DIR" "$BACKUP_DIR")
  local abs
  abs=$(python3 -c 'import os, sys; print(os.path.abspath(sys.argv[1]))' "$path" 2>/dev/null) || abs="$path"
  for base in "${allowed[@]}"; do
    [ -n "$base" ] || continue
    if [[ "$abs" == "$base"* ]]; then
      return 0
    fi
  done
  fail "Ruta fuera de los directorios permitidos: $path"
}

GIT_BRANCH="${GIT_BRANCH:-$(get_conf GIT_BRANCH 2>/dev/null)}"
ALLOW_GIT_PUSH="${ALLOW_GIT_PUSH:-$(get_conf ALLOW_GIT_PUSH 2>/dev/null)}"

git_safe_push() {
  local repo="$1"
  local branch="${2:-$GIT_BRANCH}"
  if [ "${ALLOW_GIT_PUSH}" != "true" ]; then
    warn "git push deshabilitado por configuración"
    return 1
  fi
  (cd "$repo" && git rev-parse --git-dir >/dev/null 2>&1) || fail "Directorio git inválido: $repo"
  local current
  current=$(cd "$repo" && git rev-parse --abbrev-ref HEAD)
  if [ -n "$branch" ] && [ "$current" != "$branch" ]; then
    fail "La rama activa ($current) no coincide con la configurada ($branch)"
  fi
  (cd "$repo" && git push origin "$current")
}

notify() {
  local message="$1"
  local title="${2:-GPT-OSS Neural Shell}"
  local msg_escaped=$(printf '%s' "$message" | sed 's/"/\\"/g')
  local title_escaped=$(printf '%s' "$title" | sed 's/"/\\"/g')
  log_event "NOTIFY" "$title → $message"
  if command -v osascript >/dev/null 2>&1; then
    osascript -e "display notification \"$msg_escaped\" with title \"$title_escaped\"" >/dev/null 2>&1 || true
  else
    echo "$title: $message"
  fi
}

say_voice() {
  local msg="$1"
  local voice="${2:-${VOICE_DEFAULT:-Samantha}}"
  local mode="${3:-${VOICE_MODE:-summary}}"
  [ "${VOICE_ENABLED}" = "true" ] || return 0
  [ "$mode" = "off" ] && return 0
  log_event "VOICE" "${voice}: ${msg}"
  if command -v say >/dev/null 2>&1; then
    nohup bash -c "say \"${msg}\" using \"${voice}\"" >/dev/null 2>&1 &
  fi
}

init_runtime() {
  local script_name="$1"; local agent="$2"
  log_init "$script_name"
  validate_security_state
  load_plugins
  export CURRENT_AGENT="$agent"
}

usage_header() {
  local name="$1"; shift
  printf 'Uso: %s %s\n\nOpciones comunes:\n  -h, --help        Muestra esta ayuda\n' "$name" "$*"
}

