import Store from "electron-store";
import { DEFAULT_STATE, LIMITS } from "../../shared/defaultState.js";
import type {
  EditorStatePatch,
  NudgeDirection,
  NudgeStep,
  TeleprompterState,
} from "../../shared/ipc.js";

interface StoreShape {
  layoutVersion: number;
  menuBarAnchorMigrated?: boolean;
  state: TeleprompterState;
}

function clamp(value: number, min: number, max: number): number {
  return Math.min(max, Math.max(min, value));
}

function sanitizeState(state: TeleprompterState): TeleprompterState {
  return {
    scriptText: state.scriptText,
    playback: {
      isPlaying: state.playback.isPlaying,
      speedPxPerSec: clamp(Math.round(state.playback.speedPxPerSec), LIMITS.speedMin, LIMITS.speedMax),
      offsetPx: Math.max(0, state.playback.offsetPx),
    },
    prompterWindow: {
      width: clamp(Math.round(state.prompterWindow.width), LIMITS.widthMin, LIMITS.widthMax),
      height: clamp(Math.round(state.prompterWindow.height), LIMITS.heightMin, LIMITS.heightMax),
      topOffsetPx: clamp(
        Math.round(state.prompterWindow.topOffsetPx),
        LIMITS.topOffsetMin,
        LIMITS.topOffsetMax,
      ),
      fontSizePx: clamp(
        Math.round(state.prompterWindow.fontSizePx),
        LIMITS.fontSizeMin,
        LIMITS.fontSizeMax,
      ),
      lineHeight: clamp(state.prompterWindow.lineHeight, LIMITS.lineHeightMin, LIMITS.lineHeightMax),
      visible: state.prompterWindow.visible,
    },
    editorWindow: {
      width: Math.max(520, Math.round(state.editorWindow.width)),
      height: Math.max(420, Math.round(state.editorWindow.height)),
      x: state.editorWindow.x,
      y: state.editorWindow.y,
    },
  };
}

function mergeState(current: TeleprompterState, patch: EditorStatePatch): TeleprompterState {
  return {
    ...current,
    ...("scriptText" in patch ? { scriptText: patch.scriptText ?? current.scriptText } : {}),
    playback: {
      ...current.playback,
      ...(patch.playback ?? {}),
    },
    prompterWindow: {
      ...current.prompterWindow,
      ...(patch.prompterWindow ?? {}),
    },
    editorWindow: {
      ...current.editorWindow,
      ...(patch.editorWindow ?? {}),
    },
  };
}

export class StateStore {
  private readonly store: Store<StoreShape>;

  constructor() {
    this.store = new Store<StoreShape>({
      name: "notchy-teleprompter",
      defaults: {
        layoutVersion: 2,
        state: DEFAULT_STATE,
      },
    });

    const hasMigratedMenuBarAnchor = this.store.get("menuBarAnchorMigrated", false);
    if (!hasMigratedMenuBarAnchor) {
      const previousState = this.store.get("state");
      if ((previousState.prompterWindow.topOffsetPx ?? 0) >= 24) {
        this.store.set("state", {
          ...previousState,
          prompterWindow: {
            ...previousState.prompterWindow,
            // Migrate from legacy absolute-top placement to menu-bar anchored placement.
            topOffsetPx: (previousState.prompterWindow.topOffsetPx ?? 34) - 34,
          },
        });
      }
      this.store.set("menuBarAnchorMigrated", true);
    }

    this.setState(sanitizeState(this.store.get("state")));
  }

  getState(): TeleprompterState {
    return this.store.get("state");
  }

  setState(nextState: TeleprompterState): TeleprompterState {
    const sanitized = sanitizeState(nextState);
    this.store.set("state", sanitized);
    return sanitized;
  }

  updateState(patch: EditorStatePatch): TeleprompterState {
    const current = this.getState();
    return this.setState(mergeState(current, patch));
  }

  togglePlayback(): TeleprompterState {
    const current = this.getState();
    return this.updateState({
      playback: {
        isPlaying: !current.playback.isPlaying,
      },
    });
  }

  setPlaying(isPlaying: boolean): TeleprompterState {
    return this.updateState({ playback: { isPlaying } });
  }

  setSpeed(speedPxPerSec: number): TeleprompterState {
    return this.updateState({ playback: { speedPxPerSec } });
  }

  resetPlayback(): TeleprompterState {
    return this.updateState({
      playback: {
        isPlaying: false,
        offsetPx: 0,
      },
    });
  }

  nudgeOffset(direction: NudgeDirection, step: NudgeStep): TeleprompterState {
    const current = this.getState();
    const delta = direction === "up" ? -step : step;
    return this.updateState({
      prompterWindow: {
        topOffsetPx: current.prompterWindow.topOffsetPx + delta,
      },
    });
  }
}
