# TRACKER — Sportroutine

Eine sehr kleine, selbst gehostete Web-App für genau eine Routine: **zwei Einheiten
pro Woche**, **ein Spaziergang an jedem Werktag** und **jeden Tag sauber essen**.
Kein Login, kein Setup. Dahinter läuft ein winziges Backend, das alles in **einer
JSON-Datei** speichert — damit Handy und Desktop denselben Stand sehen.

Neben dieser Web-App gibt es eine native Variante mit Flutter in
[`../app`](../app), die dasselbe Backend nutzt. Wird die Logik hier geändert,
muss sie dort mitgezogen werden — die Zuordnung der Dateien steht im
[Haupt-README](../README.md).

## Die Routine

| Einheit | Tag | XP |
| --- | --- | --- |
| Bouldern (Halle) | Mittwoch | 20 |
| Home-Workout, volle Einheit (~15 Min, 2 Runden) | Montag | 14 |
| Home-Workout, Minimum (~5 Min, 1 Runde) | Montag | 8 |
| Fallback-Einheit mit Klimmzügen | flexibel | 16 (Minimum: 8) |
| Spaziergang | Montag – Freitag, einer pro Tag | 6 |
| Tag ohne Schokolade & Chips | täglich | 2 → 6, je nach Serie |
| Tag ohne Zuckergetränke | täglich | 2 → 6, je nach Serie |
| beide Ernährungs-Spuren am selben Tag | täglich | +2 Bonus |

**Wochenziel:** 2 Einheiten. Normalfall `Bouldern + Home`, in Wochen ohne Halle
`Home + Fallback`. Die Minimum-Version zählt voll mit — der Streak soll nicht an
einem stressigen Montag zerbrechen.

**Wochen-Streak** statt Tages-Streak: aufeinanderfolgende Wochen mit erreichtem Ziel.
Die laufende Woche bricht den Streak nie, solange sie noch läuft. Verpasste Wochen
werden im Verlauf neutral grau dargestellt — keine Warnungen, keine roten Zahlen.

**Spaziergänge** laufen daneben und nach eigener Rechnung: Ziel sind fünf Werktage
pro Woche, angehakt wird tageweise. Sie zählen **nicht** ins Wochenziel der
Einheiten — ein verpasster Spaziergang kostet also keinen Wochen-Streak, und ein
Spaziergang ersetzt kein Training. Ihre eigene Serie zählt aufeinanderfolgende
**Werktage**: das Wochenende unterbricht sie nicht, zählt aber auch nicht mit.
Der laufende Tag bricht die Serie nie. Am Wochenende lässt sich trotzdem einer
eintragen — er gibt XP, aber zählt nicht fürs Ziel.

**Ernährung** hat zwei getrennte Spuren, die jeden Tag laufen: *ohne Schokolade &
Chips* und *ohne zuckerhaltige Getränke*. Abgehakt wird pro Tag und Spur. Anders
als beim Rest **wächst die Belohnung mit der Serie**: der erste saubere Tag bringt
2 XP, jeder weitere Tag in Folge einen mehr — bis 6 XP ab Tag 5. Sind an einem Tag
beide Spuren sauber, kommen 2 XP Kombi-Bonus dazu. Ein Ausrutscher setzt nur den
Zähler zurück, verdiente XP bleiben; das Ziel ist Weitermachen, nicht Perfektion.
Wochenziel sind 7 von 7 Tagen in beiden Spuren. Vergangene Tage lassen sich
nachtragen, künftige nicht.

**Level:** alle 150 XP eins rauf, mit kleiner Animation. Einheiten, Spaziergänge
und saubere Tage zahlen auf dasselbe XP-Konto ein. Eine perfekte Woche —
2 Einheiten, 5 Spaziergänge, 7 saubere Tage in beiden Spuren — sind gut 160 XP,
also etwa ein Level pro Woche.

