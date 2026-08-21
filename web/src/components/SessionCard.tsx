import { useState } from 'react';
import { confettiFrom } from '../lib/confetti';
import { shortDate } from '../lib/date';
import { SESSION_META, WORKOUTS } from '../lib/workouts';
import type { Intensity, Session, SessionType } from '../lib/types';
import { XP } from '../lib/types';
import { HoldIcon } from './HoldIcon';
import { Timer } from './Timer';

interface Props {
  type: SessionType;
  done: Session[];
  onComplete: (type: SessionType, intensity: Intensity, checked: string[]) => void;
  onRemove: (id: string) => void;
}

export function SessionCard({ type, done, onComplete, onRemove }: Props) {
  const meta = SESSION_META[type];
  const [open, setOpen] = useState(false);
  const [variant, setVariant] = useState<Intensity>('full');
  const [checked, setChecked] = useState<string[]>([]);
  const workout = WORKOUTS[type][variant];
  const isDone = done.length > 0;

  const toggle = (id: string) =>
    setChecked((c) => (c.includes(id) ? c.filter((x) => x !== id) : [...c, id]));

  /**
   * Abhaken ist der Moment, auf den die ganze Karte hinarbeitet — der bekommt
   * Konfetti, und zwar aus dem gedrückten Knopf heraus.
   */
  const complete = (intensity: Intensity, e: React.MouseEvent<HTMLButtonElement>) => {
    confettiFrom(e.currentTarget, {
      colors: [meta.color, meta.color, 'var(--color-chalk)', 'var(--color-grade-yellow)'],
      count: intensity === 'min' ? 45 : 80,
      power: intensity === 'min' ? 11 : 14,
    });
    onComplete(type, intensity, checked);
    setChecked([]);
    setOpen(false);
  };

  return (
    <section
      className="chalk-edge chalk-dust relative overflow-hidden rounded-2xl border bg-rock-900/80"
      style={{ borderColor: isDone ? meta.color : 'var(--color-rock-700)' }}
    >
      <div
        aria-hidden="true"
        className="absolute inset-x-0 top-0 h-1"
        style={{ background: meta.color, opacity: isDone ? 1 : 0.45 }}
      />

      <div className="flex items-start gap-3 p-4 pt-5">
        {/* Farbe folgt der Grade-Skala der Einheit */}
        <span className="mt-0.5 shrink-0" style={{ color: meta.color }}>
          <HoldIcon className="h-8 w-8" filled={isDone} />
        </span>
        <div className="min-w-0 flex-1">
          <div className="flex flex-wrap items-center gap-x-2 gap-y-1">
            <span
              className="rounded-full px-2 py-0.5 text-[11px] font-semibold uppercase tracking-wider"
              style={{ background: `color-mix(in srgb, ${meta.color} 22%, transparent)`, color: meta.color }}
            >
              {meta.weekday}
            </span>
            <h2 className="font-display text-2xl uppercase leading-none">{meta.title}</h2>
          </div>
          <p className="mt-1 text-sm text-chalk-dim">{meta.tagline}</p>
        </div>
      </div>

      {isDone ? (
        <div className="space-y-2 px-4 pb-4">
          {done.map((s) => (
            <div
              key={s.id}
              className="animate-rise flex items-center gap-3 rounded-xl border border-rock-700 bg-rock-850 px-3 py-2.5"
            >
              <span
                className="grid h-6 w-6 place-items-center rounded-full text-sm font-bold text-rock-950"
                style={{ background: meta.color }}
                aria-hidden="true"
              >
                ✓
              </span>
              <div className="text-sm">
                <span className="font-semibold">
                  {s.intensity === 'min' ? 'Minimum' : 'Volle Einheit'}
                </span>
                <span className="text-chalk-dim"> · {shortDate(s.date)} · +{XP[s.type][s.intensity]} XP</span>
              </div>
              <button
                type="button"
                onClick={() => onRemove(s.id)}
                className="ml-auto rounded-lg px-2 py-1 text-xs text-chalk-faint transition hover:text-chalk"
              >
                rückgängig
              </button>
            </div>
          ))}
        </div>
      ) : (
        <div className="px-4 pb-4">
          {type === 'boulder' ? (
            <button
              type="button"
              onClick={(e) => complete('full', e)}
              className="w-full rounded-xl px-4 py-4 text-lg font-bold text-rock-950 transition active:scale-[0.98]"
              style={{ background: meta.color }}
            >
              Abhaken · +{XP.boulder.full} XP
            </button>
          ) : (
            <div className="flex gap-2">
              <button
                type="button"
                onClick={(e) => complete('full', e)}
                className="flex-1 rounded-xl px-4 py-4 text-base font-bold text-rock-950 transition active:scale-[0.98]"
                style={{ background: meta.color }}
              >
                Volle Einheit
                <span className="block text-xs font-semibold opacity-70">
                  +{XP[type].full} XP
                </span>
              </button>
              <button
                type="button"
                onClick={(e) => complete('min', e)}
                className="flex-1 rounded-xl border border-rock-600 bg-rock-850 px-4 py-4 text-base font-bold text-chalk transition hover:border-rock-500 active:scale-[0.98]"
              >
                Minimum
                <span className="block text-xs font-semibold text-chalk-dim">
                  +{XP[type].min} XP · ~5 Min.
                </span>
              </button>
            </div>
          )}
          <p className="mt-2 text-xs text-chalk-faint">{meta.hint}</p>
        </div>
      )}

      <div className="border-t border-rock-800">
        <button
          type="button"
          onClick={() => setOpen((o) => !o)}
          aria-expanded={open}
          className="flex w-full items-center justify-between px-4 py-3 text-sm text-chalk-dim transition hover:text-chalk"
        >
          <span>Übungen &amp; Timer</span>
          <span aria-hidden="true" className={`transition-transform ${open ? 'rotate-180' : ''}`}>
            ⌄
          </span>
        </button>

        {open && (
          <div className="animate-fade space-y-3 border-t border-rock-800 bg-rock-950/50 p-4">
            {type !== 'boulder' && (
              <div className="flex gap-1 rounded-lg border border-rock-700 p-1" role="group">
                {(['full', 'min'] as Intensity[]).map((v) => (
                  <button
                    key={v}
                    type="button"
                    onClick={() => setVariant(v)}
                    aria-pressed={variant === v}
                    className={`flex-1 rounded-md px-3 py-1.5 text-sm font-medium transition ${
                      variant === v ? 'bg-rock-700 text-chalk' : 'text-chalk-dim hover:text-chalk'
                    }`}
                  >
                    {WORKOUTS[type][v].label}
                  </button>
                ))}
              </div>
            )}

            <p className="text-xs uppercase tracking-wider text-chalk-faint">
              {workout.rounds} {workout.rounds === 1 ? 'Runde' : 'Runden'} · {workout.duration}
            </p>

            <ul className="space-y-1.5">
              {workout.exercises.map((ex) => {
                const on = checked.includes(ex.id);
                return (
                  <li key={ex.id}>
                    <label
                      className={`flex cursor-pointer items-start gap-3 rounded-xl border px-3 py-2.5 transition ${
                        on ? 'border-rock-600 bg-rock-800' : 'border-rock-800 bg-rock-900/60'
                      }`}
                    >
                      <input
                        type="checkbox"
                        checked={on}
                        onChange={() => toggle(ex.id)}
                        className="mt-1 h-4 w-4 shrink-0 accent-[var(--color-tape)]"
                      />
                      <span className="min-w-0">
                        <span
                          className={`block text-sm font-medium ${on ? 'text-chalk-dim line-through' : ''}`}
                        >
                          {ex.name}
                        </span>
                        <span className="block text-xs text-chalk-faint">{ex.detail}</span>
                      </span>
                    </label>
                    {ex.timer && (
                      <div className="mt-1.5">
                        <Timer initial={ex.timer} />
                      </div>
                    )}
                  </li>
                );
              })}
            </ul>
            <p className="text-xs text-chalk-faint">
              Die Checkliste ist optional — abhaken kannst du die Einheit jederzeit.
            </p>
          </div>
        )}
      </div>
    </section>
  );
}
