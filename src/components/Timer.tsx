import { useEffect, useRef, useState } from 'react';

const PRESETS = [30, 45, 60];

export function Timer({ initial = 45 }: { initial?: number }) {
  const [target, setTarget] = useState(initial);
  const [left, setLeft] = useState(initial);
  const [running, setRunning] = useState(false);
  const raf = useRef<number | null>(null);

  useEffect(() => {
    if (!running) return;
    const end = Date.now() + left * 1000;
    const tick = () => {
      const remaining = Math.max(0, (end - Date.now()) / 1000);
      setLeft(remaining);
      if (remaining <= 0) setRunning(false);
      else raf.current = window.requestAnimationFrame(tick);
    };
    raf.current = window.requestAnimationFrame(tick);
    return () => {
      if (raf.current) window.cancelAnimationFrame(raf.current);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [running]);

  const pct = target > 0 ? 1 - left / target : 0;
  const done = left <= 0;

  return (
    <div className="rounded-xl border border-rock-700 bg-rock-850 p-3">
      <div className="flex items-center gap-3">
        <div
          className="font-display text-3xl tabular-nums leading-none"
          style={{ color: done ? 'var(--color-grade-green)' : 'var(--color-chalk)' }}
          aria-live="off"
        >
          {Math.ceil(left)}
          <span className="text-base text-chalk-dim"> s</span>
        </div>
        <button
          type="button"
          onClick={() => {
            if (done) {
              setLeft(target);
              setRunning(true);
            } else setRunning((r) => !r);
          }}
          className="rounded-lg bg-chalk px-3 py-1.5 text-sm font-semibold text-rock-950 transition hover:bg-white"
        >
          {done ? 'Nochmal' : running ? 'Pause' : 'Start'}
        </button>
        <button
          type="button"
          onClick={() => {
            setRunning(false);
            setLeft(target);
          }}
          className="rounded-lg border border-rock-600 px-3 py-1.5 text-sm text-chalk-dim transition hover:text-chalk"
        >
          Reset
        </button>
        <div className="ml-auto flex gap-1">
          {PRESETS.map((p) => (
            <button
              key={p}
              type="button"
              onClick={() => {
                setTarget(p);
                setLeft(p);
                setRunning(false);
              }}
              aria-pressed={target === p}
              className={`rounded-md px-2 py-1 text-xs transition ${
                target === p
                  ? 'bg-rock-600 text-chalk'
                  : 'text-chalk-faint hover:text-chalk-dim'
              }`}
            >
              {p}s
            </button>
          ))}
        </div>
      </div>
      <div className="mt-2 h-1 overflow-hidden rounded-full bg-rock-700">
        <div
          className="h-full rounded-full transition-[width] duration-100"
          style={{
            width: `${Math.min(100, pct * 100)}%`,
            background: done ? 'var(--color-grade-green)' : 'var(--color-tape)',
          }}
        />
      </div>
    </div>
  );
}
