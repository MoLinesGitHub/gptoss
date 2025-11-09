#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1090
source "$SCRIPT_DIR/common.sh"

AGENT_NAME="BuilderAgent"
SCRIPT_NAME="xcode"
init_runtime "$SCRIPT_NAME" "$AGENT_NAME"

XCODE_BIN="$(get_conf XCODE_PATH)"
PROJECT_PATH="$(get_conf DEFAULT_PROJECT_PATH)"
SCHEME="$(get_conf DEFAULT_SCHEME)"
SIMULATOR="$(get_conf DEFAULT_SIMULATOR)"
BUILD_DEST="platform=iOS Simulator,name=${SIMULATOR}" 

usage() {
  usage_header "$(basename "$0")" "[build|test|review|analyze]"
  cat <<'USAGE'
Comandos:
  build             Ejecuta xcodebuild build con la configuración por defecto
  test              Ejecuta la suite de tests configurada
  review            Solicita revisión de código usando IA
  analyze           Analiza el último log de compilación
USAGE
}

ensure_project_path() {
  [ -n "$PROJECT_PATH" ] || fail "DEFAULT_PROJECT_PATH no definido"
  check_allowed_path "$PROJECT_PATH"
  [ -d "$PROJECT_PATH" ] || fail "Ruta de proyecto inválida: $PROJECT_PATH"
}

run_xcode() {
  local action="$1"
  shift
  require_permission "$AGENT_NAME" "$action"
  ensure_project_path
  local cmd=("${XCODE_BIN:-xcodebuild}" "$@")
  notify "Ejecutando xcodebuild ($action)..."
  (cd "$PROJECT_PATH" && "${cmd[@]}" 2>&1 | tee "$BUILD_LOG")
  log_event "XCODE" "Acción $action ejecutada"
}

compile_xcode() {
  [ "${AUTO_COMPILE:-$(get_conf AUTO_COMPILE 2>/dev/null)}" = "true" ] || warn "AUTO_COMPILE deshabilitado"
  run_xcode "build" build -scheme "$SCHEME" -destination "$BUILD_DEST"
  notify "Compilación finalizada"
  say_voice "Compilación completada" "${VOICE_DEFAULT:-Samantha}"
}

run_tests() {
  [ "${AUTO_TEST:-$(get_conf AUTO_TEST 2>/dev/null)}" = "true" ] || warn "AUTO_TEST deshabilitado"
  run_xcode "test" test -scheme "$SCHEME" -destination "$BUILD_DEST"
  notify "Tests finalizados"
  say_voice "Tests completados" "${VOICE_DEFAULT:-Samantha}"
}

review_code() {
  require_permission "SwiftExpert" "code_read"
  local diff=$(cd "$PROJECT_PATH" && (git diff --cached || git diff) || true)
  [ -z "$diff" ] && { notify "Sin cambios recientes"; echo "Sin diff"; return 0; }
  invoke_ai "Revisión técnica del siguiente diff Swift (claridad, arquitectura, rendimiento):\n$diff" | tee -a "$LOG_DIR/reviews.log"
  say_voice "Revisión de código lista" "${VOICE_DEFAULT:-Samantha}"
}

analyze_xcode_log() {
  require_permission "$AGENT_NAME" "build"
  [ -f "$BUILD_LOG" ] || fail "No existe build log en $BUILD_LOG"
  invoke_ai "Analiza el log de Xcode y propone fixes:\n$(tail -n 400 "$BUILD_LOG")" | tee -a "$LOG_DIR/analyzer.log"
  say_voice "Análisis del log completado" "${VOICE_DEFAULT:-Samantha}"
}

dispatch() {
  case "${1:-build}" in
    build)
      compile_xcode
      ;;
    test)
      run_tests
      ;;
    review)
      review_code
      ;;
    analyze)
      analyze_xcode_log
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
