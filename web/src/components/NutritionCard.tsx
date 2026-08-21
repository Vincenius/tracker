import { toISODate } from '../lib/date';
import { LANE_LIST, type LaneMeta } from '../lib/nutrition';
import type { LaneStats, Stats } from '../lib/stats';
import type { Tracker } from '../lib/store';
import { XP_TREAT } from '../lib/types';

interface Props {
  stats: Stats;
  addTreat: Tracker['addTreat'];
  removeTreat: Tracker['removeTreat'];
}

/**
 * Die Tageskarte der Ernährung: nichts abzuhaken, nur mitzuzählen. Ein sauberer
 * Tag ist der Normalfall und bleibt leer — jeder Eintrag kostet XP.
 */
export function NutritionCard({ stats, addTreat, removeTreat }: Props) {
  const today = toISODate(new Date());
  const count = stats.treatToday;
  const streak = stats.cleanStreak;

  return (
    <section className="chalk-edge chalk-dust rounded-2xl border border-rock-700 bg-rock-900/80 p-4">
      <div className="flex items-baseline gap-2">
        <h2 className="font-display text-2xl uppercase leading-none">Heute genascht?</h2>
        <span className="ml-auto text-xs uppercase tracking-wider text-chalk-faint">
          {count === 0 ? 'Noch sauber' : `${count}× · −${count * XP_TREAT} XP`}
        </span>
      </div>

      <div className="mt-3 grid gap-2 sm:grid-cols-2">
        {LANE_LIST.map((lane) => (
          <LaneCounter
            key={lane.kind}
            lane={lane}
            stats={stats.lanes[lane.kind]}
            onAdd={() => addTreat(today, lane.kind)}
            onRemove={() => removeTreat(today, lane.kind)}
          />
        ))}
      </div>

      <p className="mt-2 text-xs text-chalk-faint">
        {count > 0
          ? `Eingetragen ist besser als verdrängt — morgen ist wieder Tag eins.`
          : streak > 0
            ? `🔥 ${streak} ${streak === 1 ? 'Tag' : 'Tage'} ohne Süßes. Nichts eintragen heißt sauber.`
            : `Jeder Eintrag kostet ${XP_TREAT} XP. Nichts eintragen kostet nichts.`}
      </p>
    </section>
  );
}

function LaneCounter({
  lane,
  stats,
  onAdd,
  onRemove,
}: {
  lane: LaneMeta;
  stats: LaneStats;
  onAdd: () => void;
  onRemove: () => void;
}) {
  const on = stats.today > 0;
  return (
    <div
      className="flex items-center gap-3 rounded-xl border p-3 transition"
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
          {stats.today > 0
            ? `Heute ${stats.today}× · −${stats.today * XP_TREAT} XP`
            : stats.cleanStreak > 0
              ? `${stats.cleanStreak} ${stats.cleanStreak === 1 ? 'Tag' : 'Tage'} ohne`
              : 'Heute noch nichts'}
        </span>
      </span>
      <span className="flex shrink-0 items-center gap-1">
        <button
          type="button"
          onClick={onRemove}
          disabled={stats.today === 0}
          aria-label={`Letzten Eintrag zurücknehmen: ${lane.title}`}
          className="h-9 w-9 rounded-lg border border-rock-700 bg-rock-850 text-lg font-semibold text-chalk-dim transition hover:border-rock-500 active:scale-[0.96] disabled:cursor-not-allowed disabled:opacity-35"
        >
          −
        </button>
        <span
          key={stats.today}
          className="animate-bump w-6 text-center font-display text-xl leading-none tabular-nums"
        >
          {stats.today}
        </span>
        <button
          type="button"
          onClick={onAdd}
          aria-label={`${lane.title} eintragen`}
          className="h-9 w-9 rounded-lg text-lg font-semibold text-rock-950 transition hover:brightness-110 active:scale-[0.96]"
          style={{ background: lane.color }}
        >
          +
        </button>
      </span>
    </div>
  );
}
