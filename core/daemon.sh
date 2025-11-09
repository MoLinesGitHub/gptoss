#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1090
source "$SCRIPT_DIR/common.sh"

AGENT_NAME="SchedulerAgent"
SCRIPT_NAME="daemon"
PID_FILE="$LOG_DIR/gptoss-daemon.pid"
init_runtime "$SCRIPT_NAME" "$AGENT_NAME"

usage() {
  usage_header "$(basename "$0")" "[start|stop|status]"
  cat <<'USAGE'
Comandos:
  start            Inicia el daemon de monitoreo neural
  stop             Detiene el daemon si está activo
  status           Muestra el estado actual
USAGE
}

daemon_worker() {
  local fail_count=0
  local last_checksum=""
  local build_log="$(get_conf BUILD_LOG)"
  [ -n "$build_log" ] || build_log="/tmp/xcode-build.log"
  while true; do
    local checksum=""
    [ -f "$build_log" ] && checksum=$(cksum "$build_log" | awk '{print $1}')
    if [ "$checksum" != "$last_checksum" ]; then
      last_checksum="$checksum"
      if [ -n "$checksum" ] && grep -q "error:" "$build_log" 2>/dev/null; then
        fail_count=$((fail_count + 1))
        notify "Fallo de build ($fail_count) — analizando" "Neural Daemon"
        invoke_ai "Analiza el log de Xcode y explica errores:\n$(tail -n 400 "$build_log")" >> "$LOG_DIR/analyzer.log" 2>&1 || true
        if [ $fail_count -ge 3 ] && command -v defaults >/dev/null 2>&1; then
          defaults write com.apple.notificationcenterui doNotDisturb -boolean true && killall NotificationCenter >/dev/null 2>&1 || true
          notify "Focus Mode activado (3 fallos seguidos)" "Neural Daemon"
        fi
      else
        [ $fail_count -gt 0 ] && fail_count=0
      fi
      "$SCRIPT_DIR/dashboard2.sh" run >/dev/null 2>&1 || true
    fi
    sleep 2
  done
}

daemon_start() {
  require_permission "$AGENT_NAME" "agent_spawn"
  if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    warn "Daemon ya se encuentra activo"
    return 0
  fi
  notify "Daemon cognitivo ON"
  "$0" worker >/tmp/gptoss-daemon.log 2>&1 &
  echo $! > "$PID_FILE"
  log_event "DAEMON" "Proceso iniciado con PID $(cat "$PID_FILE")"
}

daemon_stop() {
  require_permission "$AGENT_NAME" "health_monitor"
  if [ -f "$PID_FILE" ]; then
    local pid
    pid=$(cat "$PID_FILE")
    if kill -0 "$pid" 2>/dev/null; then
      kill "$pid" || true
    fi
    rm -f "$PID_FILE"
  fi
  pkill -f "gptoss/core/dashboard2.sh" >/dev/null 2>&1 || true
  notify "Daemon cognitivo OFF"
  log_event "DAEMON" "Proceso detenido"
}

daemon_status() {
  if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    ok "Daemon activo (PID $(cat "$PID_FILE"))"
  else
    warn "Daemon inactivo"
  fi
}

dispatch() {
  case "${1:-status}" in
    start)
      daemon_start
      ;;
    stop)
      daemon_stop
      ;;
    status)
      daemon_status
      ;;
    worker)
      daemon_worker
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
