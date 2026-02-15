import { useEffect, useRef, useState } from "react";

interface UseScrollEngineOptions {
  isPlaying: boolean;
  speedPxPerSec: number;
  initialOffsetPx: number;
  viewportRef: React.RefObject<HTMLDivElement | null>;
  contentRef: React.RefObject<HTMLDivElement | null>;
  onPersistOffset: (offsetPx: number) => void;
  onReachedEnd: () => void;
}

interface UseScrollEngineResult {
  offsetPx: number;
  maxOffsetPx: number;
}

function getMaxOffset(viewport: HTMLDivElement | null, content: HTMLDivElement | null): number {
  if (!viewport || !content) {
    return 0;
  }

  return Math.max(0, content.scrollHeight - viewport.clientHeight);
}

export function useScrollEngine(options: UseScrollEngineOptions): UseScrollEngineResult {
  const [offsetPx, setOffsetPx] = useState(options.initialOffsetPx);
  const [maxOffsetPx, setMaxOffsetPx] = useState(0);

  const rafIdRef = useRef<number | null>(null);
  const previousTimestampRef = useRef<number | null>(null);
  const offsetRef = useRef(options.initialOffsetPx);
  const latestSpeedRef = useRef(options.speedPxPerSec);
  const latestPersistRef = useRef(options.onPersistOffset);
  const latestReachedEndRef = useRef(options.onReachedEnd);

  latestSpeedRef.current = options.speedPxPerSec;
  latestPersistRef.current = options.onPersistOffset;
  latestReachedEndRef.current = options.onReachedEnd;

  useEffect(() => {
    if (!options.isPlaying) {
      setOffsetPx(options.initialOffsetPx);
      offsetRef.current = options.initialOffsetPx;
    }
  }, [options.initialOffsetPx, options.isPlaying]);

  useEffect(() => {
    const recomputeMaxOffset = () => {
      const nextMaxOffset = getMaxOffset(options.viewportRef.current, options.contentRef.current);
      setMaxOffsetPx(nextMaxOffset);
      setOffsetPx((previous) => {
        const clamped = Math.min(previous, nextMaxOffset);
        offsetRef.current = clamped;
        return clamped;
      });
    };

    recomputeMaxOffset();

    if (!options.viewportRef.current || !options.contentRef.current) {
      return;
    }

    const observer = new ResizeObserver(() => {
      recomputeMaxOffset();
    });

    observer.observe(options.viewportRef.current);
    observer.observe(options.contentRef.current);

    return () => {
      observer.disconnect();
    };
  }, [options.contentRef, options.viewportRef]);

  useEffect(() => {
    if (!options.isPlaying) {
      previousTimestampRef.current = null;
      if (rafIdRef.current) {
        window.cancelAnimationFrame(rafIdRef.current);
        rafIdRef.current = null;
      }
      latestPersistRef.current(offsetRef.current);
      return;
    }

    const tick = (timestamp: number) => {
      if (previousTimestampRef.current === null) {
        previousTimestampRef.current = timestamp;
      }

      const deltaSec = (timestamp - previousTimestampRef.current) / 1000;
      previousTimestampRef.current = timestamp;

      const nextOffset = Math.min(offsetRef.current + latestSpeedRef.current * deltaSec, maxOffsetPx);
      const reachedEnd = nextOffset >= maxOffsetPx;

      offsetRef.current = nextOffset;
      setOffsetPx(nextOffset);

      if (reachedEnd && maxOffsetPx > 0) {
        latestPersistRef.current(nextOffset);
        latestReachedEndRef.current();
        return;
      }

      rafIdRef.current = window.requestAnimationFrame(tick);
    };

    rafIdRef.current = window.requestAnimationFrame(tick);

    return () => {
      if (rafIdRef.current) {
        window.cancelAnimationFrame(rafIdRef.current);
        rafIdRef.current = null;
      }
      previousTimestampRef.current = null;
    };
  }, [maxOffsetPx, options.isPlaying]);

  useEffect(() => {
    if (!options.isPlaying) {
      return;
    }

    const interval = window.setInterval(() => {
      latestPersistRef.current(offsetRef.current);
    }, 260);

    return () => {
      window.clearInterval(interval);
    };
  }, [options.isPlaying]);

  return {
    offsetPx,
    maxOffsetPx,
  };
}
