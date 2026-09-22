import { useRef, useState } from 'react';
import {
  addDays,
  addWeeks,
  currentWeekKey,
  shortDate,
  toISODate,
  weekNumber,
  weekRangeLabel,
  weekdayLabel,
} from '../lib/date';
import { LANE_LIST } from '../lib/nutrition';
import type { Tracker } from '../lib/store';
import { summarizeWeek, type Stats, type WeekSummary } from '../lib/stats';
import { XP_STAIR, XP_TREAT, XP_WALK, xpFor } from '../lib/types';
import { SESSION_META } from '../lib/workouts';

const WALK_ROWS = ['Mo', 'Di', 'Mi', 'Do', 'Fr'];

function signed(xp: number): string {
  return xp > 0 ? `+${xp}` : xp < 0 ? `−${-xp}` : '0';
}

interface XpSource {
  key: string;
  label: string;
  color: string;
  /** Anzahl und XP je Eintrag, z.B. „40× · je 6 XP“ */
  detail: string;
  xp: number;
  weekXp: number;
}

/** Wie viel jede Art von Eintrag insgesamt und in dieser Woche gebracht (oder gekostet) hat. */
function xpSources(stats: Stats, week: WeekSummary): XpSource[] {
  const sessions = stats.orderedWeeks.flatMap((w) => w.sessions);
  const sum = (list: typeof sessions) => list.reduce((acc, s) => acc + xpFor(s), 0);
  return [
    ...(['boulder', 'home', 'fallback'] as const).map((t) => ({
      key: t,
      label: SESSION_META[t].title,
      color: SESSION_META[t].color,
      detail: `${stats.byType[t]}×`,
      xp: sum(sessions.filter((s) => s.type === t)),
      weekXp: sum(week.sessions.filter((s) => s.type === t)),
    })),
    {
      key: 'walks',
      label: 'Spaziergänge',
      color: 'var(--color-grade-green)',
      detail: `${stats.walkTotal}× · je ${XP_WALK} XP`,
      xp: stats.walkTotal * XP_WALK,
      // Wie in den Stats zählt pro Tag ein Spaziergang.
      weekXp: new Set(week.walks.map((w) => w.date)).size * XP_WALK,
    },
    {
      key: 'stairs',
      label: 'Treppe',
      color: 'var(--color-grade-yellow)',
      detail: `${stats.stairTotal}× · je ${XP_STAIR} XP`,
      xp: stats.stairTotal * XP_STAIR,
      weekXp: week.stairCount * XP_STAIR,
    },
    ...LANE_LIST.map((lane) => ({
      key: lane.kind,
      label: lane.title,
      color: lane.color,
      detail: `${stats.lanes[lane.kind].total}× · je −${XP_TREAT} XP`,
      xp: -stats.lanes[lane.kind].xpLost,
      weekXp: -week.treatsByKind[lane.kind] * XP_TREAT,
    })),
  ];
}

function XpSources({ stats, week }: { stats: Stats; week: WeekSummary }) {
  const sources = xpSources(stats, week);
  const max = Math.max(1, ...sources.map((s) => Math.abs(s.xp)));
  const gained = sources.reduce((acc, s) => acc + Math.max(0, s.xp), 0);
  const lost = sources.reduce((acc, s) => acc + Math.max(0, -s.xp), 0);

  return (
    <section className="chalk-edge rounded-2xl border border-rock-700 bg-rock-900/80 p-4">
      <h2 className="font-display text-xl uppercase">XP-Quellen</h2>
      <p className="mt-1 text-sm text-chalk-dim">
        Woher deine {stats.xp} XP kommen — insgesamt und in dieser Woche.
      </p>
      <ul className="mt-4 space-y-3">
        {sources.map((s) => (
          <li key={s.key}>
            <div className="flex items-baseline gap-2 text-sm">
              <i
                className="h-2.5 w-2.5 shrink-0 self-center rounded-full"
                style={{ background: s.color }}
              />
              <span className="min-w-0 truncate font-semibold">{s.label}</span>
              <span className="shrink-0 text-xs text-chalk-faint">{s.detail}</span>
              <span className="ml-auto shrink-0 text-xs tabular-nums text-chalk-faint">
                Woche {signed(s.weekXp)}
              </span>
              <span
                className="w-16 shrink-0 text-right font-semibold tabular-nums"
                style={{ color: s.xp < 0 ? 'var(--color-grade-red)' : undefined }}
              >
                {signed(s.xp)}
              </span>
            </div>
            <div className="mt-1.5 h-1.5 overflow-hidden rounded-full bg-rock-800">
              <div
                className="h-full rounded-full transition-[width] duration-500"
                style={{ width: `${(Math.abs(s.xp) / max) * 100}%`, background: s.color }}
              />
            </div>
          </li>
        ))}
      </ul>
      <p className="mt-4 border-t border-rock-800 pt-3 text-xs tabular-nums text-chalk-faint">
        {signed(gained)} verdient · {signed(-lost)} verloren = {stats.xp} XP
        {gained - lost < 0 && ' (unter null geht es nicht)'}
      </p>
    </section>
  );
}

