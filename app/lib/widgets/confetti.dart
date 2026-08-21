import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme.dart';

/// Konfetti als Overlay: ein paar Dutzend Papierschnipsel mit Schwerkraft, die
/// sich nach dem Fall selbst wieder abräumen. Gegenstück zu
/// web/src/lib/confetti.ts — gleiche Physik, gleiche Farben.
///
/// Wer im System „Bewegung reduzieren“ gesetzt hat, bekommt gar nichts: die
/// Feier ist Zugabe, nie Information.

const _defaultColors = [
  C.tape,
  C.gradeYellow,
  C.gradeGreen,
  C.chalk,
  C.gradePurple,
];

const _gravity = 0.32;
const _drag = 0.987;

class _Particle {
  _Particle({
    required this.position,
    required this.velocity,
    required this.size,
    required this.color,
    required this.spin,
    required this.angle,
    required this.life,
  });

  Offset position;
  Offset velocity;
  final Size size;
  final Color color;
  final double spin;
  double angle;

  /// Lebensdauer in Frames.
  final double life;
  double age = 0;
}

final _random = Random();

/// Wie viele Konfetti-Schichten gerade fliegen.
int _live = 0;

/// Fliegt gerade noch Papier? Verhindert, dass sich Salven stapeln.
bool confettiActive() => _live > 0;

/// Ein Schwung Konfetti, ausgehend von [origin] (global, ohne Angabe die Mitte
/// des Bildschirms auf halber Höhe).
void burstConfetti(
  BuildContext context, {
  Offset? origin,
  List<Color> colors = _defaultColors,
  int count = 70,
  double power = 13,
  double spread = pi * 0.75,
}) {
  if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) return;
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  final size = MediaQuery.of(context).size;
  final from = origin ?? Offset(size.width / 2, size.height * 0.55);
  final paper = colors.isEmpty ? _defaultColors : colors;

  final particles = [
    for (var i = 0; i < count; i++)
      () {
        // Nach oben streuen: -90° ± spread/2.
        final angle = -pi / 2 + (_random.nextDouble() - 0.5) * spread;
        final speed = power * (0.55 + _random.nextDouble() * 0.75);
        return _Particle(
          position: from +
              Offset(
                (_random.nextDouble() - 0.5) * 24,
                (_random.nextDouble() - 0.5) * 12,
              ),
          velocity: Offset(cos(angle) * speed, sin(angle) * speed),
          size: Size(5 + _random.nextDouble() * 6, 8 + _random.nextDouble() * 6),
          color: paper[_random.nextInt(paper.length)],
          spin: (_random.nextDouble() - 0.5) * 0.34,
          angle: _random.nextDouble() * pi,
          life: 90 + _random.nextDouble() * 60,
        );
      }(),
  ];

  late final OverlayEntry entry;
  _live++;
  entry = OverlayEntry(
    builder: (_) => IgnorePointer(
      child: _ConfettiLayer(
        particles: particles,
        onDone: () {
          _live--;
          entry.remove();
        },
      ),
    ),
  );
  overlay.insert(entry);
}

/// Der große Auftritt: eine Salve aus der Mitte, zwei von den Seiten. Für
/// Level-Ups und erreichte Wochenziele.
void cheerConfetti(BuildContext context, {List<Color> colors = _defaultColors}) {
  if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) return;
  final size = MediaQuery.of(context).size;
  burstConfetti(
    context,
    origin: Offset(size.width / 2, size.height * 0.42),
    colors: colors,
    count: 90,
    power: 15,
  );
  for (final (delay, x, y) in [(130, 0.08, 0.75), (230, 0.92, 0.75)]) {
    Future<void>.delayed(Duration(milliseconds: delay), () {
      if (!context.mounted) return;
      burstConfetti(
        context,
        origin: Offset(size.width * x, size.height * y),
        colors: colors,
        count: 45,
        power: 17,
        spread: pi / 2.4,
      );
    });
  }
}

class _ConfettiLayer extends StatefulWidget {
  const _ConfettiLayer({required this.particles, required this.onDone});

  final List<_Particle> particles;
  final VoidCallback onDone;

  @override
  State<_ConfettiLayer> createState() => _ConfettiLayerState();
}

class _ConfettiLayerState extends State<_ConfettiLayer>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_step)..start();
  }

  void _step(Duration _) {
    final height = context.size?.height ?? 4000;
    for (final p in widget.particles) {
      p.age++;
      p.velocity = Offset(
        p.velocity.dx * _drag,
        (p.velocity.dy + _gravity) * _drag,
      );
      p.position += p.velocity;
      p.angle += p.spin;
    }
    widget.particles.removeWhere((p) => p.age >= p.life || p.position.dy > height + 40);
    if (widget.particles.isEmpty) {
      if (_done) return;
      _done = true;
      _ticker.stop();
      // Nicht mitten im Ticker-Callback das Overlay abbauen.
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onDone());
      return;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _ConfettiPainter(widget.particles),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.particles);

  final List<_Particle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in particles) {
      // Am Ende ausblenden, statt die Schnipsel hart verschwinden zu lassen.
      final fade = ((p.life - p.age) / 24).clamp(0.0, 1.0);
      canvas.save();
      canvas.translate(p.position.dx, p.position.dy);
      canvas.rotate(p.angle);
      // Der schmaler werdende Streifen lässt das Papier flattern.
      canvas.scale(cos(p.angle * 1.6), 1);
      paint.color = p.color.withValues(alpha: fade);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size.width, height: p.size.height),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => true;
}
