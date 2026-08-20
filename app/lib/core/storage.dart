import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'types.dart';

/// Lokale Kopie des Stands, damit die App auch ohne Server läuft.
/// Gegenstück zu web/src/lib/storage.ts.
const _key = 'tracker.v1';

AppData parseData(Object? raw) {
  if (raw is! Map) return AppData.empty;

  List<T> pick<T>(Object? list, T? Function(Object?) parse) {
    if (list is! List) return [];
    final out = <T>[];
    for (final item in list) {
      final parsed = parse(item);
      if (parsed != null) out.add(parsed);
    }
    return out;
  }

  List<String> strings(Object? v) =>
      v is List ? [for (final x in v) if (x is String) x] : <String>[];

  return AppData(
    sessions: pick(raw['sessions'], Session.fromJson)..sort((a, b) => a.ts - b.ts),
    walks: pick(raw['walks'], Walk.fromJson)..sort((a, b) => a.ts - b.ts),
    cleanDays: pick(raw['cleanDays'], CleanDay.fromJson)..sort((a, b) => a.ts - b.ts),
    stairs: pick(raw['stairs'], Stair.fromJson)..sort((a, b) => a.ts - b.ts),
    cheatDays: pick(raw['cheatDays'], CheatDay.fromJson)..sort((a, b) => a.ts - b.ts),
    pauses: pick(raw['pauses'], PauseEvent.fromJson)..sort((a, b) => a.ts - b.ts),
    seenBadges: strings(raw['seenBadges']),
    seenLevel: raw['seenLevel'] is num ? (raw['seenLevel'] as num).toInt() : 1,
    deleted: strings(raw['deleted']),
  );
}

Future<AppData> loadData() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return AppData.empty;
    return parseData(jsonDecode(raw));
  } catch (_) {
    return AppData.empty;
  }
}

Future<void> saveData(AppData data) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(data.toJson()));
  } catch (_) {
    // Speicher voll oder blockiert – die App läuft trotzdem weiter.
  }
}

String encodeBackup(AppData data) =>
    const JsonEncoder.withIndent('  ').convert(data.toJson());

AppData decodeBackup(String text) => parseData(jsonDecode(text));
