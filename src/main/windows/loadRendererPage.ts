import type { BrowserWindow } from "electron";
import { join } from "node:path";

interface LoadRendererPageOptions {
  window: BrowserWindow;
  page: "prompter" | "editor";
  isDev: boolean;
  devServerUrl: string;
  mainDirname: string;
}

export async function loadRendererPage({
  window,
  page,
  isDev,
  devServerUrl,
  mainDirname,
}: LoadRendererPageOptions): Promise<void> {
  if (isDev) {
    await window.loadURL(`${devServerUrl}/${page}.html`);
    return;
  }

  await window.loadFile(join(mainDirname, "..", "..", `${page}.html`));
}
