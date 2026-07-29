import { useEffect, useRef } from 'react';
import type { Celebration as CelebrationData } from '../lib/store';
import { HoldIcon } from './HoldIcon';

export function Celebration({
  data,
  onClose,
}: {
  data: CelebrationData;
  onClose: () => void;
}) {
  const btn = useRef<HTMLButtonElement>(null);

  useEffect(() => {
    btn.current?.focus();
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose();
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [onClose]);

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-label="Neuer Meilenstein"
      className="animate-fade fixed inset-0 z-50 grid place-items-center bg-rock-950/85 p-6 backdrop-blur-sm"
      onClick={onClose}
    >
      <div
        className="animate-pop chalk-dust w-full max-w-sm rounded-3xl border border-rock-700 bg-rock-900 p-6 text-center"
        onClick={(e) => e.stopPropagation()}
      >
        {data.level && (
          <>
            <p className="text-xs uppercase tracking-[0.3em] text-tape">Level up</p>
            <p className="font-display text-7xl leading-none">{data.level}</p>
            <p className="mt-2 text-sm text-chalk-dim">
              100 XP weiter oben. Der nächste Griff wartet schon.
            </p>
          </>
        )}

        {data.badges.length > 0 && (
          <div className={data.level ? 'mt-6 border-t border-rock-800 pt-5' : ''}>
            <p className="text-xs uppercase tracking-[0.3em] text-chalk-faint">
              {data.badges.length > 1 ? 'Neue Abzeichen' : 'Neues Abzeichen'}
            </p>
            <ul className="mt-3 space-y-3">
              {data.badges.map((b) => (
                <li key={b.id} className="flex items-center gap-3 text-left">
                  <span style={{ color: b.color }}>
                    <HoldIcon className="h-10 w-10" filled />
                  </span>
                  <span>
                    <span className="block font-display text-lg uppercase leading-none">
                      {b.name}
                    </span>
                    <span className="block text-sm text-chalk-dim">{b.desc}</span>
                  </span>
                </li>
              ))}
            </ul>
          </div>
        )}

        <button
          ref={btn}
          type="button"
          onClick={onClose}
          className="mt-6 w-full rounded-xl bg-chalk px-4 py-3 font-semibold text-rock-950 transition hover:bg-white"
        >
          Weiter
        </button>
      </div>
    </div>
  );
}
