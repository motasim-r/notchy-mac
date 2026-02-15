import { BrowserWindow } from "electron";
import type { TeleprompterState } from "../../shared/ipc.js";
import { loadRendererPage } from "./loadRendererPage.js";

interface CreatePrompterWindowOptions {
  state: TeleprompterState;
  preloadPath: string;
  isDev: boolean;
  devServerUrl: string;
  mainDirname: string;
  onResize: (width: number, height: number) => void;
}

export async function createPrompterWindow(options: CreatePrompterWindowOptions): Promise<BrowserWindow> {
  const { state } = options;

  const window = new BrowserWindow({
    width: state.prompterWindow.width,
    height: state.prompterWindow.height,
    frame: false,
    transparent: true,
    backgroundColor: "#00000000",
    hasShadow: false,
    show: false,
    alwaysOnTop: true,
    resizable: true,
    movable: false,
    minimizable: false,
    maximizable: false,
    fullscreenable: false,
    skipTaskbar: true,
    roundedCorners: true,
    vibrancy: "under-window",
    visualEffectState: "active",
    webPreferences: {
      preload: options.preloadPath,
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: false,
    },
  });

  window.setAlwaysOnTop(true, "main-menu");
  window.setVisibleOnAllWorkspaces(true, {
    visibleOnFullScreen: true,
    skipTransformProcessType: false,
  });

  window.on("resize", () => {
    const bounds = window.getBounds();
    options.onResize(bounds.width, bounds.height);
  });

  window.once("ready-to-show", () => {
    if (state.prompterWindow.visible) {
      window.showInactive();
    }
  });

  await loadRendererPage({
    window,
    page: "prompter",
    isDev: options.isDev,
    devServerUrl: options.devServerUrl,
    mainDirname: options.mainDirname,
  });

  return window;
}
