# TRACKER — native App

Flutter-Klon der Web-App aus [`../web`](../web), gegen **dasselbe Backend**.
iOS, Android und macOS. Gleiche Daten, gleiche XP, gleiche Abzeichen — wer auf
dem Handy abhakt, sieht es im Browser und umgekehrt.

## Braucht die App ein Token?

**Nein.** Der Zugriffsschutz des Backends ist optional: Ist `TRACKER_TOKEN` in
der `.env` des Servers leer (Standard), ist die API offen und die App
funktioniert ohne jede Eingabe. Das einzige, was sie wissen muss, ist die
**Serveradresse** — eine native App kann keine relativen Pfade wie `/api/sync`
auflösen.

Setzt du auf dem Server ein Token, kommt es auf drei Wegen in die App:

1. **Zur Bauzeit** per `--dart-define=TRACKER_TOKEN=…` (siehe unten).
2. **Zur Laufzeit** über den Dialog *Server & Token* — Verlauf → „Server & Token“,
   oder langes Drücken auf den Sync-Punkt oben rechts.
3. **Über die Nachfrage**, die automatisch erscheint, sobald der Server mit 401
   antwortet.

Was gesetzt ist, landet in den `SharedPreferences` des Geräts und geht als
`x-tracker-token`-Header mit — dasselbe Verfahren wie im Web.

## Bauen

Ohne Token, Server im eigenen Netz:

```bash
flutter run --dart-define=TRACKER_BASE_URL=http://192.168.1.20:3025
```

Mit Token fest eingebaut:

```bash
flutter build apk --release \
  --dart-define=TRACKER_BASE_URL=https://tracker.example.com \
  --dart-define=TRACKER_TOKEN=DEIN_TOKEN

flutter build ipa --release \
  --dart-define=TRACKER_BASE_URL=https://tracker.example.com \
  --dart-define=TRACKER_TOKEN=DEIN_TOKEN

flutter build macos --release \
  --dart-define=TRACKER_BASE_URL=https://tracker.example.com \
  --dart-define=TRACKER_TOKEN=DEIN_TOKEN
```

Beide Werte sind nur **Vorbelegungen**: was in den Einstellungen gespeichert
wird, gewinnt. Ohne `TRACKER_BASE_URL` steht `http://localhost:3025` drin.

> Ein per `--dart-define` eingebautes Token steckt im Binary und ist mit etwas
> Mühe auslesbar. Für ein Gerät in der eigenen Hand ist das in Ordnung — für
> etwas anderes ist das Token-Modell des Backends ohnehin nicht gedacht.

## Klartext-HTTP

Läuft das Backend ohne TLS (der Normalfall im Heimnetz), blockieren die
Plattformen den Zugriff standardmäßig. Das ist bereits eingerichtet:

- **Android** — `android/app/src/main/res/xml/network_security_config.xml`
- **iOS** — `NSAppTransportSecurity` in `ios/Runner/Info.plist`
- **macOS** — `com.apple.security.network.client` in beiden `.entitlements`

Steht der Server hinter HTTPS, können die ersten beiden Ausnahmen weg.

## Aufbau

```
lib/
  main.dart              App-Rahmen, Navigation, Sync-Punkt, Token-Nachfrage
  store.dart             Zustand + Sync (Port von web/src/lib/store.ts)
  theme.dart             Farben aus web/src/index.css
  core/                  Reine Logik, 1:1 aus web/src/lib portiert
    types.dart  date.dart  stats.dart  badges.dart  merge.dart
    pause.dart  cheat.dart  storage.dart  api.dart  config.dart
    workouts.dart  nutrition.dart
  widgets/               Karten, Griff-Icon, Timer, Feier-Dialog
  views/                 Woche · Ernährung · Verlauf · Abzeichen · Einstellungen
test/core_test.dart      Hält die Zahlen der Portierung fest
```

Die Logik liegt bewusst doppelt vor (TypeScript im Web, Dart hier) — beide
Clients rechnen XP, Level, Serien und Abzeichen lokal aus denselben Rohdaten.
Welche Datei welcher entspricht, steht in der Tabelle im
[Haupt-README](../README.md).

## Unterschiede zur Web-App

Bewusst, weil nativ:

- **Export/Import über die Zwischenablage** statt Datei-Download und
  `<input type="file">`. Das Format ist identisch, Backups sind austauschbar.
- **Serveradresse einstellbar** — im Web ergibt sie sich aus der URL.
- **Kein Service Worker.** Die App hält ohnehin eine lokale Kopie und
  synchronisiert beim Start, beim Aufwachen und alle 60 Sekunden.
- **Systemschrift statt Anton/Inter.** Die Web-Fonts liegen als `woff2` vor, das
  kann Flutter nicht laden; die Display-Schrift ist als fette, weit laufende
  Systemschrift nachgebaut. Für den Originallook `.ttf`-Dateien in
  `assets/fonts/` legen und in `pubspec.yaml` eintragen.

## Entwicklung

```bash
flutter pub get
flutter analyze
flutter test
```
