# Notchy iOS Changelog

## Unreleased

### Foundation
- Bootstrapped a fully separate iOS workspace under `/ios` with no changes to macOS runtime paths.
- Added iPhone-only SwiftUI + AVFoundation architecture for full-screen recording + notch teleprompter.
- Added JSON persistence for script, playback, overlay settings, and editor tab state.

### Recorder
- Added front-camera + microphone capture session management.
- Added recording pipeline with pause/resume into multiple segments.
- Added segment composition into a single final `.mov` output.
- Added automatic save-to-Photos flow with permission handling and error surfacing.

### Teleprompter UI
- Added top-center notch-style overlay with shoulder-cut profile.
- Added safe top inset so text avoids Dynamic Island/notch clipping.
- Added smooth autoscroll ticker with px/sec speed model.
- Added manual drag scroll support with clamped bounds.

### Editor Sheet
- Added bottom sheet tabs: Script, Settings, Changelogs.
- Added script editing, speed control, play/pause, reset-to-top, offset readout.
- Added settings for overlay width, height, vertical position, font size, line height, and letter spacing.
- Added reset-settings flow that preserves script text.

### Branding
- Added Season Serif + Season Sans font integration with runtime fallback.
- Added dark-glass visual direction and iOS brand guideline baseline.

### Rule
- Every future user-facing change must be added to this file and mirrored inside the in-app Changelogs tab before release.
