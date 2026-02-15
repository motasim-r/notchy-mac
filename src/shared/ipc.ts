export const IPC_CHANNELS = {
  stateGet: "state:get",
  stateUpdate: "state:update",
  stateChanged: "state:changed",
  playbackToggle: "playback:toggle",
  playbackSetPlaying: "playback:setPlaying",
  playbackSetSpeed: "playback:setSpeed",
  playbackReset: "playback:reset",
  windowNudgeOffset: "window:nudgeOffset",
  windowSetPrompterBounds: "window:setPrompterBounds",
  windowFocusEditor: "window:focusEditor",
  windowFocusPrompter: "window:focusPrompter",
} as const;

export type NudgeDirection = "up" | "down";
export type NudgeStep = 1 | 5;

export interface PlaybackState {
  isPlaying: boolean;
  speedPxPerSec: number;
  offsetPx: number;
}

export interface PrompterWindowState {
  width: number;
  height: number;
  topOffsetPx: number;
  fontSizePx: number;
  lineHeight: number;
  visible: boolean;
}

export interface EditorWindowState {
  width: number;
  height: number;
  x?: number;
  y?: number;
}

export interface TeleprompterState {
  scriptText: string;
  playback: PlaybackState;
  prompterWindow: PrompterWindowState;
  editorWindow: EditorWindowState;
}

export interface EditorStatePatch {
  scriptText?: string;
  playback?: Partial<PlaybackState>;
  prompterWindow?: Partial<PrompterWindowState>;
  editorWindow?: Partial<EditorWindowState>;
}

export interface PrompterBoundsUpdate {
  width: number;
  height: number;
}

export type StateListener = (state: TeleprompterState) => void;

export interface TeleprompterApi {
  getState: () => Promise<TeleprompterState>;
  updateState: (patch: EditorStatePatch) => Promise<TeleprompterState>;
  togglePlayback: () => Promise<TeleprompterState>;
  setPlaying: (isPlaying: boolean) => Promise<TeleprompterState>;
  setSpeed: (speedPxPerSec: number) => Promise<TeleprompterState>;
  resetPlayback: () => Promise<TeleprompterState>;
  nudgeOffset: (direction: NudgeDirection, step: NudgeStep) => Promise<TeleprompterState>;
  setPrompterBounds: (update: PrompterBoundsUpdate) => Promise<TeleprompterState>;
  focusEditor: () => Promise<void>;
  focusPrompter: () => Promise<void>;
  onStateChanged: (listener: StateListener) => () => void;
}
