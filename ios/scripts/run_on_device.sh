#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IOS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_PATH="$IOS_DIR/NotchyTeleprompterIOS.xcodeproj"
DERIVED_PATH="$IOS_DIR/.derived-device"
DEVICE_ID="${1:-${DEVICE_ID:-}}"

if [[ -z "$DEVICE_ID" ]]; then
  echo "Usage: $0 <DEVICE_UDID>"
  echo "Tip: open Xcode -> Window -> Devices and Simulators to copy your iPhone UDID."
  exit 1
fi

if [[ ! -d "$PROJECT_PATH" ]]; then
  "$SCRIPT_DIR/gen_project.sh"
fi

if [[ -d "/Applications/Xcode.app/Contents/Developer" && -z "${DEVELOPER_DIR:-}" ]]; then
  export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
fi

xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme NotchyTeleprompterIOS \
  -configuration Debug \
  -destination "id=$DEVICE_ID" \
  -derivedDataPath "$DERIVED_PATH" \
  -allowProvisioningUpdates \
  build

echo "Device debug build complete for $DEVICE_ID."
echo "Run from Xcode for first launch/signing trust prompts if needed."
