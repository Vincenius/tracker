import type { WeekSummary } from '../lib/stats';
import type { Tracker } from '../lib/store';
import { XP_STAIR } from '../lib/types';

const STAIR_COLOR = 'var(--color-grade-yellow)';

interface Props {
  week: WeekSummary;
  stairToday: number;
  stairStreak: number;
  addStair: Tracker['addStair'];
  removeStair: Tracker['removeStair'];
}

export function StairCard({ week, stairToday, stairStreak, addStair, removeStair }: Props) {
  const status =
    stairToday === 0
      ? 'Aufzug links liegen lassen — jeder Aufstieg zählt.'
      : `Heute schon ${stairToday}× die Treppe genommen.`;

  return (
    <section
      className="chalk-edge chalk-dust relative overflow-hidden rounded-2xl border bg-rock-900/80"
      style={{ borderColor: stairToday > 0 ? STAIR_COLOR : 'var(--color-rock-700)' }}
    >
      <div
        aria-hidden="true"
        className="absolute inset-x-0 top-0 h-1"
        style={{ background: STAIR_COLOR, opacity: stairToday > 0 ? 1 : 0.45 }}
      />

      <div className="flex items-start gap-3 p-4 pt-5">
        <span className="mt-0.5 shrink-0 text-2xl leading-none" aria-hidden="true">
          🪜
        </span>
        <div className="min-w-0 flex-1">
          <div className="flex flex-wrap items-center gap-x-2 gap-y-1">
            <span
              className="rounded-full px-2 py-0.5 text-[11px] font-semibold uppercase tracking-wider"
              style={{
                background: `color-mix(in srgb, ${STAIR_COLOR} 22%, transparent)`,
                color: STAIR_COLOR,
              }}
            >
              Unbegrenzt
            </span>
            <h2 className="font-display text-2xl uppercase leading-none">Treppe</h2>
          </div>
          <p className="mt-1 text-sm text-chalk-dim">{status}</p>
        </div>
        <span className="shrink-0 font-display text-2xl leading-none tabular-nums">
          {stairToday}
          <span className="text-chalk-faint">×</span>
        </span>
      </div>

      <div className="px-4 pb-4">
        <div className="flex items-stretch gap-2">
          <button
            type="button"
            onClick={removeStair}
            disabled={stairToday === 0}
            aria-label="Letzten Aufstieg zurücknehmen"
            className="w-12 rounded-xl border border-rock-700 bg-rock-850 text-xl font-semibold text-chalk-dim transition hover:border-rock-500 active:scale-[0.96] disabled:cursor-not-allowed disabled:opacity-35"
          >
            −
          </button>
          <button
            type="button"
            onClick={addStair}
            className="flex-1 rounded-xl py-3 text-sm font-semibold text-rock-950 transition hover:brightness-110 active:scale-[0.98]"
            style={{ background: STAIR_COLOR }}
          >
            + Treppe genommen · {XP_STAIR} XP
          </button>
        </div>

        <p className="mt-2 text-xs text-chalk-faint">
          {stairStreak > 0
            ? `🔥 ${stairStreak} ${stairStreak === 1 ? 'Tag' : 'Tage'} in Folge · diese Woche ${week.stairCount}×`
            : `So oft du willst — jeder Aufstieg bringt ${XP_STAIR} XP. Diese Woche ${week.stairCount}×.`}
        </p>
      </div>
    </section>
  );
}
