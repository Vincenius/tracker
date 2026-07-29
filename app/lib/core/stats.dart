import 'date.dart';
import 'pause.dart';
import 'types.dart';
import 'workouts.dart';

/// Portierung von web/src/lib/stats.ts. Die Zahlen müssen identisch herauskommen,
/// sonst zeigen App und Web unterschiedliche Level für dieselben Daten.

/// Wurde beim Abhaken die komplette Übungsliste mit abgehakt?
bool _isFullyChecked(Session s) {
  final exercises = workouts[s.type]![s.intensity]!.exercises;
  return exercises.isNotEmpty && exercises.every((ex) => s.done.contains(ex.id));
}

/// Sieben Tage pro Woche — Ernährung kennt kein Wochenende.
const cleanGoal = 7;

class LaneStats {
  const LaneStats({
    required this.kind,
    required this.dates,
    required this.total,
    required this.currentStreak,
    required this.longestStreak,
    required this.nextXp,
    required this.xp,
  });

  final CleanKind kind;

  /// Alle sauberen Tage dieser Spur
  final Set<String> dates;
  final int total;

  /// Laufende Serie; der heutige Tag bricht sie nicht, solange er läuft
  final int currentStreak;
  final int longestStreak;

  /// XP, die der nächste saubere Tag in dieser Spur bringt
  final int nextXp;
  final int xp;
}

class WeekSummary {
  const WeekSummary({
    required this.key,
    required this.sessions,
    required this.count,
    required this.fulfilled,
    required this.fallbackWeek,
    required this.walks,
    required this.walkDays,
    required this.walkPerfect,
    required this.clean,
    required this.cleanDays,
    required this.cleanBothDays,
    required this.cleanPerfect,
    required this.stairs,
    required this.stairCount,
    required this.xp,
  });

  final String key;
  final List<Session> sessions;
  final int count;
  final bool fulfilled;

  /// Woche wurde ohne Bouldern erfüllt (Home + Fallback)
  final bool fallbackWeek;
  final List<Walk> walks;

  /// Werktage (Mo–Fr) mit Spaziergang
  final int walkDays;

  /// alle fünf Werktage mit Spaziergang
  final bool walkPerfect;
  final List<CleanDay> clean;

  /// saubere Tage je Spur in dieser Woche
  final Map<CleanKind, int> cleanDays;

  /// Tage, an denen beide Spuren sauber waren
  final int cleanBothDays;

  /// alle sieben Tage in beiden Spuren sauber
  final bool cleanPerfect;
  final List<Stair> stairs;

  /// Treppenaufstiege in dieser Woche — jeder einzelne zählt
  final int stairCount;
  final int xp;
}

class Stats {
  const Stats({
    required this.xp,
    required this.level,
    required this.xpInLevel,
    required this.xpToNext,
    required this.total,
    required this.byType,
    required this.weeks,
    required this.orderedWeeks,
    required this.currentStreak,
    required this.longestStreak,
    required this.fulfilledWeeks,
    required this.fallbackWeeks,
    required this.earlyBird,
    required this.nightOwl,
    required this.weekendSessions,
    required this.minSessions,
    required this.fullChecklists,
    required this.bigWeeks,
    required this.onPlanWeeks,
    required this.comebacks,
    required this.allMinWeeks,
    required this.walkTotal,
    required this.walkWeekdays,
    required this.weekendWalks,
    required this.walkPerfectWeeks,
    required this.walkSolidWeeks,
    required this.walkStreak,
    required this.longestWalkStreak,
    required this.doubleGoalWeeks,
    required this.lanes,
    required this.cleanBothDays,
    required this.cleanBothStreak,
    required this.longestCleanBothStreak,
    required this.cleanComebacks,
    required this.cleanAnyDays,
    required this.cleanXp,
    required this.cleanPerfectWeeks,
    required this.tripleGoalWeeks,
    required this.stairTotal,
    required this.stairToday,
    required this.stairDays,
    required this.stairBestDay,
    required this.stairStreak,
    required this.longestStairStreak,
    required this.pauseActive,
    required this.pausedSince,
  });

  final int xp;
  final int level;
  final int xpInLevel;
  final int xpToNext;
  final int total;
  final Map<SessionType, int> byType;
  final Map<String, WeekSummary> weeks;
  final List<WeekSummary> orderedWeeks;
  final int currentStreak;
  final int longestStreak;
  final int fulfilledWeeks;
  final int fallbackWeeks;

  /// Einheiten vor 9 Uhr
  final int earlyBird;

  /// Einheiten ab 21 Uhr
  final int nightOwl;

