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

Share the `.zip` file. Do not send from inside `.derived*` folders.

## First launch on recipient Mac

Because this build is not notarized yet, users may need to:

1. Unzip the app.
2. Right-click `Notchy Teleprompter.app` and choose `Open`.
3. Confirm `Open` in the macOS security prompt.

If blocked, users can also go to `System Settings > Privacy & Security` and click `Open Anyway`.

## Version support

- Built as universal binary: `Apple Silicon + Intel`
- Minimum supported macOS: `12.0`

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
