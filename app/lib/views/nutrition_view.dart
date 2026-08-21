import 'package:flutter/material.dart';

import '../core/date.dart';
import '../core/nutrition.dart';
import '../core/stats.dart';
import '../core/types.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/card.dart';

const _days = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
const _historyWeeks = 8;

/// Je mehr Einträge an einem Tag, desto kräftiger die Farbe.
Color _cellColor(int count, Color color) {
  if (count <= 0) return C.rock800;
  if (count == 1) return mix(color, C.rock800, 0.45);
  if (count == 2) return mix(color, C.rock800, 0.72);
  return color;
}

/// Portierung von web/src/components/NutritionView.tsx.
class NutritionView extends StatelessWidget {
  const NutritionView({super.key, required this.store});

  final TrackerStore store;

  @override
  Widget build(BuildContext context) {
    final stats = store.stats;
    final today = toISODate(DateTime.now());
    final weekKey = currentWeekKey();
    final start = addWeeks(weekKey, -(_historyWeeks - 1));
    final historyWeeks = [for (var i = 0; i < _historyWeeks; i++) addWeeks(start, i)];

    final streak = stats.cleanStreak;
    final status = stats.treatToday > 0
        ? 'Heute ${stats.treatToday}× eingetragen. Morgen zählt neu.'
        : streak > 0
            ? '$streak ${streak == 1 ? 'Tag' : 'Tage'} ohne Süßes am Stück.'
            : 'Ab heute wieder sauber. Nichts eintragen ist das Ziel.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TrackerCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'ERNÄHRUNG',
                style: TextStyle(fontSize: 11, letterSpacing: 1.6, color: C.chalkFaint),
              ),
              const SizedBox(height: 4),
              Text(status.toUpperCase(), style: displaySize(18)),
              const SizedBox(height: 4),
              const Text(
                'Kein Kalorienzählen und keine Punkte fürs Weglassen. Nur ein Zähler '
                'für das, was doch süß war — jeder Eintrag kostet $xpTreat XP.',
                style: TextStyle(fontSize: 14, color: C.chalkDim),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  for (final s in [
                    ('${stats.cleanStreak}', 'Tage sauber'),
                    ('${stats.longestCleanStreak}', 'Bestserie'),
                    (
                      stats.treatXpLost > 0 ? '−${stats.treatXpLost}' : '0',
                      'XP verloren'
                    ),
                  ])
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: s.$2 == 'XP verloren' ? 0 : 8),
                        child: StatTile(value: s.$1, label: s.$2, big: false),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        for (final lane in laneList) ...[
          const SizedBox(height: 16),
          _LaneCard(
            lane: lane,
            stats: stats.lanes[lane.kind]!,
            weekKey: weekKey,
            today: today,
            addTreat: store.addTreat,
            removeTreat: store.removeTreat,
          ),
        ],
        const SizedBox(height: 16),
        TrackerCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CardTitle(
                'Letzte $_historyWeeks Wochen',
                subtitle: 'Vergessen einzutragen? Tippen trägt nach, '
                    'lange drücken nimmt zurück.',
              ),
              const SizedBox(height: 16),
              for (final lane in laneList) ...[
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(color: lane.color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      lane.short.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Deckel auf die Zellgröße, sonst wird das Raster auf dem Handy
                // zur halbmeterhohen Kachelwand.
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 304),
                  child: GridView.count(
                    crossAxisCount: 7,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                    children: [
                      for (final d in _days)
                        Center(
                          child: Text(
                            d,
                            style: const TextStyle(fontSize: 10, color: C.chalkFaint),
                          ),
                        ),
                      for (final wk in historyWeeks)
                        for (var i = 0; i < 7; i++)
                          Builder(
                            builder: (context) {
                              final date = addDays(wk, i);
                              final count = stats.lanes[lane.kind]!.perDay[date] ?? 0;
                              final future = date.compareTo(today) > 0;
                              return Opacity(
                                opacity: future ? 0.25 : 1,
                                child: GestureDetector(
                                  onTap: future ? null : () => store.addTreat(date, lane.kind),
                                  onLongPress: future || count == 0
                                      ? null
                                      : () => store.removeTreat(date, lane.kind),
                                  child: Container(
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: _cellColor(count, lane.color),
                                      border: Border.all(
                                        color: count > 0
                                            ? Colors.transparent
                                            : date == today
                                                ? C.tape
                                                : C.rock700,
                                      ),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        TrackerCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CardTitle('Wie die Punkte laufen'),
              const SizedBox(height: 8),
              const _Bullet(
                'Sauber essen bringt keine XP — es ist der Normalfall, nicht die Leistung.',
              ),
              const _Bullet(
                'Jeder Eintrag kostet $xpTreat XP, so oft am Tag, wie es eben passiert '
                'ist. $xpPerLevel XP sind ein Level.',
              ),
              const _Bullet(
                'Ein Tag ohne Eintrag ist ein sauberer Tag. $cleanGoal Tage in Folge '
                'sind eine Woche — dafür gibt es Abzeichen.',
              ),
              const _Bullet(
                'Unter null geht das Konto nie. Ein schlechter Tag kostet Fortschritt, '
                'nicht alles Erreichte.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('· ', style: TextStyle(color: C.chalkDim)),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 14, color: C.chalkDim)),
          ),
        ],
      ),
    );
  }
}

class _LaneCard extends StatelessWidget {
  const _LaneCard({
    required this.lane,
    required this.stats,
    required this.weekKey,
    required this.today,
    required this.addTreat,
    required this.removeTreat,
  });

  final LaneMeta lane;
  final LaneStats stats;
  final String weekKey;
  final String today;
  final void Function(String, TreatKind) addTreat;
  final void Function(String, TreatKind) removeTreat;

  @override
  Widget build(BuildContext context) {
    final weekDates = [for (var i = 0; i < 7; i++) addDays(weekKey, i)];
    var weekCount = 0;
    for (final d in weekDates) {
      weekCount += stats.perDay[d] ?? 0;
    }

    return TrackerCard(
      accent: lane.color,
      active: weekCount > 0,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardHeader(
            leading: Text(lane.emoji, style: const TextStyle(fontSize: 24, height: 1)),
            chip: '−$xpTreat XP',
            chipColor: lane.color,
            title: lane.short,
            subtitle: lane.tagline,
            trailing: Text.rich(
              TextSpan(
                text: '$weekCount',
                style: displaySize(22),
                children: [
                  TextSpan(text: '×', style: displaySize(22, color: C.chalkFaint)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i == 6 ? 0 : 6),
                    child: _CountDay(
                      label: _days[i],
                      count: stats.perDay[weekDates[i]] ?? 0,
                      color: lane.color,
                      today: weekDates[i] == today,
                      // Die Zukunft lässt sich nicht eintragen.
                      disabled: weekDates[i].compareTo(today) > 0,
                      semantics: '${weekdayLabel(weekDates[i])}, '
                          '${shortDate(weekDates[i])} — ${lane.title}: '
                          '${stats.perDay[weekDates[i]] ?? 0}×',
                      onAdd: () => addTreat(weekDates[i], lane.kind),
                      onRemove: () => removeTreat(weekDates[i], lane.kind),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Hint(
            (weekCount == 0
                    ? 'Diese Woche noch nichts eingetragen. So soll es aussehen.'
                    : 'Diese Woche $weekCount× · −${weekCount * xpTreat} XP') +
                (stats.cleanStreak > 0
                    ? ' · 🔥 ${stats.cleanStreak} '
                        '${stats.cleanStreak == 1 ? 'Tag' : 'Tage'} ohne'
                    : '') +
                (stats.longestCleanStreak > stats.cleanStreak
                    ? ' · Bestserie ${stats.longestCleanStreak} Tage'
                    : ''),
          ),
        ],
      ),
    );
  }
}

/// Ein Tag als Zähler: tippen trägt ein, lange drücken nimmt zurück. Ein
/// Umschalter reicht hier nicht — pro Tag sind beliebig viele Einträge möglich.
class _CountDay extends StatelessWidget {
  const _CountDay({
    required this.label,
    required this.count,
    required this.color,
    required this.today,
    required this.disabled,
    required this.semantics,
    required this.onAdd,
    required this.onRemove,
  });

  final String label;
  final int count;
  final Color color;
  final bool today;
  final bool disabled;
  final String semantics;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final foreground = count >= 2 ? C.rock950 : C.chalkDim;
    return Semantics(
      label: semantics,
      button: true,
      child: Opacity(
        opacity: disabled ? 0.35 : 1,
        child: Material(
          color: _cellColor(count, color),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: disabled ? null : onAdd,
            onLongPress: disabled || count == 0 ? null : onRemove,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
              decoration: BoxDecoration(
                border: Border.all(
                  color: count > 0
                      ? Colors.transparent
                      : today
                          ? C.tape
                          : C.rock700,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: foreground,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    count > 0 ? '$count' : '·',
                    style: TextStyle(fontSize: 16, height: 1, color: foreground),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
