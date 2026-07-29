import 'package:flutter/material.dart';

import '../core/date.dart';
import '../core/stats.dart';
import '../core/types.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/card.dart';
import '../widgets/nutrition_card.dart';
import '../widgets/session_card.dart';
import '../widgets/stair_card.dart';
import '../widgets/walk_card.dart';

/// Portierung von web/src/components/WeekView.tsx.
class WeekView extends StatelessWidget {
  const WeekView({super.key, required this.store});

  final TrackerStore store;

  @override
  Widget build(BuildContext context) {
    final stats = store.stats;
    final key = currentWeekKey();
    final week = stats.weeks[key] ?? summarizeWeek(key, const []);
    final sessions = week.sessions;
    final count = sessions.length;
    bool has(SessionType t) => sessions.any((s) => s.type == t);

    final status = count == 0
        ? 'Frische Woche. Zwei Einheiten – du kennst den Plan.'
        : count == 1
            ? 'Eine geschafft. Noch eine bis zum Wochenziel.'
            : count == 2
                ? 'Wochenziel erreicht. Stark!'
                : 'Wochenziel übertroffen. Chapeau!';

    final showBoulder = !has(SessionType.fallback) || has(SessionType.boulder);
    final showFallback = !has(SessionType.boulder) || has(SessionType.fallback);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (stats.pauseActive) ...[
          _PauseBanner(stats: stats, onEnd: store.togglePause),
          const SizedBox(height: 16),
        ],
        _Summary(stats: stats, week: week, weekKey: key, count: count, status: status),
        const SizedBox(height: 16),
        NutritionCard(stats: stats, toggleClean: store.toggleClean),
        const SizedBox(height: 16),
        WalkCard(week: week, toggleWalk: store.toggleWalk, walkStreak: stats.walkStreak),
        const SizedBox(height: 16),
        StairCard(
          week: week,
          stairToday: stats.stairToday,
          stairStreak: stats.stairStreak,
          addStair: store.addStair,
          removeStair: store.removeStair,
        ),
        const SizedBox(height: 16),
        SessionCard(
          type: SessionType.home,
          done: [for (final s in sessions) if (s.type == SessionType.home) s],
          onComplete: store.addSession,
          onRemove: store.removeSession,
        ),
        if (showBoulder) ...[
          const SizedBox(height: 16),
          SessionCard(
            type: SessionType.boulder,
            done: [for (final s in sessions) if (s.type == SessionType.boulder) s],
            onComplete: store.addSession,
            onRemove: store.removeSession,
          ),
        ],
        if (showFallback) ...[
          const SizedBox(height: 16),
          if (!has(SessionType.fallback))
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 0, 4, 12),
              child: Text(
                'Bouldern klappt diese Woche nicht? Dann hol dir die Woche hiermit zurück.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: C.chalkFaint),
              ),
            ),
          SessionCard(
            type: SessionType.fallback,
            done: [for (final s in sessions) if (s.type == SessionType.fallback) s],
            onComplete: store.addSession,
            onRemove: store.removeSession,
          ),
        ],
        if (!stats.pauseActive) ...[
          const SizedBox(height: 16),
          _PauseButton(onTap: store.togglePause),
        ],
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.stats,
    required this.week,
    required this.weekKey,
    required this.count,
    required this.status,
  });

  final Stats stats;
  final WeekSummary week;
  final String weekKey;
  final int count;
  final String status;

  @override
  Widget build(BuildContext context) {
    final goals = [
      (label: 'Training', done: count, goal: 2, color: C.tape),
      (label: 'Spaziergänge', done: week.walkDays, goal: walkGoal, color: C.gradeGreen),
      (label: 'Sauber', done: week.cleanBothDays, goal: cleanGoal, color: C.mint),
    ];

    return TrackerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _GoalRing(count: count),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KW ${weekNumber(weekKey)} · ${weekRangeLabel(weekKey)}'.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.2,
                        color: C.chalkFaint,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(status.toUpperCase(), style: displaySize(18)),
                    const SizedBox(height: 4),
                    Text(
                      stats.currentStreak > 0
                          ? '🔥 ${stats.currentStreak} '
                              '${stats.currentStreak == 1 ? 'Woche' : 'Wochen'} in Folge'
                          : 'Jede Woche ist ein neuer Start.',
                      style: const TextStyle(fontSize: 14, color: C.chalkDim),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: C.rock800, height: 1),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('LEVEL ${stats.level}', style: displaySize(18)),
              const Spacer(),
              Text(
                '${stats.xpInLevel} / $xpPerLevel XP',
                style: const TextStyle(fontSize: 14, color: C.chalkDim),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 10,
              child: Stack(
                children: [
                  Container(color: C.rock800),
                  FractionallySizedBox(
                    widthFactor: stats.xpInLevel / xpPerLevel,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [C.tape, C.gradeYellow]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Hint('Noch ${stats.xpToNext} XP bis Level ${stats.level + 1}.'),
          const SizedBox(height: 16),
          // Die drei Wochenziele auf einen Blick — jedes zählt für sich.
          Row(
            children: [
              for (final g in goals)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: g == goals.last ? 0 : 8),
                    child: _GoalTile(
                      label: g.label,
                      done: g.done,
                      goal: g.goal,
                      color: g.color,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({
    required this.label,
    required this.done,
    required this.goal,
    required this.color,
  });

  final String label;
  final int done;
  final int goal;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final hit = done >= goal;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: C.rock850,
        border: Border.all(color: hit ? color : C.rock700),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text.rich(
            TextSpan(
              text: '${done < goal ? done : goal}',
              style: displaySize(18, color: hit ? color : C.chalk),
              children: [
                TextSpan(text: '/$goal', style: displaySize(18, color: C.chalkFaint)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, letterSpacing: 0.8, color: C.chalkFaint),
          ),
        ],
      ),
    );
  }
}

class _GoalRing extends StatelessWidget {
  const _GoalRing({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final pct = (count / 2).clamp(0.0, 1.0);
    return SizedBox(
      width: 76,
      height: 76,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: pct,
              strokeWidth: 7,
              strokeCap: StrokeCap.round,
              backgroundColor: C.rock700,
              valueColor: AlwaysStoppedAnimation(pct >= 1 ? C.gradeGreen : C.tape),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${count < 2 ? count : 2}', style: displaySize(22)),
              const Text(
                'VON 2',
                style: TextStyle(fontSize: 10, letterSpacing: 1, color: C.chalkFaint),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PauseBanner extends StatelessWidget {
  const _PauseBanner({required this.stats, required this.onEnd});

  final Stats stats;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: C.rock900.withValues(alpha: 0.8),
        border: Border.all(color: C.gradeYellow),
        borderRadius: BorderRadius.circular(16),
        boxShadow: chalkEdge,
      ),
      child: Row(
        children: [
          const Text('⏸️', style: TextStyle(fontSize: 24, height: 1)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PAUSENMODUS AKTIV', style: displaySize(17)),
                const SizedBox(height: 2),
                Text(
                  '${stats.pausedSince != null ? 'Seit ${shortDate(stats.pausedSince!)}. ' : ''}'
                  'Deine Streaks sind eingefroren — was du trotzdem einträgst, '
                  'zählt ganz normal.',
                  style: const TextStyle(fontSize: 14, color: C.chalkDim),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: onEnd,
            style: FilledButton.styleFrom(
              backgroundColor: C.gradeYellow,
              foregroundColor: C.rock950,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Beenden', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _PauseButton extends StatelessWidget {
  const _PauseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DottedBorderBox(
        child: Text(
          '🏖️ Urlaub oder krank? Pausenmodus starten — deine Streaks bleiben erhalten.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: C.chalkFaint),
        ),
      ),
    );
  }
}

/// Gestrichelter Rahmen — Flutters Border kennt kein `dashed`, deshalb gemalt.
class DottedBorderBox extends StatelessWidget {
  const DottedBorderBox({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedPainter(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: child,
      ),
    );
  }
}

class _DashedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = C.rock700;
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(16),
    );
    final path = Path()..addRRect(rect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + 6;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0.0, metric.length)),
          paint,
        );
        distance = next + 5;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedPainter oldDelegate) => false;
}
