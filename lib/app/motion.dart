import 'package:flutter/material.dart';

/// Shared motion system for the whole product.
///
/// One palette of durations, one hand-tuned curve family. Every animation in
/// the app must resolve to one of these so the motion feels like a single hand.
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

/// Component design tokens shared across screens.
class Tok {
  Tok._();

  static const double cornerPanel = 14;
  static const double cornerWell = 8;
  static const double hair = 1; // 1px hairlines
  static const double dockHeight = 64;
  static const double feedSnapMin = 0.15;
  static const double feedSnapMax = 0.64;

  static const Duration feedHapticCooldown = Mo.slow;
}