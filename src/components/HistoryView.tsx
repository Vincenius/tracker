import { useRef, useState } from 'react';
import { addWeeks, currentWeekKey, weekNumber, weekRangeLabel } from '../lib/date';
import type { Tracker } from '../lib/store';
import { summarizeWeek, type WeekSummary } from '../lib/stats';
import { SESSION_META } from '../lib/workouts';

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
  const weeks: WeekSummary[] = [];
  const minStart = addWeeks(today, -25);
  const start = stats.orderedWeeks[0] && stats.orderedWeeks[0].key < minStart ? stats.orderedWeeks[0].key : minStart;
  for (let k = start; k <= today; k = addWeeks(k, 1)) {
    weeks.push(stats.weeks.get(k) ?? summarizeWeek(k, []));
  }

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
