import { addDays, currentWeekKey, toISODate } from '../lib/date';
import type { WeekSummary } from '../lib/stats';
import type { Tracker } from '../lib/store';
import { WALK_GOAL, XP_WALK } from '../lib/types';

const WALK_COLOR = 'var(--color-grade-green)';

const DAYS = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

interface Props {
  week: WeekSummary;
  toggleWalk: Tracker['toggleWalk'];
  walkStreak: number;
}

export function WalkCard({ week, toggleWalk, walkStreak }: Props) {
  const today = toISODate(new Date());
  const isCurrentWeek = week.key === currentWeekKey();
  const walked = new Set(week.walks.map((w) => w.date));

  const status =
    week.walkDays === 0
      ? 'Fünf kurze Runden — eine pro Werktag.'
      : week.walkDays >= WALK_GOAL
        ? 'Alle fünf Werktage. Perfekte Woche!'
        : `Noch ${WALK_GOAL - week.walkDays} ${WALK_GOAL - week.walkDays === 1 ? 'Tag' : 'Tage'} bis zur vollen Woche.`;

  return (
    <section className="chalk-edge chalk-dust relative overflow-hidden rounded-2xl border bg-rock-900/80"
      style={{ borderColor: week.walkPerfect ? WALK_COLOR : 'var(--color-rock-700)' }}
    >
      <div
        aria-hidden="true"
        className="absolute inset-x-0 top-0 h-1"
        style={{ background: WALK_COLOR, opacity: week.walkPerfect ? 1 : 0.45 }}
      />

      <div className="flex items-start gap-3 p-4 pt-5">
        <span className="mt-0.5 shrink-0 text-2xl leading-none" aria-hidden="true">
          🚶
        </span>
        <div className="min-w-0 flex-1">
          <div className="flex flex-wrap items-center gap-x-2 gap-y-1">
            <span
              className="rounded-full px-2 py-0.5 text-[11px] font-semibold uppercase tracking-wider"
              style={{ background: `color-mix(in srgb, ${WALK_COLOR} 22%, transparent)`, color: WALK_COLOR }}
            >
              Mo – Fr
            </span>
            <h2 className="font-display text-2xl uppercase leading-none">Spaziergang</h2>
          </div>
          <p className="mt-1 text-sm text-chalk-dim">{status}</p>
        </div>
        <span className="shrink-0 font-display text-2xl leading-none tabular-nums">
          {week.walkDays}
          <span className="text-chalk-faint">/{WALK_GOAL}</span>
        </span>
      </div>

      <div className="px-4 pb-4">
        <div className="grid grid-cols-7 gap-1.5">
          {DAYS.map((label, i) => {
            const date = addDays(week.key, i);
            const on = walked.has(date);
            const isToday = date === today;
            const weekend = i >= 5;
            // Zukunft lässt sich nicht abhaken – vergangene Tage schon, falls
            // das Eintragen mal untergeht.
            const future = isCurrentWeek && date > today;

            return (
              <button
                key={date}
                type="button"
                disabled={future}
                onClick={() => toggleWalk(date)}
                aria-pressed={on}
                aria-label={`${label}, ${date}${on ? ' — Spaziergang gemacht' : ''}`}
                className={`flex flex-col items-center gap-1 rounded-xl border px-1 py-2.5 text-xs font-semibold transition active:scale-[0.96] disabled:cursor-not-allowed disabled:opacity-35 ${
                  on
                    ? 'text-rock-950'
                    : weekend
                      ? 'border-rock-800 bg-rock-900/60 text-chalk-faint hover:border-rock-600'
                      : 'border-rock-700 bg-rock-850 text-chalk-dim hover:border-rock-500'
                }`}
                style={
                  on
                    ? { background: WALK_COLOR, borderColor: WALK_COLOR }
                    : isToday
                      ? { borderColor: 'var(--color-tape)' }
                      : undefined
                }
              >
                <span>{label}</span>
                <span aria-hidden="true" className="text-base leading-none">
                  {on ? '✓' : '·'}
                </span>
              </button>
            );
          })}
        </div>

        <p className="mt-2 text-xs text-chalk-faint">
          {walkStreak > 0
            ? `🔥 ${walkStreak} ${walkStreak === 1 ? 'Werktag' : 'Werktage'} in Folge · +${XP_WALK} XP pro Runde`
            : `Jeder Tag einzeln antippen. +${XP_WALK} XP pro Runde — Wochenende ist Zugabe.`}
        </p>
      </div>
    </section>
  );
}
