import 'package:flutter/material.dart';

import '../core/date.dart';
import '../core/stats.dart';
import '../core/types.dart';
import '../theme.dart';
import 'card.dart';

const _walkColor = C.gradeGreen;
const _days = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

/// Portierung von web/src/components/WalkCard.tsx.
class WalkCard extends StatelessWidget {
  const WalkCard({
    super.key,
    required this.week,
    required this.toggleWalk,
    required this.walkStreak,
  });

  final WeekSummary week;
  final void Function(String) toggleWalk;
  final int walkStreak;

  @override
  Widget build(BuildContext context) {
    final today = toISODate(DateTime.now());
    final isCurrentWeek = week.key == currentWeekKey();
    final walked = {for (final w in week.walks) w.date};

    final remaining = walkGoal - week.walkDays;
    final status = week.walkDays == 0
        ? 'Fünf kurze Runden — eine pro Werktag.'
        : week.walkDays >= walkGoal
            ? 'Alle fünf Werktage. Perfekte Woche!'
            : 'Noch $remaining ${remaining == 1 ? 'Tag' : 'Tage'} bis zur vollen Woche.';

    return TrackerCard(
      accent: _walkColor,
      active: week.walkPerfect,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardHeader(
            leading: const Text('🚶', style: TextStyle(fontSize: 24, height: 1)),
            chip: 'Mo – Fr',
            chipColor: _walkColor,
            title: 'Spaziergang',
            subtitle: status,
            trailing: Text.rich(
              TextSpan(
                text: '${week.walkDays}',
                style: displaySize(22),
                children: [
                  TextSpan(
                    text: '/$walkGoal',
                    style: displaySize(22, color: C.chalkFaint),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (var i = 0; i < _days.length; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i == _days.length - 1 ? 0 : 6),
                    child: Builder(
                      builder: (context) {
                        final date = addDays(week.key, i);
                        // Zukunft lässt sich nicht abhaken – vergangene Tage
                        // schon, falls das Eintragen mal untergeht.
                        final future = isCurrentWeek && date.compareTo(today) > 0;
                        return DayToggle(
                          label: _days[i],
                          on: walked.contains(date),
                          color: _walkColor,
                          today: date == today,
                          muted: i >= 5,
                          disabled: future,
                          semantics: '${weekdayLabel(date)}, ${shortDate(date)}',
                          onTap: () => toggleWalk(date),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Hint(
            walkStreak > 0
                ? '🔥 $walkStreak ${walkStreak == 1 ? 'Werktag' : 'Werktage'} in Folge · '
                    '+$xpWalk XP pro Runde'
                : 'Jeden Tag einzeln antippen. +$xpWalk XP pro Runde — Wochenende ist Zugabe.',
          ),
        ],
      ),
    );
  }
}
