import { addDays, addWeeks, currentWeekKey, shortDate, toISODate, weekdayLabel } from '../lib/date';
import { LANE_LIST, type LaneMeta } from '../lib/nutrition';
import { CLEAN_GOAL, type LaneStats } from '../lib/stats';
import type { Tracker } from '../lib/store';
import {
  CLEAN_CAP_DAY,
  XP_CLEAN_CAP,
  XP_CLEAN_COMBO,
  XP_PER_LEVEL,
  xpForCleanDay,
} from '../lib/types';

const DAYS = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
const HISTORY_WEEKS = 8;

/** Die Leiter zeigt, was der nächste Tag wert ist — und wo die Serie steht. */
function StreakLadder({ lane, stats }: { lane: LaneMeta; stats: LaneStats }) {
  const steps = Array.from({ length: CLEAN_CAP_DAY }, (_, i) => i + 1);
  return (
    <div className="mt-3 flex items-end gap-1">
      {steps.map((day) => {
        const reached = stats.currentStreak >= day;
        const next = stats.currentStreak + 1 === day;
        return (
          <div key={day} className="flex-1 text-center">
            <div
              className="mx-auto w-3 rounded-t-sm transition-[height]"
              style={{
                height: `${10 + day * 6}px`,
                background: reached
                  ? lane.color
                  : next
                    ? `color-mix(in srgb, ${lane.color} 45%, transparent)`
                    : 'var(--color-rock-800)',
              }}
            />
            <span
              className="mt-1 block text-[10px] tabular-nums"
              style={{
                color: reached || next ? 'var(--color-chalk-dim)' : 'var(--color-chalk-faint)',
              }}
            >
              +{xpForCleanDay(day)}
            </span>
          </div>
        );
      })}
      <div className="flex-[1.6] pl-1 text-center">
        <div
          className="mx-auto w-7 rounded-t-sm"
          style={{
            height: `${10 + CLEAN_CAP_DAY * 6}px`,
            background:
              stats.currentStreak > CLEAN_CAP_DAY
                ? lane.color
                : `repeating-linear-gradient(90deg, var(--color-rock-800) 0 3px, transparent 3px 6px)`,
          }}
        />
        <span className="mt-1 block text-[10px] text-chalk-faint">danach</span>
      </div>
    </div>
  );
}

