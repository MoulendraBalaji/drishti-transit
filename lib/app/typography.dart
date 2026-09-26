import 'package:flutter/material.dart';

import 'motion.dart';
import 'palette.dart';

/// Typography for Drishti-Transit:
/// - ONE distinctive display face: [Fraunces] for wordmarks, headings, big numbers
/// - ONE clean technical body face: [IBMPlexSans] for lists, descriptions, labels
/// - ONE true monospace: [IBMPlexMono] for GPS coordinates, timestamps, confidence scores, telemetry IDs
/// Defined once here and reused everywhere.
class AppText {
  AppText._();

  static const String display = 'Fraunces';
  static const String sans = 'IBMPlexSans';
  static const String mono = 'IBMPlexMono';

  static Color get hi => Dp.ink;
  static Color get mi => Dp.textMuted;
  static Color get lo => Dp.textFaint;

  // --- Display Typography (Fraunces) --------------------------------------
  static TextStyle get displayHero => TextStyle(
        fontFamily: display,
        fontSize: 38,
        height: 1.08,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        color: Dp.ink,
      );

  static TextStyle get displayTitle => TextStyle(
        fontFamily: display,
        fontSize: 22,
        height: 1.15,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: Dp.ink,
      );

  static TextStyle get displaySection => TextStyle(
        fontFamily: display,
        fontSize: 17,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: Dp.ink,
      );

  static TextStyle get displayNumber => TextStyle(
        fontFamily: display,
        fontSize: 26,
        height: 1.0,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: Dp.ink,
      );

  static TextStyle displaySmall({double size = 13}) => TextStyle(
        fontFamily: display,
        fontSize: size,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: Dp.ink,
      );

  // --- Technical Body (IBM Plex Sans) -------------------------------------
  static TextStyle get body => TextStyle(
        fontFamily: sans,
        fontSize: 14,
        height: 1.45,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        color: Dp.ink,
      );

  static TextStyle get bodySmall => TextStyle(
        fontFamily: sans,
        fontSize: 12.5,
        height: 1.4,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        color: Dp.textMuted,
      );

  static TextStyle get label => TextStyle(
        fontFamily: sans,
        fontSize: 12,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: Dp.ink,
      );

  // --- Monospace Data & Telemetry (IBM Plex Mono) -------------------------
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
        fontSize: 18,
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

  static TextStyle get dataAccent => TextStyle(
        fontFamily: mono,
        fontSize: 11.5,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: Dp.accent,
      );
}

/// Helper for ad-hoc monospace data with defined weight & color
TextStyle monoTxt(double size, {Color? color, FontWeight? w, double? ls}) =>
    TextStyle(
      fontFamily: AppText.mono,
      fontSize: size,
      height: 1.25,
      fontWeight: w ?? FontWeight.w500,
      letterSpacing: ls ?? 0.4,
      color: color ?? Dp.ink,
    );

Curve tech() => Mo.easeTech;