**41 Abzeichen** in [`src/lib/badges.ts`](src/lib/badges.ts) — Meilensteine wie
*Erstbegehung*, *Vier am Stück*, *Plan B gemeistert*, *Stammgast* (10× Halle),
*Hausnummer* (25× Halle), *Stangentanz* (10 Fallback-Einheiten), *Halbjahr*,
*Hundert*, *Zehnter Grad*; dazu Charakter-Abzeichen wie *Der Minimalist*
(5× Minimum), *Saubere Linie* (Checkliste komplett), *Nach Plan* (Mo + Mi wie
im Drehbuch) und *Zugabe* (Woche mit 3 Einheiten).

Für die Spaziergänge: *Erster Schritt*, *Von Montag bis Freitag* (volle Woche),
*Fünf Werktage* und *Vier Wochen am Stück* (Serien), *Feldweg* (25), *Hundert
Runden*, *Volle Wochen* (4× fünf von fünf) und *Doppelt geliefert* — eine Woche
mit Trainingsziel **und** allen fünf Spaziergängen.

Für die Ernährung: *Erster sauberer Tag*, *Sieben ohne Süßes* und *Sieben ohne
Zucker* (7er-Serien je Spur), *Saubere Woche* (7/7 in beiden Spuren), *Zwei Wochen
doppelt* (14 volle Tage am Stück), *Ein Monat ohne Riegel* und *Ein Monat nur
Wasser* (30er-Serien), *Hundert saubere Tage* und *Dreifach geliefert* — eine Woche
mit Trainingsziel, allen Spaziergängen **und** sieben sauberen Tagen.

Sieben davon sind **Überraschungen** und werden erst beim Freischalten sichtbar:
*Morgengrauen* (vor 9 Uhr), *Nachtschicht* (ab 21 Uhr), *Wochenend-Projekt*,
*Trotzdem* (eine Woche komplett im Minimum), *Wiedereinstieg* (volle Woche
nach ≥ 2 Wochen Pause), *Extrarunde* (5 Spaziergänge am Wochenende) und
*Neu angesetzt* (nach einem Ausrutscher wieder 7 volle Tage in Folge). Alle
Bedingungen werden aus den vorhandenen Einträgen berechnet — auch rückwirkend, wenn neue Abzeichen dazukommen.

## Screens

1. **Diese Woche** — was noch offen ist, große Abhak-Buttons (Bouldern = ein Tap),
   Wochenziel-Ring, Streak, Level und XP-Balken, dazu die drei Wochenziele
   (Training / Spaziergänge / Sauber) nebeneinander. Jede Einheit lässt sich
   aufklappen: Übungsliste als optionale Checkliste plus Timer für Plank/Runden.
   Darüber die Tageskarte *Heute sauber?* mit den zwei Ernährungs-Schaltern,
   darunter die Spaziergangs-Karte mit einer Reihe Mo–So: antippen hakt den Tag ab,
   nochmal antippen nimmt ihn zurück. Vergangene Tage lassen sich nachtragen,
   künftige nicht.
2. **Ernährung** — pro Spur eine Karte mit der Woche Mo–So, der aktuellen Serie und
   einer Leiter, die zeigt, was der nächste Tag wert ist. Darunter die letzten
   8 Wochen als Kalender zum Nachtragen und eine kurze Erklärung der Punkte.
3. **Verlauf** — Heatmap über die Wochen (Contribution-Graph-Stil), ein Raster der
   Werktage mit Spaziergang, eine Zeile pro Ernährungs-Spur, Statistiken und
   Export/Import/Zurücksetzen der Daten.
4. **Abzeichen** — freigeschaltete und offene Badges mit Fortschrittsbalken.

## Mehrere Geräte / Synchronisation

Das Backend ([`server/index.js`](server/index.js)) ist eine einzige Node-Datei
**ohne Dependencies**. Es liefert die gebaute App aus und kennt drei Endpunkte:

