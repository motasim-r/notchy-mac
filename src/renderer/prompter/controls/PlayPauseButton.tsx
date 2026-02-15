import type { ReactElement } from "react";

interface PlayPauseButtonProps {
  isPlaying: boolean;
  onToggle: () => void;
}

export function PlayPauseButton({ isPlaying, onToggle }: PlayPauseButtonProps): ReactElement {
  return (
    <button className="play-pause-button" onClick={onToggle} type="button" aria-label="Toggle playback">
      <span className="play-pause-glyph">{isPlaying ? "II" : "▶"}</span>
    </button>
  );
}
