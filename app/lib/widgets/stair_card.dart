import 'package:flutter/material.dart';

import '../core/date.dart';
import '../core/stats.dart';
import '../core/types.dart';
import '../theme.dart';
import 'card.dart';
import 'count_day.dart';

const _stairColor = C.gradeYellow;
const _days = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

/// Portierung von web/src/components/StairCard.tsx.
class StairCard extends StatelessWidget {
  const StairCard({
    super.key,
    required this.week,
    required this.stairToday,
    required this.stairStreak,
    required this.addStair,
    required this.removeStair,
  });

  final WeekSummary week;
  final int stairToday;
  final int stairStreak;
  final void Function(String date) addStair;
  final void Function(String date) removeStair;

  @override
  Widget build(BuildContext context) {
    final today = toISODate(DateTime.now());
    final isCurrentWeek = week.key == currentWeekKey();
    final perDay = <String, int>{};
    for (final s in week.stairs) {
      perDay[s.date] = (perDay[s.date] ?? 0) + 1;
    }

    // In einer vergangenen Woche gibt es kein „heute“ — da zählt die Woche.
    final shown = isCurrentWeek ? stairToday : week.stairCount;
    final status = !isCurrentWeek
        ? week.stairCount == 0
              ? 'Keine Treppe eingetragen. Vergessen? Tag antippen trägt nach.'
              : 'In dieser Woche ${week.stairCount}× die Treppe genommen.'
        : stairToday == 0
        ? 'Aufzug links liegen lassen — jeder Aufstieg zählt.'
        : 'Heute schon $stairToday× die Treppe genommen.';

    return TrackerCard(
      accent: _stairColor,
      active: shown > 0,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardHeader(
            leading: const Text('🪜', style: TextStyle(fontSize: 24, height: 1)),
            chip: 'Unbegrenzt',
            chipColor: _stairColor,
            title: 'Treppe',
            subtitle: status,
            trailing: Bump(
              value: shown,
              child: Text.rich(
                TextSpan(
                  text: '$shown',
                  style: displaySize(22),
                  children: [
                    TextSpan(
                      text: '×',
                      style: displaySize(22, color: C.chalkFaint),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (isCurrentWeek) ...[
            Row(
              children: [
                Opacity(
                  opacity: stairToday == 0 ? 0.35 : 1,
                  child: Material(
                    color: C.rock850,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: stairToday == 0 ? null : () => removeStair(today),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(color: C.rock700),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '−',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: C.chalkDim,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Material(
                    color: _stairColor,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => addStair(today),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 48,
                        alignment: Alignment.center,
                        child: Text(
                          '+ Treppe genommen · $xpStair XP',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: C.rock950,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          // Die Woche Tag für Tag — vergessene Aufstiege lassen sich nachtragen.
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i == 6 ? 0 : 6),
                    child: Builder(
                      builder: (_) {
                        final date = addDays(week.key, i);
                        final count = perDay[date] ?? 0;
                        return CountDay(
                          label: _days[i],
                          count: count,
                          color: _stairColor,
                          today: date == today,
                          disabled: date.compareTo(today) > 0,
                          semantics: '${weekdayLabel(date)}, ${shortDate(date)} — Treppe: $count×',
                          onAdd: () => addStair(date),
                          onRemove: () => removeStair(date),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Hint(
            '${stairStreak > 0 ? '🔥 $stairStreak ${stairStreak == 1 ? 'Tag' : 'Tage'} in Folge · '
                      'diese Woche ${week.stairCount}×' : 'So oft du willst — jeder Aufstieg bringt $xpStair XP. '
                      'Diese Woche ${week.stairCount}×.'} '
            'Tag antippen trägt nach, lange drücken nimmt zurück.',
          ),
        ],
      ),
    );
  }
}
