import 'package:flutter/material.dart';

import '../core/date.dart';
import '../core/types.dart';
import '../core/workouts.dart';
import '../theme.dart';
import 'card.dart';
import 'exercise_timer.dart';
import 'hold_icon.dart';

/// Portierung von web/src/components/SessionCard.tsx.
class SessionCard extends StatefulWidget {
  const SessionCard({
    super.key,
    required this.type,
    required this.done,
    required this.onComplete,
    required this.onRemove,
  });

  final SessionType type;
  final List<Session> done;
  final void Function(SessionType, Intensity, List<String>) onComplete;
  final void Function(String) onRemove;

  @override
  State<SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends State<SessionCard> {
  bool _open = false;
  Intensity _variant = Intensity.full;
  final _checked = <String>{};

  void _complete(Intensity intensity) {
    widget.onComplete(widget.type, intensity, _checked.toList());
    setState(() {
      _checked.clear();
      _open = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final meta = sessionMeta[widget.type]!;
    final workout = workouts[widget.type]![_variant]!;
    final isDone = widget.done.isNotEmpty;

    return TrackerCard(
      accent: meta.color,
      active: isDone,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CardHeader(
                  leading: HoldIcon(size: 32, filled: isDone, color: meta.color),
                  chip: meta.weekday,
                  chipColor: meta.color,
                  title: meta.title,
                  subtitle: meta.tagline,
                ),
                const SizedBox(height: 16),
                if (isDone)
                  for (final s in widget.done)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _DoneRow(
                        session: s,
                        color: meta.color,
                        onRemove: () => widget.onRemove(s.id),
                      ),
                    )
                else ...[
                  if (widget.type == SessionType.boulder)
                    _BigButton(
                      color: meta.color,
                      label: 'Abhaken · +${xpTable[SessionType.boulder]![Intensity.full]} XP',
                      onTap: () => _complete(Intensity.full),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: _BigButton(
                            color: meta.color,
                            label: 'Volle Einheit',
                            sub: '+${xpTable[widget.type]![Intensity.full]} XP',
                            onTap: () => _complete(Intensity.full),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _BigButton(
                            label: 'Minimum',
                            sub: '+${xpTable[widget.type]![Intensity.min]} XP · ~5 Min.',
                            onTap: () => _complete(Intensity.min),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  Hint(meta.hint),
                ],
              ],
            ),
          ),
          const Divider(color: C.rock800, height: 1),
          InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Übungen & Timer',
                      style: TextStyle(fontSize: 14, color: C.chalkDim),
                    ),
                  ),
                  Icon(
                    _open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 20,
                    color: C.chalkDim,
                  ),
                ],
              ),
            ),
          ),
          if (_open) ...[
            const Divider(color: C.rock800, height: 1),
            Container(
              color: C.rock950.withValues(alpha: 0.5),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.type != SessionType.boulder) ...[
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        border: Border.all(color: C.rock700),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          for (final v in Intensity.values)
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _variant = v),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _variant == v ? C.rock700 : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    workouts[widget.type]![v]!.label,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: _variant == v ? C.chalk : C.chalkDim,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    '${workout.rounds} ${workout.rounds == 1 ? 'RUNDE' : 'RUNDEN'} · '
                    '${workout.duration.toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 12,
                      letterSpacing: 0.8,
                      color: C.chalkFaint,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final ex in workout.exercises) ...[
                    _ExerciseRow(
                      exercise: ex,
                      checked: _checked.contains(ex.id),
                      onToggle: () => setState(() {
                        if (!_checked.remove(ex.id)) _checked.add(ex.id);
                      }),
                    ),
                    if (ex.timer != null) ...[
                      const SizedBox(height: 6),
                      ExerciseTimer(initial: ex.timer!),
                    ],
                    const SizedBox(height: 6),
                  ],
                  const Hint(
                    'Die Checkliste ist optional — abhaken kannst du die Einheit jederzeit.',
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DoneRow extends StatelessWidget {
  const _DoneRow({required this.session, required this.color, required this.onRemove});

  final Session session;
  final Color color;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: C.rock850,
        border: Border.all(color: C.rock700),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: const Text(
              '✓',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: C.rock950,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: session.intensity == Intensity.min ? 'Minimum' : 'Volle Einheit',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                children: [
                  TextSpan(
                    text: ' · ${shortDate(session.date)} · +${xpFor(session)} XP',
                    style: const TextStyle(
                      fontWeight: FontWeight.normal,
                      color: C.chalkDim,
                    ),
                  ),
                ],
              ),
            ),
          ),
          TextButton(
            onPressed: onRemove,
            style: TextButton.styleFrom(
              foregroundColor: C.chalkFaint,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('rückgängig', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _BigButton extends StatelessWidget {
  const _BigButton({required this.label, required this.onTap, this.color, this.sub});

  final String label;
  final VoidCallback onTap;

  /// Ohne Farbe wird der Knopf zur zurückhaltenden Minimum-Variante.
  final Color? color;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    final filled = color != null;
    return Material(
      color: filled ? color : C.rock850,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            border: filled ? null : Border.all(color: C.rock600),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: sub == null ? 17 : 16,
                  fontWeight: FontWeight.bold,
                  color: filled ? C.rock950 : C.chalk,
                ),
              ),
              if (sub != null) ...[
                const SizedBox(height: 2),
                Text(
                  sub!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: filled ? C.rock950.withValues(alpha: 0.7) : C.chalkDim,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({
    required this.exercise,
    required this.checked,
    required this.onToggle,
  });

  final Exercise exercise;
  final bool checked;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: checked ? C.rock800 : C.rock900.withValues(alpha: 0.6),
          border: Border.all(color: checked ? C.rock600 : C.rock800),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: checked,
                onChanged: (_) => onToggle(),
                activeColor: C.tape,
                checkColor: C.rock950,
                side: const BorderSide(color: C.rock500),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: checked ? C.chalkDim : C.chalk,
                      decoration: checked ? TextDecoration.lineThrough : null,
                      decorationColor: C.chalkDim,
                    ),
                  ),
                  Text(
                    exercise.detail,
                    style: const TextStyle(fontSize: 12, color: C.chalkFaint),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
