/// Alle Wochen laufen Montag–Sonntag. Wochen-Key = ISO-Datum des Montags.
///
/// Gerechnet wird über den DateTime-Konstruktor statt über `add(Duration)` —
/// nur so bleibt „ein Tag weiter“ über Sommerzeitwechsel hinweg ein Kalendertag.
library;

String _two(int n) => n < 10 ? '0$n' : '$n';

String toISODate(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

DateTime fromISODate(String iso) {
  final parts = iso.split('-');
  return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
}

DateTime startOfWeek(DateTime d) {
  final c = DateTime(d.year, d.month, d.day);
  return DateTime(c.year, c.month, c.day - (c.weekday - 1)); // weekday: Mo = 1
}

String addDays(String dateIso, int n) {
  final d = fromISODate(dateIso);
  return toISODate(DateTime(d.year, d.month, d.day + n));
}

/// Montag–Freitag. Spaziergänge zielen nur auf diese Tage.
bool isWeekday(String dateIso) {
  final dow = fromISODate(dateIso).weekday;
  return dow >= DateTime.monday && dow <= DateTime.friday;
}

/// Der vorherige Werktag — das Wochenende wird übersprungen, nicht gewertet.
String prevWeekday(String dateIso) {
  var d = addDays(dateIso, -1);
  while (!isWeekday(d)) {
    d = addDays(d, -1);
  }
  return d;
}

String weekKeyOf(String dateIso) => toISODate(startOfWeek(fromISODate(dateIso)));

String currentWeekKey([DateTime? now]) => toISODate(startOfWeek(now ?? DateTime.now()));

String addWeeks(String weekKey, int n) => addDays(weekKey, n * 7);

const _months = [
  'Jan.', 'Feb.', 'März', 'Apr.', 'Mai', 'Juni',
  'Juli', 'Aug.', 'Sept.', 'Okt.', 'Nov.', 'Dez.',
];

const _weekdays = [
  'Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag', 'Sonntag',
];

String weekRangeLabel(String weekKey) {
  final mo = fromISODate(weekKey);
  final so = DateTime(mo.year, mo.month, mo.day + 6);
  return '${mo.day}. ${_months[mo.month - 1]} – ${so.day}. ${_months[so.month - 1]}';
}

int weekNumber(String weekKey) {
  // ISO-Kalenderwoche des Montags
  final d = fromISODate(weekKey);
  final target = DateTime(d.year, d.month, d.day + 3); // Donnerstag der Woche
  var firstThursday = DateTime(target.year, 1, 4);
  firstThursday = DateTime(
    firstThursday.year,
    firstThursday.month,
    firstThursday.day + ((11 - (firstThursday.weekday % 7)) % 7) - 3,
  );
  final days = target.difference(firstThursday).inHours / 24;
  return 1 + (days / 7).round();
}

String weekdayLabel(String dateIso) => _weekdays[fromISODate(dateIso).weekday - 1];

String shortDate(String dateIso) {
  final d = fromISODate(dateIso);
  return '${_two(d.day)}.${_two(d.month)}';
}

List<String> weeksBetween(String fromKey, String toKey) {
  final out = <String>[];
  var k = fromKey;
  var guard = 0;
  while (k.compareTo(toKey) <= 0 && guard++ < 2000) {
    out.add(k);
    k = addWeeks(k, 1);
  }
  return out;
}
