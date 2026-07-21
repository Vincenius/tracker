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
const COCOA = 'var(--color-cocoa)';
const MINT = 'var(--color-mint)';

const bestStreak = (s: Stats) => Math.max(s.currentStreak, s.longestStreak);
const bestWalkStreak = (s: Stats) => Math.max(s.walkStreak, s.longestWalkStreak);
const bestSnackStreak = (s: Stats) => s.lanes.snacks.longestStreak;
const bestDrinkStreak = (s: Stats) => s.lanes.drinks.longestStreak;
const bestBothStreak = (s: Stats) => s.longestCleanBothStreak;

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
  counter('level-5', 'Level 5', '600 XP gesammelt.', TAPE, 600, 'XP', (s) => s.xp),

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
  counter('level-10', 'Zehnter Grad', '1350 XP gesammelt. Level 10.', TAPE, 1350, 'XP', (s) => s.xp),

  // ——— Spaziergänge: Montag bis Freitag, einer pro Tag ———
  counter(
    'walk-first',
    'Erster Schritt',
    'Der erste Spaziergang ist eingetragen. Tür auf, der Rest ergibt sich.',
    GREEN,
    1,
    'Spaziergang',
    (s) => s.walkTotal,
  ),
  counter(
    'walk-week',
    'Von Montag bis Freitag',
    'Eine Woche mit fünf Spaziergängen an fünf Werktagen.',
    GREEN,
    1,
    'Woche',
    (s) => s.walkPerfectWeeks,
  ),
  counter(
    'walk-streak-5',
    'Fünf Werktage',
    '5 Werktage in Folge spazieren. Das Wochenende zählt nicht dagegen.',
    YELLOW,
    5,
    'Tage',
    bestWalkStreak,
  ),
  counter(
    'walk-25',
    'Feldweg',
    '25 Spaziergänge gesammelt.',
    BLUE,
    25,
    'Spaziergänge',
    (s) => s.walkTotal,
  ),
  counter(
    'walk-perfect-4',
    'Volle Wochen',
    '4 Wochen mit allen fünf Spaziergängen.',
    GREEN,
    4,
    'Wochen',
    (s) => s.walkPerfectWeeks,
  ),
  counter(
    'double-goal',
    'Doppelt geliefert',
    'Eine Woche mit Trainingsziel und allen fünf Spaziergängen.',
    RED,
    1,
    'Woche',
    (s) => s.doubleGoalWeeks,
  ),
  counter(
    'walk-streak-20',
    'Vier Wochen am Stück',
    '20 Werktage in Folge — einen ganzen Monat lang jeden Tag raus.',
    TAPE,
    20,
    'Tage',
    bestWalkStreak,
  ),
  counter(
    'walk-100',
    'Hundert Runden',
    '100 Spaziergänge. Die Nachbarschaft kennt dich.',
    CHALK,
    100,
    'Spaziergänge',
    (s) => s.walkTotal,
  ),

  // ——— Ernährung: jeder saubere Tag zählt, jede Serie zählt mehr ———
  counter(
    'clean-first',
    'Erster sauberer Tag',
    'Ein Tag ohne Schokolade, Chips oder Zuckergetränke ist eingetragen.',
    COCOA,
    1,
    'Tag',
    (s) => s.cleanAnyDays,
  ),
  counter(
    'snack-7',
    'Sieben ohne Süßes',
    '7 Tage in Folge ohne Schokolade und Chips. Der Reflex ist gebrochen.',
    COCOA,
    7,
    'Tage',
    bestSnackStreak,
  ),
  counter(
    'drink-7',
    'Sieben ohne Zucker',
    '7 Tage in Folge ohne zuckerhaltige Getränke. Wasser kann auch schmecken.',
    MINT,
    7,
    'Tage',
    bestDrinkStreak,
  ),
  counter(
    'clean-week',
    'Saubere Woche',
    'Eine Woche mit sieben Tagen in beiden Spuren. Lückenlos.',
    GREEN,
    1,
    'Woche',
    (s) => s.cleanPerfectWeeks,
  ),
  counter(
    'both-14',
    'Zwei Wochen doppelt',
    '14 Tage in Folge, an denen beide Spuren sauber waren.',
    YELLOW,
    14,
    'Tage',
    bestBothStreak,
  ),
  counter(
    'snack-30',
    'Ein Monat ohne Riegel',
    '30 Tage in Folge ohne Schokolade und Chips.',
    COCOA,
    30,
    'Tage',
    bestSnackStreak,
  ),
  counter(
    'drink-30',
    'Ein Monat nur Wasser',
    '30 Tage in Folge ohne Zuckergetränke.',
    MINT,
    30,
    'Tage',
    bestDrinkStreak,
  ),
  counter(
    'clean-100',
    'Hundert saubere Tage',
    '100 Tage, an denen beide Spuren sauber waren.',
    CHALK,
    100,
    'Tage',
    (s) => s.cleanBothDays,
  ),
  counter(
    'triple-goal',
    'Dreifach geliefert',
    'Eine Woche mit Trainingsziel, fünf Spaziergängen und sieben sauberen Tagen. Das volle Programm.',
    RED,
    1,
    'Woche',
    (s) => s.tripleGoalWeeks,
  ),

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
    'walk-extra',
    'Extrarunde',
    '5 Spaziergänge am Wochenende. Zählt nicht fürs Ziel — schön war es trotzdem.',
    PURPLE,
    5,
    'Spaziergänge',
    (s) => s.weekendWalks,
    true,
  ),

  counter(
    'clean-comeback',
    'Neu angesetzt',
    'Nach einem Ausrutscher wieder 7 Tage in Folge sauber. Eine Serie zu verlieren ist kein Grund aufzuhören.',
    MINT,
    1,
    'Serie',
    (s) => s.cleanComebacks,
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
