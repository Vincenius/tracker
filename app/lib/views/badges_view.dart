import 'package:flutter/material.dart';

import '../core/badges.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/card.dart';
import '../widgets/hold_icon.dart';

/// Portierung von web/src/components/BadgesView.tsx.
class BadgesView extends StatelessWidget {
  const BadgesView({super.key, required this.store});

  final TrackerStore store;

  @override
  Widget build(BuildContext context) {
    final stats = store.stats;
    final items = [for (final b in badges) (badge: b, progress: b.progress(stats))]
      ..sort((a, b) {
        final done = (b.progress >= 1 ? 1 : 0) - (a.progress >= 1 ? 1 : 0);
        if (done != 0) return done;
        final secret = (a.badge.secret ? 1 : 0) - (b.badge.secret ? 1 : 0);
        if (secret != 0) return secret;
        return b.progress.compareTo(a.progress);
      });
    final unlocked = items.where((i) => i.progress >= 1).length;
    final hiddenSecrets = items.where((i) => i.badge.secret && i.progress < 1).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TrackerCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CardTitle('Abzeichen'),
              const SizedBox(height: 4),
              Text.rich(
                TextSpan(
                  text: '$unlocked von ${badges.length} freigeschaltet. '
                      'Kein Ablaufdatum — alles bleibt dir.',
                  style: const TextStyle(fontSize: 14, color: C.chalkDim),
                  children: [
                    if (hiddenSecrets > 0)
                      TextSpan(
                        text: ' $hiddenSecrets '
                            '${hiddenSecrets == 1 ? 'Überraschung wartet' : 'Überraschungen warten'}'
                            ' noch.',
                        style: const TextStyle(color: C.chalkFaint),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        for (final item in items) ...[
          const SizedBox(height: 12),
          _BadgeTile(badge: item.badge, progress: item.progress, label: item.badge.label(stats)),
        ],
      ],
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.badge, required this.progress, required this.label});

  final Achievement badge;
  final double progress;
  final String label;

  @override
  Widget build(BuildContext context) {
    final done = progress >= 1;
    final veiled = badge.secret && !done;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: C.rock900.withValues(alpha: 0.8),
        border: Border.all(color: done ? badge.color : C.rock800),
        borderRadius: BorderRadius.circular(16),
        boxShadow: chalkEdge,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HoldIcon(size: 36, filled: done, color: done ? badge.color : C.rock600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (veiled ? 'Überraschung' : badge.name).toUpperCase(),
                  style: displaySize(17, color: done ? C.chalk : C.chalkDim),
                ),
                const SizedBox(height: 4),
                Text(
                  veiled
                      ? 'Taucht auf, sobald du sie dir verdient hast.'
                      : badge.desc,
                  style: const TextStyle(fontSize: 14, color: C.chalkDim),
                ),
                if (!veiled) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: C.rock800,
                      valueColor: AlwaysStoppedAnimation(done ? badge.color : C.rock500),
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Hint(veiled ? '???' : (done ? 'Freigeschaltet ✓' : label)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
