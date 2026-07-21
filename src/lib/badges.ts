import type { Stats } from './stats';

export interface Badge {
  id: string;
  name: string;
  desc: string;
  color: string;
  /** 0..1 – Fortschritt in Richtung Freischaltung */
  progress: (s: Stats) => number;
  label: (s: Stats) => string;
  /** Überraschungs-Abzeichen: Name & Beschreibung erst nach dem Freischalten sichtbar */
  secret?: boolean;
}

const clamp = (v: number) => Math.max(0, Math.min(1, v));

/** Badge, das bei `need` Zählern voll ist. */
function counter(
  id: string,
  name: string,
  desc: string,
  color: string,
  need: number,
  unit: string,
  pick: (s: Stats) => number,
  secret = false,
): Badge {
  return {
    id,
    name,
    desc,
    color,
    secret,
    progress: (s) => clamp(pick(s) / need),
    label: (s) => `${Math.min(pick(s), need)}/${need} ${unit}`,
  };
}

const YELLOW = 'var(--color-grade-yellow)';
const GREEN = 'var(--color-grade-green)';
const BLUE = 'var(--color-grade-blue)';
const RED = 'var(--color-grade-red)';
const PURPLE = 'var(--color-grade-purple)';
const TAPE = 'var(--color-tape)';
const CHALK = 'var(--color-chalk)';

const bestStreak = (s: Stats) => Math.max(s.currentStreak, s.longestStreak);

export const BADGES: Badge[] = [
  counter(
    'first-session',
    'Erstbegehung',
    'Die allererste Einheit ist abgehakt. Der Rest ist Wiederholung.',
    YELLOW,
    1,
    'Einheit',
    (s) => s.total,
  ),
  counter(
    'first-week',
    'Erster Zug',
    'Eine Woche mit 2 Einheiten geschafft.',
    YELLOW,
    1,
    'Woche',
    (s) => s.fulfilledWeeks,
  ),
  counter(
    'streak-4',
    'Vier am Stück',
    '4 Wochen in Folge das Wochenziel erreicht.',
    GREEN,
    4,
    'Wochen',
    bestStreak,
  ),
  counter(
    'fallback-week',
    'Plan B gemeistert',
    'Eine Woche ohne Bouldern mit einer Fallback-Einheit erfüllt.',
    PURPLE,
    1,
    'Woche',
    (s) => s.fallbackWeeks,
  ),
  counter(
    'boulder-10',
    'Stammgast',
    '10× in der Halle gewesen. Die Griffe kennen dich.',
    BLUE,
    10,
    'Sessions',
    (s) => s.byType.boulder,
  ),
  counter(
    'sessions-25',
    'Fünfundzwanzig',
    '25 Einheiten insgesamt abgehakt.',
    RED,
    25,
    'Einheiten',
    (s) => s.total,
  ),
  counter(
    'streak-8',
    'Ausdauer',
    '8 Wochen in Folge das Wochenziel erreicht.',
    GREEN,
    8,
    'Wochen',
    bestStreak,
  ),
  counter('level-5', 'Level 5', '400 XP gesammelt.', TAPE, 400, 'XP', (s) => s.xp),

  // ——— Kreative Meilensteine ———
  counter(
    'minimalist',
    'Der Minimalist',
    '5× die Minimum-Version gemacht. Angefangen schlägt aufgeschoben.',
    BLUE,
    5,
    'Minimum-Einheiten',
    (s) => s.minSessions,
  ),
  counter(
    'clean-line',
    'Saubere Linie',
    '5× die komplette Übungsliste abgehakt — keine Übung ausgelassen.',
    CHALK,
    5,
    'Einheiten',
    (s) => s.fullChecklists,
  ),
  counter(
    'on-plan',
    'Nach Plan',
    'Montag Home, Mittwoch Halle — beides in derselben Woche, wie im Drehbuch.',
    YELLOW,
    1,
    'Woche',
    (s) => s.onPlanWeeks,
  ),
  counter(
    'bonus-round',
    'Zugabe',
    'Eine Woche mit 3 Einheiten. Ziel übertroffen.',
    TAPE,
    1,
    'Woche',
    (s) => s.bigWeeks,
  ),
  counter(
    'pullup-club',
    'Stangentanz',
    '10 Fallback-Einheiten an der Klimmzugstange.',
    PURPLE,
    10,
    'Einheiten',
    (s) => s.byType.fallback,
  ),
  counter(
    'boulder-25',
    'Hausnummer',
    '25× bouldern. Das ist keine Phase mehr, das ist eine Gewohnheit.',
    BLUE,
    25,
    'Sessions',
    (s) => s.byType.boulder,
  ),
  counter(
    'half-year',
    'Halbjahr',
    '26 Wochen mit erreichtem Ziel — ein halbes Jahr Routine.',
    GREEN,
    26,
    'Wochen',
    (s) => s.fulfilledWeeks,
  ),
  counter(
    'sessions-100',
    'Hundert',
    '100 Einheiten insgesamt. Respekt.',
    CHALK,
    100,
    'Einheiten',
    (s) => s.total,
  ),
  counter('level-10', 'Zehnter Grad', '900 XP gesammelt. Level 10.', TAPE, 900, 'XP', (s) => s.xp),

  // ——— Überraschungen: tauchen erst auf, wenn du sie hast ———
  counter(
    'early-bird',
    'Morgengrauen',
    '3 Einheiten vor 9 Uhr. Erledigt, bevor der Tag Einwände hat.',
    YELLOW,
    3,
    'Einheiten',
    (s) => s.earlyBird,
    true,
  ),
  counter(
    'night-owl',
    'Nachtschicht',
    '3 Einheiten ab 21 Uhr. Spät, aber gemacht.',
    PURPLE,
    3,
    'Einheiten',
    (s) => s.nightOwl,
    true,
  ),
  counter(
    'weekend-project',
    'Wochenend-Projekt',
    '5 Einheiten an einem Samstag oder Sonntag.',
    BLUE,
    5,
    'Einheiten',
    (s) => s.weekendSessions,
    true,
  ),
  counter(
    'anyway',
    'Trotzdem',
    'Eine Woche komplett im Minimum erfüllt. Genau dafür gibt es das Minimum.',
    GREEN,
    1,
    'Woche',
    (s) => s.allMinWeeks,
    true,
  ),
  counter(
    'comeback',
    'Wiedereinstieg',
    'Nach mindestens 2 Wochen Pause wieder eine volle Woche geschafft. Das zählt doppelt.',
    RED,
    1,
    'Woche',
    (s) => s.comebacks,
    true,
  ),
];

export function unlockedBadges(stats: Stats): string[] {
  return BADGES.filter((b) => b.progress(stats) >= 1).map((b) => b.id);
}
