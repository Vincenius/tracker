import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';

import 'core/api.dart';
import 'core/badges.dart';
import 'core/config.dart';
import 'core/date.dart';
import 'core/merge.dart';
import 'core/pause.dart';
import 'core/stats.dart';
import 'core/storage.dart';
import 'core/types.dart';

/// Portierung von web/src/lib/store.ts als ChangeNotifier.

class Celebration {
  const Celebration({this.level, required this.badges});
  final int? level;
  final List<Achievement> badges;
}

enum SyncState { idle, syncing, synced, offline, unauthorized }

const _pushDelay = Duration(milliseconds: 600);
const _pollInterval = Duration(seconds: 60);

final _random = Random();

String _newId() {
  final stamp = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
  final rand = _random.nextInt(1 << 30).toRadixString(36).padLeft(6, '0');
  return '$stamp-${rand.substring(rand.length - 6)}';
}

class TrackerStore extends ChangeNotifier with WidgetsBindingObserver {
  TrackerStore() {
    _stats = computeStats(const [], const [], const [], const [], const []);
  }

  AppData _data = AppData.empty;
  late Stats _stats;
  SyncState _sync = SyncState.idle;
  Celebration? _celebration;
  String? _toast;
  bool _ready = false;

  Timer? _toastTimer;
  Timer? _pushTimer;
  Timer? _pollTimer;

  AppData get data => _data;
  Stats get stats => _stats;
  SyncState get sync => _sync;
  Celebration? get celebration => _celebration;
  String? get toast => _toast;
  bool get ready => _ready;

  /// Beim Laden/Mergen gelten alle erfüllten Badges/Level als gesehen –
  /// keine Nachfeier.
  AppData _normalizeSeen(AppData data) {
    final s = computeStats(
      data.sessions,
      data.walks,
      data.treats,
      data.stairs,
      data.pauses,
    );
    return data.copyWith(seenBadges: unlockedBadges(s), seenLevel: s.level);
  }

  Future<void> init() async {
    WidgetsBinding.instance.addObserver(this);
    await Config.load();
    _apply(_normalizeSeen(await loadData()), persist: false);
    _ready = true;
    notifyListeners();
    unawaited(pushAndPull());
    _pollTimer = Timer.periodic(_pollInterval, (_) => unawaited(pushAndPull()));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _toastTimer?.cancel();
    _pushTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  // Beim Aufwachen sofort synchronisieren — das Gegenstück zu den
  // focus/visibilitychange-Listenern im Web.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _ready) unawaited(pushAndPull());
  }

  void _apply(AppData next, {bool persist = true}) {
    _data = next;
    _stats = computeStats(
      next.sessions,
      next.walks,
      next.treats,
      next.stairs,
      next.pauses,
    );
    if (persist) unawaited(saveData(next));
    notifyListeners();
  }

  void flash(String msg) {
    _toast = msg;
    notifyListeners();
    _toastTimer?.cancel();
    _toastTimer = Timer(const Duration(milliseconds: 3200), () {
      _toast = null;
      notifyListeners();
    });
  }

  void dismissCelebration() {
    _celebration = null;
    notifyListeners();
  }

  void _setSync(SyncState state) {
    if (_sync == state) return;
    _sync = state;
    notifyListeners();
  }

  /// Lokalen Stand hochschicken und den gemergten Server-Stand übernehmen.
  Future<bool> pushAndPull() async {
    _setSync(SyncState.syncing);
    try {
      final remote = await syncWithServer(_data);
      // Erneut mergen: währenddessen kann lokal etwas dazugekommen sein.
      final merged = _normalizeSeen(mergeData(_data, remote));
      if (!sameData(merged, _data)) {
        _apply(merged);
      } else {
        unawaited(saveData(merged));
      }
      _setSync(SyncState.synced);
      return true;
    } on UnauthorizedError {
      _setSync(SyncState.unauthorized);
      return false;
    } catch (_) {
      _setSync(SyncState.offline);
      return false;
    }
  }

