builder_run_build() {
  deny_if_no_perm "BuilderAgent" "build" || return 1
  xcodebuild build -scheme "$(basename "$(pwd)")" -destination "platform=iOS Simulator,name=iPhone 16e,OS=26.0" 2>&1 | tee /tmp/xcode-build.log
}
