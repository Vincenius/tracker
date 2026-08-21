import 'package:flutter/material.dart';

import '../core/stats.dart';
import '../core/types.dart';
import '../theme.dart';
import 'card.dart';

const _stairColor = C.gradeYellow;

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
  final VoidCallback addStair;
  final VoidCallback removeStair;

  @override
  Widget build(BuildContext context) {
    final status = stairToday == 0
        ? 'Aufzug links liegen lassen — jeder Aufstieg zählt.'
        : 'Heute schon $stairToday× die Treppe genommen.';

    return TrackerCard(
      accent: _stairColor,
      active: stairToday > 0,
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
              value: stairToday,
              child: Text.rich(
                TextSpan(
                  text: '$stairToday',
                  style: displaySize(22),
                  children: [
                    TextSpan(text: '×', style: displaySize(22, color: C.chalkFaint)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Opacity(
                opacity: stairToday == 0 ? 0.35 : 1,
                child: Material(
                  color: C.rock850,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: stairToday == 0 ? null : removeStair,
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
                    onTap: addStair,
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
          Hint(
            stairStreak > 0
                ? '🔥 $stairStreak ${stairStreak == 1 ? 'Tag' : 'Tage'} in Folge · '
                    'diese Woche ${week.stairCount}×'
                : 'So oft du willst — jeder Aufstieg bringt $xpStair XP. '
                    'Diese Woche ${week.stairCount}×.',
          ),
        ],
      ),
    );
  }
}
