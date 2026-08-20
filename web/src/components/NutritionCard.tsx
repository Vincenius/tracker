import { shortDate, toISODate, weekdayLabel } from '../lib/date';
import { LANE_LIST } from '../lib/nutrition';
import type { Stats } from '../lib/stats';
import type { Tracker } from '../lib/store';
import { XP_CLEAN_COMBO } from '../lib/types';

interface Props {
  stats: Stats;
  toggleClean: Tracker['toggleClean'];
  toggleCheat: Tracker['toggleCheat'];
}

/**
 * Der Tages-Griff für die Wochenansicht: zwei Schalter, mehr nicht. Die
 * Ernährung ist die einzige Gewohnheit, die *jeden* Tag eine Entscheidung
 * verlangt — deshalb steht sie auch auf dem Startbildschirm.
 */
export function NutritionCard({ stats, toggleClean, toggleCheat }: Props) {
  const today = toISODate(new Date());
  const openCombo = LANE_LIST.some((l) => !stats.lanes[l.kind].dates.has(today));
  const bothToday = LANE_LIST.every((l) => stats.lanes[l.kind].dates.has(today));
  const cheat = stats.cheatThisWeek;
  const cheatToday = cheat === today;

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

      {/* Die Notbremse für heute — an anderen Tagen der Woche nur als Hinweis,
          zurücknehmen lässt sie sich in der Ernährungs-Ansicht. */}
      <button
        type="button"
        disabled={cheat !== null && !cheatToday}
        onClick={() => toggleCheat(today)}
        aria-pressed={cheatToday}
        className="mt-2 flex w-full items-center gap-2 rounded-xl border px-3 py-2 text-left text-xs font-semibold transition active:scale-[0.98] disabled:cursor-not-allowed disabled:opacity-60"
        style={{
          borderColor: cheatToday ? 'var(--color-grade-yellow)' : 'var(--color-rock-700)',
          background: cheatToday
            ? 'color-mix(in srgb, var(--color-grade-yellow) 16%, transparent)'
            : 'var(--color-rock-850)',
        }}
      >
        <span className="text-base leading-none" aria-hidden="true">
          🍕
        </span>
        <span className="min-w-0 flex-1">
          {cheatToday
            ? 'Heute ist Cheat Day — die Serien laufen weiter.'
            : cheat
              ? `Cheat Day diese Woche: ${weekdayLabel(cheat)}, ${shortDate(cheat)}.`
              : 'Heute zum Cheat Day machen — einer pro Woche.'}
        </span>
      </button>

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
