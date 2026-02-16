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
- Fixed exported video orientation by preserving source track preferred transform during segment merge.

### Teleprompter UI
- Added top-center notch-style overlay with shoulder-cut profile.
- Added safe top inset so text avoids Dynamic Island/notch clipping.
- Added smooth autoscroll ticker with px/sec speed model.
- Added manual drag scroll support with clamped bounds.
- Fixed top anchoring so notch-ui stitches to the physical top edge by default.
- Added hard shape clipping so teleprompter text cannot render outside notch-ui bounds.
- Added migration normalization for legacy escaped script text (`\\n` to newline).
- Polished notch-ui surface with translucent dark-glass layering and softer border/shadow.
- Added slow top fade mask so scrolling text eases out as it exits the top edge.
- Increased internal text padding and widened default notch panel for cleaner spacing.
- Switched notch-ui surface from transparent glass back to dark black for better readability and closer notch blend.
- Tuned fade effect to be subtler and shorter while still starting at the top edge.
- Reduced default notch height and default font size for tighter camera-adjacent eye-line behavior.

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
