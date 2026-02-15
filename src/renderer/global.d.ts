import type { TeleprompterApi } from "../shared/ipc.js";

declare global {
  interface Window {
    teleprompter: TeleprompterApi;
  }
}

export {};
