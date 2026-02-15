import type { ReactElement } from "react";
import { useCallback, useMemo, useRef } from "react";
import { useTeleprompterState } from "../hooks/useTeleprompterState.js";
import { PlayPauseButton } from "./controls/PlayPauseButton.js";
import { SpeedControl } from "./controls/SpeedControl.js";
import { useScrollEngine } from "./useScrollEngine.js";

export function PrompterBar(): ReactElement {
  const { state, loading, togglePlayback, setSpeed, setPlaying, updateState } = useTeleprompterState();
  const viewportRef = useRef<HTMLDivElement | null>(null);
  const contentRef = useRef<HTMLDivElement | null>(null);
  const lastPersistedOffsetRef = useRef<number | null>(null);

  const persistOffset = useCallback(
    (offsetPx: number) => {
      const roundedOffset = Math.max(0, Math.round(offsetPx));
      if (lastPersistedOffsetRef.current === roundedOffset) {
        return;
      }

      lastPersistedOffsetRef.current = roundedOffset;
      void updateState({
        playback: {
          offsetPx: roundedOffset,
        },
      });
    },
    [updateState],
  );

  const currentOffset = state?.playback.offsetPx ?? 0;

  const { offsetPx, maxOffsetPx } = useScrollEngine({
    isPlaying: state?.playback.isPlaying ?? false,
    speedPxPerSec: state?.playback.speedPxPerSec ?? 42,
    initialOffsetPx: currentOffset,
    viewportRef,
    contentRef,
    onPersistOffset: persistOffset,
    onReachedEnd: () => {
      void setPlaying(false);
    },
  });

  const scriptLines = useMemo(() => {
    if (!state) {
      return [];
    }

    return state.scriptText.split("\n");
  }, [state]);

  if (loading || !state) {
    return <div className="prompter-loading">Loading teleprompter...</div>;
  }

  const handleSpeedDecrease = () => {
    void setSpeed(state.playback.speedPxPerSec - 2);
  };

  const handleSpeedIncrease = () => {
    void setSpeed(state.playback.speedPxPerSec + 2);
  };

  const progressPercent = maxOffsetPx > 0 ? Math.min(100, Math.round((offsetPx / maxOffsetPx) * 100)) : 0;

  return (
    <div className="prompter-shell">
      <PlayPauseButton
        isPlaying={state.playback.isPlaying}
        onToggle={() => {
          void togglePlayback();
        }}
      />
      <div className="prompter-surface">
        <div className="prompter-header">
          <div className="prompter-pill">Notchy Prompt</div>
          <SpeedControl
            speedPxPerSec={state.playback.speedPxPerSec}
            onIncrease={handleSpeedIncrease}
            onDecrease={handleSpeedDecrease}
          />
        </div>

        <div className="prompter-viewport" ref={viewportRef}>
          <div
            className="prompter-content"
            ref={contentRef}
            style={{
              transform: `translateY(-${offsetPx}px)`,
              fontSize: `${state.prompterWindow.fontSizePx}px`,
              lineHeight: state.prompterWindow.lineHeight,
            }}
          >
            {scriptLines.map((line, index) => (
              <p className="prompter-line" key={`${line}-${index}`}>
                {line.length > 0 ? line : "\u00a0"}
              </p>
            ))}
          </div>
        </div>

        <div className="prompter-footer" aria-label="Progress">
          <div className="progress-track">
            <div className="progress-fill" style={{ width: `${progressPercent}%` }} />
          </div>
          <span className="progress-label">{progressPercent}%</span>
        </div>
      </div>
    </div>
  );
}
