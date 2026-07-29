import 'package:shared_preferences/shared_preferences.dart';

/// Wohin die App synchronisiert und womit sie sich ausweist.
///
/// Beides ist zur Bauzeit vorbelegbar und zur Laufzeit überschreibbar:
///
///   flutter build apk \
///     --dart-define=TRACKER_BASE_URL=https://tracker.example.com \
///     --dart-define=TRACKER_TOKEN=DEIN_TOKEN
///
/// Ohne `TRACKER_TOKEN` läuft die App tokenfrei — das ist der Normalfall und
/// passt zu einem Server, bei dem TRACKER_TOKEN in der .env leer bleibt. Setzt
/// der Server ein Token, trägt man es entweder hier zur Bauzeit ein oder in den
/// Einstellungen der App nach.
abstract final class Config {
  static const _baseUrlKey = 'tracker.baseUrl';
  static const _tokenKey = 'tracker.token';

  static const defaultBaseUrl =
      String.fromEnvironment('TRACKER_BASE_URL', defaultValue: 'http://localhost:3025');
  static const buildToken = String.fromEnvironment('TRACKER_TOKEN');

  static String baseUrl = defaultBaseUrl;
  static String token = buildToken;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final storedUrl = prefs.getString(_baseUrlKey);
    final storedToken = prefs.getString(_tokenKey);
    if (storedUrl != null && storedUrl.isNotEmpty) baseUrl = storedUrl;
    if (storedToken != null) token = storedToken;
  }

  static Future<void> setBaseUrl(String value) async {
    baseUrl = _normalize(value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, baseUrl);
  }

  static Future<void> setToken(String value) async {
    token = value.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Ohne Schema kommt `Uri.parse` nicht klar, und ein Schrägstrich am Ende
  /// würde zu `//api/sync` führen.
  static String _normalize(String raw) {
    var v = raw.trim();
    if (v.isEmpty) return v;
    if (!v.startsWith('http://') && !v.startsWith('https://')) v = 'http://$v';
    while (v.endsWith('/')) {
      v = v.substring(0, v.length - 1);
    }
    return v;
  }
}
