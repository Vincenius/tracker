import 'package:flutter/material.dart';

import '../theme.dart';
import 'stats.dart';
import 'types.dart';

class Achievement {
  const Achievement({
    required this.id,
    required this.name,
    required this.desc,
    required this.color,
    required this.progress,
    required this.label,
    this.secret = false,
  });

  final String id;
  final String name;
  final String desc;
  final Color color;

  /// 0..1 – Fortschritt in Richtung Freischaltung
  final double Function(Stats) progress;
  final String Function(Stats) label;

  /// Überraschungs-Abzeichen: Name & Beschreibung erst nach dem Freischalten sichtbar
  final bool secret;
}

double _clamp(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);

/// Achievement, das bei `need` Zählern voll ist.
Achievement _counter(
  String id,
  String name,
  String desc,
  Color color,
  int need,
  String unit,
  int Function(Stats) pick, [
  bool secret = false,
]) {
  return Achievement(
    id: id,
    name: name,
    desc: desc,
    color: color,
    secret: secret,
    progress: (s) => _clamp(pick(s) / need),
    label: (s) => '${pick(s) < need ? pick(s) : need}/$need $unit',
  );
}

int _bestStreak(Stats s) =>
    s.currentStreak > s.longestStreak ? s.currentStreak : s.longestStreak;
int _bestWalkStreak(Stats s) =>
    s.walkStreak > s.longestWalkStreak ? s.walkStreak : s.longestWalkStreak;
int _bestCleanStreak(Stats s) =>
    s.cleanStreak > s.longestCleanStreak ? s.cleanStreak : s.longestCleanStreak;
int _bestLaneStreak(Stats s, TreatKind kind) {
  final lane = s.lanes[kind]!;
  return lane.cleanStreak > lane.longestCleanStreak
      ? lane.cleanStreak
      : lane.longestCleanStreak;
}

int _bestSweetsStreak(Stats s) => _bestLaneStreak(s, TreatKind.sweets);
int _bestDrinksStreak(Stats s) => _bestLaneStreak(s, TreatKind.drinks);

