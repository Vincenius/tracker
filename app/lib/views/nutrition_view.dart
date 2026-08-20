import 'package:flutter/material.dart';

import '../core/cheat.dart';
import '../core/date.dart';
import '../core/nutrition.dart';
import '../core/stats.dart';
import '../core/types.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/card.dart';

const _days = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
const _historyWeeks = 8;

/// Der Cheat Day gehört zu keiner Spur — deshalb eine eigene Farbe.
const _cheatColor = C.gradeYellow;

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

    final both = stats.cleanBothStreak;
    final status = both > 0
        ? '$both ${both == 1 ? 'Tag' : 'Tage'} komplett sauber am Stück.'
        : stats.lanes[CleanKind.snacks]!.currentStreak > 0 ||
                stats.lanes[CleanKind.drinks]!.currentStreak > 0
            ? 'Eine Spur läuft schon. Die zweite dazu und es gibt Bonus.'
            : 'Heute ist Tag eins. Zwei Häkchen, mehr braucht es nicht.';

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
                'Kein Kalorienzählen. Nur zwei Fragen pro Tag — und für jeden Tag '
                'in Folge mehr XP.',
                style: TextStyle(fontSize: 14, color: C.chalkDim),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  for (final s in [
                    (stats.cleanBothDays, 'Volle Tage'),
                    (stats.longestCleanBothStreak, 'Bestserie'),
                    (stats.cleanXp, 'XP daraus'),
                  ])
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: s.$2 == 'XP daraus' ? 0 : 8),
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
            cheatDates: stats.cheatDates,
            weekKey: weekKey,
            today: today,
            toggleClean: store.toggleClean,
          ),
        ],
        const SizedBox(height: 16),
        _CheatCard(
          picked: stats.cheatThisWeek,
          weekKey: weekKey,
          today: today,
          toggleCheat: store.toggleCheat,
        ),
        const SizedBox(height: 16),
        TrackerCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CardTitle(
                'Letzte $_historyWeeks Wochen',
                subtitle: 'Vergessen einzutragen? Vergangene Tage lassen sich hier nachtragen.',
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
                              final on = stats.lanes[lane.kind]!.dates.contains(date);
                              final cheat = stats.cheatDates.contains(date);
                              final future = date.compareTo(today) > 0;
                              return Opacity(
                                opacity: future ? 0.25 : 1,
                                child: GestureDetector(
                                  onTap: future
                                      ? null
                                      : () => store.toggleClean(date, lane.kind),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: on ? lane.color : C.rock800,
                                      border: Border.all(
                                        color: on
                                            ? Colors.transparent
                                            : cheat
                                                ? _cheatColor
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
              _Bullet(
                'Erster sauberer Tag: +${xpForCleanDay(1)} XP. Jeder weitere Tag in '
                'Folge einen mehr, bis +$xpCleanCap XP ab Tag $cleanCapDay.',
              ),
              _Bullet(
                'Beide Spuren am selben Tag: +$xpCleanCombo XP Kombi-Bonus obendrauf.',
              ),
              _Bullet(
                'Ein Ausrutscher setzt nur den Zähler zurück — verdiente XP bleiben. '
                '$xpPerLevel XP sind ein Level.',
              ),
              _Bullet(
                'Cheat Day: $cheatPerWeek× pro Woche ein Tag, der übersprungen wird. '
                'Keine XP, aber die Serie läuft weiter.',
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
    required this.cheatDates,
    required this.weekKey,
    required this.today,
    required this.toggleClean,
  });

  final LaneMeta lane;
  final LaneStats stats;
  final Set<String> cheatDates;
  final String weekKey;
  final String today;
  final void Function(String, CleanKind) toggleClean;

  @override
  Widget build(BuildContext context) {
    final weekDates = [for (var i = 0; i < 7; i++) addDays(weekKey, i)];
    final weekDone = weekDates.where(stats.dates.contains).length;
    final perfect = weekDone >= cleanGoal;

    return TrackerCard(
      accent: lane.color,
      active: perfect,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardHeader(
            leading: Text(lane.emoji, style: const TextStyle(fontSize: 24, height: 1)),
            chip: 'Täglich',
            chipColor: lane.color,
            title: lane.short,
            subtitle: lane.tagline,
            trailing: Text.rich(
              TextSpan(
                text: '$weekDone',
                style: displaySize(22),
                children: [
                  TextSpan(
                    text: '/$cleanGoal',
                    style: displaySize(22, color: C.chalkFaint),
                  ),
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
                    child: DayToggle(
                      label: _days[i],
                      on: stats.dates.contains(weekDates[i]),
                      color: lane.color,
                      today: weekDates[i] == today,
                      // Die Zukunft lässt sich nicht abhaken — der Tag ist noch offen.
                      disabled: weekDates[i].compareTo(today) > 0,
                      offMark: cheatDates.contains(weekDates[i]) ? '🍕' : '·',
                      offBorder:
                          cheatDates.contains(weekDates[i]) ? _cheatColor : null,
                      semantics: '${weekdayLabel(weekDates[i])}, '
                          '${shortDate(weekDates[i])} — ${lane.title}'
                          '${cheatDates.contains(weekDates[i]) ? ' (Cheat Day)' : ''}',
                      onTap: () => toggleClean(weekDates[i], lane.kind),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _StreakLadder(lane: lane, stats: stats),
          const SizedBox(height: 10),
          Hint(
            stats.currentStreak > 0
                ? '🔥 ${stats.currentStreak} '
                    '${stats.currentStreak == 1 ? 'Tag' : 'Tage'} in Folge · '
                    '${stats.dates.contains(today) ? 'morgen' : 'heute'} +${stats.nextXp} XP'
                    '${stats.longestStreak > stats.currentStreak ? ' · Bestserie ${stats.longestStreak} Tage' : ''}'
                : 'Der erste Tag bringt +${xpForCleanDay(1)} XP, jeder weitere mehr — '
                    'bis +$xpCleanCap.'
                    '${stats.longestStreak > stats.currentStreak ? ' · Bestserie ${stats.longestStreak} Tage' : ''}',
          ),
        ],
      ),
    );
  }
}

/// Der Cheat Day ist die Notbremse der Ernährung: ein Tag pro Woche, an dem
/// nichts zählt — weder als sauberer Tag noch als Ausrutscher. Bewusst gesetzt
/// statt automatisch verrechnet, damit die Entscheidung sichtbar bleibt.
class _CheatCard extends StatelessWidget {
  const _CheatCard({
    required this.picked,
    required this.weekKey,
    required this.today,
    required this.toggleCheat,
  });

  final String? picked;
  final String weekKey;
  final String today;
  final void Function(String) toggleCheat;

  @override
  Widget build(BuildContext context) {
    final weekDates = [for (var i = 0; i < 7; i++) addDays(weekKey, i)];

    return TrackerCard(
      accent: _cheatColor,
      active: picked != null,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardHeader(
            leading: const Text('🍕', style: TextStyle(fontSize: 24, height: 1)),
            chip: '$cheatPerWeek× pro Woche',
            chipColor: _cheatColor,
            title: 'Cheat Day',
            subtitle: picked != null
                ? '${weekdayLabel(picked!)}, ${shortDate(picked!)} zählt nicht — '
                    'deine Serien laufen weiter.'
                : 'Ein Tag pro Woche, an dem die Ernährung nicht zählt. '
                    'Die Serie bricht nicht.',
            trailing: Text.rich(
              TextSpan(
                text: picked != null ? '1' : '0',
                style: displaySize(22),
                children: [
                  TextSpan(
                    text: '/$cheatPerWeek',
                    style: displaySize(22, color: C.chalkFaint),
                  ),
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
                    child: DayToggle(
                      label: _days[i],
                      on: weekDates[i] == picked,
                      color: _cheatColor,
                      today: weekDates[i] == today,
                      // Die Zukunft bleibt offen, und ist der Tag vergeben,
                      // führt nur der Weg über den gesetzten Tag zurück.
                      disabled: weekDates[i].compareTo(today) > 0 ||
                          (picked != null && weekDates[i] != picked),
                      onMark: '🍕',
                      semantics: '${weekdayLabel(weekDates[i])}, '
                          '${shortDate(weekDates[i])} — Cheat Day',
                      onTap: () => toggleCheat(weekDates[i]),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Hint(
            picked != null
                ? 'Nochmal antippen nimmt ihn zurück — dann ist die Woche wieder frei.'
                : 'Der Tag bringt keine XP, er hält nur die Serie am Leben. '
                    'Am Montag gibt es einen neuen.',
          ),
        ],
      ),
    );
  }
}

/// Die Leiter zeigt, was der nächste Tag wert ist — und wo die Serie steht.
class _StreakLadder extends StatelessWidget {
  const _StreakLadder({required this.lane, required this.stats});

  final LaneMeta lane;
  final LaneStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var day = 1; day <= cleanCapDay; day++)
          Expanded(
            child: Builder(
              builder: (context) {
                final reached = stats.currentStreak >= day;
                final next = stats.currentStreak + 1 == day;
                return Column(
                  children: [
                    Container(
                      width: 12,
                      height: 10 + day * 6,
                      decoration: BoxDecoration(
                        color: reached
                            ? lane.color
                            : next
                                ? tint(lane.color, 0.45)
                                : C.rock800,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '+${xpForCleanDay(day)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: reached || next ? C.chalkDim : C.chalkFaint,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        Expanded(
          flex: 2,
          child: Column(
            children: [
              Container(
                width: 28,
                height: 10 + cleanCapDay * 6,
                decoration: BoxDecoration(
                  color: stats.currentStreak > cleanCapDay ? lane.color : C.rock800,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                ),
              ),
              const SizedBox(height: 4),
              const Text('danach', style: TextStyle(fontSize: 10, color: C.chalkFaint)),
            ],
          ),
        ),
      ],
    );
  }
}
