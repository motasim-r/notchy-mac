#!/usr/bin/env bash
set -euo pipefail

# One-command public release pipeline:
# 1) Push main
# 2) Build release app
# 3) Sign + notarize + staple + generate appcast
# 4) Commit/push appcast changes
# 5) Create/push git tag (v<version>)
# 6) Create or update GitHub release and upload notarized assets
#
# Required env vars:
#   DEVELOPER_ID_APP_CERT
#   APPLE_ID
#   APPLE_APP_SPECIFIC_PASSWORD
#   TEAM_ID
#
# GitHub release upload:
#   Preferred: gh CLI installed and authenticated
#   Fallback: set GITHUB_TOKEN (repo scope for private repos, public_repo for public)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NATIVE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_DIR="$(cd "$NATIVE_DIR/.." && pwd)"
RELEASE_DIR="$NATIVE_DIR/release"
APP_PATH="$RELEASE_DIR/Notchy Teleprompter.app"

if [[ -d "/Applications/Xcode.app/Contents/Developer" && -z "${DEVELOPER_DIR:-}" ]]; then
  export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
fi

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1"
    exit 1
  fi
}

require_cmd git
require_cmd xcodebuild
require_cmd xcrun
require_cmd codesign
require_cmd shasum
require_cmd curl

: "${DEVELOPER_ID_APP_CERT:?Set DEVELOPER_ID_APP_CERT}"
: "${APPLE_ID:?Set APPLE_ID}"
: "${APPLE_APP_SPECIFIC_PASSWORD:?Set APPLE_APP_SPECIFIC_PASSWORD}"
: "${TEAM_ID:?Set TEAM_ID}"

CURRENT_BRANCH="$(git -C "$REPO_DIR" branch --show-current)"
if [[ "$CURRENT_BRANCH" != "main" ]]; then
  echo "Current branch is '$CURRENT_BRANCH'. Switch to 'main' before public release."
  exit 1
fi

ORIGIN_URL="$(git -C "$REPO_DIR" config --get remote.origin.url || true)"
if [[ "$ORIGIN_URL" =~ github.com[:/]([^/]+)/([^.]+)(\.git)?$ ]]; then
  OWNER="${BASH_REMATCH[1]}"
  REPO="${BASH_REMATCH[2]}"
else
  echo "Could not parse GitHub owner/repo from origin URL: $ORIGIN_URL"
  exit 1
fi

echo "==> Step 1/6: push main"
git -C "$REPO_DIR" push origin main

echo "==> Step 2/6: build universal release"
"$NATIVE_DIR/scripts/build_release.sh"

echo "==> Step 3/6: notarize and generate appcast"
"$NATIVE_DIR/scripts/notarize_release.sh"

if [[ ! -d "$APP_PATH" ]]; then
  echo "Missing built app at $APP_PATH"
  exit 1
fi

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_PATH/Contents/Info.plist")"
BUILD_NUMBER="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$APP_PATH/Contents/Info.plist")"
TAG="v${VERSION}"
BASE_BASENAME="Notchy-Teleprompter-v${VERSION}-${BUILD_NUMBER}-macOS-universal"
ZIP_PATH="$RELEASE_DIR/${BASE_BASENAME}-notarized.zip"
ZIP_SHA_PATH="$RELEASE_DIR/${BASE_BASENAME}-notarized.sha256"
DMG_PATH="$RELEASE_DIR/${BASE_BASENAME}-notarized.dmg"
DMG_SHA_PATH="$RELEASE_DIR/${BASE_BASENAME}-notarized.dmg.sha256"

for required_file in "$ZIP_PATH" "$ZIP_SHA_PATH" "$DMG_PATH" "$DMG_SHA_PATH" "$NATIVE_DIR/appcast/appcast.xml"; do
  if [[ ! -f "$required_file" ]]; then
    echo "Missing expected artifact: $required_file"
    exit 1
  fi
done

echo "==> Step 4/6: commit/push appcast updates"
if [[ -n "$(git -C "$REPO_DIR" status --porcelain -- native/appcast/appcast.xml)" ]]; then
  git -C "$REPO_DIR" add native/appcast/appcast.xml
  git -C "$REPO_DIR" commit -m "chore(release): update appcast for ${TAG} (${BUILD_NUMBER})"
  git -C "$REPO_DIR" push origin main
else
  echo "No appcast changes detected."
fi

echo "==> Step 5/6: create/push tag ${TAG}"
if git -C "$REPO_DIR" ls-remote --tags origin "refs/tags/${TAG}" | grep -q "${TAG}"; then
  echo "Tag ${TAG} already exists on origin."
