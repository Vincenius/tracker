import 'package:flutter/material.dart';

import '../core/date.dart';
import '../core/types.dart';
import '../core/workouts.dart';
import '../theme.dart';
import 'card.dart';
import 'confetti.dart';
import 'exercise_timer.dart';
import 'hold_icon.dart';

/// Portierung von web/src/components/SessionCard.tsx.
class SessionCard extends StatefulWidget {
  const SessionCard({
    super.key,
    required this.type,
    required this.weekKey,
    required this.done,
    required this.onComplete,
    required this.onRemove,
  });

  final SessionType type;

  /// Montag der angezeigten Woche
  final String weekKey;
  final List<Session> done;
  final void Function(SessionType, Intensity, List<String>, String) onComplete;
  final void Function(String) onRemove;

  @override
  State<SessionCard> createState() => _SessionCardState();
}

const _days = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

class _SessionCardState extends State<SessionCard> {
  bool _open = false;
  bool _pickDay = false;
  late String _day = _defaultDay();
  Intensity _variant = Intensity.full;
  final _checked = <String>{};

  bool get _isCurrentWeek => widget.weekKey == currentWeekKey();

  /// Standardtag zum Abhaken: heute in der laufenden Woche, sonst der geplante
  /// Wochentag der Einheit.
  String _defaultDay() => _isCurrentWeek
      ? toISODate(DateTime.now())
      : addDays(widget.weekKey, sessionMeta[widget.type]!.weekdayIndex);

  @override
  void didUpdateWidget(SessionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Wochenwechsel setzt den Tag zurück — sonst landet die Einheit in der falschen Woche.
    if (oldWidget.weekKey != widget.weekKey) {
      _day = _defaultDay();
      _pickDay = false;
    }
  }

  /// Abhaken ist der Moment, auf den die ganze Karte hinarbeitet — der bekommt
  /// Konfetti, und zwar aus der Karte heraus.
  void _complete(Intensity intensity) {
    final meta = sessionMeta[widget.type]!;
    final box = context.findRenderObject() as RenderBox?;
    burstConfetti(
      context,
      origin: box != null && box.hasSize
          ? box.localToGlobal(Offset(box.size.width / 2, box.size.height * 0.55))
          : null,
      colors: [meta.color, meta.color, C.chalk, C.gradeYellow],
      count: intensity == Intensity.min ? 45 : 80,
      power: intensity == Intensity.min ? 11 : 14,
    );
    widget.onComplete(widget.type, intensity, _checked.toList(), _day);
    setState(() {
      _checked.clear();
      _open = false;
      _pickDay = false;
      _day = _defaultDay();
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
                  if (!_isCurrentWeek || _pickDay) ...[
                    _DayPicker(
                      weekKey: widget.weekKey,
                      day: _day,
                      color: meta.color,
                      onPick: (d) => setState(() => _day = d),
                    ),
                    const SizedBox(height: 8),
                  ],
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
                  if (_isCurrentWeek && !_pickDay)
                    GestureDetector(
                      onTap: () => setState(() => _pickDay = true),
                      child: const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          'An einem anderen Tag?',
                          style: TextStyle(
                            fontSize: 12,
                            color: C.chalkFaint,
                            decoration: TextDecoration.underline,
                            decorationColor: C.rock600,
                          ),
                        ),
                      ),
                    ),
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

/// Tag der angezeigten Woche wählen, auf den die Einheit gebucht wird.
class _DayPicker extends StatelessWidget {
  const _DayPicker({
    required this.weekKey,
    required this.day,
    required this.color,
    required this.onPick,
  });

  final String weekKey;
  final String day;
  final Color color;
  final void Function(String) onPick;

  @override
  Widget build(BuildContext context) {
    final today = toISODate(DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Hint('An welchem Tag? ${weekdayLabel(day)}, ${shortDate(day)}'),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i == 6 ? 0 : 6),
                  child: Builder(builder: (_) {
                    final date = addDays(weekKey, i);
                    final on = date == day;
                    final future = date.compareTo(today) > 0;
                    return Semantics(
                      label: '${weekdayLabel(date)}, ${shortDate(date)}',
                      selected: on,
                      button: true,
                      child: Opacity(
                        opacity: future ? 0.35 : 1,
                        child: Material(
                          color: on ? color : C.rock850,
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            onTap: future ? null : () => onPick(date),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border.all(color: on ? color : C.rock700),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _days[i],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: on ? C.rock950 : C.chalkDim,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
