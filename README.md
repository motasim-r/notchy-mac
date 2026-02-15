# Notchy Teleprompter

This repository now includes a native macOS implementation for a notch-adjacent teleprompter.

## Native App (Primary)

- Xcode project: `/Users/motasimrahman/Desktop/notchy-mac-app/native/NotchyTeleprompter.xcodeproj`
- Native sources: `/Users/motasimrahman/Desktop/notchy-mac-app/native/NotchyTeleprompter/`

### Run

1. Install full Xcode (App Store) if not already installed.
2. Open `/Users/motasimrahman/Desktop/notchy-mac-app/native/NotchyTeleprompter.xcodeproj` in Xcode.
3. Select target `NotchyTeleprompter` and run on `My Mac`.

### Behavior

- Menu bar utility app (`LSUIElement = YES`) with no Dock icon.
- Notch/menu-bar teleprompter panel using AppKit `NSPanel` + SwiftUI content.
- Separate native editor window for script and controls.
- Global shortcuts for play/pause, speed, and notch nudge.
- Local persistence at:
  - `~/Library/Application Support/NotchyTeleprompter/state.json`
- One-time import from legacy Electron state:
  - `~/Library/Application Support/notchy-mac-app/notchy-teleprompter.json`

### Regenerate Xcode Project

The project is generated with `xcodegen` from:

- `/Users/motasimrahman/Desktop/notchy-mac-app/native/project.yml`

Regenerate with:

```bash
xcodegen generate --spec native/project.yml
```

## Legacy Electron App

The Electron code remains in this repository as legacy reference (`src/`, `package.json`), but the native app under `native/` is now the primary implementation.
