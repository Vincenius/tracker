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
    required this.add,
  });

  final TreatKind kind;

  /// Was der Eintrag bedeutet
  final String title;

  /// Kurzform für enge Stellen
  final String short;
  final String emoji;
  final Color color;
  final String tagline;

  /// Beschriftung des Plus-Knopfes
  final String add;
}

/// Zwei Spuren, beide negativ: eingetragen wird, was danebenging. Der Ton
/// bleibt trotzdem sachlich — ein Eintrag ist Buchhaltung, keine Strafpredigt.
const _sweets = LaneMeta(
  kind: TreatKind.sweets,
  title: 'Süßes gegessen',
  short: 'Gegessen',
  emoji: '🍫',
  color: C.cocoa,
  tagline: 'Schokolade, Kuchen, Chips — alles, was zwischendurch reinrutscht.',
  add: 'Genascht',
);

const _drinks = LaneMeta(
  kind: TreatKind.drinks,
  title: 'Süßes getrunken',
  short: 'Getrunken',
  emoji: '🥤',
  color: C.mint,
  tagline: 'Limo, Saft, Zucker im Kaffee — alles außer Wasser und Tee.',
  add: 'Getrunken',
);

const lanes = <TreatKind, LaneMeta>{
  TreatKind.sweets: _sweets,
  TreatKind.drinks: _drinks,
};

const laneList = [_sweets, _drinks];
