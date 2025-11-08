show_menu() {
  OPTION=$(osascript -e 'choose from list {"Chat", "Talk", "Compilar", "Tests", "Analizar Log", "Revisión de Código", "Visualizer", "Daemon ON", "Daemon OFF", "Update", "Salir"} with prompt "Neural Shell v5.5 — elige acción:" default items {"Chat"}' 2>/dev/null)
  case $OPTION in
    "Chat") chat_mode ;;
    "Talk") talk_mode ;;
    "Compilar") compile_xcode ;;
    "Tests") run_tests ;;
    "Analizar Log") analyze_xcode_log ;;
    "Revisión de Código") review_code ;;
    "Visualizer") generate_dashboard2 ;;
    "Daemon ON") daemon_start ;;
    "Daemon OFF") daemon_stop ;;
    "Update") neural_update ;;
    "Salir") notify "Asistente cerrado"; exit 0 ;;
  esac
}
