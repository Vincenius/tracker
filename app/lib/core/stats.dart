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
    required this.perDay,
    required this.total,
    required this.today,
    required this.days,
    required this.worstDay,
    required this.cleanStreak,
    required this.longestCleanStreak,
    required this.xpLost,
  });

  final TreatKind kind;

  /// Einträge je Tag
  final Map<String, int> perDay;

  /// Einträge insgesamt
  final int total;

  /// Einträge heute
  final int today;

  /// Tage mit mindestens einem Eintrag
  final int days;

  /// meiste Einträge an einem Tag
  final int worstDay;

  /// laufende Serie an Tagen ohne Eintrag in dieser Spur
  final int cleanStreak;
  final int longestCleanStreak;

  /// XP, die diese Spur gekostet hat
  final int xpLost;
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
    required this.treats,
    required this.treatsByKind,
    required this.treatCount,
    required this.treatDays,
    required this.cleanDays,
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
  final List<Treat> treats;

  /// Einträge dieser Woche, je Spur
  final Map<TreatKind, int> treatsByKind;

  /// Einträge dieser Woche insgesamt
  final int treatCount;

  /// Tage dieser Woche mit mindestens einem Eintrag
  final int treatDays;

  /// vergangene Tage dieser Woche ganz ohne Eintrag
  final int cleanDays;

  /// die ganze Woche ohne einen einzigen Eintrag
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
    required this.treatTotal,
    required this.treatToday,
    required this.treatDays,
    required this.treatWorstDay,
    required this.treatXpLost,
    required this.cleanStreak,
    required this.longestCleanStreak,
    required this.cleanDayTotal,
    required this.cleanComebacks,
    required this.cleanPerfectWeeks,
    required this.tripleGoalWeeks,
    required this.trackedSince,
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

  // ——— Ernährung: gezählt wird, was danebenging ———
  final Map<TreatKind, LaneStats> lanes;

  /// Einträge insgesamt (beide Spuren)
  final int treatTotal;

  /// Einträge heute
  final int treatToday;

  /// Tage mit mindestens einem Eintrag
  final int treatDays;

  /// meiste Einträge an einem Tag
  final int treatWorstDay;

  /// XP, die die Ernährung insgesamt gekostet hat
  final int treatXpLost;

  /// laufende Serie an Tagen ganz ohne Eintrag
  final int cleanStreak;
  final int longestCleanStreak;

  /// getrackte Tage ganz ohne Eintrag
  final int cleanDayTotal;

  /// Serien von 7 sauberen Tagen nach einem Ausrutscher
  final int cleanComebacks;

  /// Wochen ganz ohne Eintrag
  final int cleanPerfectWeeks;

  /// Wochen mit Trainingsziel, allen Spaziergängen und ohne einen Ausrutscher
  final int tripleGoalWeeks;

  /// Erster Tag mit irgendeinem Eintrag — davor wird nichts gewertet
  final String? trackedSince;

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

class CleanScan {
  const CleanScan(this.dates, this.current, this.longest, this.sevens);

  /// Alle sauberen Tage — getrackt, nicht pausiert, ohne Eintrag
  final Set<String> dates;

  /// Laufende Serie bis heute
  final int current;
  final int longest;

  /// Wie oft eine Serie die 7 Tage erreicht hat
  final int sevens;
}

/// Sauber ist ein Tag, an dem *nichts* eingetragen wurde — die Serie ergibt
/// sich also aus dem Ausbleiben von Einträgen. Damit das nicht rückwirkend bis
/// zum Urknall gilt, zählt erst ab dem ersten getrackten Tag. Pausierte Tage
/// werden übersprungen: sie zählen nicht mit, brechen aber auch nichts.
CleanScan _cleanScan(
  Set<String> treatDates,
  String? from,
  String today,
  Set<String> paused,
) {
  final dates = <String>{};
  var current = 0;
  var longest = 0;
  var sevens = 0;
  if (from == null || from.compareTo(today) > 0) {
    return CleanScan(dates, current, longest, sevens);
  }
  var guard = 0;
  for (var d = from; d.compareTo(today) <= 0 && guard++ < 20000; d = addDays(d, 1)) {
    if (paused.contains(d)) continue;
    if (treatDates.contains(d)) {
      current = 0;
      continue;
    }
    dates.add(d);
    current++;
    if (current > longest) longest = current;
    if (current == cleanGoal) sevens++;
  }
  return CleanScan(dates, current, longest, sevens);
}

