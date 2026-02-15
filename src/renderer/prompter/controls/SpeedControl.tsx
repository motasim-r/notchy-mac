import type { ReactElement } from "react";

interface SpeedControlProps {
  speedPxPerSec: number;
  onIncrease: () => void;
  onDecrease: () => void;
}

export function SpeedControl({ speedPxPerSec, onIncrease, onDecrease }: SpeedControlProps): ReactElement {
  return (
    <div className="speed-control" role="group" aria-label="Speed controls">
      <button className="speed-button" onClick={onDecrease} type="button" aria-label="Decrease speed">
        -
      </button>
      <span className="speed-value">{speedPxPerSec}px/s</span>
      <button className="speed-button" onClick={onIncrease} type="button" aria-label="Increase speed">
        +
      </button>
    </div>
  );
}
