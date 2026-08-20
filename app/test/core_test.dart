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

CleanDay _clean(String date, CleanKind kind) => CleanDay(
      id: 'c-$date-${kind.name}',
      date: date,
      kind: kind,
      ts: fromISODate(date).millisecondsSinceEpoch,
    );

CheatDay _cheat(String date) =>
    CheatDay(id: 'x-$date', date: date, ts: fromISODate(date).millisecondsSinceEpoch);

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

    test('Ernährungsserie steigert die XP bis zur Deckelung', () {
      final dates = [for (var i = 0; i < 8; i++) addDays('2026-07-22', i)];
      final s = computeStats(
        const [],
        const [],
        [for (final d in dates) _clean(d, CleanKind.snacks)],
        const [],
        const [],
        const [],
        now,
      );
      // Tage 1..8 -> 2,3,4,5,6,6,6,6 = 38
      expect(s.lanes[CleanKind.snacks]!.xp, 38);
      expect(s.lanes[CleanKind.snacks]!.longestStreak, 8);
      expect(s.lanes[CleanKind.snacks]!.nextXp, xpCleanCap);
      expect(s.cleanBothDays, 0); // nur eine Spur
    });

    test('Kombi-Bonus für beide Spuren am selben Tag', () {
      final s = computeStats(
        const [],
        const [],
        [_clean('2026-07-29', CleanKind.snacks), _clean('2026-07-29', CleanKind.drinks)],
        const [],
        const [],
        const [],
        now,
      );
      expect(s.cleanBothDays, 1);
      expect(s.cleanXp, xpCleanBase * 2 + xpCleanCombo);
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
        const [],
        now,
      );
      expect(s.pauseActive, isTrue);
      expect(s.pausedSince, '2026-07-27');
      // Mo–Mi sind pausiert, die Serie reicht durch bis Donnerstag der Vorwoche.
      expect(s.walkStreak, 2);
    });

    test('Cheat Day überspringt den Tag, statt die Serie zu brechen', () {
      // Mo, Di, Do, Mi ist der Cheat Day — die Serie läuft durch.
      final s = computeStats(
        const [],
        const [],
        [
          for (final d in ['2026-07-27', '2026-07-28', '2026-07-30'])
            _clean(d, CleanKind.snacks),
        ],
        const [],
        const [],
        [_cheat('2026-07-29')],
        fromISODate('2026-07-30'),
      );
      final lane = s.lanes[CleanKind.snacks]!;
      expect(lane.currentStreak, 3);
      expect(s.cheatThisWeek, '2026-07-29');
      // Der Cheat Day bringt keine XP: 2 + 3 + 4 für die drei sauberen Tage.
      expect(lane.xp, 9);
    });

    test('pro Woche zählt nur der älteste Cheat Day', () {
      final s = computeStats(
        const [],
        const [],
        const [],
        const [],
        const [],
        [
          const CheatDay(id: 'b', date: '2026-07-30', ts: 200),
          const CheatDay(id: 'a', date: '2026-07-28', ts: 100),
          // Nächste Woche zählt wieder ein eigener.
          const CheatDay(id: 'c', date: '2026-08-04', ts: 300),
        ],
        fromISODate('2026-08-05'),
      );
      expect(s.cheatDates, {'2026-07-28', '2026-08-04'});
      expect(s.cheatThisWeek, '2026-08-04');
      expect(s.cheatTotal, 2);
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
        const [],
        now,
      );
      expect(s.stairTotal, 3);
      expect(s.stairToday, 3);
      expect(s.stairBestDay, 3);
      expect(s.xp, 3 * xpStair);
    });

    test('leere Daten liefern Level 1', () {
      final s = computeStats(
        const [],
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
        cleanDays: [_clean('2026-07-29', CleanKind.drinks)],
        stairs: const [Stair(id: 's1', date: '2026-07-29', ts: 5)],
        cheatDays: const [CheatDay(id: 'x1', date: '2026-07-25', ts: 4)],
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
      expect(back.cleanDays.single.kind, CleanKind.drinks);
      expect(back.stairs.single.id, 's1');
      expect(back.cheatDays.single.date, '2026-07-25');
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
