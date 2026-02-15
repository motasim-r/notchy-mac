# Native Notchy Teleprompter

## Paths

- Project: `/Users/motasimrahman/Desktop/notchy-mac-app/native/NotchyTeleprompter.xcodeproj`
- Sources: `/Users/motasimrahman/Desktop/notchy-mac-app/native/NotchyTeleprompter/`
- XcodeGen spec: `/Users/motasimrahman/Desktop/notchy-mac-app/native/project.yml`
- Release script: `/Users/motasimrahman/Desktop/notchy-mac-app/native/scripts/build_release.sh`
- Notarization script: `/Users/motasimrahman/Desktop/notchy-mac-app/native/scripts/notarize_release.sh`

## Runtime targets

- Minimum macOS: `12.0` (Monterey)
- Architectures for release: `arm64` + `x86_64` (universal app)

## Features

- Notch-adjacent panel anchored to the menu-bar/notch region.
- Separate native editor window for script and tuning controls.
- Keyboard playback control (`Space` when focused, plus global modifier shortcuts).
- Global hotkeys via Carbon.
- Local JSON persistence and one-time migration from legacy Electron state.

## Development build

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild \
  -project native/NotchyTeleprompter.xcodeproj \
  -scheme NotchyTeleprompter \
  -configuration Debug \
  -derivedDataPath native/.derived \
  build
```

Run:

```bash
open -n "native/.derived/Build/Products/Debug/Notchy Teleprompter.app"
```

## Release build for sharing

```bash
./native/scripts/build_release.sh
```

Output:

- `native/release/Notchy Teleprompter.app`
- `native/release/Notchy-Teleprompter-v<version>-<build>-macOS-universal.zip`
- `native/release/Notchy-Teleprompter-v<version>-<build>-macOS-universal.sha256`

Full handoff steps are documented in `/Users/motasimrahman/Desktop/notchy-mac-app/native/DISTRIBUTION.md`.

## Automated public release

For full public release automation (push, notarize, appcast, tag, GitHub release upload), use:

```bash
DEVELOPER_ID_APP_CERT="Developer ID Application: Your Name (TEAMID)" \
APPLE_ID="you@example.com" \
APPLE_APP_SPECIFIC_PASSWORD="xxxx-xxxx-xxxx-xxxx" \
TEAM_ID="TEAMID" \
GITHUB_TOKEN="ghp_xxx" \
./native/scripts/public_release.sh
```

## Optional notarized distribution

If you have Apple Developer credentials, run:

```bash
DEVELOPER_ID_APP_CERT="Developer ID Application: Your Name (TEAMID)" \
APPLE_ID="you@example.com" \
APPLE_APP_SPECIFIC_PASSWORD="xxxx-xxxx-xxxx-xxxx" \
TEAM_ID="TEAMID" \
./native/scripts/notarize_release.sh
```

This signs, notarizes, and staples the app so users avoid first-run security friction.
It also outputs notarized `ZIP + DMG + SHA256` files in `native/release/`.

## Regenerate project from spec

```bash
xcodegen generate --spec native/project.yml
```