| Route | Zweck |
| --- | --- |
| `GET /api/data` | aktueller Stand |
| `POST /api/sync` | Stand des Geräts einmischen, gemergten Stand zurückgeben |
| `PUT /api/data` | Stand hart ersetzen (Import / Zurücksetzen) |

Der Client hält weiterhin eine Kopie im `localStorage` — die App startet dadurch
sofort und funktioniert **offline** (z.B. im Keller der Boulderhalle) weiter.
Synchronisiert wird beim Start, nach jeder Änderung, beim Zurückkehren zur App
und einmal pro Minute. Der Punkt oben rechts zeigt den Zustand (grün = synchron,
grau = offline) und synchronisiert per Klick sofort.

**Merge statt Überschreiben:** Einheiten, Spaziergänge und saubere Tage sind
unveränderlich und haben eine eindeutige ID, gemergt wird also die Vereinigung beider Stände. Gelöschte
Einträge landen in `deleted` (Tombstones), damit ein zweites Gerät sie nicht
wieder hochschiebt. Zwei Geräte können damit auch offline nebeneinander abhaken,
ohne dass etwas verloren geht.

### Zugriffsschutz per Token (optional)

Der Token kommt aus der Umgebungsvariable **`TRACKER_TOKEN`** — lokal wie im
Container aus einer `.env`-Datei, die nicht eingecheckt wird:

```bash
cp .env.example .env
echo "TRACKER_TOKEN=$(openssl rand -hex 16)" >> .env
docker compose up -d          # compose liest .env automatisch
```

Ist die Variable **leer oder nicht gesetzt**, läuft alles ohne Schutz — praktisch
im LAN oder hinter VPN. Ist sie **gesetzt**, ist *alles* gesperrt: die API **und**
die App selbst. Jedes Gerät öffnet dann einmalig

```
http://<server>:3025/?token=<dein-token>
```

Der Server setzt daraufhin den Cookie `tracker_token` (`HttpOnly`, ein Jahr) und
leitet auf die saubere URL um — der Token bleibt also nicht in History oder
Lesezeichen stehen. Ohne gültigen Token kommt `401`, bei der App als kleine
Sperrseite statt des Tracker-Frontends. Im offenen Internet solltest du den Token
setzen — oder den Reverse Proxy mit Basic Auth davorhängen.

Frei erreichbar bleiben nur die Icons (`/icon-*.png`, `/apple-touch-icon.png`,
`/favicon.svg`): sie enthalten keine Daten, und manche Browser holen Manifest-Icons
ohne Cookie — sonst schlüge die Installation als App fehl.

| Variable | Default | Zweck |
| --- | --- | --- |
| `TRACKER_TOKEN` | *(leer)* | Zugriffsschutz, leer = offen |
| `PORT` | `3025` | Port des Backends |
| `DATA_FILE` | `./data/tracker.json`, im Container `/data/tracker.json` | Speicherort |
| `STATIC_DIR` | `./dist` | ausgelieferte Frontend-Dateien |

## Als App aufs Handy (PWA)

Die App ist installierbar: Seite im Browser öffnen → **Zum Home-Bildschirm**
(iOS: Teilen-Menü, Android: Menü oder der Installieren-Hinweis). Danach läuft sie
ohne Browser-Leiste und startet auch offline mit dem zuletzt gecachten Stand;
synchronisiert wird, sobald der Server wieder erreichbar ist.

Zusammenspiel mit dem Token: Das Manifest wird vom Server erzeugt und trägt den
Token in der `start_url`. Das ist nötig, weil iOS einer installierten App einen
**eigenen Cookie-Speicher** gibt — der Cookie aus Safari gilt dort nicht, die App
würde sonst direkt auf der Sperrseite landen. Nebenwirkung: Der Token steckt damit
in der Installation auf dem Gerät. Wer das nicht will, lässt `TRACKER_TOKEN` leer
und schützt stattdessen über VPN oder Reverse Proxy.

Nach einem Tokenwechsel muss die App einmal neu über den `?token=`-Link geöffnet
(bzw. neu installiert) werden.

