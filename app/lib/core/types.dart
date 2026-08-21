/// Datenmodell — Gegenstück zu web/src/lib/types.ts. Die JSON-Form muss exakt
/// zum Backend passen (web/server/index.js), sonst wirft `sanitize` Einträge weg.
library;

enum SessionType { boulder, home, fallback }

enum Intensity { full, min }

/// Die zwei Spuren der Ernährung: Süßes gegessen, Süßes getrunken.
enum TreatKind { sweets, drinks }

const treatKinds = TreatKind.values;

T? _enumOf<T extends Enum>(List<T> values, Object? raw) {
  for (final v in values) {
    if (v.name == raw) return v;
  }
  return null;
}

class Session {
  const Session({
    required this.id,
    required this.type,
    required this.intensity,
    required this.date,
    required this.ts,
    this.done = const [],
  });

  final String id;
  final SessionType type;
  final Intensity intensity;

  /// ISO-Datum, z.B. 2026-07-20
  final String date;
  final int ts;

  /// IDs der abgehakten Übungen (optional, rein informativ)
  final List<String> done;

  static Session? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final type = _enumOf(SessionType.values, raw['type']);
    final intensity = _enumOf(Intensity.values, raw['intensity']);
    if (raw['id'] is! String ||
        type == null ||
        intensity == null ||
        raw['date'] is! String ||
        raw['ts'] is! num) {
      return null;
    }
    return Session(
      id: raw['id'] as String,
      type: type,
      intensity: intensity,
      date: raw['date'] as String,
      ts: (raw['ts'] as num).toInt(),
      done: raw['done'] is List
          ? [for (final d in raw['done'] as List) if (d is String) d]
          : const [],
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'type': type.name,
        'intensity': intensity.name,
        'date': date,
        'ts': ts,
        'done': done,
      };
}

/// Ein Spaziergang an einem Tag. Ziel: Montag bis Freitag jeweils einer.
class Walk {
  const Walk({required this.id, required this.date, required this.ts});

  final String id;
  final String date;
  final int ts;

  static Walk? fromJson(Object? raw) {
    if (raw is! Map) return null;
    if (raw['id'] is! String || raw['date'] is! String || raw['ts'] is! num) return null;
    return Walk(
      id: raw['id'] as String,
      date: raw['date'] as String,
      ts: (raw['ts'] as num).toInt(),
    );
  }

  Map<String, Object?> toJson() => {'id': id, 'date': date, 'ts': ts};
}

/// Einmal etwas Süßes gegessen oder getrunken. Anders als alles andere ist das
/// ein Minus: jeder Eintrag kostet XP, beliebig oft am Tag.
class Treat {
  const Treat({
    required this.id,
    required this.date,
    required this.kind,
    required this.ts,
  });

  final String id;
  final String date;
  final TreatKind kind;
  final int ts;

  static Treat? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final kind = _enumOf(TreatKind.values, raw['kind']);
    if (raw['id'] is! String || raw['date'] is! String || raw['ts'] is! num || kind == null) {
      return null;
    }
    return Treat(
      id: raw['id'] as String,
      date: raw['date'] as String,
      kind: kind,
      ts: (raw['ts'] as num).toInt(),
    );
  }

  Map<String, Object?> toJson() => {'id': id, 'date': date, 'kind': kind.name, 'ts': ts};
}

/// Einmal die Treppe statt des Aufzugs genommen — jeder Eintrag zählt.
class Stair {
  const Stair({required this.id, required this.date, required this.ts});

  final String id;
  final String date;
  final int ts;

  static Stair? fromJson(Object? raw) {
    if (raw is! Map) return null;
    if (raw['id'] is! String || raw['date'] is! String || raw['ts'] is! num) return null;
    return Stair(
      id: raw['id'] as String,
      date: raw['date'] as String,
      ts: (raw['ts'] as num).toInt(),
    );
  }

