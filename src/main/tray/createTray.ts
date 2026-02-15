import { Menu, Tray, app, nativeImage } from "electron";
import type { TeleprompterState } from "../../shared/ipc.js";

interface CreateTrayOptions {
  getState: () => TeleprompterState;
  onTogglePrompterVisibility: () => void;
  onOpenEditor: () => void;
  onTogglePlayback: () => void;
}

function createTrayIcon(): Electron.NativeImage {
  const svg = `
    <svg width="18" height="18" viewBox="0 0 18 18" xmlns="http://www.w3.org/2000/svg">
      <rect x="1.2" y="3" width="15.6" height="11.4" rx="4" fill="black"/>
      <circle cx="4.6" cy="9" r="2" fill="white"/>
      <rect x="8" y="7" width="6" height="1.5" rx="0.75" fill="white"/>
      <rect x="8" y="9.5" width="5" height="1.5" rx="0.75" fill="white"/>
    </svg>
  `;

  const image = nativeImage.createFromDataURL(`data:image/svg+xml;base64,${Buffer.from(svg).toString("base64")}`);
  image.setTemplateImage(true);
  return image;
}

export function createTray(options: CreateTrayOptions): Tray {
  const tray = new Tray(createTrayIcon());
  tray.setToolTip("Notchy Teleprompter");

  const refreshMenu = (): void => {
    const state = options.getState();

    const menu = Menu.buildFromTemplate([
      {
        label: state.prompterWindow.visible ? "Hide Prompter" : "Show Prompter",
        click: () => options.onTogglePrompterVisibility(),
      },
      {
        label: "Open Editor",
        click: () => options.onOpenEditor(),
      },
      { type: "separator" },
      {
        label: state.playback.isPlaying ? "Pause" : "Play",
        click: () => options.onTogglePlayback(),
      },
      { type: "separator" },
      {
        label: "Quit",
        click: () => app.quit(),
      },
    ]);

    tray.setContextMenu(menu);
  };

  tray.on("click", () => {
    options.onTogglePrompterVisibility();
  });

  refreshMenu();

  // Attach lightweight hook for external updates.
  (tray as Tray & { refreshMenu?: () => void }).refreshMenu = refreshMenu;

  return tray;
}

export function refreshTrayMenu(tray: Tray | null): void {
  const maybeTray = tray as (Tray & { refreshMenu?: () => void }) | null;
  maybeTray?.refreshMenu?.();
}