Wer lieber eine echte native App möchte: [`../app`](../app) baut dieselbe
Oberfläche mit Flutter für iOS, Android und macOS — ohne Token, solange
`TRACKER_TOKEN` leer bleibt.

Die Icons liegen in `public/` und werden aus dem Griff-Motiv generiert:

```bash
npm run icons        # nur nötig, wenn du Form oder Farben änderst
```

## Entwicklung

```bash
npm install
cp .env.example .env  # optional, für TRACKER_TOKEN & Co.
npm run dev:all  # Backend (:3025) + Vite-Dev-Server -> http://localhost:3025
npm run dev      # nur Frontend (läuft dann rein lokal/offline)
npm run build    # Produktions-Build nach dist/
npm run start    # Backend liefert dist/ aus -> http://localhost:3025
```

Vite proxyt `/api` im Dev-Modus auf `localhost:3025`. Die Daten landen dabei in
`data/tracker.json`, die Konfiguration liest Node per `--env-file-if-exists=.env`
— beides ist per `.gitignore` ausgenommen.

Stack: Vite + React + TypeScript + Tailwind v4, Backend Node ohne Dependencies.
Schriften (Anton, Inter) werden über `@fontsource` mitgebündelt — die App braucht
zur Laufzeit kein externes Netz.

## Deploy auf dem Server (Port 3025)

```bash
git clone <repo> tracker && cd tracker
docker compose up -d --build
```

Danach läuft die App auf `http://<server>:3025`. Das Image ist ein zweistufiger
Build: Node baut das Frontend, das schlanke Runtime-Image startet nur noch
`server/index.js` (als User `node`, ohne Dependencies).

Die Daten liegen auf dem Host in `./data/tracker.json` — das ist das Volume aus
der `docker-compose.yml` und überlebt jedes Rebuild.

Updates:

```bash
git pull && docker compose up -d --build
```

Hinter einem Reverse Proxy (Caddy/Traefik/nginx) einfach auf `localhost:3025`
weiterleiten. **Empfehlung:** per HTTPS ausliefern — sonst gehen die Daten im
Klartext übers Netz.

## Backups

Am einfachsten auf dem Server:

```bash
cp data/tracker.json backups/tracker-$(date +%F).json
```

In der App geht es auch ohne Shell: Verlauf → *Daten* → **Export (JSON)** lädt
`tracker-backup-JJJJ-MM-TT.json` herunter. **Import** ersetzt den Stand — lokal
*und* auf dem Server, also bewusst einsetzen.

## Datenformat

```jsonc
{
  "version": 1,
  "sessions": [
    {
      "id": "m2x4k1-a9f3b2",
      "type": "home",        // "boulder" | "home" | "fallback"
      "intensity": "full",   // "full" | "min"
      "date": "2026-07-20",  // ISO-Datum
      "ts": 1753000000000,
      "done": ["pushups", "plank"] // optional abgehakte Übungen
    }
  ],
  "walks": [
    {
      "id": "m2x4k2-77c1de",
      "date": "2026-07-20",  // ein Eintrag pro Tag
      "ts": 1753000000000    // Zeitpunkt des Eintragens
    }
  ],
  "cleanDays": [
    {
      "id": "m2x4k3-1b8ee0",
      "date": "2026-07-20",  // ein Eintrag pro Tag und Spur
      "kind": "snacks",      // "snacks" | "drinks"
      "ts": 1753000000000
    }
  ],
  "seenBadges": ["first-week"],
  "seenLevel": 2,
  "deleted": ["alte-id"]        // Tombstones gelöschter Einträge
}
```

Identisch auf dem Server (`data/tracker.json`) und im `localStorage`
(`tracker.v1`). Alles Weitere (XP, Level, Streaks, Badges, Heatmap) wird daraus
berechnet — es gibt keinen doppelt gespeicherten Zustand, der auseinanderlaufen
könnte.
