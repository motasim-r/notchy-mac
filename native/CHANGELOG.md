# Notchy Changelog

This file tracks product changes for Notchy.  
Process rule: every user-visible change should be appended here and mirrored in the in-app `Changelogs` tab.

## Unreleased
- Reserved for changes after `2.2.0`.

## 2.2.1 - 2026-02-15

### Highlights
- Added installer-style drag-and-drop DMG layout (`Notchy Teleprompter.app` + `Applications` shortcut) for a familiar install experience.
- Updated DMG creation pipeline to configure Finder icon view and placement for clearer install instructions.
- Kept notarization/stapling/signing flow intact for both ZIP and DMG artifacts.
- Prepared this release as the baseline public install before future in-app Sparkle-only updates.

## 2.2.0 - 2026-02-15

### Highlights
- Added native Sparkle updater integration for in-app updates.
- Added `Check for Updates…` action to app menus (status menu, dock menu, and app menu).
- Added conditional `Update` button in Script tab playback strip that appears when a newer version is detected.
- Added Sparkle feed metadata (`SUFeedURL`, `SUPublicEDKey`, automatic-check settings) to app configuration.
- Added Sparkle tooling script to build `generate_keys`, `sign_update`, and `generate_appcast` from source.
- Extended notarization pipeline to auto-generate `native/appcast/appcast.xml` from notarized ZIP releases.

## 2.1.2 - 2026-02-15

### Highlights
- Fixed default panel vertical position drift by normalizing existing installs back to `0` (top anchor).
- Added conditional top-corner rounding when vertical position is positive (`1+`) so detached panel states look intentional.
- Reduced playback-driven UI update pressure on older Macs by throttling scroll state publish frequency.
- Improved editor tab responsiveness by using lazy tab content stacks for heavy scroll sections.

## 2.1.1 - 2026-02-15

### Highlights
- Lowered minimum supported macOS from `12.0` to `11.0` to improve install compatibility on older Macs.
- Added SwiftUI compatibility fallbacks so the editor and notch UI render correctly on macOS 11/12/13+.
- Updated app metadata to align `LSMinimumSystemVersion` with the active deployment target.
- Produced a fresh universal (`arm64 + x86_64`) notarized release build for broader machine coverage.
- Clarified distribution recommendation: share the `-notarized.dmg` artifact for end users.

## 2.1.0 - 2026-02-13

### Highlights
- Added editor `Changelogs` tab with readable V1-to-V2.1 grouped summaries.
- Added explicit tracking rule in app and repo changelog so future releases are documented consistently.
- Added notch UI mouse/trackpad scrolling for live script movement.
- Redesigned hover controls into a high-contrast black tray that animates in/out.
- Added tray `Play/Pause` button as first action and swapped settings shortcut to `Script`.
- Auto-restored notch UI when Play is pressed from editor while the notch panel is hidden.

## V2 (Cumulative from V1, included in 2.1.0)

### Notch UI
- Rebuilt notch panel shape with true shoulder cut-in profile to match Mac notch silhouette.
- Anchored panel to menu-bar zone with zero-gap blend and black notch-continuous background.
- Added notch-safe top text inset so first lines do not disappear under hardware notch.
- Tuned compact panel defaults and centered text for camera-adjacent reading.
- Moved panel controls to a hover-only tray for clean default appearance.
- Redesigned tray with black background and slide animation for visibility on bright/messy backgrounds.
- Tray actions now include `Play/Pause`, `Script`, `Shortcuts`, and `Minimize`.
- Added direct mouse/trackpad scrolling on notch UI to move script offset.

### Editor UI
- Full redesign to dark-glass left-rail layout.
- Tab model introduced and stabilized across app run: `Script`, `Settings`, `Shortcuts`, `Changelogs`.
- Script tab: playback strip with Play/Pause, Reset to Top, Speed slider, Offset display.
- Settings tab: slider-driven controls for panel width, panel height, vertical position, font size, line spacing, and letter spacing.
- Removed old vertical quick-step button row in Settings after slider migration.
- Reset flow keeps script text while resetting playback/layout/text preferences.

### Playback and Controls
- Fixed initial playback issue where play required panel resize before starting.
- Added auto-show behavior: pressing Play while notch UI is hidden restores panel automatically.
- Kept continuous auto-scroll with end-of-script auto-pause.
- Focused-space play/pause behavior retained when typing is not active.

### Keyboard Shortcuts
- Updated global mapping:
  - `Cmd+Shift+Left/Right`: speed down/up.
  - `Cmd+Shift+Up/Down`: move script one line up/down.
  - `Cmd+Shift+Space`: play/pause.
- Removed bracket-based vertical-position shortcut behavior.
- Simplified UX by removing Remote Mode toggle complexity from active flow.

### App Lifecycle and Distribution
- Native Swift/AppKit + SwiftUI implementation superseded Electron path for notch-accurate behavior.
- Dock icon enabled for easier app discovery, reopen, and quit flows.
- Hide/show behavior clarified so panel visibility is controllable without quitting the app.
- Persistence continues for script, playback, panel geometry, and text settings.
- Signing/notarization workflow prepared for release pipeline.
