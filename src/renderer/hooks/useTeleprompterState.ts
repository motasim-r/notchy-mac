import { useCallback, useEffect, useState } from "react";
import type {
  EditorStatePatch,
  NudgeDirection,
  NudgeStep,
  PrompterBoundsUpdate,
  TeleprompterState,
} from "../../shared/ipc.js";

interface UseTeleprompterStateResult {
  state: TeleprompterState | null;
  loading: boolean;
  updateState: (patch: EditorStatePatch) => Promise<TeleprompterState>;
  togglePlayback: () => Promise<TeleprompterState>;
  setPlaying: (isPlaying: boolean) => Promise<TeleprompterState>;
  setSpeed: (speedPxPerSec: number) => Promise<TeleprompterState>;
  resetPlayback: () => Promise<TeleprompterState>;
  nudgeOffset: (direction: NudgeDirection, step: NudgeStep) => Promise<TeleprompterState>;
  setPrompterBounds: (update: PrompterBoundsUpdate) => Promise<TeleprompterState>;
}

export function useTeleprompterState(): UseTeleprompterStateResult {
  const [state, setState] = useState<TeleprompterState | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let mounted = true;

    window.teleprompter
      .getState()
      .then((nextState) => {
        if (!mounted) {
          return;
        }
        setState(nextState);
        setLoading(false);
      })
      .catch((error) => {
        console.error("[renderer] Failed to load state", error);
        if (mounted) {
          setLoading(false);
        }
      });

    const unsubscribe = window.teleprompter.onStateChanged((nextState) => {
      setState(nextState);
    });

    return () => {
      mounted = false;
      unsubscribe();
    };
  }, []);

  const wrappedUpdate = useCallback(async (promise: Promise<TeleprompterState>) => {
    const nextState = await promise;
    setState(nextState);
    return nextState;
  }, []);

  const updateState = useCallback(
    (patch: EditorStatePatch) => wrappedUpdate(window.teleprompter.updateState(patch)),
    [wrappedUpdate],
  );

  const togglePlayback = useCallback(
    () => wrappedUpdate(window.teleprompter.togglePlayback()),
    [wrappedUpdate],
  );

  const setPlaying = useCallback(
    (isPlaying: boolean) => wrappedUpdate(window.teleprompter.setPlaying(isPlaying)),
    [wrappedUpdate],
  );

  const setSpeed = useCallback(
    (speedPxPerSec: number) => wrappedUpdate(window.teleprompter.setSpeed(speedPxPerSec)),
    [wrappedUpdate],
  );

  const resetPlayback = useCallback(
    () => wrappedUpdate(window.teleprompter.resetPlayback()),
    [wrappedUpdate],
  );

  const nudgeOffset = useCallback(
    (direction: NudgeDirection, step: NudgeStep) =>
      wrappedUpdate(window.teleprompter.nudgeOffset(direction, step)),
    [wrappedUpdate],
  );

  const setPrompterBounds = useCallback(
    (update: PrompterBoundsUpdate) => wrappedUpdate(window.teleprompter.setPrompterBounds(update)),
    [wrappedUpdate],
  );

  return {
    state,
    loading,
    updateState,
    togglePlayback,
    setPlaying,
    setSpeed,
    resetPlayback,
    nudgeOffset,
    setPrompterBounds,
  };
}
