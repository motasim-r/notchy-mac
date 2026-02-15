import { BrowserWindow } from "electron";
import type { TeleprompterState } from "../../shared/ipc.js";
import { loadRendererPage } from "./loadRendererPage.js";

interface CreateEditorWindowOptions {
  state: TeleprompterState;
  preloadPath: string;
  isDev: boolean;
  devServerUrl: string;
  mainDirname: string;
  onBoundsChanged: (bounds: { width: number; height: number; x: number; y: number }) => void;
}

export async function createEditorWindow(options: CreateEditorWindowOptions): Promise<BrowserWindow> {
  const { editorWindow } = options.state;

  const window = new BrowserWindow({
    width: editorWindow.width,
    height: editorWindow.height,
    x: editorWindow.x,
    y: editorWindow.y,
    minWidth: 680,
    minHeight: 520,
    show: false,
    title: "Notchy Teleprompter",
    titleBarStyle: "default",
    vibrancy: "sidebar",
    visualEffectState: "active",
    webPreferences: {
      preload: options.preloadPath,
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: false,
    },
  });

  window.on("moved", () => {
    const bounds = window.getBounds();
    options.onBoundsChanged(bounds);
  });

  window.on("resize", () => {
    const bounds = window.getBounds();
    options.onBoundsChanged(bounds);
  });

  window.once("ready-to-show", () => {
    window.show();
  });

  await loadRendererPage({
    window,
    page: "editor",
    isDev: options.isDev,
    devServerUrl: options.devServerUrl,
    mainDirname: options.mainDirname,
  });

  return window;
}
