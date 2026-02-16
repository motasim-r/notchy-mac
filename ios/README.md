# Notchy Teleprompter iOS

## Paths
- Project spec: `/Users/motasimrahman/Desktop/notchy-mac-app/ios/project.yml`
- Xcode project: `/Users/motasimrahman/Desktop/notchy-mac-app/ios/NotchyTeleprompterIOS.xcodeproj`
- Source root: `/Users/motasimrahman/Desktop/notchy-mac-app/ios/NotchyTeleprompterIOS`

## Generate project
```bash
/Users/motasimrahman/Desktop/notchy-mac-app/ios/scripts/gen_project.sh
```

## Debug build (simulator)
```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
/Users/motasimrahman/Desktop/notchy-mac-app/ios/scripts/build_debug.sh
```

## Debug build (physical iPhone)
```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
/Users/motasimrahman/Desktop/notchy-mac-app/ios/scripts/run_on_device.sh <YOUR_DEVICE_UDID>
```

## Product scope (V1)
- iPhone-only, portrait-only.
- Full-screen selfie recorder + notch teleprompter overlay.
- Pause/resume recording merged to one final video.
- Saves final recording to Photos.
- Bottom sheet editor tabs: Script / Settings / Changelogs.