function cellStyle(w: WeekSummary): React.CSSProperties {
  const base: React.CSSProperties = {
    background: 'var(--color-rock-800)',
    borderColor: 'var(--color-rock-700)',
  };
  if (w.count === 1)
    return { background: 'color-mix(in srgb, var(--color-grade-green) 32%, var(--color-rock-800))', borderColor: 'transparent' };
  if (w.count === 2) return { background: 'var(--color-grade-green)', borderColor: 'transparent' };
  if (w.count >= 3) return { background: 'var(--color-grade-yellow)', borderColor: 'transparent' };
  return base;
}

function Stat({ value, label }: { value: string | number; label: string }) {
  return (
    <div className="rounded-xl border border-rock-700 bg-rock-900/80 p-3">
      <div className="font-display text-3xl leading-none">{value}</div>
      <div className="mt-1 text-xs uppercase tracking-wider text-chalk-faint">{label}</div>
    </div>
  );
}

export function HistoryView({ tracker }: { tracker: Tracker }) {
  const { stats, doExport, doImport, resetAll } = tracker;
  const fileRef = useRef<HTMLInputElement>(null);
  const [confirmReset, setConfirmReset] = useState(false);

  // Mindestens 26 Wochen anzeigen, auch wenn die Historie kürzer ist.
  const today = currentWeekKey();
  const thisWeek = stats.weeks.get(today) ?? summarizeWeek(today, []);
  const weeks: WeekSummary[] = [];
  const minStart = addWeeks(today, -25);
  const start = stats.orderedWeeks[0] && stats.orderedWeeks[0].key < minStart ? stats.orderedWeeks[0].key : minStart;
  for (let k = start; k <= today; k = addWeeks(k, 1)) {
    weeks.push(stats.weeks.get(k) ?? summarizeWeek(k, []));
  }

  // Werktage der letzten 8 Wochen, zeilenweise Mo–Fr.
  const todayDate = toISODate(new Date());
  const walkedDates = new Set(
    stats.orderedWeeks.flatMap((w) => w.walks.map((walk) => walk.date)),
  );
  const walkWeeks = weeks.slice(-8).map((w) =>
    [0, 1, 2, 3, 4].map((i) => {
      const date = addDays(w.key, i);
      return { date, done: walkedDates.has(date), future: date > todayDate };
    }),
  );

  // Ernährung läuft an allen sieben Tagen — hier die letzten 8 Wochen am Stück.
  const foodDays = weeks.slice(-8).flatMap((w) =>
    [0, 1, 2, 3, 4, 5, 6].map((i) => {
      const date = addDays(w.key, i);
      return { date, future: date > todayDate };
    }),
  );

  const totalSessions = stats.total || 1;
  const dist = (['boulder', 'home', 'fallback'] as const).map((t) => ({
    type: t,
    n: stats.byType[t],
    pct: (stats.byType[t] / totalSessions) * 100,
  }));

  return (
    <div className="space-y-5">
      <section className="chalk-edge rounded-2xl border border-rock-700 bg-rock-900/80 p-4">
        <h2 className="font-display text-xl uppercase">Wochen-Verlauf</h2>
        <p className="mt-1 text-sm text-chalk-dim">
          Jedes Feld ist eine Woche. Grün heißt: Ziel erreicht.
        </p>
        <div className="mt-4 grid grid-cols-[repeat(auto-fill,minmax(26px,1fr))] gap-1.5">
          {weeks.map((w) => (
            <div
              key={w.key}
              title={`KW ${weekNumber(w.key)} (${weekRangeLabel(w.key)}) — ${w.count} ${
                w.count === 1 ? 'Einheit' : 'Einheiten'
              }${w.fallbackWeek ? ' · Fallback-Woche' : ''}`}
              className="relative aspect-square rounded-[5px] border"
              style={cellStyle(w)}
            >
              {w.fallbackWeek && (
                <span
                  aria-hidden="true"
                  className="absolute bottom-0.5 right-0.5 h-1.5 w-1.5 rounded-full"
                  style={{ background: 'var(--color-grade-purple)' }}
                />
              )}
              {w.key === today && (
                <span
                  aria-hidden="true"
                  className="absolute inset-0 rounded-[5px] ring-2 ring-tape ring-offset-1 ring-offset-rock-900"
                />
              )}
            </div>
          ))}
        </div>
        <div className="mt-3 flex flex-wrap items-center gap-x-4 gap-y-1 text-xs text-chalk-faint">
          <span className="flex items-center gap-1.5">
            <i className="h-3 w-3 rounded-[3px] border border-rock-700 bg-rock-800" /> keine Einheit
          </span>
          <span className="flex items-center gap-1.5">
            <i
              className="h-3 w-3 rounded-[3px]"
              style={{ background: 'color-mix(in srgb, var(--color-grade-green) 32%, var(--color-rock-800))' }}
            />{' '}
            eine
          </span>
          <span className="flex items-center gap-1.5">
            <i className="h-3 w-3 rounded-[3px]" style={{ background: 'var(--color-grade-green)' }} />{' '}
            Ziel erreicht
          </span>
          <span className="flex items-center gap-1.5">
            <i className="h-3 w-3 rounded-full" style={{ background: 'var(--color-grade-purple)' }} />{' '}
            Fallback-Woche
          </span>
        </div>
      </section>

      <section className="grid grid-cols-2 gap-3 sm:grid-cols-4">
        <Stat value={stats.total} label="Einheiten gesamt" />
        <Stat value={stats.currentStreak} label="Wochen-Streak" />
        <Stat value={stats.longestStreak} label="Längster Streak" />
        <Stat value={stats.fulfilledWeeks} label="Volle Wochen" />
      </section>

      <XpSources stats={stats} week={thisWeek} />

      <section className="chalk-edge rounded-2xl border border-rock-700 bg-rock-900/80 p-4">
        <h2 className="font-display text-xl uppercase">Spaziergänge</h2>
        <p className="mt-1 text-sm text-chalk-dim">
          Eine Spalte pro Woche, ein Feld pro Werktag. Das Wochenende bleibt frei.
        </p>
        <div className="mt-4 flex gap-1">
          <div className="flex flex-col gap-1 pr-1 text-[10px] leading-4 text-chalk-faint">
            {WALK_ROWS.map((d) => (
              <span key={d} className="h-4">
                {d}
              </span>
            ))}
          </div>
          {walkWeeks.map((days) => (
            <div key={days[0].date} className="flex flex-col gap-1">
              {days.map((d) => (
                <div
                  key={d.date}
                  title={`${weekdayLabel(d.date)}, ${shortDate(d.date)}${d.done ? ' — Spaziergang' : ''}`}
                  className="h-4 w-4 rounded-[4px] border"
                  style={{
                    background: d.done ? 'var(--color-grade-green)' : 'var(--color-rock-800)',
                    borderColor: d.done ? 'transparent' : 'var(--color-rock-700)',
                    opacity: d.future ? 0.3 : 1,
                  }}
                />
              ))}
            </div>
          ))}
        </div>
        <div className="mt-4 grid grid-cols-2 gap-3 sm:grid-cols-4">
          <Stat value={stats.walkTotal} label="Spaziergänge" />
          <Stat value={stats.walkStreak} label="Tage-Streak" />
          <Stat value={stats.longestWalkStreak} label="Längster Streak" />
          <Stat value={stats.walkPerfectWeeks} label="Volle Wochen" />
        </div>
      </section>

      <section className="chalk-edge rounded-2xl border border-rock-700 bg-rock-900/80 p-4">
        <h2 className="font-display text-xl uppercase">Treppe</h2>
        <p className="mt-1 text-sm text-chalk-dim">
          Jeder Aufstieg zählt — so oft am Tag, wie du magst.
        </p>
        <div className="mt-4 grid grid-cols-2 gap-3 sm:grid-cols-4">
          <Stat value={stats.stairTotal} label="Aufstiege" />
          <Stat value={stats.stairDays} label="Tage mit Treppe" />
          <Stat value={stats.stairBestDay} label="Tagesrekord" />
          <Stat value={stats.longestStairStreak} label="Längster Streak" />
        </div>
      </section>

      <section className="chalk-edge rounded-2xl border border-rock-700 bg-rock-900/80 p-4">
        <h2 className="font-display text-xl uppercase">Ernährung</h2>
        <p className="mt-1 text-sm text-chalk-dim">
          Zwei Zeilen pro Woche: oben Süßes gegessen, unten Süßes getrunken. Leer ist gut.
        </p>
        <div className="mt-4 space-y-3">
          {LANE_LIST.map((lane) => {
            const laneStats = stats.lanes[lane.kind];
            return (
              <div key={lane.kind}>
                <div className="mb-1.5 flex items-center gap-2 text-xs text-chalk-faint">
                  <i className="h-2.5 w-2.5 rounded-full" style={{ background: lane.color }} />
                  {lane.short}
                  <span className="ml-auto tabular-nums">
                    {laneStats.total}× · {laneStats.days} Tage · längste saubere Serie{' '}
                    {Math.max(laneStats.cleanStreak, laneStats.longestCleanStreak)}
                  </span>
                </div>
                <div className="grid grid-cols-[repeat(auto-fill,minmax(14px,1fr))] gap-1">
                  {foodDays.map((d) => {
                    const count = laneStats.perDay.get(d.date) ?? 0;
                    return (
                      <div
                        key={`${lane.kind}-${d.date}`}
                        title={`${weekdayLabel(d.date)}, ${shortDate(d.date)} — ${count}×`}
                        className="aspect-square rounded-[4px] border"
                        style={{
                          background:
                            count === 0
                              ? 'var(--color-rock-800)'
                              : count === 1
                                ? `color-mix(in srgb, ${lane.color} 45%, var(--color-rock-800))`
                                : count === 2
                                  ? `color-mix(in srgb, ${lane.color} 72%, var(--color-rock-800))`
                                  : lane.color,
                          borderColor: count > 0 ? 'transparent' : 'var(--color-rock-700)',
                          opacity: d.future ? 0.3 : 1,
                        }}
                      />
                    );
                  })}
                </div>
              </div>
            );
          })}
        </div>
        <div className="mt-4 grid grid-cols-2 gap-3 sm:grid-cols-4">
          <Stat value={stats.cleanDayTotal} label="Saubere Tage" />
          <Stat value={stats.cleanStreak} label="Tage-Streak" />
          <Stat value={stats.longestCleanStreak} label="Längster Streak" />
          <Stat value={stats.treatXpLost > 0 ? `−${stats.treatXpLost}` : 0} label="XP verloren" />
        </div>
      </section>

      <section className="chalk-edge rounded-2xl border border-rock-700 bg-rock-900/80 p-4">
        <h2 className="font-display text-xl uppercase">Verteilung</h2>
        {stats.total === 0 ? (
          <p className="mt-2 text-sm text-chalk-dim">Noch keine Einheiten — das ändert sich gleich.</p>
        ) : (
          <>
            <div className="mt-3 flex h-3 overflow-hidden rounded-full bg-rock-800">
              {dist.map((d) => (
                <div
                  key={d.type}
                  style={{ width: `${d.pct}%`, background: SESSION_META[d.type].color }}
                />
              ))}
            </div>
            <ul className="mt-3 space-y-1.5 text-sm">
              {dist.map((d) => (
                <li key={d.type} className="flex items-center gap-2">
                  <i
                    className="h-2.5 w-2.5 rounded-full"
                    style={{ background: SESSION_META[d.type].color }}
                  />
                  <span>{SESSION_META[d.type].title}</span>
                  <span className="ml-auto tabular-nums text-chalk-dim">
                    {d.n} · {Math.round(d.pct)}%
                  </span>
                </li>
              ))}
            </ul>
          </>
        )}
      </section>

      <section className="chalk-edge rounded-2xl border border-rock-700 bg-rock-900/80 p-4">
        <h2 className="font-display text-xl uppercase">Daten</h2>
        <p className="mt-1 text-sm text-chalk-dim">
          {tracker.sync === 'offline'
            ? 'Gerade kein Server erreichbar — alles läuft lokal weiter und wird beim nächsten Mal synchronisiert.'
            : 'Deine Einheiten liegen auf dem Server und werden auf allen Geräten zusammengeführt. Lokal bleibt eine Kopie, damit die App auch offline funktioniert.'}
        </p>
        <p className="mt-1 text-xs text-chalk-faint">
          Import und Zurücksetzen ersetzen auch den Stand auf dem Server.
        </p>
        <div className="mt-3 flex flex-wrap gap-2">
          <button
            type="button"
            onClick={doExport}
            className="rounded-lg bg-chalk px-4 py-2 text-sm font-semibold text-rock-950 transition hover:bg-white"
          >
            Export (JSON)
          </button>
          <button
            type="button"
            onClick={() => fileRef.current?.click()}
            className="rounded-lg border border-rock-600 px-4 py-2 text-sm font-semibold text-chalk transition hover:border-rock-500"
          >
            Import
          </button>
          <input
            ref={fileRef}
            type="file"
            accept="application/json,.json"
            className="sr-only"
            onChange={(e) => {
              const f = e.target.files?.[0];
              if (f) void doImport(f);
              e.target.value = '';
            }}
          />
          <button
            type="button"
            onClick={() => {
              if (confirmReset) {
                resetAll();
                setConfirmReset(false);
              } else setConfirmReset(true);
            }}
            onBlur={() => setConfirmReset(false)}
            className="ml-auto rounded-lg px-3 py-2 text-sm text-chalk-faint transition hover:text-chalk-dim"
          >
            {confirmReset ? 'Wirklich alles löschen?' : 'Zurücksetzen'}
          </button>
        </div>
      </section>
    </div>
  );
}