WeekSummary summarizeWeek(
  String key,
  List<Session> sessions, [
  List<Walk> walks = const [],
  List<Treat> treats = const [],
  List<Stair> stairs = const [],
  Set<String> cleanDates = const {},
]) {
  final count = sessions.length;
  bool has(SessionType t) => sessions.any((s) => s.type == t);
  // Vergebend: zwei Einheiten reichen.
  final fulfilled = count >= 2;
  // Pro Tag zählt ein Spaziergang — zwei Geräte können denselben Tag eintragen.
  final dates = {for (final w in walks) w.date};
  final walkDays = dates.where(isWeekday).length;

  final treatsByKind = {TreatKind.sweets: 0, TreatKind.drinks: 0};
  for (final t in treats) {
    treatsByKind[t.kind] = treatsByKind[t.kind]! + 1;
  }
  // Saubere Tage kommen fertig gerechnet von computeStats: ob ein Tag zählt,
  // hängt am Trackingstart, am heutigen Datum und am Pausenmodus.
  var cleanDays = 0;
  for (var i = 0; i < 7; i++) {
    if (cleanDates.contains(addDays(key, i))) cleanDays++;
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
    treats: treats,
    treatsByKind: treatsByKind,
    treatCount: treats.length,
    treatDays: {for (final t in treats) t.date}.length,
    cleanDays: cleanDays,
    cleanPerfect: cleanDays >= cleanGoal,
    stairs: stairs,
    stairCount: stairs.length,
    xp: sessionXp +
        dates.length * xpWalk +
        stairs.length * xpStair -
        treats.length * xpTreat,
  );
}

Stats computeStats(
  List<Session> sessions, [
  List<Walk> walks = const [],
  List<Treat> treatsInput = const [],
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
  final treatBuckets = <String, List<Treat>>{};
  for (final t in treatsInput) {
    treatBuckets.putIfAbsent(weekKeyOf(t.date), () => []).add(t);
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

  // Der erste Tag, an dem überhaupt etwas eingetragen wurde. Vorher gibt es
  // keine sauberen Tage — sonst wäre jede frisch installierte App im Rekord.
  String? trackedSince;
  for (final date in [
    for (final s in sessions) s.date,
    for (final w in walks) w.date,
    for (final t in treatsInput) t.date,
    for (final s in stairs) s.date,
  ]) {
    if (trackedSince == null || date.compareTo(trackedSince) < 0) trackedSince = date;
  }

  // ——— Ernährung: gezählt wird, was danebenging ———
  final lanePerDay = {
    TreatKind.sweets: <String, int>{},
    TreatKind.drinks: <String, int>{},
  };
  final treatPerDay = <String, int>{};
  for (final t in treatsInput) {
    final lane = lanePerDay[t.kind]!;
    lane[t.date] = (lane[t.date] ?? 0) + 1;
    treatPerDay[t.date] = (treatPerDay[t.date] ?? 0) + 1;
  }

  final lanes = <TreatKind, LaneStats>{};
  for (final kind in treatKinds) {
    final perDay = lanePerDay[kind]!;
    final scan = _cleanScan(perDay.keys.toSet(), trackedSince, today, paused);
    var total = 0;
    var worstDay = 0;
    for (final n in perDay.values) {
      total += n;
      if (n > worstDay) worstDay = n;
    }
    lanes[kind] = LaneStats(
      kind: kind,
      perDay: perDay,
      total: total,
      today: perDay[today] ?? 0,
      days: perDay.length,
      worstDay: worstDay,
      cleanStreak: scan.current,
      longestCleanStreak: scan.longest,
      xpLost: total * xpTreat,
    );
  }

  final clean = _cleanScan(treatPerDay.keys.toSet(), trackedSince, today, paused);
  // Die erste 7er-Serie ist der Normalfall; jede weitere folgt auf einen
  // Ausrutscher — genau das ist der Wiedereinstieg.
  final cleanComebacks = clean.sevens > 1 ? clean.sevens - 1 : 0;
  final treatXpLost = treatsInput.length * xpTreat;

  final thisWeek = currentWeekKey(now);
  final keys = <String>{
    ...buckets.keys,
    ...walkBuckets.keys,
    ...treatBuckets.keys,
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
      [...?treatBuckets[k]]..sort((a, b) => a.ts - b.ts),
      [...?stairBuckets[k]]..sort((a, b) => a.ts - b.ts),
      clean.dates,
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
  var earned = 0;
  var earlyBird = 0;
  var nightOwl = 0;
  var weekendSessions = 0;
  var minSessions = 0;
  var fullChecklists = 0;
  for (final s in sessions) {
    byType[s.type] = byType[s.type]! + 1;
    earned += xpFor(s);
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
  earned += walkDates.length * xpWalk;
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
  earned += stairs.length * xpStair;

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

  // Unter null geht es nicht: ein schlechter Monat kostet Fortschritt, aber
  // niemals das Konto.
  final xp = earned - treatXpLost > 0 ? earned - treatXpLost : 0;
  final level = xp ~/ xpPerLevel + 1;
  var stairBestDay = 0;
  for (final v in stairPerDay.values) {
    if (v > stairBestDay) stairBestDay = v;
  }
  var treatWorstDay = 0;
  for (final v in treatPerDay.values) {
    if (v > treatWorstDay) treatWorstDay = v;
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
    treatTotal: treatsInput.length,
    treatToday: treatPerDay[today] ?? 0,
    treatDays: treatPerDay.length,
    treatWorstDay: treatWorstDay,
    treatXpLost: treatXpLost,
    cleanStreak: clean.current,
    longestCleanStreak: clean.longest,
    cleanDayTotal: clean.dates.length,
    cleanComebacks: cleanComebacks,
    cleanPerfectWeeks: cleanPerfectWeeks,
    tripleGoalWeeks: tripleGoalWeeks,
    trackedSince: trackedSince,
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
