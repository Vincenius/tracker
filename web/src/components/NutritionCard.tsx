import { toISODate } from '../lib/date';
import { LANE_LIST } from '../lib/nutrition';
import type { Stats } from '../lib/stats';
import type { Tracker } from '../lib/store';
import { XP_CLEAN_COMBO } from '../lib/types';

interface Props {
  stats: Stats;
  toggleClean: Tracker['toggleClean'];
}

/**
 * Der Tages-Griff für die Wochenansicht: zwei Schalter, mehr nicht. Die
 * Ernährung ist die einzige Gewohnheit, die *jeden* Tag eine Entscheidung
 * verlangt — deshalb steht sie auch auf dem Startbildschirm.
 */
export function NutritionCard({ stats, toggleClean }: Props) {
  const today = toISODate(new Date());
  const openCombo = LANE_LIST.some((l) => !stats.lanes[l.kind].dates.has(today));
  const bothToday = LANE_LIST.every((l) => stats.lanes[l.kind].dates.has(today));

  return (
    <section className="chalk-edge chalk-dust rounded-2xl border border-rock-700 bg-rock-900/80 p-4">
      <div className="flex items-baseline gap-2">
        <h2 className="font-display text-2xl uppercase leading-none">Heute sauber?</h2>
        <span className="ml-auto text-xs uppercase tracking-wider text-chalk-faint">
          {bothToday ? 'Beides ✓' : 'Jeden Tag neu'}
        </span>
      </div>

      <div className="mt-3 grid gap-2 sm:grid-cols-2">
        {LANE_LIST.map((lane) => {
          const s = stats.lanes[lane.kind];
          const on = s.dates.has(today);
          return (
            <button
              key={lane.kind}
              type="button"
              onClick={() => toggleClean(today, lane.kind)}
              aria-pressed={on}
              className="flex items-center gap-3 rounded-xl border p-3 text-left transition active:scale-[0.98]"
              style={{
                borderColor: on ? lane.color : 'var(--color-rock-700)',
                background: on
                  ? `color-mix(in srgb, ${lane.color} 16%, transparent)`
                  : 'var(--color-rock-850)',
              }}
            >
              <span className="text-2xl leading-none" aria-hidden="true">
                {lane.emoji}
              </span>
              <span className="min-w-0 flex-1">
                <span className="block text-sm font-semibold leading-tight">{lane.title}</span>
                <span className="block text-xs text-chalk-faint">
                  {s.currentStreak > 0
                    ? `🔥 ${s.currentStreak} ${s.currentStreak === 1 ? 'Tag' : 'Tage'} in Folge`
                    : 'Neue Serie startet heute'}
                </span>
              </span>
              <span
                className="shrink-0 rounded-full px-2 py-1 text-xs font-semibold tabular-nums"
                style={{
                  background: on ? lane.color : 'var(--color-rock-800)',
                  color: on ? 'var(--color-rock-950)' : 'var(--color-chalk-dim)',
                }}
              >
                {on ? '✓' : `+${s.nextXp}`}
              </span>
            </button>
          );
        })}
      </div>

      <p className="mt-2 text-xs text-chalk-faint">
        {bothToday
          ? `Beide Spuren sauber — inklusive +${XP_CLEAN_COMBO} XP Kombi-Bonus.`
          : openCombo
            ? `Jeder Tag in Folge bringt mehr XP. Beide an einem Tag: +${XP_CLEAN_COMBO} extra.`
            : ''}
      </p>
    </section>
  );
}
