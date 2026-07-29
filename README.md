# TRACKER

Eine selbst gehostete Sportroutine — **zwei Einheiten pro Woche**, **ein
Spaziergang an jedem Werktag**, **Treppe statt Aufzug** und **jeden Tag sauber
essen**. Zwei Frontends, ein Backend, eine JSON-Datei.

| Ordner / Datei | Was drin ist |
| --- | --- |
| [`web/`](web) | React-PWA **und** das Backend (Node, ohne Dependencies). Siehe [`web/README.md`](web/README.md). |
| [`app/`](app) | Native App mit Flutter (iOS, Android, macOS). Siehe [`app/README.md`](app/README.md). |
| [`docker-compose.yml`](docker-compose.yml) | Deploy des Backends. Baut aus `./web`, läuft aber **von hier** — `./data` und `.env` liegen daneben. |
| `data/` | Die einzige Datei mit deinen Daten (`data/tracker.json`). Nicht eingecheckt. |
| `.env` | `TRACKER_TOKEN` & Co., aus [`.env.example`](.env.example). Nicht eingecheckt. |

> Compose immer aus dem Repo-Root starten, **nicht** aus `web/`. Sonst nennt
> Compose das Projekt nach dem Verzeichnis, und der Bind-Mount `./data` zeigt
> ins Leere statt auf die vorhandenen Daten.

> `data/` muss dem Container-User gehören: Docker legt einen fehlenden
> Mount-Ordner als `root` an, der Container läuft aber als `node` (uid 1000).
> Dann liest die App noch, aber jeder Sync scheitert. Einmalig auf dem Server:
> `sudo chown -R 1000:1000 data`. Das Backend sagt beim Start Bescheid, wenn
> der Ordner nicht beschreibbar ist.

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
# Deploy (Repo-Root)
docker compose up -d --build                  # http://<server>:3025

# Entwicklung: Backend + Web
cd web && npm install && npm run dev:all      # http://localhost:3025

# Native App gegen dasselbe Backend
cd app && flutter run --dart-define=TRACKER_BASE_URL=http://localhost:3025
```
