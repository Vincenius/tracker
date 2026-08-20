import { weekKeyOf } from './date';
import type { CheatDay } from './types';

/**
 * Cheat Day: ein selbst gewählter Tag, an dem die Ernährung übersprungen wird
 * — wie ein Pausentag, nur bewusst gesetzt. Er bricht keine Serie, zählt aber
 * auch nicht als sauberer Tag und bringt keine XP. Einer pro Woche.
 */
export const CHEAT_PER_WEEK = 1;

export interface CheatInfo {
  /** Alle gültigen Cheat-Tage als ISO-Daten */
  dates: Set<string>;
  /** Der gültige Cheat-Tag je Woche: Wochen-Key → ISO-Datum */
  byWeek: Map<string, string>;
}

/**
 * Pro Woche zählt genau ein Cheat Day. Zwei Geräte können offline denselben
 * Zeitraum markieren — beim Mergen bleiben beide Einträge erhalten. Damit
 * überall dieselbe Rechnung herauskommt, gewinnt der älteste Eintrag der
 * Woche; bei gleichem Zeitstempel entscheidet die ID.
 */
export function cheatInfo(days: CheatDay[]): CheatInfo {
  const winners = new Map<string, CheatDay>();
  for (const day of days) {
    const key = weekKeyOf(day.date);
    const held = winners.get(key);
    if (!held || day.ts < held.ts || (day.ts === held.ts && day.id < held.id)) {
      winners.set(key, day);
    }
  }
  const byWeek = new Map<string, string>();
  const dates = new Set<string>();
  for (const [key, day] of winners) {
    byWeek.set(key, day.date);
    dates.add(day.date);
  }
  return { dates, byWeek };
}
