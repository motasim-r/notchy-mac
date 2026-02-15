import type { ReactElement } from "react";
import { useMemo } from "react";
import { PlaybackSettings } from "./PlaybackSettings.js";
import { ScriptEditor } from "./ScriptEditor.js";
import { WindowSettings } from "./WindowSettings.js";
import { useTeleprompterState } from "../hooks/useTeleprompterState.js";

function safeNumber(value: number, fallback: number): number {
  return Number.isFinite(value) ? value : fallback;
}

export function EditorApp(): ReactElement {
  const { state, loading, updateState, togglePlayback, setSpeed, resetPlayback, nudgeOffset, setPrompterBounds } =
    useTeleprompterState();

  const shortcuts = useMemo(
    () => [
      "Cmd/Ctrl + Shift + Space: Play/Pause",
      "Cmd/Ctrl + Shift + Up: Speed +2",
      "Cmd/Ctrl + Shift + Down: Speed -2",
      "Cmd/Ctrl + Shift + [: Move up 1px",
      "Cmd/Ctrl + Shift + ]: Move down 1px",
    ],
    [],
  );

  if (loading || !state) {
    return <div className="editor-loading">Loading teleprompter settings...</div>;
  }

  return (
    <main className="editor-shell">
      <div className="editor-hero">
        <h1>Notchy Teleprompter</h1>
        <p>
          Floating near the notch, always-on-top, and tuned for direct eye-line delivery.
        </p>
      </div>

      <div className="editor-layout">
        <ScriptEditor
          scriptText={state.scriptText}
          onChange={(text) => {
            void updateState({ scriptText: text });
          }}
        />

        <PlaybackSettings
          isPlaying={state.playback.isPlaying}
          speedPxPerSec={state.playback.speedPxPerSec}
          offsetPx={state.playback.offsetPx}
          onTogglePlayback={() => {
            void togglePlayback();
          }}
          onReset={() => {
            void resetPlayback();
          }}
          onSpeedChange={(value) => {
            void setSpeed(safeNumber(value, state.playback.speedPxPerSec));
          }}
        />

        <WindowSettings
          width={state.prompterWindow.width}
          height={state.prompterWindow.height}
          topOffsetPx={state.prompterWindow.topOffsetPx}
          fontSizePx={state.prompterWindow.fontSizePx}
          lineHeight={state.prompterWindow.lineHeight}
          onResizePrompter={(width, height) => {
            void setPrompterBounds({
              width: safeNumber(width, state.prompterWindow.width),
              height: safeNumber(height, state.prompterWindow.height),
            });
          }}
          onNudgeOffset={(direction, step) => {
            void nudgeOffset(direction, step);
          }}
          onFontSizeChange={(value) => {
            void updateState({
              prompterWindow: {
                fontSizePx: safeNumber(value, state.prompterWindow.fontSizePx),
              },
            });
          }}
          onLineHeightChange={(value) => {
            void updateState({
              prompterWindow: {
                lineHeight: safeNumber(value, state.prompterWindow.lineHeight),
              },
            });
          }}
        />

        <section className="editor-card shortcuts">
          <header className="card-header">
            <h2>Shortcuts</h2>
            <p>Use global controls while any app is focused.</p>
          </header>
          <ul className="shortcut-list">
            {shortcuts.map((shortcut) => (
              <li key={shortcut}>{shortcut}</li>
            ))}
          </ul>
        </section>
      </div>
    </main>
  );
}
