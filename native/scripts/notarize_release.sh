#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   DEVELOPER_ID_APP_CERT="Developer ID Application: Your Name (TEAMID)" \
#   APPLE_ID="you@example.com" \
#   APPLE_APP_SPECIFIC_PASSWORD="xxxx-xxxx-xxxx-xxxx" \
#   TEAM_ID="TEAMID" \
#   SPARKLE_DOWNLOAD_URL_PREFIX="https://github.com/<owner>/<repo>/releases/download/vX.Y.Z" \
#   ./native/scripts/notarize_release.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NATIVE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
RELEASE_DIR="$NATIVE_DIR/release"
APP_PATH="$RELEASE_DIR/Notchy Teleprompter.app"
APPCAST_DIR="$NATIVE_DIR/appcast"
APPCAST_ARCHIVES_DIR="$APPCAST_DIR/archives"
SPARKLE_TOOLS_DIR_DEFAULT="$NATIVE_DIR/.derived-sparkle-tools/Build/Products/Release"
SPARKLE_TOOLS_DIR="${SPARKLE_TOOLS_DIR:-$SPARKLE_TOOLS_DIR_DEFAULT}"
GENERATE_APPCAST="${GENERATE_APPCAST:-1}"

if [[ ! -d "$APP_PATH" ]]; then
  echo "Release app not found at $APP_PATH"
  echo "Run ./native/scripts/build_release.sh first."
  exit 1
fi

: "${DEVELOPER_ID_APP_CERT:?Set DEVELOPER_ID_APP_CERT}"
: "${APPLE_ID:?Set APPLE_ID}"
: "${APPLE_APP_SPECIFIC_PASSWORD:?Set APPLE_APP_SPECIFIC_PASSWORD}"
: "${TEAM_ID:?Set TEAM_ID}"

xattr -cr "$APP_PATH"
codesign --force --deep --options runtime --timestamp --sign "$DEVELOPER_ID_APP_CERT" "$APP_PATH"
codesign --verify --deep --strict --verbose=2 "$APP_PATH"

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_PATH/Contents/Info.plist")"
BUILD_NUMBER="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$APP_PATH/Contents/Info.plist")"
BASE_BASENAME="Notchy-Teleprompter-v${VERSION}-${BUILD_NUMBER}-macOS-universal"
SUBMIT_ZIP_PATH="$RELEASE_DIR/${BASE_BASENAME}-notary-submit.zip"
FINAL_ZIP_PATH="$RELEASE_DIR/${BASE_BASENAME}-notarized.zip"
FINAL_ZIP_SHA_PATH="$RELEASE_DIR/${BASE_BASENAME}-notarized.sha256"
DMG_PATH="$RELEASE_DIR/${BASE_BASENAME}-notarized.dmg"
DMG_SHA_PATH="$RELEASE_DIR/${BASE_BASENAME}-notarized.dmg.sha256"

rm -f "$SUBMIT_ZIP_PATH" "$FINAL_ZIP_PATH" "$FINAL_ZIP_SHA_PATH" "$DMG_PATH" "$DMG_SHA_PATH"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$SUBMIT_ZIP_PATH"

xcrun notarytool submit "$SUBMIT_ZIP_PATH" \
  --apple-id "$APPLE_ID" \
  --password "$APPLE_APP_SPECIFIC_PASSWORD" \
  --team-id "$TEAM_ID" \
  --wait

xcrun stapler staple "$APP_PATH"
xcrun stapler validate "$APP_PATH"
spctl --assess --type execute --verbose=4 "$APP_PATH"

# Export final notarized ZIP + checksum.
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$FINAL_ZIP_PATH"
shasum -a 256 "$FINAL_ZIP_PATH" > "$FINAL_ZIP_SHA_PATH"

# Build, sign, notarize, and staple DMG.
hdiutil create -volname "Notchy Teleprompter" -srcfolder "$APP_PATH" -ov -format UDZO "$DMG_PATH"
codesign --force --timestamp --sign "$DEVELOPER_ID_APP_CERT" "$DMG_PATH"
codesign --verify --verbose=2 "$DMG_PATH"

xcrun notarytool submit "$DMG_PATH" \
  --apple-id "$APPLE_ID" \
  --password "$APPLE_APP_SPECIFIC_PASSWORD" \
  --team-id "$TEAM_ID" \
  --wait

xcrun stapler staple "$DMG_PATH"
xcrun stapler validate "$DMG_PATH"
spctl --assess --type open --context context:primary-signature --verbose=4 "$DMG_PATH"
shasum -a 256 "$DMG_PATH" > "$DMG_SHA_PATH"

if [[ "$GENERATE_APPCAST" == "1" ]]; then
  GENERATE_APPCAST_TOOL="$SPARKLE_TOOLS_DIR/generate_appcast"

  if [[ ! -x "$GENERATE_APPCAST_TOOL" ]]; then
    "$NATIVE_DIR/scripts/build_sparkle_tools.sh"
  fi

  if [[ ! -x "$GENERATE_APPCAST_TOOL" ]]; then
    echo "Sparkle generate_appcast tool not found at $GENERATE_APPCAST_TOOL"
    exit 1
  fi

  if [[ -z "${SPARKLE_DOWNLOAD_URL_PREFIX:-}" ]]; then
    ORIGIN_URL="$(git -C "$NATIVE_DIR/.." config --get remote.origin.url || true)"
    if [[ "$ORIGIN_URL" =~ github.com[:/]([^/]+)/([^.]+)(\.git)?$ ]]; then
      OWNER="${BASH_REMATCH[1]}"
      REPO="${BASH_REMATCH[2]}"
      SPARKLE_DOWNLOAD_URL_PREFIX="https://github.com/$OWNER/$REPO/releases/download/v${VERSION}/"
    else
      echo "Set SPARKLE_DOWNLOAD_URL_PREFIX to your public release asset URL prefix."
      exit 1
    fi
  fi

  if [[ "$SPARKLE_DOWNLOAD_URL_PREFIX" != */ ]]; then
    SPARKLE_DOWNLOAD_URL_PREFIX="${SPARKLE_DOWNLOAD_URL_PREFIX}/"
  fi

  mkdir -p "$APPCAST_ARCHIVES_DIR"
  cp -f "$FINAL_ZIP_PATH" "$APPCAST_ARCHIVES_DIR/"

  "$GENERATE_APPCAST_TOOL" \
    --download-url-prefix "$SPARKLE_DOWNLOAD_URL_PREFIX" \
    --maximum-versions 6 \
    -o "$APPCAST_DIR/appcast.xml" \
    "$APPCAST_ARCHIVES_DIR"
fi

cat <<REPORT
Public distribution artifacts ready:
- App: $APP_PATH
- Zip: $FINAL_ZIP_PATH
- Zip SHA256: $FINAL_ZIP_SHA_PATH
- DMG: $DMG_PATH
- DMG SHA256: $DMG_SHA_PATH
$( [[ "$GENERATE_APPCAST" == "1" ]] && echo "- Appcast: $APPCAST_DIR/appcast.xml" )
REPORT
