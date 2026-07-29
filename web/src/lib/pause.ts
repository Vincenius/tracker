import { addDays } from './date';
import type { PauseEvent } from './types';

/**
 * Pausenmodus: pausierte Tage brechen keine Streaks — sie werden übersprungen,
 * als gäbe es sie nicht. Was trotzdem eingetragen wird, zählt ganz normal.
 */

/** Das jüngste Ereignis entscheidet: 'start' heißt aktiv. */
export function isPauseActive(events: PauseEvent[]): boolean {
  let active = false;
  for (const e of [...events].sort((a, b) => a.ts - b.ts)) active = e.action === 'start';
  return active;
}

export interface PauseInfo {
  /** Alle pausierten ISO-Tage, inklusive Start- und Stop-Tag. */
  paused: Set<string>;
  /** Startdatum der offenen Pause — null, wenn keine läuft. */
  activeSince: string | null;
}

export function pauseInfo(events: PauseEvent[], today: string): PauseInfo {
  const paused = new Set<string>();
  let openSince: string | null = null;
  for (const e of [...events].sort((a, b) => a.ts - b.ts)) {
    if (e.action === 'start') {
      openSince ??= e.date;
    } else if (openSince) {
      addRange(paused, openSince, e.date < today ? e.date : today);
      openSince = null;
    }
  }
  if (openSince) addRange(paused, openSince, today);
  return { paused, activeSince: openSince };
}

/** Auch der Stop-Tag zählt als pausiert — großzügig, der Rückreisetag bricht nichts. */
function addRange(into: Set<string>, from: string, to: string): void {
  let d = from;
  let guard = 0;
  while (d <= to && guard++ < 1500) {
    into.add(d);
    d = addDays(d, 1);
  }
}
