import 'package:flutter/material.dart';

import '../theme.dart';
import 'types.dart';

class LaneMeta {
  const LaneMeta({
    required this.kind,
    required this.title,
    required this.short,
    required this.emoji,
    required this.color,
    required this.tagline,
    required this.ask,
  });

  final CleanKind kind;

  /// Was der Tag bedeutet, positiv formuliert
  final String title;

  /// Kurzform für enge Stellen
  final String short;
  final String emoji;
  final Color color;
  final String tagline;

  /// Frage, die der Tages-Button stellt
  final String ask;
}

/// Beide Spuren sind Verzicht, werden aber als Gewinn gezeigt: nicht "keine
/// Schokolade", sondern ein sauberer Tag, der Punkte bringt.
const _snacks = LaneMeta(
  kind: CleanKind.snacks,
  title: 'Ohne Schokolade & Chips',
  short: 'Snacks',
  emoji: '🍫',
  color: C.cocoa,
  tagline: 'Ein Tag ohne Süßkram und Knabberzeug.',
  ask: 'Heute weder Schokolade noch Chips',
);

const _drinks = LaneMeta(
  kind: CleanKind.drinks,
  title: 'Ohne Zuckergetränke',
  short: 'Getränke',
  emoji: '🥤',
  color: C.mint,
  tagline: 'Wasser, Tee, Kaffee — alles ohne Zucker.',
  ask: 'Heute nichts Zuckerhaltiges getrunken',
);

const lanes = <CleanKind, LaneMeta>{
  CleanKind.snacks: _snacks,
  CleanKind.drinks: _drinks,
};

const laneList = [_snacks, _drinks];
