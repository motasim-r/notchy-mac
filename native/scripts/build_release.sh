#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NATIVE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_PATH="$NATIVE_DIR/NotchyTeleprompter.xcodeproj"
SCHEME="NotchyTeleprompter"
DERIVED_DATA_PATH="$NATIVE_DIR/.derived-release"
APP_NAME="Notchy Teleprompter.app"
APP_PATH="$DERIVED_DATA_PATH/Build/Products/Release/$APP_NAME"
RELEASE_DIR="$NATIVE_DIR/release"

if [[ -d "/Applications/Xcode.app/Contents/Developer" && -z "${DEVELOPER_DIR:-}" ]]; then
  export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
fi

if [[ ! -d "$PROJECT_PATH" ]]; then
  echo "Project not found at $PROJECT_PATH"
  exit 1
fi

mkdir -p "$RELEASE_DIR"

xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination "generic/platform=macOS" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  ARCHS="arm64 x86_64" \
  ONLY_ACTIVE_ARCH=NO \
  clean build

if [[ ! -d "$APP_PATH" ]]; then
  echo "Build succeeded but app bundle not found at: $APP_PATH"
  exit 1
fi

BIN_PATH="$APP_PATH/Contents/MacOS/Notchy Teleprompter"
if [[ ! -f "$BIN_PATH" ]]; then
  echo "App binary missing at: $BIN_PATH"
  exit 1
fi

ARCHS="$(lipo -archs "$BIN_PATH")"
if [[ "$ARCHS" != *"arm64"* || "$ARCHS" != *"x86_64"* ]]; then
  echo "Expected universal binary (arm64 + x86_64), got: $ARCHS"
  exit 1
fi

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_PATH/Contents/Info.plist")"
BUILD_NUMBER="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$APP_PATH/Contents/Info.plist")"
ZIP_BASENAME="Notchy-Teleprompter-v${VERSION}-${BUILD_NUMBER}-macOS-universal"
ZIP_PATH="$RELEASE_DIR/${ZIP_BASENAME}.zip"
SHA_PATH="$RELEASE_DIR/${ZIP_BASENAME}.sha256"
DIST_APP_PATH="$RELEASE_DIR/$APP_NAME"

rm -rf "$DIST_APP_PATH" "$ZIP_PATH" "$SHA_PATH"
cp -R "$APP_PATH" "$DIST_APP_PATH"
ditto -c -k --sequesterRsrc --keepParent "$DIST_APP_PATH" "$ZIP_PATH"
shasum -a 256 "$ZIP_PATH" > "$SHA_PATH"

cat <<REPORT
Release build complete.
- App: $DIST_APP_PATH
- Zip: $ZIP_PATH
- SHA256: $SHA_PATH
- Architectures: $ARCHS
REPORT
