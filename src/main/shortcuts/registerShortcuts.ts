import { globalShortcut } from "electron";

interface RegisterShortcutsOptions {
  onTogglePlayback: () => void;
  onAdjustSpeed: (delta: number) => void;
  onNudgeOffset: (direction: "up" | "down", step: 1 | 5) => void;
}

const SHORTCUTS: Array<{ accelerator: string; action: (options: RegisterShortcutsOptions) => void }> = [
  {
    accelerator: "CommandOrControl+Shift+Space",
    action: (options) => options.onTogglePlayback(),
  },
  {
    accelerator: "CommandOrControl+Shift+Up",
    action: (options) => options.onAdjustSpeed(2),
  },
  {
    accelerator: "CommandOrControl+Shift+Down",
    action: (options) => options.onAdjustSpeed(-2),
  },
  {
    accelerator: "CommandOrControl+Shift+[",
    action: (options) => options.onNudgeOffset("up", 1),
  },
  {
    accelerator: "CommandOrControl+Shift+]",
    action: (options) => options.onNudgeOffset("down", 1),
  },
];

export function registerShortcuts(options: RegisterShortcutsOptions): void {
  for (const shortcut of SHORTCUTS) {
    const success = globalShortcut.register(shortcut.accelerator, () => {
      shortcut.action(options);
    });

    if (!success) {
      console.warn(`[shortcuts] Unable to register ${shortcut.accelerator}`);
    }
  }
}
