#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IOS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_PATH="$IOS_DIR/NotchyTeleprompterIOS.xcodeproj"
DERIVED_PATH="$IOS_DIR/.derived-debug"

if [[ ! -d "$PROJECT_PATH" ]]; then
  "$SCRIPT_DIR/gen_project.sh"
fi

if [[ -d "/Applications/Xcode.app/Contents/Developer" && -z "${DEVELOPER_DIR:-}" ]]; then
  export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
fi

run_build() {
  local destination="$1"
  local log_file="$2"
  set +e
  xcodebuild \
    -project "$PROJECT_PATH" \
    -scheme NotchyTeleprompterIOS \
    -configuration Debug \
    -destination "$destination" \
    -derivedDataPath "$DERIVED_PATH" \
    CODE_SIGNING_ALLOWED=NO \
    build 2>&1 | tee "$log_file"
  local status=${PIPESTATUS[0]}
  set -e
  return "$status"
}

SIM_LOG="$(mktemp)"
IOS_LOG="$(mktemp)"
trap 'rm -f "$SIM_LOG" "$IOS_LOG"' EXIT

if run_build "generic/platform=iOS Simulator" "$SIM_LOG"; then
  :
elif grep -q "Unable to find a destination matching the provided destination specifier" "$SIM_LOG"; then
  if run_build "generic/platform=iOS" "$IOS_LOG"; then
    :
  elif grep -q "Unable to find a destination matching the provided destination specifier" "$IOS_LOG"; then
    echo "Build failed because iOS platform/runtime components appear missing in Xcode."
    echo "Open Xcode -> Settings -> Components and install the latest iOS + iOS Simulator platforms."
    exit 1
  else
    echo "Build failed due code/project errors. See xcodebuild output above."
    exit 1
  fi
else
  echo "Build failed due code/project errors. See xcodebuild output above."
  exit 1
fi

echo "Debug build complete."
echo "App bundle: $DERIVED_PATH/Build/Products/Debug-iphonesimulator/Notchy Teleprompter iOS.app"