  /// Token nachtragen und sofort neu synchronisieren.
  Future<void> saveToken(String token) async {
    await Config.setToken(token);
    await pushAndPull();
  }

  Future<void> saveBaseUrl(String url) async {
    await Config.setBaseUrl(url);
    await pushAndPull();
  }

  void _schedulePush() {
    _pushTimer?.cancel();
    _pushTimer = Timer(_pushDelay, () => unawaited(pushAndPull()));
  }

  /// Fortschritt übernehmen und alles feiern, was dabei neu freigeschaltet wurde.
  void _commitEarned({
    List<Session>? sessions,
    List<Walk>? walks,
    List<Treat>? treats,
    List<Stair>? stairs,
  }) {
    final prev = _data;
    final next = prev.copyWith(
      sessions: sessions,
      walks: walks,
      treats: treats,
      stairs: stairs,
    );
    final nextStats = computeStats(
      next.sessions,
      next.walks,
      next.treats,
      next.stairs,
      prev.pauses,
    );
    final unlocked = unlockedBadges(nextStats);
    final fresh = [for (final id in unlocked) if (!prev.seenBadges.contains(id)) id];
    final leveledUp = nextStats.level > prev.seenLevel;

    if (leveledUp || fresh.isNotEmpty) {
      _celebration = Celebration(
        level: leveledUp ? nextStats.level : null,
        badges: [for (final b in badges) if (fresh.contains(b.id)) b],
      );
    }

    _apply(next.copyWith(seenBadges: unlocked, seenLevel: nextStats.level));
    _schedulePush();
  }

  /// Etwas zurücknehmen. Tombstones setzen, damit ein anderes Gerät den Eintrag
  /// nicht zurückschiebt, und `seenLevel` nachziehen — sonst feiert die App
  /// dasselbe Level beim nächsten Mal erneut.
  void _commitRemoved(
    Iterable<String> ids,
    String msg, {
    List<Session>? sessions,
    List<Walk>? walks,
    List<Treat>? treats,
    List<Stair>? stairs,
  }) {
    final prev = _data;
    final next = prev.copyWith(
      sessions: sessions,
      walks: walks,
      treats: treats,
      stairs: stairs,
    );
    final level = computeStats(
      next.sessions,
      next.walks,
      next.treats,
      next.stairs,
      prev.pauses,
    ).level;
    _apply(next.copyWith(
      deleted: {...prev.deleted, ...ids}.toList(),
      seenLevel: level,
    ));
    _schedulePush();
    flash(msg);
  }

  void addSession(SessionType type, Intensity intensity, [List<String> done = const []]) {
    final session = Session(
      id: _newId(),
      type: type,
      intensity: intensity,
      date: toISODate(DateTime.now()),
      ts: DateTime.now().millisecondsSinceEpoch,
      done: done,
    );
    _commitEarned(sessions: [..._data.sessions, session]);
  }

  void removeSession(String id) {
    _commitRemoved(
      [id],
      'Einheit entfernt.',
      sessions: [for (final s in _data.sessions) if (s.id != id) s],
    );
  }

  /// Spaziergang für einen Tag an- oder abhaken. Pro Tag zählt genau einer —
  /// ein zweiter Klick nimmt ihn wieder zurück.
  void toggleWalk(String date) {
    final existing = [for (final w in _data.walks) if (w.date == date) w];
    if (existing.isNotEmpty) {
      final ids = {for (final w in existing) w.id};
      _commitRemoved(
        ids,
        'Spaziergang entfernt.',
        walks: [for (final w in _data.walks) if (!ids.contains(w.id)) w],
      );
      return;
    }
    // ts trägt den Zeitpunkt des Eintragens – das Datum steht in `date`.
    final walk = Walk(
      id: _newId(),
      date: date,
      ts: DateTime.now().millisecondsSinceEpoch,
    );
    _commitEarned(walks: [..._data.walks, walk]);
  }

