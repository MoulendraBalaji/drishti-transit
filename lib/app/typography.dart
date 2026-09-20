import 'package:flutter/material.dart';

import 'motion.dart';
import 'palette.dart';

/// Typography for Drishti Transit — calibrated with DESIGN-mobbin.md.
///
/// Display titles, clean modern sans body, and crisp monospace data telemetry.
/// Monochromatic hierarchy using Dp.ink (#141414), Dp.textMuted (#707070),
/// and Dp.textFaint (#ADADAD).
class AppText {
  AppText._();

  static const String display = 'Fraunces';
  static const String sans = 'IBMPlexSans';
  static const String mono = 'IBMPlexMono';

  static Color get hi => Dp.ink;
  static Color get mi => Dp.textMuted;
  static Color get lo => Dp.textFaint;

  // --- Display Typography (DESIGN-mobbin.md hierarchy) ---------------------
  static TextStyle get displayHero => TextStyle(
    fontFamily: display,
    fontSize: 42,
    height: 1.05,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.0,
    color: Dp.ink,
  );

  static TextStyle get displayTitle => TextStyle(
    fontFamily: display,
    fontSize: 24,
    height: 1.15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: Dp.ink,
  );

  static TextStyle get displaySection => TextStyle(
    fontFamily: display,
    fontSize: 18,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: Dp.ink,
  );

  static TextStyle get displayNumber => TextStyle(
    fontFamily: display,
    fontSize: 28,
    height: 1.0,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: Dp.ink,
  );

  static TextStyle displaySmall({double size = 13}) => TextStyle(
        fontFamily: display,
        fontSize: size,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: Dp.ink,
      );

  // --- Technical body (IBM Plex Sans) ----------------------------------
  static TextStyle get body => TextStyle(
    fontFamily: sans,
    fontSize: 15,
    height: 1.4,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    color: Dp.ink,
  );

  static TextStyle get bodySmall => TextStyle(
    fontFamily: sans,
    fontSize: 13,
    height: 1.35,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.15,
    color: Dp.textMuted,
  );

  static TextStyle get label => TextStyle(
    fontFamily: sans,
    fontSize: 12,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.4,
    color: Dp.ink,
  );

  // --- Data & Telemetry (IBM Plex Mono) --------------------------------
  static TextStyle get data => TextStyle(
    fontFamily: mono,
    fontSize: 12,
    height: 1.3,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.3,
    color: Dp.ink,
  );

  static TextStyle get dataStrong => TextStyle(
    fontFamily: mono,
    fontSize: 12,
    height: 1.3,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
    color: Dp.ink,
  );

  static TextStyle get dataBig => TextStyle(
    fontFamily: mono,
    fontSize: 20,
    height: 1.1,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    color: Dp.ink,
  );

  static TextStyle get dataTiny => TextStyle(
    fontFamily: mono,
    fontSize: 10,
    height: 1.25,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6,
    color: Dp.textMuted,
  );
}

/// Small helpers to apply the motion + typography tokens.
TextStyle monoTxt(double size, {Color? color, FontWeight? w, double? ls}) =>
    TextStyle(
      fontFamily: AppText.mono,
      fontSize: size,
      height: 1.25,
      fontWeight: w ?? FontWeight.w500,
      letterSpacing: ls ?? 0.4,
      color: color ?? Dp.ink,
    );

Curve tech() => Mo.easeOutTech;