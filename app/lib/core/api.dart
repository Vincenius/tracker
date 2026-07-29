import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';
import 'storage.dart';
import 'types.dart';

/// Der Server hat den Request mit 401 abgelehnt — Token fehlt oder ist falsch.
class UnauthorizedError implements Exception {
  const UnauthorizedError();
  @override
  String toString() => 'UnauthorizedError';
}

const _timeout = Duration(seconds: 12);

Map<String, String> _headers() => {
      'content-type': 'application/json',
      'cache-control': 'no-store',
      // Ohne Token bleibt der Header weg: ein Server ohne TRACKER_TOKEN
      // beantwortet die Requests dann ganz normal.
      if (Config.token.isNotEmpty) 'x-tracker-token': Config.token,
    };

Future<AppData> _request(
  String path,
  Future<http.Response> Function(Uri url, Map<String, String> headers, String body) send,
  AppData payload,
) async {
  final url = Uri.parse('${Config.baseUrl}$path');
  final res = await send(url, _headers(), jsonEncode(payload.toJson())).timeout(_timeout);
  if (res.statusCode == 401) throw const UnauthorizedError();
  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw http.ClientException('${res.statusCode}', url);
  }
  return parseData(jsonDecode(utf8.decode(res.bodyBytes)));
}

/// Lokalen Stand einmischen und den gemergten Server-Stand zurückbekommen.
Future<AppData> syncWithServer(AppData local) => _request(
      '/api/sync',
      (url, headers, body) => http.post(url, headers: headers, body: body),
      local,
    );

/// Server-Stand hart ersetzen (Import, Zurücksetzen).
Future<AppData> replaceOnServer(AppData data) => _request(
      '/api/data',
      (url, headers, body) => http.put(url, headers: headers, body: body),
      data,
    );
