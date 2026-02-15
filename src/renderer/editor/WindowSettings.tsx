import type { ReactElement } from "react";

interface WindowSettingsProps {
  width: number;
  height: number;
  topOffsetPx: number;
  fontSizePx: number;
  lineHeight: number;
  onResizePrompter: (width: number, height: number) => void;
  onNudgeOffset: (direction: "up" | "down", step: 1 | 5) => void;
  onFontSizeChange: (fontSizePx: number) => void;
  onLineHeightChange: (lineHeight: number) => void;
}

export function WindowSettings({
  width,
  height,
  topOffsetPx,
  fontSizePx,
  lineHeight,
  onResizePrompter,
  onNudgeOffset,
  onFontSizeChange,
  onLineHeightChange,
}: WindowSettingsProps): ReactElement {
  return (
    <section className="editor-card">
      <header className="card-header">
        <h2>Window + Text</h2>
        <p>Tune size and vertical nudge from the menu-bar notch anchor.</p>
      </header>

      <div className="form-grid two-columns">
        <label className="control-label" htmlFor="width-input">
          Width
          <input
            id="width-input"
            className="number-input"
            type="number"
            min={420}
            max={1400}
            value={Math.round(width)}
            onChange={(event) => onResizePrompter(Number(event.target.value), height)}
          />
        </label>

        <label className="control-label" htmlFor="height-input">
          Height
          <input
            id="height-input"
            className="number-input"
            type="number"
            min={140}
            max={600}
            value={Math.round(height)}
            onChange={(event) => onResizePrompter(width, Number(event.target.value))}
          />
        </label>
      </div>

      <div className="form-row wrap">
        <span className="inline-note">Vertical nudge: {topOffsetPx}px (0 = menu bar anchor)</span>
        <button className="action-button" type="button" onClick={() => onNudgeOffset("up", 5)}>
          Up 5
        </button>
        <button className="action-button" type="button" onClick={() => onNudgeOffset("up", 1)}>
          Up 1
        </button>
        <button className="action-button" type="button" onClick={() => onNudgeOffset("down", 1)}>
          Down 1
        </button>
        <button className="action-button" type="button" onClick={() => onNudgeOffset("down", 5)}>
          Down 5
        </button>
      </div>

      <label className="control-label" htmlFor="font-size-range">
        Font size ({Math.round(fontSizePx)}px)
      </label>
      <div className="form-row">
        <input
          id="font-size-range"
          className="range-input"
          type="range"
          min={18}
          max={110}
          step={1}
          value={fontSizePx}
          onChange={(event) => onFontSizeChange(Number(event.target.value))}
        />
        <input
          className="number-input"
          type="number"
          min={18}
          max={110}
          step={1}
          value={Math.round(fontSizePx)}
          onChange={(event) => onFontSizeChange(Number(event.target.value))}
        />
      </div>

      <label className="control-label" htmlFor="line-height-range">
        Line height ({lineHeight.toFixed(2)})
      </label>
      <div className="form-row">
        <input
          id="line-height-range"
          className="range-input"
          type="range"
          min={1}
          max={2.2}
          step={0.01}
          value={lineHeight}
          onChange={(event) => onLineHeightChange(Number(event.target.value))}
        />
        <input
          className="number-input"
          type="number"
          min={1}
          max={2.2}
          step={0.01}
          value={lineHeight.toFixed(2)}
          onChange={(event) => onLineHeightChange(Number(event.target.value))}
        />
      </div>
    </section>
  );
}
