import 'dart:ui';
import 'package:flutter/material.dart';

/// Drishti Palette — Crafted exactly according to Mobbin's design system:
/// A gallery-white, monochrome interface system built to disappear behind the
/// content it curates. Near-black ink (#141414) on pure white canvas (#FFFFFF),
/// a subtle ladder of barely-there neutral tints (#F3F3F3, #F0F0F0) and crisp
/// hairline borders (#E0E0E0), stadium-pill controls (9999px), 24px card geometry,
/// 30% squircle icons, and an electric blue accent (#0066FF) reserved for active
/// signals and live telemetry.
class Dp {
  Dp._();

  // Mobbin Canvas & Neutral ladder
  static const Color canvas = Color(0xFFFFFFFF);
  static const Color canvasSoft = Color(0xFFF3F3F3);
  static const Color field = Color(0xFFF0F0F0);
  static const Color hairline = Color(0xFFE0E0E0);
  static const Color hairlineSoft = Color(0xFFF0F0F0);

  // Surface aliases for backward compatibility
  static const Color bg = canvas;
  static const Color surface = canvas;
  static const Color raised = canvasSoft;
  static const Color raised2 = field;
  static const Color line = hairline;
  static const Color lineBright = Color(0xFFCCCCCC);

  // Mobbin Inks & Typography colors
  static const Color primary = Color(0xFF141414);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF141414);
  static const Color inkSoft = Color(0xFF262626);
  static const Color textMuted = Color(0xFF707070);
  static const Color textFaint = Color(0xFFADADAD);

  // Text aliases
  static const Color mist = textMuted;
  static const Color fog = textFaint;
  static const Color dim = Color(0xFFD4D4D4);

  // Electric Blue Accent (reserved for live state, active nav, primary CTAs)
  static const Color accent = Color(0xFF0066FF);
  static const Color signal = accent;
  static const Color signalDim = Color(0xFF0052CC);
  static const Color onSignal = Color(0xFFFFFFFF);

  // Brand accent for highlights
  static const Color saffron = Color(0xFF0066FF);

  // Geometry tokens from DESIGN-mobbin.md
  static const double rSm = 16.0;
  static const double rMd = 24.0;
  static const double rFull = 9999.0;

  // Alert severity scale (high-contrast, crystal-clear detection)
  static const Color note = Color(0xFF0066FF); // Blue note
  static const Color watch = Color(0xFFE69500); // Amber watch
  static const Color elevated = Color(0xFFE65C00); // Orange alert
  static const Color critical = Color(0xFFD92D20); // Crimson critical

  static Color severityColor(SeverityClass s) {
    switch (s) {
      case SeverityClass.note:
        return note;
      case SeverityClass.watch:
        return watch;
      case SeverityClass.elevated:
        return elevated;
      case SeverityClass.critical:
        return critical;
    }
  }

  static Color severitySoft(SeverityClass s) =>
      severityColor(s).withValues(alpha: 0.12);

  static const Color vehicleColor = Color(0xFF141414);

  // Heat layer ramp
  static const Color heatLow = Color(0x000066FF);
  static const Color heatHigh = Color(0xE6D92D20);
}

/// Severity tier shared across models and the alert UI.
enum SeverityClass { note, watch, elevated, critical }

extension SeverityX on SeverityClass {
  String get code {
    switch (this) {
      case SeverityClass.note:
        return 'NOTE';
      case SeverityClass.watch:
        return 'WATCH';
      case SeverityClass.elevated:
        return 'ALERT';
      case SeverityClass.critical:
        return 'CRIT';
    }
  }

  String get label {
    switch (this) {
      case SeverityClass.note:
        return 'Note';
      case SeverityClass.watch:
        return 'Watch';
      case SeverityClass.elevated:
        return 'Alert';
      case SeverityClass.critical:
        return 'Critical';
    }
  }
}

/// A tiny stochastic color picker used to seed scene/render variation.
final class Rand {
  Rand(this.seed);
  int seed;
  double next() {
    seed = (seed + 0x6D2B79F5) & 0xFFFFFFFF;
    var t = seed;
    t = (t ^ (t >> 15)) * (t | 1);
    t ^= t + ((t ^ (t >> 7)) * (t | 61));
    return ((t ^ (t >> 14)) & 0xFFFFFFFF) / 0xFFFFFFFF;
  }

  double range(double a, double b) => a + (b - a) * next();
  int intRange(int a, int b) => a + (next() * (b - a)).floor();
}