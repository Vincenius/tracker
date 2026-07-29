import { currentWeekKey, shortDate, weekNumber, weekRangeLabel } from '../lib/date';
import { CLEAN_GOAL, summarizeWeek } from '../lib/stats';
import type { Tracker } from '../lib/store';
import type { SessionType } from '../lib/types';
import { WALK_GOAL, XP_PER_LEVEL } from '../lib/types';
import { NutritionCard } from './NutritionCard';
import { SessionCard } from './SessionCard';
import { StairCard } from './StairCard';
import { WalkCard } from './WalkCard';

function GoalRing({ count }: { count: number }) {
  const pct = Math.min(1, count / 2);
  const r = 30;
  const c = 2 * Math.PI * r;
  return (
    <div className="relative grid h-[76px] w-[76px] shrink-0 place-items-center">
      <svg viewBox="0 0 76 76" className="absolute inset-0 -rotate-90">
        <circle cx="38" cy="38" r={r} fill="none" stroke="var(--color-rock-700)" strokeWidth="7" />
        <circle
          cx="38"
          cy="38"
          r={r}
          fill="none"
          stroke={pct >= 1 ? 'var(--color-grade-green)' : 'var(--color-tape)'}
          strokeWidth="7"
          strokeLinecap="round"
          strokeDasharray={c}
          strokeDashoffset={c * (1 - pct)}
          className="transition-[stroke-dashoffset] duration-500"
        />
      </svg>
      <div className="text-center leading-none">
        <div className="font-display text-2xl">{Math.min(count, 2)}</div>
        <div className="text-[10px] uppercase tracking-wider text-chalk-faint">von 2</div>
      </div>
    </div>
  );
}

