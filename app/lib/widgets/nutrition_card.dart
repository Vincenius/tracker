import 'package:flutter/material.dart';

import '../core/date.dart';
import '../core/nutrition.dart';
import '../core/stats.dart';
import '../core/types.dart';
import '../theme.dart';
import 'card.dart';

/// Der Tages-Griff für die Wochenansicht: zwei Schalter, mehr nicht. Die
/// Ernährung ist die einzige Gewohnheit, die *jeden* Tag eine Entscheidung
/// verlangt — deshalb steht sie auch auf dem Startbildschirm.
/// Portierung von web/src/components/NutritionCard.tsx.
class NutritionCard extends StatelessWidget {
  const NutritionCard({super.key, required this.stats, required this.toggleClean});

  final Stats stats;
  final void Function(String, CleanKind) toggleClean;

  @override
  Widget build(BuildContext context) {
    final today = toISODate(DateTime.now());
    final openCombo = laneList.any((l) => !stats.lanes[l.kind]!.dates.contains(today));
    final bothToday = laneList.every((l) => stats.lanes[l.kind]!.dates.contains(today));

    return TrackerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('HEUTE SAUBER?', style: displaySize(22)),
              const Spacer(),
              Text(
                bothToday ? 'BEIDES ✓' : 'JEDEN TAG NEU',
                style: const TextStyle(
                  fontSize: 12,
                  letterSpacing: 0.8,
                  color: C.chalkFaint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final lane in laneList) ...[
            _LaneToggle(
              lane: lane,
              stats: stats.lanes[lane.kind]!,
              today: today,
              onTap: () => toggleClean(today, lane.kind),
            ),
            const SizedBox(height: 8),
          ],
          Hint(
            bothToday
                ? 'Beide Spuren sauber — inklusive +$xpCleanCombo XP Kombi-Bonus.'
                : openCombo
                    ? 'Jeder Tag in Folge bringt mehr XP. Beide an einem Tag: '
                        '+$xpCleanCombo extra.'
                    : '',
          ),
        ],
      ),
    );
  }
}

class _LaneToggle extends StatelessWidget {
  const _LaneToggle({
    required this.lane,
    required this.stats,
    required this.today,
    required this.onTap,
  });

  final LaneMeta lane;
  final LaneStats stats;
  final String today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final on = stats.dates.contains(today);
    return Material(
      color: on ? tint(lane.color, 0.16) : C.rock850,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: on ? lane.color : C.rock700),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Text(lane.emoji, style: const TextStyle(fontSize: 22, height: 1)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lane.title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      stats.currentStreak > 0
                          ? '🔥 ${stats.currentStreak} '
                              '${stats.currentStreak == 1 ? 'Tag' : 'Tage'} in Folge'
                          : 'Neue Serie startet heute',
                      style: const TextStyle(fontSize: 12, color: C.chalkFaint),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: on ? lane.color : C.rock800,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  on ? '✓' : '+${stats.nextXp}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: on ? C.rock950 : C.chalkDim,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
