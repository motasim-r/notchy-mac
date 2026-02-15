#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NATIVE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_PROJECT="$NATIVE_DIR/NotchyTeleprompter.xcodeproj"
APP_SCHEME="NotchyTeleprompter"
PACKAGE_DERIVED="$NATIVE_DIR/.derived-updater-probe"
TOOLS_DERIVED="$NATIVE_DIR/.derived-sparkle-tools"
SPARKLE_PROJECT="$PACKAGE_DERIVED/SourcePackages/checkouts/Sparkle/Sparkle.xcodeproj"

if [[ -d "/Applications/Xcode.app/Contents/Developer" && -z "${DEVELOPER_DIR:-}" ]]; then
  export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
fi

if [[ ! -d "$APP_PROJECT" ]]; then
  echo "App project not found at $APP_PROJECT"
  exit 1
fi

xcodebuild \
  -project "$APP_PROJECT" \
  -scheme "$APP_SCHEME" \
  -configuration Debug \
  -derivedDataPath "$PACKAGE_DERIVED" \
  -resolvePackageDependencies >/dev/null

if [[ ! -d "$SPARKLE_PROJECT" ]]; then
  echo "Sparkle project not found at $SPARKLE_PROJECT"
  exit 1
fi

for scheme in generate_keys sign_update generate_appcast; do
  xcodebuild \
    -project "$SPARKLE_PROJECT" \
    -scheme "$scheme" \
    -configuration Release \
    -derivedDataPath "$TOOLS_DERIVED" \
    build >/dev/null
done

cat <<REPORT
Sparkle tools ready:
- $TOOLS_DERIVED/Build/Products/Release/generate_keys
- $TOOLS_DERIVED/Build/Products/Release/sign_update
- $TOOLS_DERIVED/Build/Products/Release/generate_appcast
REPORT