  /// Einheiten an Samstag oder Sonntag
  final int weekendSessions;

  /// abgehakte Minimum-Einheiten
  final int minSessions;

  /// Einheiten, bei denen die komplette Checkliste abgehakt wurde
  final int fullChecklists;

  /// Wochen mit 3 oder mehr Einheiten
  final int bigWeeks;

  /// Wochen mit Home am Montag und Bouldern am Mittwoch
  final int onPlanWeeks;

  /// erfüllte Wochen nach mindestens 2 leeren Wochen
  final int comebacks;

  /// erfüllte Wochen, in denen ausschließlich Minimum-Einheiten liefen
  final int allMinWeeks;

  final int walkTotal;
  final int walkWeekdays;
  final int weekendWalks;
  final int walkPerfectWeeks;
  final int walkSolidWeeks;
  final int walkStreak;
  final int longestWalkStreak;
  final int doubleGoalWeeks;

  // ——— Ernährung ———
  final Map<CleanKind, LaneStats> lanes;
  final int cleanBothDays;
  final int cleanBothStreak;
  final int longestCleanBothStreak;
  final int cleanComebacks;
  final int cleanAnyDays;
  final int cleanXp;
  final int cleanPerfectWeeks;
  final int tripleGoalWeeks;

  // ——— Treppe ———
  final int stairTotal;
  final int stairToday;
  final int stairDays;
  final int stairBestDay;
  final int stairStreak;
  final int longestStairStreak;

  // ——— Pausenmodus ———
  final bool pauseActive;
  final String? pausedSince;
}

/// Folgt `date` lückenlos auf `prev`? Pausierte Tage dazwischen zählen nicht
/// als Lücke — eine Serie überlebt den Urlaub.
bool _joins(String? prev, String date, Set<String> paused) {
  if (prev == null) return false;
  var d = addDays(prev, 1);
  while (d.compareTo(date) < 0) {
    if (!paused.contains(d)) return false;
    d = addDays(d, 1);
  }
  return d == date;
}

class _LaneXp {
  const _LaneXp(this.xp, this.longest);
  final Map<String, int> xp;
  final int longest;
}

/// XP pro Tag einer Spur — der wievielte Tag der Serie zählt, nicht der Kalendertag.
_LaneXp _laneXpByDate(Set<String> dates, Set<String> paused) {
  final xp = <String, int>{};
  var longest = 0;
  var run = 0;
  String? prev;
  for (final date in dates.toList()..sort()) {
    run = _joins(prev, date, paused) ? run + 1 : 1;
    if (run > longest) longest = run;
    xp[date] = xpForCleanDay(run);
    prev = date;
  }
  return _LaneXp(xp, longest);
}

/// Serie rückwärts ab heute. Ein noch nicht abgehakter heutiger Tag bricht sie
/// nicht — und pausierte Tage ohne Eintrag werden übersprungen.
int _streakBack(Set<String> dates, String today, Set<String> paused) {
  var streak = 0;
  var cursor = dates.contains(today) ? today : addDays(today, -1);
  for (;;) {
    if (dates.contains(cursor)) {
      streak++;
    } else if (!paused.contains(cursor)) {
      break;
    }
    cursor = addDays(cursor, -1);
  }
  return streak;
}

WeekSummary summarizeWeek(
  String key,
  List<Session> sessions, [
  List<Walk> walks = const [],
  List<CleanDay> clean = const [],
  Map<String, int> cleanXpByDate = const {},
  List<Stair> stairs = const [],
]) {
  final count = sessions.length;
  bool has(SessionType t) => sessions.any((s) => s.type == t);
  // Vergebend: zwei Einheiten reichen.
  final fulfilled = count >= 2;
  // Pro Tag zählt ein Spaziergang — zwei Geräte können denselben Tag eintragen.
  final dates = {for (final w in walks) w.date};
  final walkDays = dates.where(isWeekday).length;

  final cleanSets = {CleanKind.snacks: <String>{}, CleanKind.drinks: <String>{}};
  for (final c in clean) {
    cleanSets[c.kind]!.add(c.date);
  }
  final cleanDays = {
    CleanKind.snacks: cleanSets[CleanKind.snacks]!.length,
    CleanKind.drinks: cleanSets[CleanKind.drinks]!.length,
  };
  final cleanBothDays =
      cleanSets[CleanKind.snacks]!.where(cleanSets[CleanKind.drinks]!.contains).length;

  // Ernährungs-XP hängt an der Serie über Wochengrenzen hinweg und kommt
  // deshalb fertig berechnet von computeStats.
  final weekDates = {...cleanSets[CleanKind.snacks]!, ...cleanSets[CleanKind.drinks]!};
  var cleanXp = 0;
  for (final d in weekDates) {
    cleanXp += cleanXpByDate[d] ?? 0;
  }

  var sessionXp = 0;
  for (final s in sessions) {
    sessionXp += xpFor(s);
  }

  return WeekSummary(
    key: key,
    sessions: sessions,
    count: count,
    fulfilled: fulfilled,
    fallbackWeek: fulfilled && has(SessionType.fallback) && !has(SessionType.boulder),
    walks: walks,
    walkDays: walkDays,
    walkPerfect: walkDays >= walkGoal,
    clean: clean,
    cleanDays: cleanDays,
    cleanBothDays: cleanBothDays,
    cleanPerfect: cleanBothDays >= cleanGoal,
    stairs: stairs,
    stairCount: stairs.length,
    xp: sessionXp + dates.length * xpWalk + stairs.length * xpStair + cleanXp,
  );
}

