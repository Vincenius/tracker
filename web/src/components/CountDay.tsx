import { useRef } from 'react';

const HOLD_MS = 450;

/** Je mehr Einträge an einem Tag, desto kräftiger die Farbe. */
function cellBackground(count: number, color: string): string {
  if (count <= 0) return 'var(--color-rock-800)';
  if (count === 1) return `color-mix(in srgb, ${color} 45%, var(--color-rock-800))`;
  if (count === 2) return `color-mix(in srgb, ${color} 72%, var(--color-rock-800))`;
  return color;
}

interface CellProps {
  count: number;
  color: string;
  disabled: boolean;
  today: boolean;
  label?: string;
  title: string;
  onAdd: () => void;
  onRemove: () => void;
}

/**
 * Ein Tag als Zähler: tippen trägt ein, gedrückt halten (oder Rechtsklick)
 * nimmt zurück. Ein Umschalter reicht hier nicht — pro Tag sind beliebig viele
 * Einträge möglich.
 */
export function CountDay({ count, color, disabled, today, label, title, onAdd, onRemove }: CellProps) {
  const held = useRef(false);
  const timer = useRef<number | null>(null);

  const start = () => {
    if (disabled || count === 0) return;
    held.current = false;
    timer.current = window.setTimeout(() => {
      held.current = true;
      onRemove();
    }, HOLD_MS);
  };
  const stop = () => {
    if (timer.current) window.clearTimeout(timer.current);
    timer.current = null;
  };

  return (
    <button
      type="button"
      disabled={disabled}
      title={title}
      aria-label={title}
      onPointerDown={start}
      onPointerUp={stop}
      onPointerLeave={stop}
      onPointerCancel={stop}
      onContextMenu={(e) => {
        e.preventDefault();
        if (!disabled && count > 0) onRemove();
      }}
      onClick={() => {
        // Nach einem langen Druck ist der Eintrag schon weg — nicht gleich
        // wieder einen neuen setzen.
        if (held.current) {
          held.current = false;
          return;
        }
        onAdd();
      }}
      className={`flex touch-manipulation select-none flex-col items-center justify-center gap-1 border text-xs font-semibold transition active:scale-[0.96] disabled:cursor-not-allowed disabled:opacity-35 ${
        label ? 'rounded-xl px-1 py-2.5' : 'aspect-square rounded-[5px]'
      }`}
      style={{
        background: cellBackground(count, color),
        borderColor:
          count > 0
            ? 'transparent'
            : today
              ? 'var(--color-tape)'
              : 'var(--color-rock-700)',
        color: count >= 2 ? 'var(--color-rock-950)' : 'var(--color-chalk-dim)',
      }}
    >
      {label && <span>{label}</span>}
      {label && (
        <span aria-hidden="true" className="text-base leading-none tabular-nums">
          {count > 0 ? count : '·'}
        </span>
      )}
    </button>
  );
}
