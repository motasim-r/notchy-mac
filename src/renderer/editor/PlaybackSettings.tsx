import type { ReactElement } from "react";

interface PlaybackSettingsProps {
  isPlaying: boolean;
  speedPxPerSec: number;
  offsetPx: number;
  onTogglePlayback: () => void;
  onReset: () => void;
  onSpeedChange: (speedPxPerSec: number) => void;
}

export function PlaybackSettings({
  isPlaying,
  speedPxPerSec,
  offsetPx,
  onTogglePlayback,
  onReset,
  onSpeedChange,
}: PlaybackSettingsProps): ReactElement {
  return (
    <section className="editor-card">
      <header className="card-header">
        <h2>Playback</h2>
        <p>Continuous auto-scroll with precise speed control.</p>
      </header>

      <div className="form-row">
        <button className="action-button primary" type="button" onClick={onTogglePlayback}>
          {isPlaying ? "Pause" : "Play"}
        </button>
        <button className="action-button" type="button" onClick={onReset}>
          Reset to Top
        </button>
        <span className="inline-note">Offset: {Math.round(offsetPx)}px</span>
      </div>

      <label className="control-label" htmlFor="speed-range">
        Speed ({Math.round(speedPxPerSec)} px/s)
      </label>
      <div className="form-row">
        <input
          id="speed-range"
          className="range-input"
          type="range"
          min={4}
          max={260}
          step={1}
          value={speedPxPerSec}
          onChange={(event) => onSpeedChange(Number(event.target.value))}
        />
        <input
          className="number-input"
          type="number"
          min={4}
          max={260}
          step={1}
          value={Math.round(speedPxPerSec)}
          onChange={(event) => onSpeedChange(Number(event.target.value))}
        />
      </div>
    </section>
  );
}
