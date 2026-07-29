import { BADGES } from '../lib/badges';
import type { Tracker } from '../lib/store';
import { HoldIcon } from './HoldIcon';

export function BadgesView({ tracker }: { tracker: Tracker }) {
  const { stats } = tracker;
  const items = BADGES.map((b) => ({ badge: b, progress: b.progress(stats) })).sort((a, b) => {
    const done = Number(b.progress >= 1) - Number(a.progress >= 1);
    if (done) return done;
    const secret = Number(!!a.badge.secret) - Number(!!b.badge.secret);
    if (secret) return secret;
    return b.progress - a.progress;
  });
  const unlocked = items.filter((i) => i.progress >= 1);
  const hiddenSecrets = items.filter((i) => i.badge.secret && i.progress < 1).length;

  return (
    <div className="space-y-4">
      <section className="chalk-edge rounded-2xl border border-rock-700 bg-rock-900/80 p-4">
        <h2 className="font-display text-xl uppercase">Abzeichen</h2>
        <p className="mt-1 text-sm text-chalk-dim">
          {unlocked.length} von {BADGES.length} freigeschaltet. Kein Ablaufdatum — alles bleibt dir.
          {hiddenSecrets > 0 && (
            <>
              {' '}
              <span className="text-chalk-faint">
                {hiddenSecrets} {hiddenSecrets === 1 ? 'Überraschung wartet' : 'Überraschungen warten'} noch.
              </span>
            </>
          )}
        </p>
      </section>

      <ul className="grid gap-3 sm:grid-cols-2">
        {items.map(({ badge, progress }) => {
          const done = progress >= 1;
          const veiled = !!badge.secret && !done;
          return (
            <li
              key={badge.id}
              className="chalk-edge relative overflow-hidden rounded-2xl border bg-rock-900/80 p-4"
              style={{ borderColor: done ? badge.color : 'var(--color-rock-800)' }}
            >
              <div className="flex items-start gap-3">
                <span
                  className="shrink-0"
                  style={{ color: done ? badge.color : 'var(--color-rock-600)' }}
                >
                  <HoldIcon className="h-9 w-9" filled={done} />
                </span>
                <div className="min-w-0 flex-1">
                  <h3
                    className="font-display text-lg uppercase leading-none"
                    style={{ color: done ? 'var(--color-chalk)' : 'var(--color-chalk-dim)' }}
                  >
                    {veiled ? 'Überraschung' : badge.name}
                  </h3>
                  <p className="mt-1 text-sm text-chalk-dim">
                    {veiled ? 'Taucht auf, sobald du sie dir verdient hast.' : badge.desc}
                  </p>
                  {!veiled && (
                    <div className="mt-2.5 h-1.5 overflow-hidden rounded-full bg-rock-800">
                      <div
                        className="h-full rounded-full transition-[width] duration-500"
                        style={{
                          width: `${progress * 100}%`,
                          background: done ? badge.color : 'var(--color-rock-500)',
                        }}
                      />
                    </div>
                  )}
                  <p className="mt-1.5 text-xs text-chalk-faint">
                    {veiled ? '???' : done ? 'Freigeschaltet ✓' : badge.label(stats)}
                  </p>
                </div>
              </div>
            </li>
          );
        })}
      </ul>
    </div>
  );
}
