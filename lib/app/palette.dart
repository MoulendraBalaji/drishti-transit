import 'dart:ui';

import 'package:flutter/material.dart';

/// Drishti palette — deep night-map ink with one signal accent, and a
/// restrained amber-to-red alert scale. No pure black, no pure white.
class Dp {
  Dp._();

  // Ink / surfaces (deep night navy, never pure black)
  static const Color bg = Color(0xFF070B14); // map void / app background
  static const Color surface = Color(0xFF0B1323); // panels
  static const Color raised = Color(0xFF111C30); // raised cards
  static const Color raised2 = Color(0xFF17243C); // chips / inputs / wells
  static const Color line = Color(0xFF1D2A44); // hairlines
  static const Color lineBright = Color(0xFF2C3D5F); // strong hairlines

  // Text
  static const Color ink = Color(0xFFE9EEF8); // primary text (off-white)
  static const Color mist = Color(0xFF96A5C0); // secondary text
  static const Color fog = Color(0xFF5D6D8A); // disabled / hints
  static const Color dim = Color(0xFF3A4760); // very quiet

  // Signal accent — "system alive" state (live pill, active nav, locked trusts)
  static const Color signal = Color(0xFF34E2B4);
  static const Color signalDim = Color(0xFF15A37F);
  static const Color onSignal = Color(0xFF04201A);

  // Brand restraint — a single saffron note for the wordmark in quiet moments.
  static const Color saffron = Color(0xFFE9A23B);

  // Alert severity scale (cyan note -> amber -> orange -> red)
  static const Color note = Color(0xFF58B8F2);
  static const Color watch = Color(0xFFF2C33D);
  static const Color elevated = Color(0xFFF28B34);
  static const Color critical = Color(0xFFF2504D);

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
      severityColor(s).withValues(alpha: 0.14);

  static const Color vehicleColor = Color(0xFF86A0C8);

  // Heat layer ramp
  static const Color heatLow = Color(0x0034E2B4);
  static const Color heatHigh = Color(0xE6F2504D);
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