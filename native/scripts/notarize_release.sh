#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   DEVELOPER_ID_APP_CERT="Developer ID Application: Your Name (TEAMID)" \
#   APPLE_ID="you@example.com" \
#   APPLE_APP_SPECIFIC_PASSWORD="xxxx-xxxx-xxxx-xxxx" \
#   TEAM_ID="TEAMID" \
#   ./native/scripts/notarize_release.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NATIVE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
RELEASE_DIR="$NATIVE_DIR/release"
APP_PATH="$RELEASE_DIR/Notchy Teleprompter.app"

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

cat <<REPORT
Public distribution artifacts ready:
- App: $APP_PATH
- Zip: $FINAL_ZIP_PATH
- Zip SHA256: $FINAL_ZIP_SHA_PATH
- DMG: $DMG_PATH
- DMG SHA256: $DMG_SHA_PATH
REPORT
