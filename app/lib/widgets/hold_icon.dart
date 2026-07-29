import 'package:flutter/material.dart';

import '../theme.dart';

/// Signature-Element: Silhouette eines Klettergriffs. Portierung des SVG aus
/// web/src/components/HoldIcon.tsx auf einen CustomPainter.
class HoldIcon extends StatelessWidget {
  const HoldIcon({super.key, this.size = 32, this.filled = false, required this.color});

  final double size;
  final bool filled;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _HoldPainter(color: color, filled: filled)),
    );
  }
}

class _HoldPainter extends CustomPainter {
  const _HoldPainter({required this.color, required this.filled});

  final Color color;
  final bool filled;

  static final _outer = _parse(
    'M11.6 2.6c4.6-1.9 10.1-.4 13.4 3.4 3.6 4.1 4.4 10.4 1.6 15.2-2.4 4.2-7.3 6.9-12 6.6'
    '-3.9-.2-7.7-2.6-9.5-6.1C2.7 17.3 3.2 11.6 6 7.6c1.4-2 3.3-3.9 5.6-5Z',
  );
  static final _inner = _parse(
    'M13.4 10.2c2.9-1 6.1.6 6.9 3.5.7 2.6-.9 5.4-3.5 6.2-2.4.7-5.1-.5-6.1-2.8'
    '-1.1-2.5.1-5.6 2.7-6.9Z',
  );

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 32, size.height / 32);

    if (filled) {
      canvas.drawPath(_outer, Paint()..color = color);
      canvas.drawPath(
        _inner,
        Paint()..color = C.rock950.withValues(alpha: 0.85),
      );
    } else {
      Paint stroke(Color c) => Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..color = c;
      canvas.drawPath(_outer, stroke(color));
      canvas.drawPath(_inner, stroke(color.withValues(alpha: 0.55)));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HoldPainter old) => old.color != color || old.filled != filled;
}

/// Minimaler SVG-Path-Parser: deckt genau die Kommandos ab, die im Icon
/// vorkommen (M/m, c, s, l, h, v, Z).
Path _parse(String d) {
  final path = Path();
  final tokens = RegExp(r'[MmCcSsLlHhVvZz]|-?\d*\.?\d+').allMatches(d).map((m) => m[0]!);
  var x = 0.0;
  var y = 0.0;
  var lastCx = 0.0;
  var lastCy = 0.0;
  var cmd = '';
  final queue = tokens.toList();
  var i = 0;

  double num() => double.parse(queue[i++]);

  while (i < queue.length) {
    final t = queue[i];
    if (RegExp(r'^[A-Za-z]$').hasMatch(t)) {
      cmd = t;
      i++;
      if (cmd == 'Z' || cmd == 'z') {
        path.close();
        continue;
      }
    }
    switch (cmd) {
      case 'M':
        x = num();
        y = num();
        path.moveTo(x, y);
        cmd = 'L';
      case 'm':
        x += num();
        y += num();
        path.moveTo(x, y);
        cmd = 'l';
      case 'L':
        x = num();
        y = num();
        path.lineTo(x, y);
      case 'l':
        x += num();
        y += num();
        path.lineTo(x, y);
      case 'H':
        x = num();
        path.lineTo(x, y);
      case 'h':
        x += num();
        path.lineTo(x, y);
      case 'V':
        y = num();
        path.lineTo(x, y);
      case 'v':
        y += num();
        path.lineTo(x, y);
      case 'c':
        final c1x = x + num();
        final c1y = y + num();
        final c2x = x + num();
        final c2y = y + num();
        final ex = x + num();
        final ey = y + num();
        path.cubicTo(c1x, c1y, c2x, c2y, ex, ey);
        lastCx = c2x;
        lastCy = c2y;
        x = ex;
        y = ey;
      case 'C':
        final c1x = num();
        final c1y = num();
        final c2x = num();
        final c2y = num();
        final ex = num();
        final ey = num();
        path.cubicTo(c1x, c1y, c2x, c2y, ex, ey);
        lastCx = c2x;
        lastCy = c2y;
        x = ex;
        y = ey;
      case 's':
        final c1x = 2 * x - lastCx;
        final c1y = 2 * y - lastCy;
        final c2x = x + num();
        final c2y = y + num();
        final ex = x + num();
        final ey = y + num();
        path.cubicTo(c1x, c1y, c2x, c2y, ex, ey);
        lastCx = c2x;
        lastCy = c2y;
        x = ex;
        y = ey;
      default:
        i++;
    }
  }
  return path;
}
