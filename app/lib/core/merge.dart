import 'types.dart';

/// Zusammenführen zweier Stände (lokal ⟷ Server). Einheiten und Spaziergänge
/// sind unveränderlich und haben eindeutige IDs, deshalb reicht die Vereinigung.
/// Gelöschtes bleibt gelöscht — dafür die Tombstones in `deleted`.
///
/// Dieselbe Logik steckt in web/server/index.js und web/src/lib/merge.ts —
/// bei Änderungen dort mitziehen.
List<T> _union<T>(
  List<T> a,
  List<T> b,
  Set<String> deleted,
  String Function(T) id,
  int Function(T) ts,
) {
  final byId = <String, T>{};
  for (final item in [...a, ...b]) {
    if (!deleted.contains(id(item))) byId[id(item)] = item;
  }
  return byId.values.toList()..sort((x, y) => ts(x) - ts(y));
}

AppData mergeData(AppData a, AppData b) {
  final deleted = <String>{...a.deleted, ...b.deleted};
  return AppData(
    sessions: _union(a.sessions, b.sessions, deleted, (s) => s.id, (s) => s.ts),
    walks: _union(a.walks, b.walks, deleted, (w) => w.id, (w) => w.ts),
    cleanDays: _union(a.cleanDays, b.cleanDays, deleted, (c) => c.id, (c) => c.ts),
    stairs: _union(a.stairs, b.stairs, deleted, (s) => s.id, (s) => s.ts),
    cheatDays: _union(a.cheatDays, b.cheatDays, deleted, (c) => c.id, (c) => c.ts),
    pauses: _union(a.pauses, b.pauses, deleted, (p) => p.id, (p) => p.ts),
    seenBadges: {...a.seenBadges, ...b.seenBadges}.toList(),
    seenLevel: a.seenLevel > b.seenLevel ? a.seenLevel : b.seenLevel,
    deleted: deleted.toList(),
  );
}

bool sameData(AppData a, AppData b) {
  bool sameIds<T>(List<T> x, List<T> y, String Function(T) id) {
    if (x.length != y.length) return false;
    for (var i = 0; i < x.length; i++) {
      if (id(x[i]) != id(y[i])) return false;
    }
    return true;
  }

  return a.deleted.length == b.deleted.length &&
      sameIds(a.sessions, b.sessions, (s) => s.id) &&
      sameIds(a.walks, b.walks, (w) => w.id) &&
      sameIds(a.cleanDays, b.cleanDays, (c) => c.id) &&
      sameIds(a.stairs, b.stairs, (s) => s.id) &&
      sameIds(a.cheatDays, b.cheatDays, (c) => c.id) &&
      sameIds(a.pauses, b.pauses, (p) => p.id);
}
