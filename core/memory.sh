update_memory() {
  local project=$(basename "$(pwd)")
  local when=$(date +"%F %T")
  local evt="$1"
  local file="$HOME/Documents/Scripts/gptoss/data/memory.json"
  mkdir -p "$(dirname "$file")"
  jq -c --arg p "$project" --arg w "$when" --arg e "$evt" '
    .events += [{"project":$p,"when":$w,"event":$e}]' "$file" 2>/dev/null \
    || echo '{"events":[]}' > "$file"
  jq -c --arg p "$project" --arg w "$when" --arg e "$evt" '
    .events += [{"project":$p,"when":$w,"event":$e}]' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
}
load_memory() {
  local file="$HOME/Documents/Scripts/gptoss/data/memory.json"
  [ -f "$file" ] && cat "$file"
}
init_memory_if_missing() {
  local file="$HOME/Documents/Scripts/gptoss/data/memory.json"
  [ -f "$file" ] || echo '{"events":[]}' > "$file"
}
