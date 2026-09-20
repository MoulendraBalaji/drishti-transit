import 'package:flutter/material.dart';

/// Shared motion system for the whole product.
///
/// One palette of durations, one hand-tuned curve family. Every animation in
/// the app resolves to one of these so motion feels fluid, premium, and unified.
class Mo {
  Mo._();

  // Durations
  static const Duration micro = Duration(milliseconds: 120);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration standard = Duration(milliseconds: 300);
  static const Duration scene = Duration(milliseconds: 480);
  static const Duration slow = Duration(milliseconds: 900);

  // Hand-tuned curves
  static const Curve easeOutTech = Cubic(0.22, 1, 0.36, 1);
  static const Curve easeInTech = Cubic(0.4, 0, 0.68, 0.06);
  static const Curve easeInOutTech = Cubic(0.65, 0, 0.35, 1);

  // Live-loop durations (subtle continuous motion)
  static const Duration livePulse = Duration(milliseconds: 1600);
  static const Duration radarSweep = Duration(milliseconds: 2600);
}

/// Component design tokens shared across screens, directly derived from DESIGN-mobbin.md.
class Tok {
  Tok._();

  // Mobbin Corner Radii
  static const double rNone = 0;
  static const double rSm = 16;
  static const double rMd = 24;
  static const double rFull = 9999;

  // Aliases for compatibility
  static const double cornerPanel = rMd;
  static const double cornerWell = rSm;
  static const double hair = 1; // 1px hairline borders
  static const double dockHeight = 64;
  static const double feedSnapMin = 0.16;
  static const double feedSnapMax = 0.65;

  static const Duration feedHapticCooldown = Mo.slow;
}