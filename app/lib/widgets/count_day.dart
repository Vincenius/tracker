import 'package:flutter/material.dart';

import '../theme.dart';

/// Je mehr Einträge an einem Tag, desto kräftiger die Farbe.
Color cellColor(int count, Color color) {
  if (count <= 0) return C.rock800;
  if (count == 1) return mix(color, C.rock800, 0.45);
  if (count == 2) return mix(color, C.rock800, 0.72);
  return color;
}

/// Ein Tag als Zähler: tippen trägt ein, lange drücken nimmt zurück. Ein
/// Umschalter reicht hier nicht — pro Tag sind beliebig viele Einträge möglich.
class CountDay extends StatelessWidget {
  const CountDay({
    super.key,
    required this.label,
    required this.count,
    required this.color,
    required this.today,
    required this.disabled,
    required this.semantics,
    required this.onAdd,
    required this.onRemove,
  });

  final String label;
  final int count;
  final Color color;
  final bool today;
  final bool disabled;
  final String semantics;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final foreground = count >= 2 ? C.rock950 : C.chalkDim;
    return Semantics(
      label: semantics,
      button: true,
      child: Opacity(
        opacity: disabled ? 0.35 : 1,
        child: Material(
          color: cellColor(count, color),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: disabled ? null : onAdd,
            onLongPress: disabled || count == 0 ? null : onRemove,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
              decoration: BoxDecoration(
                border: Border.all(
                  color: count > 0
                      ? Colors.transparent
                      : today
                      ? C.tape
                      : C.rock700,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: foreground),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    count > 0 ? '$count' : '·',
                    style: TextStyle(fontSize: 16, height: 1, color: foreground),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
