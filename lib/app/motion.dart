import 'package:flutter/material.dart';

/// Shared motion system for Drishti-Transit.
///
/// Hand-tuned durations and custom Cubic curve family. Every transition,
/// tactile press, and data motion in the app resolves to this signature
/// so the whole product feels unified and tactile.
class Mo {
  Mo._();

  // Hand-tuned durations as specified:
  // micro=120ms, standard=280ms, scene=420ms
  static const Duration micro = Duration(milliseconds: 120);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration standard = Duration(milliseconds: 280);
  static const Duration scene = Duration(milliseconds: 420);
  static const Duration slow = Duration(milliseconds: 700);

  // Single hand-tuned Cubic curve: responsive entry with smooth deceleration
  static const Curve easeTech = Cubic(0.20, 0.0, 0.0, 1.0);
  static const Curve easeOutTech = Cubic(0.16, 1.0, 0.3, 1.0);
  static const Curve easeInTech = Cubic(0.4, 0.0, 0.7, 0.1);
  static const Curve easeInOutTech = Cubic(0.20, 0.0, 0.0, 1.0);

  // Tactile press scale down
  static const double pressScale = 0.97;

  // Live telemetry pulse durations
  static const Duration livePulse = Duration(milliseconds: 1500);
  static const Duration radarSweep = Duration(milliseconds: 2400);
}

/// Component design tokens shared across screens.
class Tok {
  Tok._();

  static const double rSm = 12.0;
  static const double rMd = 18.0;
  static const double rLg = 24.0;
  static const double rFull = 9999.0;

  static const double hair = 1.0;
  static const double dockHeight = 64.0;
}