/** Alle Wochen laufen Montag–Sonntag. Wochen-Key = ISO-Datum des Montags. */

export function toISODate(d: Date): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

export function fromISODate(iso: string): Date {
  const [y, m, d] = iso.split('-').map(Number);
  return new Date(y, m - 1, d);
}

export function startOfWeek(d: Date): Date {
  const c = new Date(d.getFullYear(), d.getMonth(), d.getDate());
  const dow = (c.getDay() + 6) % 7; // Mo = 0
  c.setDate(c.getDate() - dow);
  return c;
}

export function addDays(dateIso: string, n: number): string {
  const d = fromISODate(dateIso);
  d.setDate(d.getDate() + n);
  return toISODate(d);
}

/** Montag–Freitag. Spaziergänge zielen nur auf diese Tage. */
export function isWeekday(dateIso: string): boolean {
  const dow = fromISODate(dateIso).getDay();
  return dow >= 1 && dow <= 5;
}

/** Der vorherige Werktag — das Wochenende wird übersprungen, nicht gewertet. */
export function prevWeekday(dateIso: string): string {
  let d = addDays(dateIso, -1);
  while (!isWeekday(d)) d = addDays(d, -1);
  return d;
}

export function weekKeyOf(dateIso: string): string {
  return toISODate(startOfWeek(fromISODate(dateIso)));
}

export function currentWeekKey(now = new Date()): string {
  return toISODate(startOfWeek(now));
}

export function addWeeks(weekKey: string, n: number): string {
  const d = fromISODate(weekKey);
  d.setDate(d.getDate() + n * 7);
  return toISODate(d);
}

export function weekRangeLabel(weekKey: string): string {
  const mo = fromISODate(weekKey);
  const so = new Date(mo);
  so.setDate(so.getDate() + 6);
  const f = new Intl.DateTimeFormat('de-DE', { day: 'numeric', month: 'short' });
  return `${f.format(mo)} – ${f.format(so)}`;
}

export function weekNumber(weekKey: string): number {
  // ISO-Kalenderwoche des Montags
  const d = fromISODate(weekKey);
  const target = new Date(d.getFullYear(), d.getMonth(), d.getDate());
  target.setDate(target.getDate() + 3); // Donnerstag der Woche
  const firstThursday = new Date(target.getFullYear(), 0, 4);
  firstThursday.setDate(firstThursday.getDate() + ((11 - firstThursday.getDay()) % 7) - 3);
  return 1 + Math.round((target.getTime() - firstThursday.getTime()) / (7 * 86400000));
}

export function weekdayLabel(dateIso: string): string {
  return new Intl.DateTimeFormat('de-DE', { weekday: 'long' }).format(fromISODate(dateIso));
}

export function shortDate(dateIso: string): string {
  return new Intl.DateTimeFormat('de-DE', { day: '2-digit', month: '2-digit' }).format(
    fromISODate(dateIso),
  );
}

export function weeksBetween(fromKey: string, toKey: string): string[] {
  const out: string[] = [];
  let k = fromKey;
  let guard = 0;
  while (k <= toKey && guard++ < 2000) {
    out.push(k);
    k = addWeeks(k, 1);
  }
  return out;
}
