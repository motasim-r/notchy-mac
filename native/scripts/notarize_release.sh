#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   Preferred (keychain profile, one-time setup via notarytool store-credentials):
#   DEVELOPER_ID_APP_CERT="Developer ID Application: Your Name (TEAMID)" \
#   NOTARYTOOL_PROFILE="notchy-notary" \
#   SPARKLE_DOWNLOAD_URL_PREFIX="https://github.com/<owner>/<repo>/releases/download/vX.Y.Z" \
#   ./native/scripts/notarize_release.sh
#
#   Fallback (direct Apple credentials):
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
DMG_BACKGROUND_SCRIPT="$NATIVE_DIR/scripts/generate_dmg_background.swift"
DMG_BACKGROUND_REL_PATH=".background/installer-background.png"

if [[ ! -d "$APP_PATH" ]]; then
  echo "Release app not found at $APP_PATH"
  echo "Run ./native/scripts/build_release.sh first."
  exit 1
fi

: "${DEVELOPER_ID_APP_CERT:?Set DEVELOPER_ID_APP_CERT}"

NOTARYTOOL_PROFILE="${NOTARYTOOL_PROFILE:-notchy-notary}"
HAS_KEYCHAIN_PROFILE=0
if xcrun notarytool history --keychain-profile "$NOTARYTOOL_PROFILE" >/dev/null 2>&1; then
  HAS_KEYCHAIN_PROFILE=1
else
  : "${APPLE_ID:?Set APPLE_ID (or configure notary keychain profile)}"
  : "${APPLE_APP_SPECIFIC_PASSWORD:?Set APPLE_APP_SPECIFIC_PASSWORD (or configure notary keychain profile)}"
  : "${TEAM_ID:?Set TEAM_ID (or configure notary keychain profile)}"
fi

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
TMP_DIR="$(mktemp -d "$RELEASE_DIR/.notchy-dmg-XXXXXX")"
DMG_STAGING_DIR="$TMP_DIR/staging"
RW_DMG_PATH="$TMP_DIR/${BASE_BASENAME}-installer-rw.dmg"

cleanup() {
  if [[ -n "${MOUNT_POINT:-}" && -d "${MOUNT_POINT:-}" ]]; then
    hdiutil detach "$MOUNT_POINT" -quiet >/dev/null 2>&1 || true
  fi
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

rm -f "$SUBMIT_ZIP_PATH" "$FINAL_ZIP_PATH" "$FINAL_ZIP_SHA_PATH" "$DMG_PATH" "$DMG_SHA_PATH"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$SUBMIT_ZIP_PATH"

if [[ "$HAS_KEYCHAIN_PROFILE" == "1" ]]; then
  xcrun notarytool submit "$SUBMIT_ZIP_PATH" \
    --keychain-profile "$NOTARYTOOL_PROFILE" \
    --wait
else
  xcrun notarytool submit "$SUBMIT_ZIP_PATH" \
    --apple-id "$APPLE_ID" \
    --password "$APPLE_APP_SPECIFIC_PASSWORD" \
    --team-id "$TEAM_ID" \
    --wait
fi

xcrun stapler staple "$APP_PATH"
xcrun stapler validate "$APP_PATH"
spctl --assess --type execute --verbose=4 "$APP_PATH"

# Export final notarized ZIP + checksum.
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$FINAL_ZIP_PATH"
shasum -a 256 "$FINAL_ZIP_PATH" > "$FINAL_ZIP_SHA_PATH"

# Build installer-style DMG (drag app into Applications).
mkdir -p "$DMG_STAGING_DIR"
cp -R "$APP_PATH" "$DMG_STAGING_DIR/"
ln -s /Applications "$DMG_STAGING_DIR/Applications"
DMG_BACKGROUND_PATH="$DMG_STAGING_DIR/$DMG_BACKGROUND_REL_PATH"
if [[ -f "$DMG_BACKGROUND_SCRIPT" ]]; then
  xcrun swift "$DMG_BACKGROUND_SCRIPT" "$DMG_BACKGROUND_PATH" 720 440 || {
    echo "Warning: failed to generate DMG background image; continuing without custom background."
  }
  chflags hidden "$DMG_STAGING_DIR/.background" >/dev/null 2>&1 || true
fi

hdiutil create \
  -volname "Notchy Teleprompter" \
  -srcfolder "$DMG_STAGING_DIR" \
  -format UDRW \
  -ov \
  "$RW_DMG_PATH"

MOUNT_POINT="$(
  hdiutil attach "$RW_DMG_PATH" -readwrite -noverify -noautoopen | \
    sed -n 's#^.*\(/Volumes/.*\)$#\1#p' | head -n 1
)"
if [[ -z "$MOUNT_POINT" || ! -d "$MOUNT_POINT" ]]; then
  echo "Failed to mount temporary installer DMG."
  exit 1
fi

# Configure Finder window (icon view + drag-to-Applications layout). If this fails,
# release still proceeds with a functional DMG.
VOLUME_NAME="$(basename "$MOUNT_POINT")"
FINDER_BACKGROUND_LINE=""
if [[ -f "$DMG_BACKGROUND_PATH" ]]; then
  FINDER_BACKGROUND_LINE='set background picture of theViewOptions to file ".background:installer-background.png"'
fi
osascript <<APPLESCRIPT || true
tell application "Finder"
  tell disk "$VOLUME_NAME"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set bounds of container window to {140, 120, 860, 560}
    set theViewOptions to the icon view options of container window
    set arrangement of theViewOptions to not arranged
    set icon size of theViewOptions to 112
    set text size of theViewOptions to 14
    $FINDER_BACKGROUND_LINE
    set position of item "Notchy Teleprompter.app" of container window to {200, 240}
    set position of item "Applications" of container window to {520, 240}
    close
    open
    update without registering applications
  end tell
end tell
APPLESCRIPT

sync
bless --folder "$MOUNT_POINT" --openfolder "$MOUNT_POINT" >/dev/null 2>&1 || true
hdiutil detach "$MOUNT_POINT" -quiet
MOUNT_POINT=""
hdiutil convert "$RW_DMG_PATH" -format UDZO -imagekey zlib-level=9 -o "$DMG_PATH"

# Sign, notarize, and staple final DMG.
codesign --force --timestamp --sign "$DEVELOPER_ID_APP_CERT" "$DMG_PATH"
codesign --verify --verbose=2 "$DMG_PATH"

if [[ "$HAS_KEYCHAIN_PROFILE" == "1" ]]; then
  xcrun notarytool submit "$DMG_PATH" \
    --keychain-profile "$NOTARYTOOL_PROFILE" \
    --wait
else
  xcrun notarytool submit "$DMG_PATH" \
    --apple-id "$APPLE_ID" \
    --password "$APPLE_APP_SPECIFIC_PASSWORD" \
    --team-id "$TEAM_ID" \
    --wait
fi

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
  rm -f "$APPCAST_ARCHIVES_DIR"/*.zip
  cp -f "$FINAL_ZIP_PATH" "$APPCAST_ARCHIVES_DIR/"

  "$GENERATE_APPCAST_TOOL" \
    --download-url-prefix "$SPARKLE_DOWNLOAD_URL_PREFIX" \
    --maximum-versions 1 \
    --maximum-deltas 0 \
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
