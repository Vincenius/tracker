import 'package:flutter/material.dart';

import '../core/date.dart';
import '../core/nutrition.dart';
import '../core/stats.dart';
import '../core/types.dart';
import '../theme.dart';
import 'card.dart';

/// Die Tageskarte der Ernährung: nichts abzuhaken, nur mitzuzählen. Ein
/// sauberer Tag ist der Normalfall und bleibt leer — jeder Eintrag kostet XP.
/// Portierung von web/src/components/NutritionCard.tsx.
class NutritionCard extends StatelessWidget {
  const NutritionCard({
    super.key,
    required this.stats,
    required this.addTreat,
    required this.removeTreat,
  });

  final Stats stats;
  final void Function(String, TreatKind) addTreat;
  final void Function(String, TreatKind) removeTreat;

  @override
  Widget build(BuildContext context) {
    final today = toISODate(DateTime.now());
    final count = stats.treatToday;
    final streak = stats.cleanStreak;

    return TrackerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('HEUTE GENASCHT?', style: displaySize(22)),
              const Spacer(),
              Text(
                count == 0 ? 'NOCH SAUBER' : '$count× · −${count * xpTreat} XP',
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
            _LaneCounter(
              lane: lane,
              stats: stats.lanes[lane.kind]!,
              onAdd: () => addTreat(today, lane.kind),
              onRemove: () => removeTreat(today, lane.kind),
            ),
            const SizedBox(height: 8),
          ],
          Hint(
            count > 0
                ? 'Eingetragen ist besser als verdrängt — morgen ist wieder Tag eins.'
                : streak > 0
                    ? '🔥 $streak ${streak == 1 ? 'Tag' : 'Tage'} ohne Süßes. '
                        'Nichts eintragen heißt sauber.'
                    : 'Jeder Eintrag kostet $xpTreat XP. Nichts eintragen kostet nichts.',
          ),
        ],
      ),
    );
  }
}

class _LaneCounter extends StatelessWidget {
  const _LaneCounter({
    required this.lane,
    required this.stats,
    required this.onAdd,
    required this.onRemove,
  });

  final LaneMeta lane;
  final LaneStats stats;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final on = stats.today > 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: on ? tint(lane.color, 0.16) : C.rock850,
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
                  stats.today > 0
                      ? 'Heute ${stats.today}× · −${stats.today * xpTreat} XP'
                      : stats.cleanStreak > 0
                          ? '${stats.cleanStreak} '
                              '${stats.cleanStreak == 1 ? 'Tag' : 'Tage'} ohne'
                          : 'Heute noch nichts',
                  style: const TextStyle(fontSize: 12, color: C.chalkFaint),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _StepButton(
            label: '−',
            background: C.rock850,
            border: C.rock700,
            foreground: C.chalkDim,
            semantics: 'Letzten Eintrag zurücknehmen: ${lane.title}',
            onTap: stats.today == 0 ? null : onRemove,
          ),
          SizedBox(
            width: 28,
            child: Bump(
              value: stats.today,
              child: Text(
                '${stats.today}',
                textAlign: TextAlign.center,
                style: displaySize(20),
              ),
            ),
          ),
          _StepButton(
            label: '+',
            background: lane.color,
            border: lane.color,
            foreground: C.rock950,
            semantics: '${lane.title} eintragen',
            onTap: onAdd,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.label,
    required this.background,
    required this.border,
    required this.foreground,
    required this.semantics,
    this.onTap,
  });

  final String label;
  final Color background;
  final Color border;
  final Color foreground;
  final String semantics;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semantics,
      button: true,
      child: Opacity(
        opacity: onTap == null ? 0.35 : 1,
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: border),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
