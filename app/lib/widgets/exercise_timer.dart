import 'dart:async';

import 'package:flutter/material.dart';

import '../theme.dart';

const _presets = [30, 45, 60];

/// Portierung von web/src/components/Timer.tsx.
class ExerciseTimer extends StatefulWidget {
  const ExerciseTimer({super.key, this.initial = 45});

  final int initial;

  @override
  State<ExerciseTimer> createState() => _ExerciseTimerState();
}

class _ExerciseTimerState extends State<ExerciseTimer> {
  late int _target = widget.initial;
  late double _left = widget.initial.toDouble();
  bool _running = false;
  Timer? _ticker;
  DateTime? _end;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _start() {
    _end = DateTime.now().add(Duration(milliseconds: (_left * 1000).round()));
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 50), (_) {
      final remaining = _end!.difference(DateTime.now()).inMilliseconds / 1000;
      setState(() {
        _left = remaining > 0 ? remaining : 0;
        if (_left <= 0) {
          _running = false;
          _ticker?.cancel();
        }
      });
    });
  }

  void _stop() {
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  Widget build(BuildContext context) {
    final done = _left <= 0;
    final pct = _target > 0 ? 1 - _left / _target : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: C.rock850,
        border: Border.all(color: C.rock700),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text.rich(
                TextSpan(
                  text: '${_left.ceil()}',
                  style: displaySize(26, color: done ? C.gradeGreen : C.chalk),
                  children: const [
                    TextSpan(
                      text: ' s',
                      style: TextStyle(fontSize: 14, color: C.chalkDim),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _Btn(
                label: done ? 'Nochmal' : (_running ? 'Pause' : 'Start'),
                primary: true,
                onTap: () {
                  setState(() {
                    if (done) {
                      _left = _target.toDouble();
                      _running = true;
                      _start();
                    } else if (_running) {
                      _running = false;
                      _stop();
                    } else {
                      _running = true;
                      _start();
                    }
                  });
                },
              ),
              const SizedBox(width: 8),
              _Btn(
                label: 'Reset',
                onTap: () => setState(() {
                  _running = false;
                  _stop();
                  _left = _target.toDouble();
                }),
              ),
              const Spacer(),
              for (final p in _presets)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _target = p;
                      _left = p.toDouble();
                      _running = false;
                      _stop();
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _target == p ? C.rock600 : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${p}s',
                        style: TextStyle(
                          fontSize: 12,
                          color: _target == p ? C.chalk : C.chalkFaint,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: C.rock700,
              valueColor: AlwaysStoppedAnimation(done ? C.gradeGreen : C.tape),
            ),
          ),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  const _Btn({required this.label, required this.onTap, this.primary = false});

  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: primary ? C.chalk : Colors.transparent,
          border: primary ? null : Border.all(color: C.rock600),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: primary ? FontWeight.w600 : FontWeight.normal,
            color: primary ? C.rock950 : C.chalkDim,
          ),
        ),
      ),
    );
  }
}
