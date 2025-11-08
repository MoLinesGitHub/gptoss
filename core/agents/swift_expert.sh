swift_expert_review() {
  deny_if_no_perm "SwiftExpert" "code_read" || return 1
  local diff=$(git diff --cached || git diff || true)
  [ -z "$diff" ] && { echo "ℹ️  No hay cambios para revisar"; return 0; }
  ollama run "$MODEL" -p "Como experto Swift, propone mejoras y refactors para este diff:\n$diff" --temperature "$TEMPERATURE"
}