final badges = <Achievement>[
  _counter(
    'first-session',
    'Erstbegehung',
    'Die allererste Einheit ist abgehakt. Der Rest ist Wiederholung.',
    C.gradeYellow,
    1,
    'Einheit',
    (s) => s.total,
  ),
  _counter(
    'first-week',
    'Erster Zug',
    'Eine Woche mit 2 Einheiten geschafft.',
    C.gradeYellow,
    1,
    'Woche',
    (s) => s.fulfilledWeeks,
  ),
  _counter(
    'streak-4',
    'Vier am Stück',
    '4 Wochen in Folge das Wochenziel erreicht.',
    C.gradeGreen,
    4,
    'Wochen',
    _bestStreak,
  ),
  _counter(
    'fallback-week',
    'Plan B gemeistert',
    'Eine Woche ohne Bouldern mit einer Fallback-Einheit erfüllt.',
    C.gradePurple,
    1,
    'Woche',
    (s) => s.fallbackWeeks,
  ),
  _counter(
    'boulder-10',
    'Stammgast',
    '10× in der Halle gewesen. Die Griffe kennen dich.',
    C.gradeBlue,
    10,
    'Sessions',
    (s) => s.byType[SessionType.boulder]!,
  ),
  _counter(
    'sessions-25',
    'Fünfundzwanzig',
    '25 Einheiten insgesamt abgehakt.',
    C.gradeRed,
    25,
    'Einheiten',
    (s) => s.total,
  ),
  _counter(
    'streak-8',
    'Ausdauer',
    '8 Wochen in Folge das Wochenziel erreicht.',
    C.gradeGreen,
    8,
    'Wochen',
    _bestStreak,
  ),
  _counter('level-5', 'Level 5', '600 XP gesammelt.', C.tape, 600, 'XP', (s) => s.xp),

  // ——— Kreative Meilensteine ———
  _counter(
    'minimalist',
    'Der Minimalist',
    '5× die Minimum-Version gemacht. Angefangen schlägt aufgeschoben.',
    C.gradeBlue,
    5,
    'Minimum-Einheiten',
    (s) => s.minSessions,
  ),
  _counter(
    'clean-line',
    'Saubere Linie',
    '5× die komplette Übungsliste abgehakt — keine Übung ausgelassen.',
    C.chalk,
    5,
    'Einheiten',
    (s) => s.fullChecklists,
  ),
  _counter(
    'on-plan',
    'Nach Plan',
    'Montag Home, Mittwoch Halle — beides in derselben Woche, wie im Drehbuch.',
    C.gradeYellow,
    1,
    'Woche',
    (s) => s.onPlanWeeks,
  ),
  _counter(
    'bonus-round',
    'Zugabe',
    'Eine Woche mit 3 Einheiten. Ziel übertroffen.',
    C.tape,
    1,
    'Woche',
    (s) => s.bigWeeks,
  ),
  _counter(
    'pullup-club',
    'Stangentanz',
    '10 Fallback-Einheiten an der Klimmzugstange.',
    C.gradePurple,
    10,
    'Einheiten',
    (s) => s.byType[SessionType.fallback]!,
  ),
  _counter(
    'boulder-25',
    'Hausnummer',
    '25× bouldern. Das ist keine Phase mehr, das ist eine Gewohnheit.',
    C.gradeBlue,
    25,
    'Sessions',
    (s) => s.byType[SessionType.boulder]!,
  ),
  _counter(
    'half-year',
    'Halbjahr',
    '26 Wochen mit erreichtem Ziel — ein halbes Jahr Routine.',
    C.gradeGreen,
    26,
    'Wochen',
    (s) => s.fulfilledWeeks,
  ),
  _counter(
    'sessions-100',
    'Hundert',
    '100 Einheiten insgesamt. Respekt.',
    C.chalk,
    100,
    'Einheiten',
    (s) => s.total,
  ),
  _counter('level-10', 'Zehnter Grad', '1350 XP gesammelt. Level 10.', C.tape, 1350, 'XP',
      (s) => s.xp),

  // ——— Spaziergänge: Montag bis Freitag, einer pro Tag ———
  _counter(
    'walk-first',
    'Erster Schritt',
    'Der erste Spaziergang ist eingetragen. Tür auf, der Rest ergibt sich.',
    C.gradeGreen,
    1,
    'Spaziergang',
    (s) => s.walkTotal,
  ),
  _counter(
    'walk-week',
    'Von Montag bis Freitag',
    'Eine Woche mit fünf Spaziergängen an fünf Werktagen.',
    C.gradeGreen,
    1,
    'Woche',
    (s) => s.walkPerfectWeeks,
  ),
  _counter(
    'walk-streak-5',
    'Fünf Werktage',
    '5 Werktage in Folge spazieren. Das Wochenende zählt nicht dagegen.',
    C.gradeYellow,
    5,
    'Tage',
    _bestWalkStreak,
  ),
  _counter(
    'walk-25',
    'Feldweg',
    '25 Spaziergänge gesammelt.',
    C.gradeBlue,
    25,
    'Spaziergänge',
    (s) => s.walkTotal,
  ),
  _counter(
    'walk-perfect-4',
    'Volle Wochen',
    '4 Wochen mit allen fünf Spaziergängen.',
    C.gradeGreen,
    4,
    'Wochen',
    (s) => s.walkPerfectWeeks,
  ),
  _counter(
    'double-goal',
    'Doppelt geliefert',
    'Eine Woche mit Trainingsziel und allen fünf Spaziergängen.',
    C.gradeRed,
    1,
    'Woche',
    (s) => s.doubleGoalWeeks,
  ),
  _counter(
    'walk-streak-20',
    'Vier Wochen am Stück',
    '20 Werktage in Folge — einen ganzen Monat lang jeden Tag raus.',
    C.tape,
    20,
    'Tage',
    _bestWalkStreak,
  ),
  _counter(
    'walk-100',
    'Hundert Runden',
    '100 Spaziergänge. Die Nachbarschaft kennt dich.',
    C.chalk,
    100,
    'Spaziergänge',
    (s) => s.walkTotal,
  ),

  // ——— Treppe: jeder Aufstieg zählt, so oft du willst ———
  _counter(
    'stair-first',
    'Erste Stufen',
    'Einmal die Treppe statt des Aufzugs genommen. Der Anfang ist gemacht.',
    C.gradeYellow,
    1,
    'Aufstieg',
    (s) => s.stairTotal,
  ),
  _counter(
    'stair-day-5',
    'Treppenhaus-Tag',
    '5 Aufstiege an einem einzigen Tag.',
    C.tape,
    5,
    'Aufstiege',
    (s) => s.stairBestDay,
  ),
  _counter(
    'stair-50',
    'Etagenwechsel',
    '50 Aufstiege insgesamt. Der Aufzug wird langsam nervös.',
    C.gradeBlue,
    50,
    'Aufstiege',
    (s) => s.stairTotal,
  ),
  _counter(
    'stair-streak-7',
    'Woche im Treppenhaus',
    '7 Tage in Folge mindestens einmal die Treppe genommen.',
    C.gradeGreen,
    7,
    'Tage',
    (s) => s.longestStairStreak,
  ),
  _counter(
    'stair-250',
    'Hochhaus',
    '250 Aufstiege insgesamt. Der Aufzug kennt dich nicht mehr.',
    C.chalk,
    250,
    'Aufstiege',
    (s) => s.stairTotal,
  ),

  // ——— Ernährung: Punkte gibt es keine, saubere Tage zählen trotzdem ———
  _counter(
    'clean-7',
    'Sieben Tage sauber',
    '7 Tage in Folge nichts Süßes eingetragen. Der Reflex ist gebrochen.',
    C.mint,
    7,
    'Tage',
    _bestCleanStreak,
  ),
  _counter(
    'clean-week',
    'Saubere Woche',
    'Eine ganze Woche ohne einen einzigen Ausrutscher. Lückenlos.',
    C.gradeGreen,
    1,
    'Woche',
    (s) => s.cleanPerfectWeeks,
  ),
  _counter(
    'sweets-14',
    'Zwei Wochen ohne Riegel',
    '14 Tage in Folge ohne Schokolade, Kuchen oder Chips.',
    C.cocoa,
    14,
    'Tage',
    _bestSweetsStreak,
  ),
  _counter(
    'drinks-14',
    'Zwei Wochen nur Wasser',
    '14 Tage in Folge ohne zuckerhaltige Getränke.',
    C.mint,
    14,
    'Tage',
    _bestDrinksStreak,
  ),
  _counter(
    'clean-30',
    'Ein Monat sauber',
    '30 Tage in Folge ganz ohne Süßes. Einen ganzen Monat lang.',
    C.gradeYellow,
    30,
    'Tage',
    _bestCleanStreak,
  ),
  _counter(
    'clean-100',
    'Hundert saubere Tage',
    '100 Tage ohne einen Eintrag — nicht am Stück, aber gezählt.',
    C.chalk,
    100,
    'Tage',
    (s) => s.cleanDayTotal,
  ),
  _counter(
    'triple-goal',
    'Dreifach geliefert',
    'Eine Woche mit Trainingsziel, fünf Spaziergängen und ohne einen Ausrutscher. Das volle Programm.',
    C.gradeRed,
    1,
    'Woche',
    (s) => s.tripleGoalWeeks,
  ),

  // ——— Überraschungen: tauchen erst auf, wenn du sie hast ———
  _counter(
    'early-bird',
    'Morgengrauen',
    '3 Einheiten vor 9 Uhr. Erledigt, bevor der Tag Einwände hat.',
    C.gradeYellow,
    3,
    'Einheiten',
    (s) => s.earlyBird,
    true,
  ),
  _counter(
    'night-owl',
    'Nachtschicht',
    '3 Einheiten ab 21 Uhr. Spät, aber gemacht.',
    C.gradePurple,
    3,
    'Einheiten',
    (s) => s.nightOwl,
    true,
  ),
  _counter(
    'weekend-project',
    'Wochenend-Projekt',
    '5 Einheiten an einem Samstag oder Sonntag.',
    C.gradeBlue,
    5,
    'Einheiten',
    (s) => s.weekendSessions,
    true,
  ),
  _counter(
    'anyway',
    'Trotzdem',
    'Eine Woche komplett im Minimum erfüllt. Genau dafür gibt es das Minimum.',
    C.gradeGreen,
    1,
    'Woche',
    (s) => s.allMinWeeks,
    true,
  ),
  _counter(
    'walk-extra',
    'Extrarunde',
    '5 Spaziergänge am Wochenende. Zählt nicht fürs Ziel — schön war es trotzdem.',
    C.gradePurple,
    5,
    'Spaziergänge',
    (s) => s.weekendWalks,
    true,
  ),
  _counter(
    'stair-day-10',
    'Wolkenkratzer',
    '10 Aufstiege an einem Tag. Wo willst du eigentlich hin?',
    C.gradeRed,
    10,
    'Aufstiege',
    (s) => s.stairBestDay,
    true,
  ),
  _counter(
    'clean-comeback',
    'Neu angesetzt',
    'Nach einem Ausrutscher wieder 7 Tage in Folge sauber. Eine Serie zu verlieren ist kein Grund aufzuhören.',
    C.mint,
    1,
    'Serie',
    (s) => s.cleanComebacks,
    true,
  ),
  _counter(
    'honest',
    'Ehrlich gemacht',
    'Den ersten Ausrutscher eingetragen, statt ihn zu verschweigen. Genau dafür ist der Knopf da.',
    C.cocoa,
    1,
    'Eintrag',
    (s) => s.treatTotal,
    true,
  ),
  _counter(
    'comeback',
    'Wiedereinstieg',
    'Nach mindestens 2 Wochen Pause wieder eine volle Woche geschafft. Das zählt doppelt.',
    C.gradeRed,
    1,
    'Woche',
    (s) => s.comebacks,
    true,
  ),
];

List<String> unlockedBadges(Stats stats) =>
    [for (final b in badges) if (b.progress(stats) >= 1) b.id];
