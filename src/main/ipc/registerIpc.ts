import { ipcMain } from "electron";
import { IPC_CHANNELS, type EditorStatePatch, type NudgeDirection, type NudgeStep, type PrompterBoundsUpdate } from "../../shared/ipc.js";
import type { StateStore } from "../store/stateStore.js";

interface RegisterIpcOptions {
  stateStore: StateStore;
  broadcastState: () => void;
  onPrompterGeometryChanged: () => void;
  onFocusEditor: () => void;
  onFocusPrompter: () => void;
}

function patchTouchesPrompterGeometry(patch: EditorStatePatch): boolean {
  return Boolean(
    patch.prompterWindow &&
      (typeof patch.prompterWindow.width === "number" ||
        typeof patch.prompterWindow.height === "number" ||
        typeof patch.prompterWindow.topOffsetPx === "number"),
  );
}

export function registerIpc(options: RegisterIpcOptions): void {
  const channels = [
    IPC_CHANNELS.stateGet,
    IPC_CHANNELS.stateUpdate,
    IPC_CHANNELS.playbackToggle,
    IPC_CHANNELS.playbackSetPlaying,
    IPC_CHANNELS.playbackSetSpeed,
    IPC_CHANNELS.playbackReset,
    IPC_CHANNELS.windowNudgeOffset,
    IPC_CHANNELS.windowSetPrompterBounds,
    IPC_CHANNELS.windowFocusEditor,
    IPC_CHANNELS.windowFocusPrompter,
  ];

  for (const channel of channels) {
    ipcMain.removeHandler(channel);
  }

  ipcMain.handle(IPC_CHANNELS.stateGet, () => {
    return options.stateStore.getState();
  });

  ipcMain.handle(IPC_CHANNELS.stateUpdate, (_, patch: EditorStatePatch) => {
    const next = options.stateStore.updateState(patch);
    if (patchTouchesPrompterGeometry(patch)) {
      options.onPrompterGeometryChanged();
    }
    options.broadcastState();
    return next;
  });

  ipcMain.handle(IPC_CHANNELS.playbackToggle, () => {
    const next = options.stateStore.togglePlayback();
    options.broadcastState();
    return next;
  });

  ipcMain.handle(IPC_CHANNELS.playbackSetPlaying, (_, isPlaying: boolean) => {
    const next = options.stateStore.setPlaying(isPlaying);
    options.broadcastState();
    return next;
  });

  ipcMain.handle(IPC_CHANNELS.playbackSetSpeed, (_, speedPxPerSec: number) => {
    const next = options.stateStore.setSpeed(speedPxPerSec);
    options.broadcastState();
    return next;
  });

  ipcMain.handle(IPC_CHANNELS.playbackReset, () => {
    const next = options.stateStore.resetPlayback();
    options.broadcastState();
    return next;
  });

  ipcMain.handle(
    IPC_CHANNELS.windowNudgeOffset,
    (_, direction: NudgeDirection, step: NudgeStep) => {
      const next = options.stateStore.nudgeOffset(direction, step);
      options.onPrompterGeometryChanged();
      options.broadcastState();
      return next;
    },
  );

  ipcMain.handle(IPC_CHANNELS.windowSetPrompterBounds, (_, update: PrompterBoundsUpdate) => {
    const next = options.stateStore.updateState({
      prompterWindow: {
        width: update.width,
        height: update.height,
      },
    });

    options.onPrompterGeometryChanged();
    options.broadcastState();
    return next;
  });

  ipcMain.handle(IPC_CHANNELS.windowFocusEditor, () => {
    options.onFocusEditor();
  });

  ipcMain.handle(IPC_CHANNELS.windowFocusPrompter, () => {
    options.onFocusPrompter();
  });
}
