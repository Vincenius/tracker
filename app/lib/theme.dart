import 'package:flutter/material.dart';

/// Farbpalette 1:1 aus web/src/index.css. Änderungen dort hier mitziehen.
abstract final class C {
  // Fels / Basalt
  static const rock950 = Color(0xFF0D0C0B);
  static const rock900 = Color(0xFF14120F);
  static const rock850 = Color(0xFF191713);
  static const rock800 = Color(0xFF1D1A16);
  static const rock700 = Color(0xFF2A2621);
  static const rock600 = Color(0xFF3B352E);
  static const rock500 = Color(0xFF554D43);

  // Chalk
  static const chalk = Color(0xFFF2EFE7);
  static const chalkDim = Color(0xFFA9A296);
  static const chalkFaint = Color(0xFF6F695F);

  // Route-Grades als Farbskala
  static const gradeYellow = Color(0xFFE7B93F);
  static const gradeGreen = Color(0xFF5FA86B);
  static const gradeBlue = Color(0xFF4C86C6);
  static const gradeRed = Color(0xFFC9553F);
  static const gradePurple = Color(0xFF8A63B8);

  // Ernährung: Kakao für Süßes & Salziges, Minze für Getränke
  static const cocoa = Color(0xFFB07A45);
  static const mint = Color(0xFF4FA88F);

  // Signature: Tape
  static const tape = Color(0xFFE4572E);
}

/// Entspricht `color-mix(in srgb, <color> <pct>%, transparent)` aus dem Web.
Color tint(Color color, double pct) => color.withValues(alpha: pct);

/// Entspricht `color-mix(in srgb, <a> <pct>%, <b>)`.
Color mix(Color a, Color b, double pct) => Color.lerp(b, a, pct)!;

/// Ersatz für die Anton-Schrift: die woff-Dateien des Webs kann Flutter nicht
/// laden, deshalb übernimmt die System-Schrift in Schwarz mit weiter Laufweite
/// die Rolle der Display-Schrift.
const display = TextStyle(
  fontWeight: FontWeight.w900,
  letterSpacing: 0.6,
  height: 1.05,
  color: C.chalk,
);

TextStyle displaySize(double size, {Color? color}) =>
    display.copyWith(fontSize: size, color: color ?? C.chalk);

ThemeData buildTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: C.rock950,
    colorScheme: base.colorScheme.copyWith(
      surface: C.rock950,
      primary: C.tape,
      secondary: C.gradeYellow,
      onPrimary: C.rock950,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: C.chalk,
      displayColor: C.chalk,
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );
}

/// Die „gekreidete Kante“ der Karten: heller Rand oben, dunkler Schatten unten.
const chalkEdge = <BoxShadow>[
  BoxShadow(color: Color(0x17F2EFE7), offset: Offset(0, 1), blurRadius: 0, spreadRadius: -0.5),
  BoxShadow(color: Color(0x66000000), offset: Offset(0, 1), blurRadius: 0, spreadRadius: -0.5),
];
