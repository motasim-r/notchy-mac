# Notchy Brand Guidelines

This is the source-of-truth brand guideline for Notchy UI (editor first), based on the Monaco-inspired direction you approved.

## 1) Brand Direction
- Personality: premium, focused, calm, high-trust.
- Visual mood: dark glass + flat minimal surfaces.
- Product posture: technical but elegant; clear hierarchy, low noise.

## 2) Typography System

### Primary Typeface Roles
- Display / editorial headings: `Season Serif`
- UI / controls / body: `Season Sans`
- Numeric telemetry (speed, offsets, key chords): monospaced system font

### Font Files (bundled)
- Path: `/Users/motasimrahman/Desktop/notchy-mac-app/native/NotchyTeleprompter/Resources/Fonts/Season`
- Families used in app:
  - `SeasonSerif-Regular-TRIAL`
  - `SeasonSerif-Medium-TRIAL`
  - `SeasonSerif-Bold-TRIAL`
  - `SeasonSans-Regular-TRIAL`
  - `SeasonSans-Medium-TRIAL`
  - `SeasonSans-Bold-TRIAL`

### Runtime Loading
- `ATSApplicationFontsPath` is set in:
  - `/Users/motasimrahman/Desktop/notchy-mac-app/native/NotchyTeleprompter/Info.plist`
- Value: `.`
- Fallback behavior: if custom font registration fails, UI falls back to native system serif/sans.

## 3) Color System
- Background base: near-black graphite (`~#111315` to `~#0F1114`)
- Surface card: dark translucent charcoal (`~#1A1B1D` at low alpha)
- Borders: subtle white alpha (`8%` to `20%`)
- Primary text: white (`~#F8F8F8`)
- Secondary text: white alpha (`52%` to `76%`)
- Accent behavior: neutral gray emphasis (no bright/purple accent bias)

## 4) Shape + Depth
- Corner radii:
  - Main cards: `14–16`
  - Buttons: `9–10`
  - Rail items: `10`
- Depth:
  - Keep blur/glass subtle
  - Avoid heavy shadows; favor layered alpha surfaces

## 5) Editor UI Rules (Primary Scope)
- Left rail tabs stay compact with icon + title + subtitle.
- Page headers use display serif style.
- Cards and controls use sans UI style.
- Data readouts remain monospaced for scanability.
- Keep vertical rhythm tight and balanced; avoid loud contrast jumps.

## 6) Notch UI Rules (Secondary Scope)
- Keep notch silhouette behavior and readability constraints as-is.
- Teleprompter script readability remains functional-first (high-contrast).
- Control tray remains minimal, legible on any background.

## 7) Website Future Mapping
- Web heading font: `Season Serif`.
- Web body/control font: Inter-like or `Season Sans` if licensed for web embedding.
- Reuse same palette family:
  - black/graphite background
  - muted gray glass surfaces
  - off-white typography

## 8) Accessibility Baseline
- Maintain strong contrast on all primary text.
- Avoid tiny low-contrast controls.
- Keep meaningful states visible without color-only cues.

## 9) Implementation Rule
- Any user-facing visual change must update:
  - `/Users/motasimrahman/Desktop/notchy-mac-app/native/CHANGELOG.md`
  - In-app Changelogs section in:
    `/Users/motasimrahman/Desktop/notchy-mac-app/native/NotchyTeleprompter/Features/Editor/EditorView.swift`

## 10) Licensing Note
- Current bundled fonts are marked `TRIAL` in provided files.
- Confirm production/commercial licensing before broad public distribution.
