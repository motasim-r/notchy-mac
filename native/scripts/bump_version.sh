#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NATIVE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_YML="$NATIVE_DIR/project.yml"
PBXPROJ="$NATIVE_DIR/NotchyTeleprompter.xcodeproj/project.pbxproj"

if [[ ! -f "$PROJECT_YML" || ! -f "$PBXPROJ" ]]; then
  echo "Missing project files required for version bump."
  exit 1
fi

current_marketing="$(sed -nE 's/^[[:space:]]*MARKETING_VERSION:[[:space:]]*([0-9]+\.[0-9]+\.[0-9]+)[[:space:]]*$/\1/p' "$PROJECT_YML" | head -n1)"
current_build="$(sed -nE 's/^[[:space:]]*CURRENT_PROJECT_VERSION:[[:space:]]*([0-9]+)[[:space:]]*$/\1/p' "$PROJECT_YML" | head -n1)"

if [[ -z "$current_marketing" || -z "$current_build" ]]; then
  echo "Unable to parse current version/build from $PROJECT_YML"
  exit 1
fi

IFS='.' read -r major minor patch <<< "$current_marketing"
next_patch=$((patch + 1))
next_build=$((current_build + 1))
next_marketing="${major}.${minor}.${next_patch}"

# Update project.yml (single source used for xcodegen sync)
sed -E -i '' "s/^([[:space:]]*MARKETING_VERSION:[[:space:]]*).*/\\1${next_marketing}/" "$PROJECT_YML"
sed -E -i '' "s/^([[:space:]]*CURRENT_PROJECT_VERSION:[[:space:]]*).*/\\1${next_build}/" "$PROJECT_YML"

# Update all build settings entries in pbxproj
sed -E -i '' "s/(MARKETING_VERSION = )[0-9]+\.[0-9]+\.[0-9]+;/\\1${next_marketing};/g" "$PBXPROJ"
sed -E -i '' "s/(CURRENT_PROJECT_VERSION = )[0-9]+;/\\1${next_build};/g" "$PBXPROJ"

echo "Bumped version: ${current_marketing} (${current_build}) -> ${next_marketing} (${next_build})"
echo "NEW_MARKETING_VERSION=${next_marketing}"
echo "NEW_BUILD_NUMBER=${next_build}"
