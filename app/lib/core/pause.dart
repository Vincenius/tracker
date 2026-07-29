import 'date.dart';
import 'types.dart';

/// Pausenmodus: pausierte Tage brechen keine Streaks — sie werden übersprungen,
/// als gäbe es sie nicht. Was trotzdem eingetragen wird, zählt ganz normal.

/// Das jüngste Ereignis entscheidet: 'start' heißt aktiv.
bool isPauseActive(List<PauseEvent> events) {
  var active = false;
  for (final e in [...events]..sort((a, b) => a.ts - b.ts)) {
    active = e.action == PauseAction.start;
  }
  return active;
}

class PauseInfo {
  const PauseInfo(this.paused, this.activeSince);

  /// Alle pausierten ISO-Tage, inklusive Start- und Stop-Tag.
  final Set<String> paused;

  /// Startdatum der offenen Pause — null, wenn keine läuft.
  final String? activeSince;
}

PauseInfo pauseInfo(List<PauseEvent> events, String today) {
  final paused = <String>{};
  String? openSince;
  for (final e in [...events]..sort((a, b) => a.ts - b.ts)) {
    if (e.action == PauseAction.start) {
      openSince ??= e.date;
    } else if (openSince != null) {
      _addRange(paused, openSince, e.date.compareTo(today) < 0 ? e.date : today);
      openSince = null;
    }
  }
  if (openSince != null) _addRange(paused, openSince, today);
  return PauseInfo(paused, openSince);
}

/// Auch der Stop-Tag zählt als pausiert — großzügig, der Rückreisetag bricht nichts.
void _addRange(Set<String> into, String from, String to) {
  var d = from;
  var guard = 0;
  while (d.compareTo(to) <= 0 && guard++ < 1500) {
    into.add(d);
    d = addDays(d, 1);
  }
}
