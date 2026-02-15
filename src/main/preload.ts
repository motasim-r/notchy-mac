import { contextBridge, ipcRenderer } from "electron";
import {
  IPC_CHANNELS,
  type EditorStatePatch,
  type NudgeDirection,
  type NudgeStep,
  type PrompterBoundsUpdate,
  type StateListener,
  type TeleprompterApi,
} from "../shared/ipc.js";

const api: TeleprompterApi = {
  getState: () => ipcRenderer.invoke(IPC_CHANNELS.stateGet),
  updateState: (patch: EditorStatePatch) => ipcRenderer.invoke(IPC_CHANNELS.stateUpdate, patch),
  togglePlayback: () => ipcRenderer.invoke(IPC_CHANNELS.playbackToggle),
  setPlaying: (isPlaying: boolean) => ipcRenderer.invoke(IPC_CHANNELS.playbackSetPlaying, isPlaying),
  setSpeed: (speedPxPerSec: number) => ipcRenderer.invoke(IPC_CHANNELS.playbackSetSpeed, speedPxPerSec),
  resetPlayback: () => ipcRenderer.invoke(IPC_CHANNELS.playbackReset),
  nudgeOffset: (direction: NudgeDirection, step: NudgeStep) =>
    ipcRenderer.invoke(IPC_CHANNELS.windowNudgeOffset, direction, step),
  setPrompterBounds: (update: PrompterBoundsUpdate) =>
    ipcRenderer.invoke(IPC_CHANNELS.windowSetPrompterBounds, update),
  focusEditor: () => ipcRenderer.invoke(IPC_CHANNELS.windowFocusEditor),
  focusPrompter: () => ipcRenderer.invoke(IPC_CHANNELS.windowFocusPrompter),
  onStateChanged: (listener: StateListener) => {
    const wrappedListener = (_event: Electron.IpcRendererEvent, state: Parameters<StateListener>[0]) => {
      listener(state);
    };

    ipcRenderer.on(IPC_CHANNELS.stateChanged, wrappedListener);

    return () => {
      ipcRenderer.off(IPC_CHANNELS.stateChanged, wrappedListener);
    };
  },
};

contextBridge.exposeInMainWorld("teleprompter", api);
