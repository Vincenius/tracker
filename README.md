# TRACKER

Eine selbst gehostete Sportroutine — **zwei Einheiten pro Woche**, **ein
Spaziergang an jedem Werktag**, **Treppe statt Aufzug** und **jeden Tag sauber
essen**. Zwei Frontends, ein Backend, eine JSON-Datei.

| Ordner | Was drin ist |
| --- | --- |
| [`web/`](web) | React-PWA **und** das Backend (Node, ohne Dependencies). Siehe [`web/README.md`](web/README.md). |
| [`app/`](app) | Native App mit Flutter (iOS, Android, macOS). Siehe [`app/README.md`](app/README.md). |

Das Backend in `web/server/index.js` ist die einzige Quelle der Wahrheit. Die
Web-App liefert es gleich mit aus, die native App spricht dieselbe API an:

```
GET  /api/data     aktueller Stand
POST /api/sync     Stand des Clients einmischen, gemergten Stand zurückgeben
PUT  /api/data     Stand hart ersetzen (Import / Zurücksetzen)
```

Beide Clients rechnen XP, Level, Serien und Abzeichen **lokal** aus denselben
Rohdaten — das Backend speichert nur Einträge und merged sie. Deshalb liegt die
Logik doppelt vor und muss zusammen geändert werden:

| Web (TypeScript) | App (Dart) |
| --- | --- |
| `web/src/lib/types.ts` | `app/lib/core/types.dart` |
| `web/src/lib/date.ts` | `app/lib/core/date.dart` |
| `web/src/lib/stats.ts` | `app/lib/core/stats.dart` |
| `web/src/lib/badges.ts` | `app/lib/core/badges.dart` |
| `web/src/lib/merge.ts` + `web/server/index.js` | `app/lib/core/merge.dart` |
| `web/src/lib/pause.ts` | `app/lib/core/pause.dart` |
| `web/src/lib/workouts.ts` | `app/lib/core/workouts.dart` |
| `web/src/lib/nutrition.ts` | `app/lib/core/nutrition.dart` |
| `web/src/lib/store.ts` | `app/lib/store.dart` |

`app/test/core_test.dart` hält die Zahlen der Portierung fest — nach Änderungen
an der Logik dort `flutter test` laufen lassen.

## Schnellstart

```bash
# Backend + Web
cd web && npm install && npm run dev:all      # http://localhost:3025

# Native App gegen dasselbe Backend
cd app && flutter run --dart-define=TRACKER_BASE_URL=http://localhost:3025
```
