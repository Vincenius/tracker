import { useRef } from 'react';
import { addDays, addWeeks, currentWeekKey, shortDate, toISODate, weekdayLabel } from '../lib/date';
import { LANE_LIST, type LaneMeta } from '../lib/nutrition';
import { CLEAN_GOAL, type LaneStats } from '../lib/stats';
import type { Tracker } from '../lib/store';
import { XP_PER_LEVEL, XP_TREAT } from '../lib/types';

const DAYS = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
const HISTORY_WEEKS = 8;
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
function CountDay({ count, color, disabled, today, label, title, onAdd, onRemove }: CellProps) {
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

function LaneCard({
  lane,
  stats,
  weekKey,
  today,
  addTreat,
  removeTreat,
}: {
  lane: LaneMeta;
  stats: LaneStats;
  weekKey: string;
  today: string;
  addTreat: Tracker['addTreat'];
  removeTreat: Tracker['removeTreat'];
}) {
  const weekDates = DAYS.map((_, i) => addDays(weekKey, i));
  const weekCount = weekDates.reduce((sum, d) => sum + (stats.perDay.get(d) ?? 0), 0);
  const cleanWeek = weekCount === 0;

  return (
    <section
      className="chalk-edge chalk-dust relative overflow-hidden rounded-2xl border bg-rock-900/80"
      style={{ borderColor: weekCount > 0 ? lane.color : 'var(--color-rock-700)' }}
    >
      <div
        aria-hidden="true"
        className="absolute inset-x-0 top-0 h-1"
        style={{ background: lane.color, opacity: weekCount > 0 ? 1 : 0.45 }}
      />

      <div className="flex items-start gap-3 p-4 pt-5">
        <span className="mt-0.5 shrink-0 text-2xl leading-none" aria-hidden="true">
          {lane.emoji}
        </span>
        <div className="min-w-0 flex-1">
          <div className="flex flex-wrap items-center gap-x-2 gap-y-1">
            <span
              className="rounded-full px-2 py-0.5 text-[11px] font-semibold uppercase tracking-wider"
              style={{
                background: `color-mix(in srgb, ${lane.color} 22%, transparent)`,
                color: lane.color,
              }}
            >
              −{XP_TREAT} XP
            </span>
            <h2 className="font-display text-2xl uppercase leading-none">{lane.short}</h2>
          </div>
          <p className="mt-1 text-sm text-chalk-dim">{lane.tagline}</p>
        </div>
        <span className="shrink-0 font-display text-2xl leading-none tabular-nums">
          {weekCount}
          <span className="text-chalk-faint">×</span>
        </span>
      </div>

      <div className="px-4 pb-4">
        <div className="grid grid-cols-7 gap-1.5">
          {DAYS.map((label, i) => {
            const date = weekDates[i];
            const count = stats.perDay.get(date) ?? 0;
            // Die Zukunft lässt sich nicht eintragen — der Tag kommt erst noch.
            const future = date > today;
            return (
              <CountDay
                key={date}
                count={count}
                color={lane.color}
                disabled={future}
                today={date === today}
                label={label}
                title={`${weekdayLabel(date)}, ${shortDate(date)} — ${lane.title}: ${count}×`}
                onAdd={() => addTreat(date, lane.kind)}
                onRemove={() => removeTreat(date, lane.kind)}
              />
            );
          })}
        </div>

        <p className="mt-2.5 text-xs text-chalk-faint">
          {cleanWeek
            ? 'Diese Woche noch nichts eingetragen. So soll es aussehen.'
            : `Diese Woche ${weekCount}× · −${weekCount * XP_TREAT} XP`}
          {stats.cleanStreak > 0 &&
            ` · 🔥 ${stats.cleanStreak} ${stats.cleanStreak === 1 ? 'Tag' : 'Tage'} ohne`}
          {stats.longestCleanStreak > stats.cleanStreak &&
            ` · Bestserie ${stats.longestCleanStreak} Tage`}
        </p>
      </div>
    </section>
  );
}

export function NutritionView({ tracker }: { tracker: Tracker }) {
  const { stats, addTreat, removeTreat } = tracker;
  const today = toISODate(new Date());
  const weekKey = currentWeekKey();
  const start = addWeeks(weekKey, -(HISTORY_WEEKS - 1));
  const historyWeeks = Array.from({ length: HISTORY_WEEKS }, (_, i) => addWeeks(start, i));

  const streak = stats.cleanStreak;
  const status =
    stats.treatToday > 0
      ? `Heute ${stats.treatToday}× eingetragen. Morgen zählt neu.`
      : streak > 0
        ? `${streak} ${streak === 1 ? 'Tag' : 'Tage'} ohne Süßes am Stück.`
        : 'Ab heute wieder sauber. Nichts eintragen ist das Ziel.';

  return (
    <div className="space-y-4">
      <section className="chalk-edge chalk-dust rounded-2xl border border-rock-700 bg-rock-900/80 p-4">
        <p className="text-xs uppercase tracking-widest text-chalk-faint">Ernährung</p>
        <p className="mt-1 font-display text-xl uppercase leading-tight">{status}</p>
        <p className="mt-1 text-sm text-chalk-dim">
          Kein Kalorienzählen und keine Punkte fürs Weglassen. Nur ein Zähler für das, was doch
          süß war — jeder Eintrag kostet {XP_TREAT} XP.
        </p>

        <div className="mt-4 grid grid-cols-3 gap-2 text-center">
          {[
            { value: stats.cleanStreak, label: 'Tage sauber' },
            { value: stats.longestCleanStreak, label: 'Bestserie' },
            { value: stats.treatXpLost > 0 ? `−${stats.treatXpLost}` : 0, label: 'XP verloren' },
          ].map((s) => (
            <div key={s.label} className="rounded-xl border border-rock-700 bg-rock-850 p-2.5">
              <div className="font-display text-2xl leading-none tabular-nums">{s.value}</div>
              <div className="mt-1 text-[11px] uppercase tracking-wider text-chalk-faint">
                {s.label}
              </div>
            </div>
          ))}
        </div>
      </section>

      {LANE_LIST.map((lane) => (
        <LaneCard
          key={lane.kind}
          lane={lane}
          stats={stats.lanes[lane.kind]}
          weekKey={weekKey}
          today={today}
          addTreat={addTreat}
          removeTreat={removeTreat}
        />
      ))}

      <section className="chalk-edge rounded-2xl border border-rock-700 bg-rock-900/80 p-4">
        <h2 className="font-display text-xl uppercase">Letzte {HISTORY_WEEKS} Wochen</h2>
        <p className="mt-1 text-sm text-chalk-dim">
          Vergessen einzutragen? Tippen trägt nach, gedrückt halten nimmt zurück.
        </p>

        <div className="mt-4 grid gap-4 sm:grid-cols-2">
          {LANE_LIST.map((lane) => {
            const perDay = stats.lanes[lane.kind].perDay;
            return (
              <div key={lane.kind}>
                <div className="mb-2 flex items-center gap-2 text-xs font-semibold uppercase tracking-wider">
                  <i className="h-2.5 w-2.5 rounded-full" style={{ background: lane.color }} />
                  {lane.short}
                </div>
                {/* Deckel auf die Zellgröße, sonst wird das Raster auf dem
                    Handy zur halbmeterhohen Kachelwand. */}
                <div className="grid max-w-[19rem] grid-cols-7 gap-1">
                  {DAYS.map((d) => (
                    <span key={d} className="text-center text-[10px] text-chalk-faint">
                      {d}
                    </span>
                  ))}
                  {historyWeeks.flatMap((wk) =>
                    DAYS.map((_, i) => {
                      const date = addDays(wk, i);
                      const count = perDay.get(date) ?? 0;
                      return (
                        <CountDay
                          key={date}
                          count={count}
                          color={lane.color}
                          disabled={date > today}
                          today={date === today}
                          title={`${weekdayLabel(date)}, ${shortDate(date)} — ${count}×`}
                          onAdd={() => addTreat(date, lane.kind)}
                          onRemove={() => removeTreat(date, lane.kind)}
                        />
                      );
                    }),
                  )}
                </div>
              </div>
            );
          })}
        </div>
      </section>

      <section className="chalk-edge rounded-2xl border border-rock-700 bg-rock-900/80 p-4">
        <h2 className="font-display text-xl uppercase">Wie die Punkte laufen</h2>
        <ul className="mt-2 space-y-1.5 text-sm text-chalk-dim">
          <li>
            Sauber essen bringt <span className="text-chalk">keine XP</span> — es ist der
            Normalfall, nicht die Leistung.
          </li>
          <li>
            Jeder Eintrag kostet <span className="text-chalk">{XP_TREAT} XP</span>, so oft am Tag,
            wie es eben passiert ist. {XP_PER_LEVEL} XP sind ein Level.
          </li>
          <li>
            Ein Tag ohne Eintrag ist ein sauberer Tag. {CLEAN_GOAL} Tage in Folge sind eine Woche —
            dafür gibt es Abzeichen.
          </li>
          <li>
            Unter null geht das Konto nie. Ein schlechter Tag kostet Fortschritt, nicht alles
            Erreichte.
          </li>
        </ul>
      </section>
    </div>
  );
}