export function WeekView({ tracker }: { tracker: Tracker }) {
  const {
    stats,
    addSession,
    removeSession,
    toggleWalk,
    toggleClean,
    addStair,
    removeStair,
    togglePause,
  } = tracker;
  const key = currentWeekKey();
  const week = stats.weeks.get(key) ?? summarizeWeek(key, []);
  const sessions = week.sessions;
  const count = sessions.length;
  const has = (t: SessionType) => sessions.some((s) => s.type === t);

  const status =
    count === 0
      ? 'Frische Woche. Zwei Einheiten – du kennst den Plan.'
      : count === 1
        ? 'Eine geschafft. Noch eine bis zum Wochenziel.'
        : count === 2
          ? 'Wochenziel erreicht. Stark!'
          : 'Wochenziel übertroffen. Chapeau!';

  const showBoulder = !has('fallback') || has('boulder');
  const showFallback = !has('boulder') || has('fallback');

  return (
    <div className="space-y-4">
      {stats.pauseActive && (
        <section
          className="chalk-edge rounded-2xl border bg-rock-900/80 p-4"
          style={{ borderColor: 'var(--color-grade-yellow)' }}
        >
          <div className="flex items-center gap-3">
            <span className="shrink-0 text-2xl leading-none" aria-hidden="true">
              ⏸️
            </span>
            <div className="min-w-0 flex-1">
              <h2 className="font-display text-lg uppercase leading-tight">Pausenmodus aktiv</h2>
              <p className="mt-0.5 text-sm text-chalk-dim">
                {stats.pausedSince ? `Seit ${shortDate(stats.pausedSince)}. ` : ''}
                Deine Streaks sind eingefroren — was du trotzdem einträgst, zählt ganz normal.
              </p>
            </div>
            <button
              type="button"
              onClick={togglePause}
              className="shrink-0 rounded-lg px-3 py-2 text-sm font-semibold text-rock-950 transition hover:brightness-110"
              style={{ background: 'var(--color-grade-yellow)' }}
            >
              Beenden
            </button>
          </div>
        </section>
      )}

      <section className="chalk-edge chalk-dust rounded-2xl border border-rock-700 bg-rock-900/80 p-4">
        <div className="flex items-center gap-4">
          <GoalRing count={count} />
          <div className="min-w-0">
            <p className="text-xs uppercase tracking-widest text-chalk-faint">
              KW {weekNumber(key)} · {weekRangeLabel(key)}
            </p>
            <p className="mt-1 font-display text-xl uppercase leading-tight">{status}</p>
            <p className="mt-1 text-sm text-chalk-dim">
              {stats.currentStreak > 0
                ? `🔥 ${stats.currentStreak} ${stats.currentStreak === 1 ? 'Woche' : 'Wochen'} in Folge`
                : 'Jede Woche ist ein neuer Start.'}
            </p>
          </div>
        </div>

        <div className="mt-4 border-t border-rock-800 pt-3">
          <div className="flex items-end justify-between text-sm">
            <span className="font-display text-lg uppercase">Level {stats.level}</span>
            <span className="text-chalk-dim">
              {stats.xpInLevel} / {XP_PER_LEVEL} XP
            </span>
          </div>
          <div className="mt-2 h-2.5 overflow-hidden rounded-full bg-rock-800">
            <div
              className="h-full rounded-full transition-[width] duration-700"
              style={{
                width: `${(stats.xpInLevel / XP_PER_LEVEL) * 100}%`,
                background: 'linear-gradient(90deg, var(--color-tape), var(--color-grade-yellow))',
              }}
            />
          </div>
          <p className="mt-1.5 text-xs text-chalk-faint">
            Noch {stats.xpToNext} XP bis Level {stats.level + 1}.
          </p>
        </div>

        {/* Die drei Wochenziele auf einen Blick — jedes zählt für sich. */}
        <div className="mt-4 grid grid-cols-3 gap-2">
          {[
            { label: 'Training', done: count, goal: 2, color: 'var(--color-tape)' },
            {
              label: 'Spaziergänge',
              done: week.walkDays,
              goal: WALK_GOAL,
              color: 'var(--color-grade-green)',
            },
            {
              label: 'Sauber',
              done: week.cleanBothDays,
              goal: CLEAN_GOAL,
              color: 'var(--color-mint)',
            },
          ].map((g) => {
            const hit = g.done >= g.goal;
            return (
              <div
                key={g.label}
                className="rounded-xl border bg-rock-850 px-2 py-2 text-center"
                style={{ borderColor: hit ? g.color : 'var(--color-rock-700)' }}
              >
                <div
                  className="font-display text-lg leading-none tabular-nums"
                  style={{ color: hit ? g.color : 'var(--color-chalk)' }}
                >
                  {Math.min(g.done, g.goal)}
                  <span className="text-chalk-faint">/{g.goal}</span>
                </div>
                <div className="mt-1 text-[10px] uppercase tracking-wider text-chalk-faint">
                  {g.label}
                </div>
              </div>
            );
          })}
        </div>
      </section>

      <NutritionCard stats={stats} toggleClean={toggleClean} />

      <WalkCard week={week} toggleWalk={toggleWalk} walkStreak={stats.walkStreak} />

      <StairCard
        week={week}
        stairToday={stats.stairToday}
        stairStreak={stats.stairStreak}
        addStair={addStair}
        removeStair={removeStair}
      />

      <SessionCard
        type="home"
        done={sessions.filter((s) => s.type === 'home')}
        onComplete={addSession}
        onRemove={removeSession}
      />

      {showBoulder && (
        <SessionCard
          type="boulder"
          done={sessions.filter((s) => s.type === 'boulder')}
          onComplete={addSession}
          onRemove={removeSession}
        />
      )}

      {showFallback && (
        <>
          {!has('fallback') && (
            <p className="px-1 text-center text-xs text-chalk-faint">
              Bouldern klappt diese Woche nicht? Dann hol dir die Woche hiermit zurück.
            </p>
          )}
          <SessionCard
            type="fallback"
            done={sessions.filter((s) => s.type === 'fallback')}
            onComplete={addSession}
            onRemove={removeSession}
          />
        </>
      )}

      {!stats.pauseActive && (
        <button
          type="button"
          onClick={togglePause}
          className="w-full rounded-2xl border border-dashed border-rock-700 px-4 py-3 text-sm text-chalk-faint transition hover:border-rock-500 hover:text-chalk-dim"
        >
          🏖️ Urlaub oder krank? Pausenmodus starten — deine Streaks bleiben erhalten.
        </button>
      )}
    </div>
  );
}
