# Notchy Teleprompter Distribution Guide

## Build a shareable app

Run:

```bash
./native/scripts/build_release.sh
```

Artifacts are created in:

- `/Users/motasimrahman/Desktop/notchy-mac-app/native/release/Notchy Teleprompter.app`
- `/Users/motasimrahman/Desktop/notchy-mac-app/native/release/Notchy-Teleprompter-v<version>-<build>-macOS-universal.zip`
- `/Users/motasimrahman/Desktop/notchy-mac-app/native/release/Notchy-Teleprompter-v<version>-<build>-macOS-universal.sha256`

## Share with other users

For public users, share the notarized `.dmg`:

- `...-notarized.dmg` (recommended)
- `...-notarized.dmg.sha256`

Do not share debug builds or anything from `.derived*` folders.

## First launch on recipient Mac

1. Open the `.dmg`.
2. Drag `Notchy Teleprompter.app` into `/Applications`.
3. Launch from `/Applications`.

If a recipient still gets a launch block, clear quarantine once:

```bash
xattr -dr com.apple.quarantine "/Applications/Notchy Teleprompter.app"
```

## Version support

- Built as universal binary: `Apple Silicon + Intel`
- Minimum supported macOS: `11.0`

## For true public production distribution

To remove first-launch security friction, use Apple Developer ID signing + notarization:

```bash
DEVELOPER_ID_APP_CERT="Developer ID Application: Your Name (TEAMID)" \
APPLE_ID="you@example.com" \
APPLE_APP_SPECIFIC_PASSWORD="xxxx-xxxx-xxxx-xxxx" \
TEAM_ID="TEAMID" \
./native/scripts/notarize_release.sh
```

This command produces notarized public artifacts in `native/release/`:

- `...-notarized.zip`
- `...-notarized.sha256`
- `...-notarized.dmg`
- `...-notarized.dmg.sha256`

## Auto-update (Sparkle)

Notchy now uses Sparkle for in-app updates.

One-time setup:

```bash
./native/scripts/build_sparkle_tools.sh
```

For each public release, notarize and generate appcast in one flow:

```bash
DEVELOPER_ID_APP_CERT="Developer ID Application: Your Name (TEAMID)" \
APPLE_ID="you@example.com" \
APPLE_APP_SPECIFIC_PASSWORD="xxxx-xxxx-xxxx-xxxx" \
TEAM_ID="TEAMID" \
SPARKLE_DOWNLOAD_URL_PREFIX="https://github.com/<owner>/<repo>/releases/download/v<version>" \
./native/scripts/notarize_release.sh
```

This also writes:

- `native/appcast/appcast.xml`

Push `native/appcast/appcast.xml` to your repo and keep GitHub Pages enabled so clients can read:

- `https://motasim-r.github.io/notchy-mac/native/appcast/appcast.xml`