else
  if git -C "$REPO_DIR" rev-parse -q --verify "refs/tags/${TAG}" >/dev/null; then
    git -C "$REPO_DIR" push origin "${TAG}"
  else
    git -C "$REPO_DIR" tag "${TAG}"
    git -C "$REPO_DIR" push origin "${TAG}"
  fi
fi

release_with_gh() {
  local release_notes
  release_notes=$(
    cat <<EOF
Notchy Teleprompter ${TAG} (build ${BUILD_NUMBER})

Assets:
- ${BASE_BASENAME}-notarized.dmg
- ${BASE_BASENAME}-notarized.dmg.sha256
- ${BASE_BASENAME}-notarized.zip
- ${BASE_BASENAME}-notarized.sha256
EOF
  )

  if gh release view "$TAG" --repo "${OWNER}/${REPO}" >/dev/null 2>&1; then
    gh release upload "$TAG" \
      "$ZIP_PATH" "$ZIP_SHA_PATH" "$DMG_PATH" "$DMG_SHA_PATH" \
      --clobber \
      --repo "${OWNER}/${REPO}"
  else
    gh release create "$TAG" \
      "$ZIP_PATH" "$ZIP_SHA_PATH" "$DMG_PATH" "$DMG_SHA_PATH" \
      --title "Notchy Teleprompter ${TAG}" \
      --notes "$release_notes" \
      --latest \
      --repo "${OWNER}/${REPO}"
  fi
}

release_with_api() {
  if [[ -z "${GITHUB_TOKEN:-}" ]]; then
    echo "gh is not installed. Set GITHUB_TOKEN to publish release assets via API."
    exit 1
  fi

  local api_base
  api_base="https://api.github.com/repos/${OWNER}/${REPO}"
  local release_id
  release_id="$(curl -sS -H "Authorization: token ${GITHUB_TOKEN}" "${api_base}/releases/tags/${TAG}" | sed -n 's/.*"id":[[:space:]]*\([0-9][0-9]*\).*/\1/p' | head -n 1)"

  if [[ -z "$release_id" ]]; then
    local payload
    payload="$(cat <<EOF
{"tag_name":"${TAG}","name":"Notchy Teleprompter ${TAG}","body":"Notchy Teleprompter ${TAG} (build ${BUILD_NUMBER})","draft":false,"prerelease":false,"make_latest":"true"}
EOF
)"
    release_id="$(curl -sS -X POST \
      -H "Authorization: token ${GITHUB_TOKEN}" \
      -H "Accept: application/vnd.github+json" \
      "${api_base}/releases" \
      -d "$payload" | sed -n 's/.*"id":[[:space:]]*\([0-9][0-9]*\).*/\1/p' | head -n 1)"
  fi

  if [[ -z "$release_id" ]]; then
    echo "Failed to create or resolve release for ${TAG}."
    exit 1
  fi

  upload_asset_api() {
    local file_path="$1"
    local file_name
    file_name="$(basename "$file_path")"
    curl -sS -X POST \
      -H "Authorization: token ${GITHUB_TOKEN}" \
      -H "Content-Type: application/octet-stream" \
      --data-binary @"$file_path" \
      "https://uploads.github.com/repos/${OWNER}/${REPO}/releases/${release_id}/assets?name=${file_name}" >/dev/null
  }

  delete_asset_if_exists_api() {
    local file_name="$1"
    local asset_id
    asset_id="$(curl -sS \
      -H "Authorization: token ${GITHUB_TOKEN}" \
      "${api_base}/releases/${release_id}/assets" | \
      awk -v target="$file_name" '
        match($0, /"id":[ ]*([0-9]+)/, a) { id=a[1] }
        match($0, /"name":"([^"]+)"/, b) {
          if (b[1] == target && id != "") { print id; exit }
        }')"
    if [[ -n "$asset_id" ]]; then
      curl -sS -X DELETE \
        -H "Authorization: token ${GITHUB_TOKEN}" \
        "${api_base}/releases/assets/${asset_id}" >/dev/null
    fi
  }

  for file_path in "$ZIP_PATH" "$ZIP_SHA_PATH" "$DMG_PATH" "$DMG_SHA_PATH"; do
    file_name="$(basename "$file_path")"
    delete_asset_if_exists_api "$file_name"
    upload_asset_api "$file_path"
  done
}

echo "==> Step 6/6: publish GitHub release assets"
if command -v gh >/dev/null 2>&1; then
  release_with_gh
else
  release_with_api
fi

cat <<REPORT
Public release complete.
- Repo: https://github.com/${OWNER}/${REPO}
- Tag: ${TAG}
- Release artifacts uploaded:
  - ${ZIP_PATH}
  - ${ZIP_SHA_PATH}
  - ${DMG_PATH}
  - ${DMG_SHA_PATH}
- Appcast updated: $NATIVE_DIR/appcast/appcast.xml
REPORT
