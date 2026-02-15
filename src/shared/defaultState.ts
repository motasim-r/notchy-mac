import type { TeleprompterState } from "./ipc.js";

export const DEFAULT_STATE: TeleprompterState = {
  scriptText:
    "Welcome. This is your notch teleprompter.\n\nPaste your script in the editor window, then press play.",
  playback: {
    isPlaying: false,
    speedPxPerSec: 42,
    offsetPx: 0,
  },
  prompterWindow: {
    width: 560,
    height: 210,
    topOffsetPx: 0,
    fontSizePx: 40,
    lineHeight: 1.35,
    visible: true,
  },
  editorWindow: {
    width: 860,
    height: 700,
  },
};

export const LIMITS = {
  speedMin: 4,
  speedMax: 260,
  fontSizeMin: 18,
  fontSizeMax: 110,
  lineHeightMin: 1,
  lineHeightMax: 2.2,
  widthMin: 420,
  widthMax: 1400,
  heightMin: 140,
  heightMax: 600,
  topOffsetMin: -70,
  topOffsetMax: 220,
} as const;
