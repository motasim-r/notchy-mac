import { app, globalShortcut, screen, type BrowserWindow, type Tray } from "electron";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { registerIpc } from "./ipc/registerIpc.js";
import { getCenteredPrompterBounds, getTargetDisplay } from "./positioning/displayPosition.js";
import { registerShortcuts } from "./shortcuts/registerShortcuts.js";
import { StateStore } from "./store/stateStore.js";
import { createTray, refreshTrayMenu } from "./tray/createTray.js";
import { createEditorWindow } from "./windows/editorWindow.js";
import { createPrompterWindow } from "./windows/prompterWindow.js";
import { IPC_CHANNELS } from "../shared/ipc.js";

const isDev = !app.isPackaged;
const devServerUrl = process.env.VITE_DEV_SERVER_URL ?? "http://127.0.0.1:5173";
const mainDirname = dirname(fileURLToPath(import.meta.url));
const preloadPath = join(mainDirname, "preload.js");

const stateStore = new StateStore();

let prompterWindow: BrowserWindow | null = null;
let editorWindow: BrowserWindow | null = null;
let tray: Tray | null = null;
let isQuitting = false;
let displayPollInterval: NodeJS.Timeout | null = null;
let lastDisplayId: number | null = null;

function getState() {
  return stateStore.getState();
}

function sendStateToWindows(): void {
  const state = getState();

  if (prompterWindow && !prompterWindow.isDestroyed()) {
    prompterWindow.webContents.send(IPC_CHANNELS.stateChanged, state);
  }

  if (editorWindow && !editorWindow.isDestroyed()) {
    editorWindow.webContents.send(IPC_CHANNELS.stateChanged, state);
  }

  refreshTrayMenu(tray);
}

function applyPrompterWindowPlacement(): void {
  if (!prompterWindow || prompterWindow.isDestroyed()) {
    return;
  }

  const state = getState();
  const targetDisplay = getTargetDisplay();
  lastDisplayId = targetDisplay.id;

  const bounds = getCenteredPrompterBounds(
    targetDisplay,
    {
      width: state.prompterWindow.width,
      height: state.prompterWindow.height,
    },
    state.prompterWindow.topOffsetPx,
  );

  prompterWindow.setBounds(bounds, false);

  if (state.prompterWindow.visible) {
    prompterWindow.showInactive();
  } else {
    prompterWindow.hide();
  }
}

function setPrompterVisibility(visible: boolean): void {
  stateStore.updateState({
    prompterWindow: {
      visible,
    },
  });

  applyPrompterWindowPlacement();
  sendStateToWindows();
}

function togglePrompterVisibility(): void {
  const currentlyVisible = getState().prompterWindow.visible;
  setPrompterVisibility(!currentlyVisible);
}

function adjustSpeed(delta: number): void {
  const current = getState();
  stateStore.setSpeed(current.playback.speedPxPerSec + delta);
  sendStateToWindows();
}

async function ensureEditorWindow(): Promise<BrowserWindow> {
  if (editorWindow && !editorWindow.isDestroyed()) {
    editorWindow.show();
    editorWindow.focus();
    return editorWindow;
  }

  editorWindow = await createEditorWindow({
    state: getState(),
    preloadPath,
    isDev,
    devServerUrl,
    mainDirname,
    onBoundsChanged: (bounds) => {
      stateStore.updateState({
        editorWindow: {
          width: bounds.width,
          height: bounds.height,
          x: bounds.x,
          y: bounds.y,
        },
      });
    },
  });

  editorWindow.on("closed", () => {
    editorWindow = null;
  });

  editorWindow.webContents.on("did-finish-load", () => {
    sendStateToWindows();
  });

  return editorWindow;
}

async function createWindows(): Promise<void> {
  prompterWindow = await createPrompterWindow({
    state: getState(),
    preloadPath,
    isDev,
    devServerUrl,
    mainDirname,
    onResize: (width, height) => {
      stateStore.updateState({
        prompterWindow: {
          width,
          height,
        },
      });
      applyPrompterWindowPlacement();
      sendStateToWindows();
    },
  });

  prompterWindow.on("closed", () => {
    prompterWindow = null;
    if (!isQuitting) {
      app.quit();
    }
  });

  prompterWindow.webContents.on("did-finish-load", () => {
    sendStateToWindows();
  });

  applyPrompterWindowPlacement();

  await ensureEditorWindow();
}

function setupDisplayWatchers(): void {
  const reposition = (): void => {
    applyPrompterWindowPlacement();
  };

  screen.on("display-added", reposition);
  screen.on("display-removed", reposition);
  screen.on("display-metrics-changed", reposition);

  displayPollInterval = setInterval(() => {
    const activeDisplay = getTargetDisplay();
    if (activeDisplay.id !== lastDisplayId) {
      applyPrompterWindowPlacement();
    }
  }, 1300);
}

async function bootstrap(): Promise<void> {
  await app.whenReady();

  registerIpc({
    stateStore,
    broadcastState: sendStateToWindows,
    onPrompterGeometryChanged: applyPrompterWindowPlacement,
    onFocusEditor: () => {
      void ensureEditorWindow();
    },
    onFocusPrompter: () => {
      if (!prompterWindow || prompterWindow.isDestroyed()) {
        return;
      }
      prompterWindow.show();
      prompterWindow.focus();
    },
  });

  await createWindows();

  tray = createTray({
    getState,
    onTogglePrompterVisibility: togglePrompterVisibility,
    onOpenEditor: () => {
      void ensureEditorWindow();
    },
    onTogglePlayback: () => {
      stateStore.togglePlayback();
      sendStateToWindows();
    },
  });

  registerShortcuts({
    onTogglePlayback: () => {
      stateStore.togglePlayback();
      sendStateToWindows();
    },
    onAdjustSpeed: (delta) => {
      adjustSpeed(delta);
    },
    onNudgeOffset: (direction, step) => {
      stateStore.nudgeOffset(direction, step);
      applyPrompterWindowPlacement();
      sendStateToWindows();
    },
  });

  setupDisplayWatchers();

  app.on("activate", () => {
    if (!prompterWindow || prompterWindow.isDestroyed()) {
      void createWindows();
      return;
    }

    if (!editorWindow || editorWindow.isDestroyed()) {
      void ensureEditorWindow();
    }
  });
}

app.on("before-quit", () => {
  isQuitting = true;
});

app.on("will-quit", () => {
  globalShortcut.unregisterAll();

  if (displayPollInterval) {
    clearInterval(displayPollInterval);
    displayPollInterval = null;
  }
});

void bootstrap();