Stats computeStats(
  List<Session> sessions, [
  List<Walk> walks = const [],
  List<CleanDay> cleanDaysInput = const [],
  List<Stair> stairs = const [],
  List<PauseEvent> pauseEvents = const [],
  DateTime? nowInput,
]) {
  final now = nowInput ?? DateTime.now();

  final buckets = <String, List<Session>>{};
  for (final s in sessions) {
    buckets.putIfAbsent(weekKeyOf(s.date), () => []).add(s);
  }
  final walkBuckets = <String, List<Walk>>{};
  for (final w in walks) {
    walkBuckets.putIfAbsent(weekKeyOf(w.date), () => []).add(w);
  }
  final cleanBuckets = <String, List<CleanDay>>{};
  for (final c in cleanDaysInput) {
    cleanBuckets.putIfAbsent(weekKeyOf(c.date), () => []).add(c);
  }
  final stairBuckets = <String, List<Stair>>{};
  for (final s in stairs) {
    stairBuckets.putIfAbsent(weekKeyOf(s.date), () => []).add(s);
  }

  final today = toISODate(now);

  // ——— Pausenmodus: diese Tage brechen keine Serie ———
  final info = pauseInfo(pauseEvents, today);
  final paused = info.paused;

  /// Eine Woche mit mindestens einem Pausentag bricht den Wochen-Streak nicht.
  bool weekPaused(String key) =>
      [0, 1, 2, 3, 4, 5, 6].any((i) => paused.contains(addDays(key, i)));

  // ——— Ernährung: erst die Serien, daraus die XP pro Tag ———
  final laneDates = {CleanKind.snacks: <String>{}, CleanKind.drinks: <String>{}};
  for (final c in cleanDaysInput) {
    laneDates[c.kind]!.add(c.date);
  }

  final bothDates = laneDates[CleanKind.snacks]!
      .where(laneDates[CleanKind.drinks]!.contains)
      .toList()
    ..sort();
  final bothSet = bothDates.toSet();

  /// XP je Kalendertag über beide Spuren inkl. Kombi-Bonus — für die Wochen-XP.
  final cleanXpByDate = <String, int>{};
  final lanes = <CleanKind, LaneStats>{};
  var cleanXp = 0;

  for (final kind in cleanKinds) {
    final dates = laneDates[kind]!;
    final laneResult = _laneXpByDate(dates, paused);
    final currentStreak = _streakBack(dates, today, paused);
    var laneXp = 0;
    laneResult.xp.forEach((date, value) {
      laneXp += value;
      cleanXpByDate[date] = (cleanXpByDate[date] ?? 0) + value;
    });
    cleanXp += laneXp;
    lanes[kind] = LaneStats(
      kind: kind,
      dates: dates,
      total: dates.length,
      currentStreak: currentStreak,
      longestStreak:
          laneResult.longest > currentStreak ? laneResult.longest : currentStreak,
      // Der nächste Tag setzt die Serie fort — also ein Schritt weiter.
      nextXp: xpForCleanDay(currentStreak + 1),
      xp: laneXp,
    );
  }

  for (final date in bothDates) {
    cleanXp += xpCleanCombo;
    cleanXpByDate[date] = (cleanXpByDate[date] ?? 0) + xpCleanCombo;
  }

  final cleanBothStreak = _streakBack(bothSet, today, paused);
  var longestCleanBothStreak = 0;
  // Serien ab einer Woche zählen; ab der zweiten ist jede ein Wiedereinstieg.
  var longRuns = 0;
  var bothRun = 0;
  String? prevBoth;
  for (final date in bothDates) {
    bothRun = _joins(prevBoth, date, paused) ? bothRun + 1 : 1;
    if (bothRun > longestCleanBothStreak) longestCleanBothStreak = bothRun;
    if (bothRun == cleanGoal) longRuns++;
    prevBoth = date;
  }
  if (cleanBothStreak > longestCleanBothStreak) longestCleanBothStreak = cleanBothStreak;
  final cleanComebacks = longRuns > 1 ? longRuns - 1 : 0;

  final thisWeek = currentWeekKey(now);
  final keys = <String>{
    ...buckets.keys,
    ...walkBuckets.keys,
    ...cleanBuckets.keys,
    ...stairBuckets.keys,
  }.toList()
    ..sort();
  final first = keys.isNotEmpty ? keys.first : thisWeek;
  final span = weeksBetween(first.compareTo(thisWeek) < 0 ? first : thisWeek, thisWeek);

  final weeks = <String, WeekSummary>{};
  final orderedWeeks = <WeekSummary>[];
  for (final k in span) {
    final w = summarizeWeek(
      k,
      [...?buckets[k]]..sort((a, b) => a.ts - b.ts),
      [...?walkBuckets[k]]..sort((a, b) => a.ts - b.ts),
      [...?cleanBuckets[k]]..sort((a, b) => a.ts - b.ts),
      cleanXpByDate,
      [...?stairBuckets[k]]..sort((a, b) => a.ts - b.ts),
    );
    weeks[k] = w;
    orderedWeeks.add(w);
  }

  // Aktueller Streak: die laufende Woche zählt nur, wenn sie schon erfüllt ist –
  // sie bricht den Streak aber niemals, solange sie noch läuft.
  var currentStreak = 0;
  var cursor = (weeks[thisWeek]?.fulfilled ?? false) ? thisWeek : addWeeks(thisWeek, -1);
  for (;;) {
    if (weeks[cursor]?.fulfilled ?? false) {
      currentStreak++;
    } else if (!weekPaused(cursor)) {
      break;
    }
    cursor = addWeeks(cursor, -1);
  }

  var longestStreak = 0;
  var run = 0;
  for (final w in orderedWeeks) {
    run = w.fulfilled
        ? run + 1
        : weekPaused(w.key)
            ? run
            : 0;
    if (run > longestStreak) longestStreak = run;
  }

  final byType = {SessionType.boulder: 0, SessionType.home: 0, SessionType.fallback: 0};
  var xp = cleanXp;
  var earlyBird = 0;
  var nightOwl = 0;
  var weekendSessions = 0;
  var minSessions = 0;
  var fullChecklists = 0;
  for (final s in sessions) {
    byType[s.type] = byType[s.type]! + 1;
    xp += xpFor(s);
    final hour = DateTime.fromMillisecondsSinceEpoch(s.ts).hour;
    if (hour < 9) earlyBird++;
    if (hour >= 21) nightOwl++;
    final dow = fromISODate(s.date).weekday;
    if (dow == DateTime.saturday || dow == DateTime.sunday) weekendSessions++;
    if (s.intensity == Intensity.min) minSessions++;
    if (_isFullyChecked(s)) fullChecklists++;
  }

  // ——— Spaziergänge ———
  final walkDates = {for (final w in walks) w.date};
  xp += walkDates.length * xpWalk;
  final weekdayWalks = walkDates.where(isWeekday).toList();
  final weekendWalks = walkDates.length - weekdayWalks.length;

  // Serie über Werktage: das Wochenende unterbricht nicht, es zählt nur nicht mit.
  var walkStreak = 0;
  var cursorDay =
      walkDates.contains(today) && isWeekday(today) ? today : prevWeekday(today);
  for (;;) {
    if (walkDates.contains(cursorDay)) {
      walkStreak++;
    } else if (!paused.contains(cursorDay)) {
      break;
    }
    cursorDay = prevWeekday(cursorDay);
  }

  /// Vorheriger Werktag, pausierte Tage ohne Spaziergang überspringen.
  String prevWalkDay(String d) {
    var x = prevWeekday(d);
    while (paused.contains(x) && !walkDates.contains(x)) {
      x = prevWeekday(x);
    }
    return x;
  }

  var longestWalkStreak = 0;
  final sortedWeekdays = [...weekdayWalks]..sort();
  var walkRun = 0;
  String? prevDay;
  for (final day in sortedWeekdays) {
    walkRun = prevDay != null && prevWalkDay(day) == prevDay ? walkRun + 1 : 1;
    if (walkRun > longestWalkStreak) longestWalkStreak = walkRun;
    prevDay = day;
  }

  // ——— Treppe: jeder Aufstieg zählt, Serien laufen über Kalendertage ———
  final stairPerDay = <String, int>{};
  for (final s in stairs) {
    stairPerDay[s.date] = (stairPerDay[s.date] ?? 0) + 1;
  }
  final stairDates = stairPerDay.keys.toSet();
  xp += stairs.length * xpStair;

  final stairStreak = _streakBack(stairDates, today, paused);
  var longestStairStreak = 0;
  var stairRun = 0;
  String? prevStairDay;
  for (final day in stairDates.toList()..sort()) {
    stairRun = _joins(prevStairDay, day, paused) ? stairRun + 1 : 1;
    if (stairRun > longestStairStreak) longestStairStreak = stairRun;
    prevStairDay = day;
  }
  if (stairStreak > longestStairStreak) longestStairStreak = stairStreak;

  var bigWeeks = 0;
  var onPlanWeeks = 0;
  var comebacks = 0;
  var allMinWeeks = 0;
  var emptyRun = 0;
  var walkPerfectWeeks = 0;
  var walkSolidWeeks = 0;
  var doubleGoalWeeks = 0;
  var cleanPerfectWeeks = 0;
  var tripleGoalWeeks = 0;
  for (final w in orderedWeeks) {
    if (w.walkPerfect) walkPerfectWeeks++;
    if (w.walkDays >= 3) walkSolidWeeks++;
    if (w.fulfilled && w.walkPerfect) doubleGoalWeeks++;
    if (w.cleanPerfect) cleanPerfectWeeks++;
    if (w.fulfilled && w.walkPerfect && w.cleanPerfect) tripleGoalWeeks++;
    if (w.count >= 3) bigWeeks++;
    if (w.fulfilled && w.sessions.every((s) => s.intensity == Intensity.min)) allMinWeeks++;
    final onPlan = w.sessions.any(
          (s) => s.type == SessionType.home && fromISODate(s.date).weekday == DateTime.monday,
        ) &&
        w.sessions.any(
          (s) =>
              s.type == SessionType.boulder &&
              fromISODate(s.date).weekday == DateTime.wednesday,
        );
    if (onPlan) onPlanWeeks++;
    if (w.fulfilled && emptyRun >= 2) comebacks++;
    emptyRun = w.count == 0 ? emptyRun + 1 : 0;
  }

  final level = xp ~/ xpPerLevel + 1;
  var stairBestDay = 0;
  for (final v in stairPerDay.values) {
    if (v > stairBestDay) stairBestDay = v;
  }

  return Stats(
    xp: xp,
    level: level,
    xpInLevel: xp % xpPerLevel,
    xpToNext: xpPerLevel - (xp % xpPerLevel),
    total: sessions.length,
    byType: byType,
    weeks: weeks,
    orderedWeeks: orderedWeeks,
    currentStreak: currentStreak,
    longestStreak: longestStreak,
    fulfilledWeeks: orderedWeeks.where((w) => w.fulfilled).length,
    fallbackWeeks: orderedWeeks.where((w) => w.fallbackWeek).length,
    earlyBird: earlyBird,
    nightOwl: nightOwl,
    weekendSessions: weekendSessions,
    minSessions: minSessions,
    fullChecklists: fullChecklists,
    bigWeeks: bigWeeks,
    onPlanWeeks: onPlanWeeks,
    comebacks: comebacks,
    allMinWeeks: allMinWeeks,
    walkTotal: walkDates.length,
    walkWeekdays: weekdayWalks.length,
    weekendWalks: weekendWalks,
    walkPerfectWeeks: walkPerfectWeeks,
    walkSolidWeeks: walkSolidWeeks,
    walkStreak: walkStreak,
    longestWalkStreak: longestWalkStreak,
    doubleGoalWeeks: doubleGoalWeeks,
    lanes: lanes,
    cleanBothDays: bothDates.length,
    cleanBothStreak: cleanBothStreak,
    longestCleanBothStreak: longestCleanBothStreak,
    cleanComebacks: cleanComebacks,
    cleanAnyDays: {...laneDates[CleanKind.snacks]!, ...laneDates[CleanKind.drinks]!}.length,
    cleanXp: cleanXp,
    cleanPerfectWeeks: cleanPerfectWeeks,
    tripleGoalWeeks: tripleGoalWeeks,
    stairTotal: stairs.length,
    stairToday: stairPerDay[today] ?? 0,
    stairDays: stairDates.length,
    stairBestDay: stairBestDay,
    stairStreak: stairStreak,
    longestStairStreak: longestStairStreak,
    pauseActive: info.activeSince != null,
    pausedSince: info.activeSince,
  );
}
