import { useState } from 'react';
import { BadgesView } from './components/BadgesView';
import { Celebration } from './components/Celebration';
import { HistoryView } from './components/HistoryView';
import { HoldIcon } from './components/HoldIcon';
import { NutritionView } from './components/NutritionView';
import { WeekView } from './components/WeekView';
import { useTracker, type Tracker } from './lib/store';

const SYNC_LABEL: Record<Tracker['sync'], string> = {
  idle: 'Verbinde …',
  syncing: 'Synchronisiert …',
  synced: 'Mit dem Server synchron',
  offline: 'Offline — lokal gespeichert, wird später synchronisiert',
};

const SYNC_COLOR: Record<Tracker['sync'], string> = {
  idle: 'var(--color-rock-500)',
  syncing: 'var(--color-grade-yellow)',
  synced: 'var(--color-grade-green)',
  offline: 'var(--color-rock-500)',
};

function SyncBadge({ tracker }: { tracker: Tracker }) {
  return (
    <button
      type="button"
      onClick={() => void tracker.syncNow()}
      title={SYNC_LABEL[tracker.sync]}
      aria-label={SYNC_LABEL[tracker.sync]}
      className="grid h-8 w-8 place-items-center rounded-full border border-rock-700 transition hover:border-rock-500"
    >
      <span
        aria-hidden="true"
        className="h-2 w-2 rounded-full transition"
        style={{ background: SYNC_COLOR[tracker.sync] }}
      />
    </button>
  );
}

/** `short` steht in der Mobile-Leiste — vier Tabs brauchen dort kurze Wörter. */
const TABS = [
  { id: 'week', label: 'Diese Woche', short: 'Woche' },
  { id: 'food', label: 'Ernährung', short: 'Essen' },
  { id: 'history', label: 'Verlauf', short: 'Verlauf' },
  { id: 'badges', label: 'Abzeichen', short: 'Abzeichen' },
] as const;

type TabId = (typeof TABS)[number]['id'];

export default function App() {
  const tracker = useTracker();
  const [tab, setTab] = useState<TabId>('week');

  return (
    <div className="mx-auto flex min-h-dvh max-w-2xl flex-col px-4 pb-28 pt-5 sm:pb-8">
      <header className="mb-5 flex items-center gap-3">
        <span className="text-tape">
          <HoldIcon className="h-7 w-7" filled />
        </span>
        <h1 className="font-display text-2xl uppercase tracking-[0.18em]">Tracker</h1>
        <span className="ml-auto rounded-full border border-rock-700 px-3 py-1 text-xs font-semibold text-chalk-dim">
          Lvl {tracker.stats.level} · {tracker.stats.xp} XP
        </span>
        <SyncBadge tracker={tracker} />
      </header>

      {/* Desktop-Navigation */}
      <nav aria-label="Ansichten" className="mb-5 hidden gap-1 rounded-xl border border-rock-800 p-1 sm:flex">
        {TABS.map((t) => (
          <button
            key={t.id}
            type="button"
            onClick={() => setTab(t.id)}
            aria-current={tab === t.id ? 'page' : undefined}
            className={`flex-1 rounded-lg px-4 py-2 text-sm font-semibold transition ${
              tab === t.id ? 'bg-rock-800 text-chalk' : 'text-chalk-dim hover:text-chalk'
            }`}
          >
            {t.label}
          </button>
        ))}
      </nav>

      <main className="flex-1">
        {tab === 'week' && <WeekView tracker={tracker} />}
        {tab === 'food' && <NutritionView tracker={tracker} />}
        {tab === 'history' && <HistoryView tracker={tracker} />}
        {tab === 'badges' && <BadgesView tracker={tracker} />}
      </main>

      <footer className="mt-8 hidden text-center text-xs text-chalk-faint sm:block">
        Zwei Einheiten pro Woche, ein Spaziergang pro Werktag, jeden Tag sauber essen. Minimum
        zählt voll.
      </footer>

      {/* Mobile-Navigation */}
      <nav
        aria-label="Ansichten"
        className="fixed inset-x-0 bottom-0 z-40 border-t border-rock-800 bg-rock-950/95 px-3 pb-[env(safe-area-inset-bottom)] backdrop-blur sm:hidden"
      >
        <div className="mx-auto flex max-w-2xl">
          {TABS.map((t) => (
            <button
              key={t.id}
              type="button"
              onClick={() => setTab(t.id)}
              aria-current={tab === t.id ? 'page' : undefined}
              className={`flex-1 py-3.5 text-[13px] font-semibold transition ${
                tab === t.id ? 'text-chalk' : 'text-chalk-faint'
              }`}
            >
              <span
                aria-hidden="true"
                className="mx-auto mb-1 block h-0.5 w-8 rounded-full transition"
                style={{ background: tab === t.id ? 'var(--color-tape)' : 'transparent' }}
              />
              {t.short}
            </button>
          ))}
        </div>
      </nav>

      {tracker.toast && (
        <div
          role="status"
          className="animate-rise fixed inset-x-0 bottom-20 z-40 mx-auto w-fit rounded-full border border-rock-700 bg-rock-800 px-4 py-2 text-sm shadow-lg sm:bottom-6"
        >
          {tracker.toast}
        </div>
      )}

      {tracker.celebration && (
        <Celebration data={tracker.celebration} onClose={tracker.dismissCelebration} />
      )}
    </div>
  );
}
