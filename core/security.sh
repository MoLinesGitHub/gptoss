check_perm() {
  local agent="$1"; local action="$2"
  awk -v a="$agent" -v ac="$action" '
  $1==a && $2==ac {print $3}' "$HOME/Documents/Scripts/gptoss/config/security.map" | grep -q "yes"
}
deny_if_no_perm() {
  local agent="$1"; local action="$2"
  if ! check_perm "$agent" "$action"; then
    osascript -e "display notification \"Denied: $agent/$action\" with title \"GPT-OSS Sandbox\" sound name \"Basso\"" >/dev/null 2>&1 || true
    echo "⛔ Sandbox: $agent no tiene permiso para $action"
    return 1
  fi
}
