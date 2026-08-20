import 'date.dart';
import 'types.dart';

/// Cheat Day: ein selbst gewählter Tag, an dem die Ernährung übersprungen wird
/// — wie ein Pausentag, nur bewusst gesetzt. Er bricht keine Serie, zählt aber
/// auch nicht als sauberer Tag und bringt keine XP. Einer pro Woche.
/// Portierung von web/src/lib/cheat.ts.
const cheatPerWeek = 1;

class CheatInfo {
  const CheatInfo(this.dates, this.byWeek);

  /// Alle gültigen Cheat-Tage als ISO-Daten
  final Set<String> dates;

  /// Der gültige Cheat-Tag je Woche: Wochen-Key → ISO-Datum
  final Map<String, String> byWeek;
}

/// Pro Woche zählt genau ein Cheat Day. Zwei Geräte können offline denselben
/// Zeitraum markieren — beim Mergen bleiben beide Einträge erhalten. Damit
/// überall dieselbe Rechnung herauskommt, gewinnt der älteste Eintrag der
/// Woche; bei gleichem Zeitstempel entscheidet die ID.
CheatInfo cheatInfo(List<CheatDay> days) {
  final winners = <String, CheatDay>{};
  for (final day in days) {
    final key = weekKeyOf(day.date);
    final held = winners[key];
    if (held == null ||
        day.ts < held.ts ||
        (day.ts == held.ts && day.id.compareTo(held.id) < 0)) {
      winners[key] = day;
    }
  }
  final byWeek = <String, String>{};
  final dates = <String>{};
  winners.forEach((key, day) {
    byWeek[key] = day.date;
    dates.add(day.date);
  });
  return CheatInfo(dates, byWeek);
}
