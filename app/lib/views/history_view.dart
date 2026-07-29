import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/date.dart';
import '../core/nutrition.dart';
import '../core/stats.dart';
import '../core/types.dart';
import '../core/workouts.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/card.dart';
import 'settings_sheet.dart';

/// Portierung von web/src/components/HistoryView.tsx.
class HistoryView extends StatefulWidget {
  const HistoryView({super.key, required this.store});

  final TrackerStore store;

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  bool _confirmReset = false;

  Color _cellColor(WeekSummary w) {
    if (w.count == 1) return mix(C.gradeGreen, C.rock800, 0.32);
    if (w.count == 2) return C.gradeGreen;
    if (w.count >= 3) return C.gradeYellow;
    return C.rock800;
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final stats = store.stats;

    // Mindestens 26 Wochen anzeigen, auch wenn die Historie kürzer ist.
    final thisWeek = currentWeekKey();
    final minStart = addWeeks(thisWeek, -25);
    final first = stats.orderedWeeks.isNotEmpty &&
            stats.orderedWeeks.first.key.compareTo(minStart) < 0
        ? stats.orderedWeeks.first.key
        : minStart;
    final weeks = [
      for (final k in weeksBetween(first, thisWeek))
        stats.weeks[k] ?? summarizeWeek(k, const []),
    ];

    // Werktage der letzten 8 Wochen, zeilenweise Mo–Fr.
    final todayDate = toISODate(DateTime.now());
    final walkedDates = {
      for (final w in stats.orderedWeeks)
        for (final walk in w.walks) walk.date,
    };
    final recent = weeks.length > 8 ? weeks.sublist(weeks.length - 8) : weeks;
    final walkDays = [
      for (final w in recent)
        for (var i = 0; i < 5; i++)
          (
            date: addDays(w.key, i),
            done: walkedDates.contains(addDays(w.key, i)),
            future: addDays(w.key, i).compareTo(todayDate) > 0,
          ),
    ];
    // Ernährung läuft an allen sieben Tagen — hier die letzten 8 Wochen am Stück.
    final foodDays = [
      for (final w in recent)
        for (var i = 0; i < 7; i++)
          (date: addDays(w.key, i), future: addDays(w.key, i).compareTo(todayDate) > 0),
    ];

    final totalSessions = stats.total == 0 ? 1 : stats.total;
    final dist = [
      for (final t in SessionType.values)
        (type: t, n: stats.byType[t]!, pct: stats.byType[t]! / totalSessions * 100),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TrackerCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CardTitle(
                'Wochen-Verlauf',
                subtitle: 'Jedes Feld ist eine Woche. Grün heißt: Ziel erreicht.',
              ),
              const SizedBox(height: 16),
              _Grid(
                cell: 26,
                children: [
                  for (final w in weeks)
                    Container(
                      decoration: BoxDecoration(
                        color: _cellColor(w),
                        border: Border.all(
                          color: w.key == thisWeek
                              ? C.tape
                              : w.count == 0
                                  ? C.rock700
                                  : Colors.transparent,
                          width: w.key == thisWeek ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: w.fallbackWeek
                          ? Align(
                              alignment: Alignment.bottomRight,
                              child: Padding(
                                padding: const EdgeInsets.all(2),
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: C.gradePurple,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            )
                          : null,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  _Legend(color: C.rock800, label: 'keine Einheit', bordered: true),
                  _Legend(color: mix(C.gradeGreen, C.rock800, 0.32), label: 'eine'),
                  const _Legend(color: C.gradeGreen, label: 'Ziel erreicht'),
                  const _Legend(color: C.gradePurple, label: 'Fallback-Woche', round: true),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _StatRow(children: [
          StatTile(value: stats.total, label: 'Einheiten gesamt'),
          StatTile(value: stats.currentStreak, label: 'Wochen-Streak'),
          StatTile(value: stats.longestStreak, label: 'Längster Streak'),
          StatTile(value: stats.fulfilledWeeks, label: 'Volle Wochen'),
        ]),
        const SizedBox(height: 20),
        TrackerCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CardTitle(
                'Spaziergänge',
                subtitle: 'Ein Punkt pro Werktag der letzten Wochen. '
                    'Das Wochenende bleibt frei.',
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 5,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                children: [
                  for (final d in walkDays)
                    Opacity(
                      opacity: d.future ? 0.3 : 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: d.done ? C.gradeGreen : C.rock800,
                          border: Border.all(
                            color: d.done ? Colors.transparent : C.rock700,
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _StatRow(children: [
                StatTile(value: stats.walkTotal, label: 'Spaziergänge'),
                StatTile(value: stats.walkStreak, label: 'Tage-Streak'),
                StatTile(value: stats.longestWalkStreak, label: 'Längster Streak'),
                StatTile(value: stats.walkPerfectWeeks, label: 'Volle Wochen'),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 20),
        TrackerCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CardTitle(
                'Treppe',
                subtitle: 'Jeder Aufstieg zählt — so oft am Tag, wie du magst.',
              ),
              const SizedBox(height: 16),
              _StatRow(children: [
                StatTile(value: stats.stairTotal, label: 'Aufstiege'),
                StatTile(value: stats.stairDays, label: 'Tage mit Treppe'),
                StatTile(value: stats.stairBestDay, label: 'Tagesrekord'),
                StatTile(value: stats.longestStairStreak, label: 'Längster Streak'),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 20),
        TrackerCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CardTitle(
                'Ernährung',
                subtitle: 'Zwei Zeilen pro Woche: oben Schokolade & Chips, '
                    'unten Zuckergetränke.',
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
                      lane.short,
                      style: const TextStyle(fontSize: 12, color: C.chalkFaint),
                    ),
                    const Spacer(),
                    Text(
                      '${stats.lanes[lane.kind]!.total} Tage · '
                      'Bestserie ${stats.lanes[lane.kind]!.longestStreak}',
                      style: const TextStyle(fontSize: 12, color: C.chalkFaint),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _Grid(
                  cell: 14,
                  spacing: 4,
                  children: [
                    for (final d in foodDays)
                      Opacity(
                        opacity: d.future ? 0.3 : 1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: stats.lanes[lane.kind]!.dates.contains(d.date)
                                ? lane.color
                                : C.rock800,
                            border: Border.all(
                              color: stats.lanes[lane.kind]!.dates.contains(d.date)
                                  ? Colors.transparent
                                  : C.rock700,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              _StatRow(children: [
                StatTile(value: stats.cleanBothDays, label: 'Volle Tage'),
                StatTile(value: stats.cleanBothStreak, label: 'Tage-Streak'),
                StatTile(value: stats.longestCleanBothStreak, label: 'Längster Streak'),
                StatTile(value: stats.cleanPerfectWeeks, label: 'Volle Wochen'),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 20),
        TrackerCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CardTitle('Verteilung'),
              if (stats.total == 0) ...[
                const SizedBox(height: 8),
                const Text(
                  'Noch keine Einheiten — das ändert sich gleich.',
                  style: TextStyle(fontSize: 14, color: C.chalkDim),
                ),
              ] else ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: SizedBox(
                    height: 12,
                    child: Row(
                      children: [
                        for (final d in dist)
                          if (d.n > 0)
                            Expanded(
                              flex: d.n,
                              child: ColoredBox(color: sessionMeta[d.type]!.color),
                            ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                for (final d in dist)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: sessionMeta[d.type]!.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          sessionMeta[d.type]!.title,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const Spacer(),
                        Text(
                          '${d.n} · ${d.pct.round()}%',
                          style: const TextStyle(fontSize: 14, color: C.chalkDim),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        _DataCard(
          store: store,
          confirmReset: _confirmReset,
          onResetTap: () {
            if (_confirmReset) {
              store.resetAll();
              setState(() => _confirmReset = false);
            } else {
              setState(() => _confirmReset = true);
            }
          },
        ),
      ],
    );
  }
}

class _DataCard extends StatelessWidget {
  const _DataCard({
    required this.store,
    required this.confirmReset,
    required this.onResetTap,
  });

  final TrackerStore store;
  final bool confirmReset;
  final VoidCallback onResetTap;

  @override
  Widget build(BuildContext context) {
    return TrackerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CardTitle('Daten'),
          const SizedBox(height: 4),
          Text(
            store.sync == SyncState.offline
                ? 'Gerade kein Server erreichbar — alles läuft lokal weiter und wird '
                    'beim nächsten Mal synchronisiert.'
                : 'Deine Einheiten liegen auf dem Server und werden auf allen Geräten '
                    'zusammengeführt. Lokal bleibt eine Kopie, damit die App auch '
                    'offline funktioniert.',
            style: const TextStyle(fontSize: 14, color: C.chalkDim),
          ),
          const SizedBox(height: 4),
          const Hint(
            'Export und Import laufen über die Zwischenablage. Import und '
            'Zurücksetzen ersetzen auch den Stand auf dem Server.',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: store.exportJson()));
                  store.flash('Backup in der Zwischenablage.');
                },
                style: FilledButton.styleFrom(
                  backgroundColor: C.chalk,
                  foregroundColor: C.rock950,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  'Export (JSON)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              OutlinedButton(
                onPressed: () async {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  final text = data?.text;
                  if (text == null || text.trim().isEmpty) {
                    store.flash('Nichts in der Zwischenablage.');
                    return;
                  }
                  await store.importJson(text);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: C.chalk,
                  side: const BorderSide(color: C.rock600),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  'Import',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              TextButton(
                onPressed: () => showSettingsSheet(context, store),
                style: TextButton.styleFrom(foregroundColor: C.chalkDim),
                child: const Text('Server & Token'),
              ),
              TextButton(
                onPressed: onResetTap,
                style: TextButton.styleFrom(foregroundColor: C.chalkFaint),
                child: Text(confirmReset ? 'Wirklich alles löschen?' : 'Zurücksetzen'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Raster mit fester Zellbreite — Gegenstück zu `repeat(auto-fill, minmax(Npx, 1fr))`.
class _Grid extends StatelessWidget {
  const _Grid({required this.cell, required this.children, this.spacing = 6});

  final double cell;
  final double spacing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            ((constraints.maxWidth + spacing) / (cell + spacing)).floor().clamp(1, 60);
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          children: children,
        );
      },
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 560 ? 4 : 2;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.2,
          children: children,
        );
      },
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.color,
    required this.label,
    this.bordered = false,
    this.round = false,
  });

  final Color color;
  final String label;
  final bool bordered;
  final bool round;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            border: bordered ? Border.all(color: C.rock700) : null,
            borderRadius: round ? null : BorderRadius.circular(3),
            shape: round ? BoxShape.circle : BoxShape.rectangle,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: C.chalkFaint)),
      ],
    );
  }
}
