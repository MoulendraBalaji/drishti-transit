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

  /// Whether the active theme is Dark Mode.
  static bool isDark = false;

  // Mobbin Canvas & Neutral ladder (Light)
  static const Color _canvasLight = Color(0xFFFFFFFF);
  static const Color _canvasSoftLight = Color(0xFFF7F8FA);
  static const Color _fieldLight = Color(0xFFF0F2F5);
  static const Color _hairlineLight = Color(0xFFE2E4E8);
  static const Color _hairlineSoftLight = Color(0xFFECEFF2);

  // Mobbin Inks (Light)
  static const Color _primaryLight = Color(0xFF121417);
  static const Color _onPrimaryLight = Color(0xFFFFFFFF);
  static const Color _inkLight = Color(0xFF121417);
  static const Color _inkSoftLight = Color(0xFF26292E);
  static const Color _textMutedLight = Color(0xFF656D76);
  static const Color _textFaintLight = Color(0xFF8C959F);

  // Mobbin Deep Charcoal Canvas & Neutral ladder (Dark Mode)
  static const Color _canvasDark = Color(0xFF0D1117);
  static const Color _canvasSoftDark = Color(0xFF161B22);
  static const Color _fieldDark = Color(0xFF21262D);
  static const Color _hairlineDark = Color(0xFF30363D);
  static const Color _hairlineSoftDark = Color(0xFF21262D);

  // Mobbin Crisp Inks (Dark Mode)
  static const Color _primaryDark = Color(0xFFF0F6FC);
  static const Color _onPrimaryDark = Color(0xFF0D1117);
  static const Color _inkDark = Color(0xFFF0F6FC);
  static const Color _inkSoftDark = Color(0xFFC9D1D9);
  static const Color _textMutedDark = Color(0xFF8B949E);
  static const Color _textFaintDark = Color(0xFF484F58);

  // Dynamic Theme-Aware Getters
  static Color get canvas => isDark ? _canvasDark : _canvasLight;
  static Color get canvasSoft => isDark ? _canvasSoftDark : _canvasSoftLight;
  static Color get field => isDark ? _fieldDark : _fieldLight;
  static Color get hairline => isDark ? _hairlineDark : _hairlineLight;
  static Color get hairlineSoft => isDark ? _hairlineSoftDark : _hairlineSoftLight;

  // Surface aliases
  static Color get bg => canvas;
  static Color get surface => canvas;
  static Color get raised => canvasSoft;
  static Color get raised2 => field;
  static Color get line => hairline;
  static Color get lineBright => isDark ? const Color(0xFF3B434D) : const Color(0xFFCCCCCC);

  // Inks & Typography colors
  static Color get primary => isDark ? _primaryDark : _primaryLight;
  static Color get onPrimary => isDark ? _onPrimaryDark : _onPrimaryLight;
  static Color get ink => isDark ? _inkDark : _inkLight;
  static Color get inkSoft => isDark ? _inkSoftDark : _inkSoftLight;
  static Color get textMuted => isDark ? _textMutedDark : _textMutedLight;
  static Color get textFaint => isDark ? _textFaintDark : _textFaintLight;

  // Text aliases
  static Color get mist => textMuted;
  static Color get fog => textFaint;
  static Color get dim => isDark ? const Color(0xFF30363D) : const Color(0xFFD4D4D4);

  // Electric Blue Accent (vibrant across both light and dark)
  static const Color accent = Color(0xFF0066FF);
  static Color get signal => accent;
  static const Color signalDim = Color(0xFF0052CC);
  static const Color onSignal = Color(0xFFFFFFFF);

  // Brand accent for highlights
  static Color get saffron => accent;

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
      severityColor(s).withValues(alpha: isDark ? 0.20 : 0.12);

  static Color get vehicleColor => isDark ? const Color(0xFFF0F6FC) : const Color(0xFF141414);

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