  /// Etwas Süßes eintragen. Anders als beim Spaziergang gibt es hier kein
  /// Umschalten: jeder Eintrag zählt einzeln, beliebig oft am Tag — und kostet
  /// XP. Vergangene Tage lassen sich nachtragen, künftige nicht.
  void addTreat(String date, TreatKind kind) {
    if (date.compareTo(toISODate(DateTime.now())) > 0) return;
    final entry = Treat(
      id: _newId(),
      date: date,
      kind: kind,
      ts: DateTime.now().millisecondsSinceEpoch,
    );
    _commitEarned(treats: [..._data.treats, entry]);
  }

  /// Den jüngsten Eintrag dieses Tages zurücknehmen — für den Fehlgriff.
  void removeTreat(String date, TreatKind kind) {
    final todays = [
      for (final t in _data.treats)
        if (t.date == date && t.kind == kind) t,
    ];
    if (todays.isEmpty) return;
    final last = todays.last;
    _commitRemoved(
      [last.id],
      'Eintrag zurückgenommen.',
      treats: [for (final t in _data.treats) if (t.id != last.id) t],
    );
  }

  /// Treppe genommen — zählt sofort, beliebig oft am Tag.
  void addStair() {
    final stair = Stair(
      id: _newId(),
      date: toISODate(DateTime.now()),
      ts: DateTime.now().millisecondsSinceEpoch,
    );
    _commitEarned(stairs: [..._data.stairs, stair]);
  }

  /// Den jüngsten heutigen Aufstieg zurücknehmen — für den Fall eines Fehlklicks.
  void removeStair() {
    final today = toISODate(DateTime.now());
    final todays = [for (final s in _data.stairs) if (s.date == today) s];
    if (todays.isEmpty) return;
    final last = todays.last;
    _commitRemoved(
      [last.id],
      'Aufstieg zurückgenommen.',
      stairs: [for (final s in _data.stairs) if (s.id != last.id) s],
    );
  }

  /// Pausenmodus an- oder abschalten. Kein `_commitEarned`: eine Pause schaltet
  /// nichts frei, sie friert nur die Streaks ein.
  void togglePause() {
    final active = isPauseActive(_data.pauses);
    final event = PauseEvent(
      id: _newId(),
      date: toISODate(DateTime.now()),
      ts: DateTime.now().millisecondsSinceEpoch,
      action: active ? PauseAction.stop : PauseAction.start,
    );
    _apply(_data.copyWith(pauses: [..._data.pauses, event]));
    _schedulePush();
    flash(active
        ? 'Pause beendet — weiter geht’s!'
        : 'Pausenmodus aktiv. Deine Streaks sind sicher.');
  }

  /// Import & Zurücksetzen ersetzen den Server-Stand, statt ihn zu mergen.
  Future<void> _replaceEverywhere(AppData next, String msg) async {
    final local = _normalizeSeen(next);
    _apply(local);
    flash(msg);
    try {
      _setSync(SyncState.syncing);
      await replaceOnServer(local);
      _setSync(SyncState.synced);
    } on UnauthorizedError {
      _setSync(SyncState.unauthorized);
    } catch (_) {
      _setSync(SyncState.offline);
    }
  }

  Future<void> resetAll() => _replaceEverywhere(AppData.empty, 'Alle Daten gelöscht.');

  /// Import aus der Zwischenablage — das native Gegenstück zum Datei-Upload.
  Future<void> importJson(String text) async {
    try {
      final incoming = decodeBackup(text);
      await _replaceEverywhere(
        incoming,
        '${incoming.sessions.length} Einheiten importiert.',
      );
    } catch (_) {
      flash('Das war kein gültiges Backup.');
    }
  }

  String exportJson() => encodeBackup(_data);
}