  Map<String, Object?> toJson() => {'id': id, 'date': date, 'ts': ts};
}

enum PauseAction { start, stop }

/// Pausenmodus als Ereignis-Paar: 'start' öffnet eine Pause, 'stop' schließt sie.
class PauseEvent {
  const PauseEvent({
    required this.id,
    required this.date,
    required this.ts,
    required this.action,
  });

  final String id;
  final String date;
  final int ts;
  final PauseAction action;

  static PauseEvent? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final action = _enumOf(PauseAction.values, raw['action']);
    if (raw['id'] is! String || raw['date'] is! String || raw['ts'] is! num || action == null) {
      return null;
    }
    return PauseEvent(
      id: raw['id'] as String,
      date: raw['date'] as String,
      ts: (raw['ts'] as num).toInt(),
      action: action,
    );
  }

  Map<String, Object?> toJson() => {'id': id, 'date': date, 'ts': ts, 'action': action.name};
}

class AppData {
  const AppData({
    this.sessions = const [],
    this.walks = const [],
    this.treats = const [],
    this.stairs = const [],
    this.pauses = const [],
    this.seenBadges = const [],
    this.seenLevel = 1,
    this.deleted = const [],
  });

  final List<Session> sessions;
  final List<Walk> walks;
  final List<Treat> treats;
  final List<Stair> stairs;
  final List<PauseEvent> pauses;

  /// Bereits gefeierte Badges – verhindert doppelte Animationen
  final List<String> seenBadges;

  /// Bereits erreichtes Level – für die Level-Up-Animation
  final int seenLevel;

  /// IDs gelöschter Einträge (Tombstones), damit sie beim Sync nicht zurückkommen
  final List<String> deleted;

  static const empty = AppData();

  AppData copyWith({
    List<Session>? sessions,
    List<Walk>? walks,
    List<Treat>? treats,
    List<Stair>? stairs,
    List<PauseEvent>? pauses,
    List<String>? seenBadges,
    int? seenLevel,
    List<String>? deleted,
  }) =>
      AppData(
        sessions: sessions ?? this.sessions,
        walks: walks ?? this.walks,
        treats: treats ?? this.treats,
        stairs: stairs ?? this.stairs,
        pauses: pauses ?? this.pauses,
        seenBadges: seenBadges ?? this.seenBadges,
        seenLevel: seenLevel ?? this.seenLevel,
        deleted: deleted ?? this.deleted,
      );

  Map<String, Object?> toJson() => {
        'version': 1,
        'sessions': [for (final s in sessions) s.toJson()],
        'walks': [for (final w in walks) w.toJson()],
        'treats': [for (final t in treats) t.toJson()],
        'stairs': [for (final s in stairs) s.toJson()],
        'pauses': [for (final p in pauses) p.toJson()],
        'seenBadges': seenBadges,
        'seenLevel': seenLevel,
        'deleted': deleted,
      };
}

/// Ein Spaziergang ist klein — er zählt trotzdem.
const xpWalk = 6;

/// Ein Treppenaufstieg ist noch kleiner — dafür ist er unbegrenzt.
const xpStair = 2;

/// Zielanzahl Spaziergänge pro Woche: Montag bis Freitag.
const walkGoal = 5;

const xpTable = <SessionType, Map<Intensity, int>>{
  SessionType.boulder: {Intensity.full: 20, Intensity.min: 20},
  SessionType.home: {Intensity.full: 14, Intensity.min: 8},
  SessionType.fallback: {Intensity.full: 16, Intensity.min: 8},
};

/// Ernährung gibt keine Punkte — sauber essen ist der Normalfall, nicht die
/// Leistung. Jeder eingetragene Ausrutscher kostet dafür XP: ungefähr so viel,
/// wie ein Spaziergang bringt.
const xpTreat = 5;

const xpPerLevel = 150;

int xpFor(Session s) => xpTable[s.type]![s.intensity]!;
