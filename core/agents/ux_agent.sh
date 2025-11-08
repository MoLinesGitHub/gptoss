ux_recommend() {
  deny_if_no_perm "UXAgent" "assets_read" || return 1
  ollama run "$MODEL" -p "Sugiere mejoras de accesibilidad y animaciones en SwiftUI para este proyecto. Responde con snippets concretos."
}