function LaneCard({
  lane,
  stats,
  weekKey,
  today,
  toggleClean,
}: {
  lane: LaneMeta;
  stats: LaneStats;
  weekKey: string;
  today: string;
  toggleClean: Tracker['toggleClean'];
}) {
  const weekDates = DAYS.map((_, i) => addDays(weekKey, i));
  const weekDone = weekDates.filter((d) => stats.dates.has(d)).length;
  const perfect = weekDone >= CLEAN_GOAL;

  return (
    <section
      className="chalk-edge chalk-dust relative overflow-hidden rounded-2xl border bg-rock-900/80"
      style={{ borderColor: perfect ? lane.color : 'var(--color-rock-700)' }}
    >
      <div
        aria-hidden="true"
        className="absolute inset-x-0 top-0 h-1"
        style={{ background: lane.color, opacity: perfect ? 1 : 0.45 }}
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
              Täglich
            </span>
            <h2 className="font-display text-2xl uppercase leading-none">{lane.short}</h2>
          </div>
          <p className="mt-1 text-sm text-chalk-dim">{lane.tagline}</p>
        </div>
        <span className="shrink-0 font-display text-2xl leading-none tabular-nums">
          {weekDone}
          <span className="text-chalk-faint">/{CLEAN_GOAL}</span>
        </span>
      </div>

      <div className="px-4 pb-4">
        <div className="grid grid-cols-7 gap-1.5">
          {DAYS.map((label, i) => {
            const date = weekDates[i];
            const on = stats.dates.has(date);
            const isToday = date === today;
            // Die Zukunft lässt sich nicht abhaken — der Tag ist noch offen.
            const future = date > today;
            return (
              <button
                key={date}
                type="button"
                disabled={future}
                onClick={() => toggleClean(date, lane.kind)}
                aria-pressed={on}
                aria-label={`${weekdayLabel(date)}, ${shortDate(date)} — ${lane.title}${
                  on ? ' ✓' : ''
                }`}
                className={`flex flex-col items-center gap-1 rounded-xl border px-1 py-2.5 text-xs font-semibold transition active:scale-[0.96] disabled:cursor-not-allowed disabled:opacity-35 ${
                  on ? 'text-rock-950' : 'border-rock-700 bg-rock-850 text-chalk-dim hover:border-rock-500'
                }`}
                style={
                  on
                    ? { background: lane.color, borderColor: lane.color }
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

        <StreakLadder lane={lane} stats={stats} />

        <p className="mt-2.5 text-xs text-chalk-faint">
          {stats.currentStreak > 0
            ? `🔥 ${stats.currentStreak} ${stats.currentStreak === 1 ? 'Tag' : 'Tage'} in Folge · ${
                stats.dates.has(today) ? 'morgen' : 'heute'
              } +${stats.nextXp} XP`
            : `Der erste Tag bringt +${xpForCleanDay(1)} XP, jeder weitere mehr — bis +${XP_CLEAN_CAP}.`}
          {stats.longestStreak > stats.currentStreak &&
            ` · Bestserie ${stats.longestStreak} Tage`}
        </p>
      </div>
    </section>
  );
}

export function NutritionView({ tracker }: { tracker: Tracker }) {
  const { stats, toggleClean } = tracker;
  const today = toISODate(new Date());
  const weekKey = currentWeekKey();
  const start = addWeeks(weekKey, -(HISTORY_WEEKS - 1));
  const historyWeeks = Array.from({ length: HISTORY_WEEKS }, (_, i) => addWeeks(start, i));

  const both = stats.cleanBothStreak;
  const status =
    both > 0
      ? `${both} ${both === 1 ? 'Tag' : 'Tage'} komplett sauber am Stück.`
      : stats.lanes.snacks.currentStreak > 0 || stats.lanes.drinks.currentStreak > 0
        ? 'Eine Spur läuft schon. Die zweite dazu und es gibt Bonus.'
        : 'Heute ist Tag eins. Zwei Häkchen, mehr braucht es nicht.';

  return (
    <div className="space-y-4">
      <section className="chalk-edge chalk-dust rounded-2xl border border-rock-700 bg-rock-900/80 p-4">
        <p className="text-xs uppercase tracking-widest text-chalk-faint">Ernährung</p>
        <p className="mt-1 font-display text-xl uppercase leading-tight">{status}</p>
        <p className="mt-1 text-sm text-chalk-dim">
          Kein Kalorienzählen. Nur zwei Fragen pro Tag — und für jeden Tag in Folge mehr XP.
        </p>

        <div className="mt-4 grid grid-cols-3 gap-2 text-center">
          {[
            { value: stats.cleanBothDays, label: 'Volle Tage' },
            { value: stats.longestCleanBothStreak, label: 'Bestserie' },
            { value: stats.cleanXp, label: 'XP daraus' },
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
          toggleClean={toggleClean}
        />
      ))}

      <section className="chalk-edge rounded-2xl border border-rock-700 bg-rock-900/80 p-4">
        <h2 className="font-display text-xl uppercase">Letzte {HISTORY_WEEKS} Wochen</h2>
        <p className="mt-1 text-sm text-chalk-dim">
          Vergessen einzutragen? Vergangene Tage lassen sich hier nachtragen.
        </p>

        <div className="mt-4 grid gap-4 sm:grid-cols-2">
          {LANE_LIST.map((lane) => {
            const dates = stats.lanes[lane.kind].dates;
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
                      const on = dates.has(date);
                      const future = date > today;
                      return (
                        <button
                          key={date}
                          type="button"
                          disabled={future}
                          onClick={() => toggleClean(date, lane.kind)}
                          aria-pressed={on}
                          aria-label={`${weekdayLabel(date)}, ${shortDate(date)} — ${lane.title}${
                            on ? ' ✓' : ''
                          }`}
                          title={`${weekdayLabel(date)}, ${shortDate(date)}`}
                          className="aspect-square rounded-[5px] border transition disabled:cursor-not-allowed"
                          style={{
                            background: on ? lane.color : 'var(--color-rock-800)',
                            borderColor: on
                              ? 'transparent'
                              : date === today
                                ? 'var(--color-tape)'
                                : 'var(--color-rock-700)',
                            opacity: future ? 0.25 : 1,
                          }}
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
            Erster sauberer Tag: <span className="text-chalk">+{xpForCleanDay(1)} XP</span>. Jeder
            weitere Tag in Folge einen mehr, bis{' '}
            <span className="text-chalk">+{XP_CLEAN_CAP} XP</span> ab Tag {CLEAN_CAP_DAY}.
          </li>
          <li>
            Beide Spuren am selben Tag: <span className="text-chalk">+{XP_CLEAN_COMBO} XP</span>{' '}
            Kombi-Bonus obendrauf.
          </li>
          <li>
            Ein Ausrutscher setzt nur den Zähler zurück — verdiente XP bleiben. {XP_PER_LEVEL} XP
            sind ein Level.
          </li>
        </ul>
      </section>
    </div>
  );
}
