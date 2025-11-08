notify() {
  osascript -e "display notification \"$1\" with title \"GPT-OSS Neural Shell\"" >/dev/null 2>&1 || true
}
say_voice() {
  local msg="$1"
  local v="${2:-${VOICE_DEFAULT:-Samantha}}"
  local mode="${3:-${VOICE_MODE:-summary}}"
  [ "${VOICE_ENABLED}" = "true" ] || return 0
  [ "${mode}" = "off" ] && return 0
  if command -v say >/dev/null 2>&1; then
    nohup bash -c "say \"${msg}\" using \"${v}\"" >/dev/null 2>&1 &
  fi
}
