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

if xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme NotchyTeleprompterIOS \
  -configuration Debug \
  -destination "generic/platform=iOS Simulator" \
  -derivedDataPath "$DERIVED_PATH" \
  CODE_SIGNING_ALLOWED=NO \
  build; then
  :
elif xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme NotchyTeleprompterIOS \
  -configuration Debug \
  -destination "generic/platform=iOS" \
  -derivedDataPath "$DERIVED_PATH" \
  CODE_SIGNING_ALLOWED=NO \
  build; then
  :
else
  echo "Build failed because iOS platform/runtime components appear missing in Xcode."
  echo "Open Xcode -> Settings -> Components and install the latest iOS + iOS Simulator platforms."
  exit 1
fi

echo "Debug build complete."
echo "App bundle: $DERIVED_PATH/Build/Products/Debug-iphonesimulator/Notchy Teleprompter iOS.app"
