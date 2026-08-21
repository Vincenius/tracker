import 'package:flutter_test/flutter_test.dart';
import 'package:tracker_app/core/date.dart';
import 'package:tracker_app/core/merge.dart';
import 'package:tracker_app/core/stats.dart';
import 'package:tracker_app/core/storage.dart';
import 'package:tracker_app/core/types.dart';

/// Der Port muss dieselben Zahlen liefern wie web/src/lib — sonst zeigen App
/// und Web für dieselben Daten unterschiedliche Level.

Session _session(String date, SessionType type, [Intensity i = Intensity.full]) =>
    Session(
      id: '$date-${type.name}-${i.name}',
      type: type,
      intensity: i,
      date: date,
      ts: fromISODate(date).millisecondsSinceEpoch,
    );

Walk _walk(String date) =>
    Walk(id: 'w-$date', date: date, ts: fromISODate(date).millisecondsSinceEpoch);

Treat _treat(String date, TreatKind kind, [int n = 0]) => Treat(
      id: 't-$date-${kind.name}-$n',
      date: date,
      kind: kind,
      ts: fromISODate(date).millisecondsSinceEpoch + n,
    );

void main() {
  group('date', () {
    test('Wochen laufen Montag bis Sonntag', () {
      expect(weekKeyOf('2026-07-29'), '2026-07-27'); // Mittwoch -> Montag
      expect(weekKeyOf('2026-07-27'), '2026-07-27');
      expect(weekKeyOf('2026-08-02'), '2026-07-27'); // Sonntag gehört noch dazu
    });

    test('addDays überspringt keinen Kalendertag über die Zeitumstellung', () {
      expect(addDays('2026-03-28', 1), '2026-03-29'); // DST-Wechsel in Europa
      expect(addDays('2026-10-24', 1), '2026-10-25');
      expect(addDays('2026-12-31', 1), '2027-01-01');
      expect(addDays('2026-01-01', -1), '2025-12-31');
    });

    test('prevWeekday überspringt das Wochenende', () {
      expect(prevWeekday('2026-07-27'), '2026-07-24'); // Mo -> Fr
      expect(isWeekday('2026-08-01'), isFalse); // Samstag
    });

    // Achtung: der Anker in weekNumber ist schon im Web um einen Tag daneben
    // (Jan 5 statt dem ersten Donnerstag), die KW liegt dadurch um eins zu
    // niedrig. Der Port bildet das bewusst 1:1 ab — App und Web müssen
    // dieselbe KW anzeigen. Wird es im Web korrigiert, hier mitziehen.
    test('Kalenderwoche stimmt mit web/src/lib/date.ts überein', () {
      expect(weekNumber('2026-07-27'), 30);
      expect(weekNumber('2026-01-05'), 1);
      expect(weekNumber('2025-12-29'), 0);
      expect(weekNumber('2026-02-16'), 7);
    });
  });

  group('stats', () {
    final now = fromISODate('2026-07-29'); // Mittwoch

    test('zwei Einheiten erfüllen die Woche', () {
      final s = computeStats(
        [
          _session('2026-07-27', SessionType.home),
          _session('2026-07-29', SessionType.boulder),
        ],
        const [],
        const [],
        const [],
        const [],
        now,
      );
      expect(s.weeks['2026-07-27']!.fulfilled, isTrue);
      expect(s.currentStreak, 1);
      // 14 (home full) + 20 (boulder) = 34
      expect(s.xp, 34);
      expect(s.level, 1);
      expect(s.onPlanWeeks, 1); // Montag Home, Mittwoch Halle
    });

    test('Süßes kostet XP, mehrfach am Tag', () {
      final s = computeStats(
        [_session('2026-07-27', SessionType.boulder)], // 20 XP
        const [],
        [
          _treat('2026-07-28', TreatKind.sweets, 1),
          _treat('2026-07-28', TreatKind.sweets, 2),
          _treat('2026-07-29', TreatKind.drinks, 1),
        ],
        const [],
        const [],
        now,
      );
      expect(s.treatTotal, 3);
      expect(s.treatToday, 1);
      expect(s.treatWorstDay, 2);
      expect(s.lanes[TreatKind.sweets]!.total, 2);
      expect(s.lanes[TreatKind.sweets]!.worstDay, 2);
      expect(s.lanes[TreatKind.drinks]!.today, 1);
      expect(s.treatXpLost, 3 * xpTreat);
      expect(s.xp, 20 - 3 * xpTreat);
    });

    test('das XP-Konto fällt nicht unter null', () {
      final s = computeStats(
        const [],
        const [],
        [for (var i = 0; i < 4; i++) _treat('2026-07-29', TreatKind.sweets, i)],
        const [],
        const [],
        now,
      );
      expect(s.xp, 0);
      expect(s.level, 1);
    });

    test('saubere Tage sind Tage ohne Eintrag — ab dem ersten getrackten Tag', () {
      // Erster Eintrag am Montag, danach nichts mehr: Mo–Mi sind sauber.
      final s = computeStats(
        [_session('2026-07-27', SessionType.home)],
        const [],
        const [],
        const [],
        const [],
        now, // Mittwoch
      );
      expect(s.trackedSince, '2026-07-27');
      expect(s.cleanStreak, 3);
      expect(s.cleanDayTotal, 3);
      // Die Woche läuft noch — 3 von 7 Tagen sind bisher sauber.
      expect(s.weeks['2026-07-27']!.cleanDays, 3);
      expect(s.weeks['2026-07-27']!.cleanPerfect, isFalse);
    });

    test('ein Eintrag bricht die saubere Serie, danach zählt sie neu', () {
      final s = computeStats(
        [_session('2026-07-20', SessionType.home)],
        const [],
        [_treat('2026-07-28', TreatKind.drinks)],
        const [],
        const [],
        now, // Mittwoch, 2026-07-29
      );
      expect(s.cleanStreak, 1); // nur der heutige Mittwoch
      expect(s.longestCleanStreak, 8); // 20.–27. Juli
      expect(s.lanes[TreatKind.sweets]!.cleanStreak, 10); // andere Spur läuft weiter
    });

    test('eine Woche ohne Eintrag ist eine saubere Woche', () {
      final s = computeStats(
        [_session('2026-07-20', SessionType.home)],
        const [],
        [_treat('2026-07-29', TreatKind.sweets)],
        const [],
        const [],
        fromISODate('2026-08-02'), // Sonntag
      );
      // Vorwoche (20.–26.) komplett sauber, laufende Woche hat einen Eintrag.
      expect(s.weeks['2026-07-20']!.cleanPerfect, isTrue);
      expect(s.weeks['2026-07-27']!.cleanPerfect, isFalse);
      expect(s.cleanPerfectWeeks, 1);
    });

    test('pausierte Tage zählen weder als sauber noch als Bruch', () {
      final pauses = [
        const PauseEvent(id: 'p1', date: '2026-07-28', ts: 1, action: PauseAction.start),
        const PauseEvent(id: 'p2', date: '2026-07-28', ts: 2, action: PauseAction.stop),
      ];
      final s = computeStats(
        [_session('2026-07-27', SessionType.home)],
        const [],
        [_treat('2026-07-28', TreatKind.sweets)], // fällt in die Pause
        const [],
        pauses,
        now,
      );
      // Montag und Mittwoch sind sauber, der pausierte Dienstag bricht nichts.
      expect(s.cleanStreak, 2);
      expect(s.cleanDayTotal, 2);
      // XP kostet der Eintrag trotzdem.
      expect(s.treatXpLost, xpTreat);
    });

    test('Pausenmodus friert die Spaziergangsserie ein', () {
      final pauses = [
        const PauseEvent(id: 'p1', date: '2026-07-27', ts: 1, action: PauseAction.start),
      ];
      final s = computeStats(
        const [],
        [_walk('2026-07-23'), _walk('2026-07-24')], // Do + Fr der Vorwoche
        const [],
        const [],
        pauses,
        now,
      );
      expect(s.pauseActive, isTrue);
      expect(s.pausedSince, '2026-07-27');
      // Mo–Mi sind pausiert, die Serie reicht durch bis Donnerstag der Vorwoche.
      expect(s.walkStreak, 2);
    });

    test('Treppe zählt jeden Aufstieg', () {
      final s = computeStats(
        const [],
        const [],
        const [],
        [
          for (var i = 0; i < 3; i++)
            Stair(id: 's$i', date: '2026-07-29', ts: 1000 + i),
        ],
        const [],
        now,
      );
      expect(s.stairTotal, 3);
      expect(s.stairToday, 3);
      expect(s.stairBestDay, 3);
      expect(s.xp, 3 * xpStair);
    });

    test('leere Daten liefern Level 1 und keine saubere Serie', () {
      final s = computeStats(
        const [],
        const [],
        const [],
        const [],
        const [],
        now,
      );
      expect(s.level, 1);
      expect(s.xp, 0);
      expect(s.stairBestDay, 0);
      expect(s.currentStreak, 0);
      // Ohne einen einzigen Eintrag gibt es keinen Trackingstart — und damit
      // auch keine rückwirkend saubere Vergangenheit.
      expect(s.trackedSince, isNull);
      expect(s.cleanStreak, 0);
      expect(s.cleanDayTotal, 0);
    });
  });

  group('merge', () {
    test('Vereinigung, Tombstones gewinnen', () {
      final a = AppData(sessions: [_session('2026-07-27', SessionType.home)]);
      final b = AppData(
        sessions: [_session('2026-07-29', SessionType.boulder)],
        deleted: const ['2026-07-27-home-full'],
      );
      final merged = mergeData(a, b);
      expect(merged.sessions.length, 1);
      expect(merged.sessions.single.type, SessionType.boulder);
      expect(merged.deleted, contains('2026-07-27-home-full'));
    });

    test('sameData erkennt identische Stände', () {
      final a = AppData(walks: [_walk('2026-07-29')]);
      final b = AppData(walks: [_walk('2026-07-29')]);
      expect(sameData(a, b), isTrue);
      expect(sameData(a, AppData(walks: [_walk('2026-07-28')])), isFalse);
    });
  });

  group('storage', () {
    test('JSON-Rundlauf verliert nichts', () {
      final data = AppData(
        sessions: [_session('2026-07-27', SessionType.home, Intensity.min)],
        walks: [_walk('2026-07-28')],
        treats: [_treat('2026-07-29', TreatKind.drinks)],
        stairs: const [Stair(id: 's1', date: '2026-07-29', ts: 5)],
        pauses: const [
          PauseEvent(id: 'p1', date: '2026-07-01', ts: 1, action: PauseAction.stop),
        ],
        seenBadges: const ['first-session'],
        seenLevel: 3,
        deleted: const ['gone'],
      );
      final back = decodeBackup(encodeBackup(data));
      expect(back.sessions.single.intensity, Intensity.min);
      expect(back.walks.single.date, '2026-07-28');
      expect(back.treats.single.kind, TreatKind.drinks);
      expect(back.stairs.single.id, 's1');
      expect(back.pauses.single.action, PauseAction.stop);
      expect(back.seenLevel, 3);
      expect(back.deleted, ['gone']);
    });

    test('Müll wird verworfen statt zu crashen', () {
      final data = parseData({
        'sessions': [
          {'id': 'x', 'type': 'nope', 'intensity': 'full', 'date': '2026-01-01', 'ts': 1},
          {'id': 'ok', 'type': 'home', 'intensity': 'full', 'date': '2026-01-01', 'ts': 1},
        ],
        'walks': 'kein array',
        'seenLevel': 'zwei',
      });
      expect(data.sessions.length, 1);
      expect(data.walks, isEmpty);
      expect(data.seenLevel, 1);
    });
  });
}
