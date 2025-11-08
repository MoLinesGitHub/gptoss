neural_update() {
  source "$HOME/Documents/Scripts/gptoss/config/gptoss.conf"
  if [ -z "$REPO_URL" ]; then
    notify "REPO_URL no definido en config. Updater omitido."
    echo "ℹ️  Configura REPO_URL en gptoss.conf para usar updater."
    return 0
  fi
  TMP=$(mktemp -d)
  git clone --depth=1 "$REPO_URL" "$TMP" || { echo "❌ git clone falló"; return 1; }
  rsync -a "$TMP/" "$HOME/Documents/Scripts/gptoss/" && notify "Actualización aplicada"
}
