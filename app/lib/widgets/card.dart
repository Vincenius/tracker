import 'package:flutter/material.dart';

import '../theme.dart';

/// Die Karte, aus der die ganze App besteht: dunkler Grund, gekreidete Kante,
/// optional ein farbiger Streifen oben, der die Spur markiert.
class TrackerCard extends StatelessWidget {
  const TrackerCard({
    super.key,
    required this.child,
    this.accent,
    this.active = false,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;

  /// Farbe des Streifens oben. Ohne accent bleibt die Karte neutral.
  final Color? accent;

  /// Aktiv = Rand und Streifen leuchten in der Akzentfarbe.
  final bool active;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: C.rock900.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active && accent != null ? accent! : C.rock700,
        ),
        boxShadow: chalkEdge,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (accent != null)
            Container(height: 4, color: accent!.withValues(alpha: active ? 1 : 0.45)),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

/// Der Kopf einer Spur-Karte: Symbol, Kennzeichnung, Titel, Untertitel, Zähler.
class CardHeader extends StatelessWidget {
  const CardHeader({
    super.key,
    required this.leading,
    required this.chip,
    required this.chipColor,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final Widget leading;
  final String chip;
  final Color chipColor;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(top: 2), child: leading),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: tint(chipColor, 0.22),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      chip.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: chipColor,
                      ),
                    ),
                  ),
                  Text(title.toUpperCase(), style: displaySize(22)),
                ],
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(fontSize: 14, color: C.chalkDim)),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
    );
  }
}

/// Ein Tag im Wochenraster (Spaziergang, Ernährung): Kürzel oben, Haken unten.
class DayToggle extends StatelessWidget {
  const DayToggle({
    super.key,
    required this.label,
    required this.on,
    required this.color,
    required this.onTap,
    this.today = false,
    this.disabled = false,
    this.muted = false,
    this.semantics,
    this.onMark = '✓',
    this.offMark = '·',
    this.offBorder,
  });

  final String label;
  final bool on;
  final Color color;
  final VoidCallback onTap;
  final bool today;
  final bool disabled;

  /// Wochenende beim Spaziergang: erlaubt, aber optisch zurückgenommen.
  final bool muted;
  final String? semantics;

  /// Zeichen im abgehakten bzw. offenen Zustand — der Cheat Day nutzt 🍕.
  final String onMark;
  final String offMark;

  /// Rand für einen offenen Tag, der trotzdem etwas bedeutet (Cheat Day).
  final Color? offBorder;

  @override
  Widget build(BuildContext context) {
    final border = on
        ? color
        : offBorder ??
            (today
                ? C.tape
                : muted
                    ? C.rock800
                    : C.rock700);
    return Semantics(
      label: semantics,
      toggled: on,
      child: Opacity(
        opacity: disabled ? 0.35 : 1,
        child: Material(
          color: on
              ? color
              : muted
                  ? C.rock900.withValues(alpha: 0.6)
                  : C.rock850,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: disabled ? null : onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
              decoration: BoxDecoration(
                border: Border.all(color: border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: on
                          ? C.rock950
                          : muted
                              ? C.chalkFaint
                              : C.chalkDim,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    on ? onMark : offMark,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1,
                      color: on ? C.rock950 : C.chalkDim,
                    ),
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

/// Kleine Kennzahl mit Beschriftung — im Verlauf und in der Ernährung genutzt.
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.value, required this.label, this.big = true});

  final Object value;
  final String label;
  final bool big;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: big ? C.rock900.withValues(alpha: 0.8) : C.rock850,
        border: Border.all(color: C.rock700),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$value', style: displaySize(big ? 28 : 24)),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 0.8,
              color: C.chalkFaint,
            ),
          ),
        ],
      ),
    );
  }
}

/// Überschrift einer neutralen Karte.
class CardTitle extends StatelessWidget {
  const CardTitle(this.text, {super.key, this.subtitle});

  final String text;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text.toUpperCase(), style: displaySize(20)),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: const TextStyle(fontSize: 14, color: C.chalkDim)),
        ],
      ],
    );
  }
}

/// Der Fließtext unter einer Karte — im Web `text-xs text-chalk-faint`.
class Hint extends StatelessWidget {
  const Hint(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(fontSize: 12, color: C.chalkFaint));
}
