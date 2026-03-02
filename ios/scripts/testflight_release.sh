#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IOS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_PATH="$IOS_DIR/NotchyTeleprompterIOS.xcodeproj"
SCHEME="${SCHEME:-NotchyTeleprompterIOS}"
CONFIGURATION="${CONFIGURATION:-Release}"
RELEASE_ROOT="$IOS_DIR/release"

if [[ ! -d "$PROJECT_PATH" ]]; then
  "$SCRIPT_DIR/gen_project.sh"
fi

if [[ -d "/Applications/Xcode.app/Contents/Developer" && -z "${DEVELOPER_DIR:-}" ]]; then
  export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
fi

APPLE_ID="${APPLE_ID:-}"
APPLE_APP_SPECIFIC_PASSWORD="${APPLE_APP_SPECIFIC_PASSWORD:-}"

if [[ -z "$APPLE_ID" ]]; then
  echo "Missing APPLE_ID env var."
  echo "Example: APPLE_ID='you@example.com' APPLE_APP_SPECIFIC_PASSWORD='xxxx-xxxx-xxxx-xxxx' $0"
  exit 1
fi

if [[ -z "$APPLE_APP_SPECIFIC_PASSWORD" ]]; then
  echo "Missing APPLE_APP_SPECIFIC_PASSWORD env var."
  echo "Example: APPLE_ID='you@example.com' APPLE_APP_SPECIFIC_PASSWORD='xxxx-xxxx-xxxx-xxxx' $0"
  exit 1
fi

show_settings() {
  xcodebuild \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -showBuildSettings
}

build_setting() {
  local key="$1"
  awk -F' = ' -v key="$key" '$1 ~ " " key " " {print $2; exit}'
}

SETTINGS="$(show_settings)"
DEFAULT_BUNDLE_ID="$(printf '%s\n' "$SETTINGS" | build_setting PRODUCT_BUNDLE_IDENTIFIER)"
DEFAULT_VERSION="$(printf '%s\n' "$SETTINGS" | build_setting MARKETING_VERSION)"
DEFAULT_TEAM_ID="$(printf '%s\n' "$SETTINGS" | build_setting DEVELOPMENT_TEAM)"

BUNDLE_ID="${BUNDLE_ID:-$DEFAULT_BUNDLE_ID}"
MARKETING_VERSION="${MARKETING_VERSION:-$DEFAULT_VERSION}"
TEAM_ID="${TEAM_ID:-$DEFAULT_TEAM_ID}"
BUILD_NUMBER="${BUILD_NUMBER:-$(date +%Y%m%d%H%M%S)}"

if [[ -z "$BUNDLE_ID" || -z "$MARKETING_VERSION" || -z "$TEAM_ID" ]]; then
  echo "Unable to resolve build settings (bundle id/version/team)."
  exit 1
fi

TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
RELEASE_DIR="$RELEASE_ROOT/testflight-v${MARKETING_VERSION}-b${BUILD_NUMBER}-${TIMESTAMP}"
ARCHIVE_PATH="$RELEASE_DIR/NotchyTeleprompterIOS.xcarchive"
EXPORT_PATH="$RELEASE_DIR/export"
EXPORT_PLIST="$RELEASE_DIR/ExportOptions.plist"

mkdir -p "$EXPORT_PATH"

cat >"$EXPORT_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>destination</key>
  <string>export</string>
  <key>method</key>
  <string>app-store-connect</string>
  <key>signingStyle</key>
  <string>automatic</string>
  <key>teamID</key>
  <string>${TEAM_ID}</string>
  <key>stripSwiftSymbols</key>
  <true/>
  <key>uploadSymbols</key>
  <true/>
  <key>manageAppVersionAndBuildNumber</key>
  <false/>
</dict>
</plist>
EOF

echo "==> Validating App Store Connect auth"
printf '%s\n' "$APPLE_APP_SPECIFIC_PASSWORD" | xcrun altool \
  --list-providers \
  -u "$APPLE_ID" \
  --output-format normal >/dev/null

echo "==> Archiving iOS app (Release)"
xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination "generic/platform=iOS" \
  -archivePath "$ARCHIVE_PATH" \
  MARKETING_VERSION="$MARKETING_VERSION" \
  CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  -allowProvisioningUpdates \
  clean archive

echo "==> Exporting IPA"
xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$EXPORT_PLIST" \
  -allowProvisioningUpdates

IPA_PATH="$(find "$EXPORT_PATH" -maxdepth 2 -name '*.ipa' | head -n 1)"
if [[ -z "$IPA_PATH" ]]; then
  echo "IPA export failed; no .ipa found in $EXPORT_PATH"
  exit 1
fi

echo "==> Uploading to TestFlight"
printf '%s\n' "$APPLE_APP_SPECIFIC_PASSWORD" | xcrun altool \
  --upload-app \
  -t ios \
  -f "$IPA_PATH" \
  -u "$APPLE_ID" \
  --show-progress \
  --output-format normal

echo ""
echo "TestFlight upload submitted."
echo "Bundle ID: $BUNDLE_ID"
echo "Version: $MARKETING_VERSION"
echo "Build: $BUILD_NUMBER"
echo "IPA: $IPA_PATH"
echo "Release dir: $RELEASE_DIR"
