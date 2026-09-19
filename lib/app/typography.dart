import 'package:flutter/material.dart';

import 'motion.dart';

/// Typography for Drishti.
///
/// One display family (Fraunces) for the wordmark, titles and big numbers.
/// One technical family (IBM Plex Sans) for body and labels, paired with its
/// true monospace (IBM Plex Mono) so GPS / time / confidence / plates read as
/// data. Hierarchy is built with weight, size and tracking, never more fonts.
class AppText {
  AppText._();

  static const String display = 'Fraunces';
  static const String sans = 'IBMPlexSans';
  static const String mono = 'IBMPlexMono';

  static const Color hi = Color(0xFFE9EEF8);
  static const Color mi = Color(0xFF96A5C0);
  static const Color lo = Color(0xFF5D6D8A);

  // --- Display (Fraunces) -----------------------------------------------
  static const TextStyle displayHero = TextStyle(
    fontFamily: display,
    fontSize: 44,
    height: 1.02,
    fontWeight: FontWeight.w600,
    letterSpacing: -1.2,
  );

  static const TextStyle displayTitle = TextStyle(
    fontFamily: display,
    fontSize: 24,
    height: 1.08,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
  );

  static const TextStyle displaySection = TextStyle(
    fontFamily: display,
    fontSize: 19,
    height: 1.12,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );

  static const TextStyle displayNumber = TextStyle(
    fontFamily: display,
    fontSize: 30,
    height: 1,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.6,
  );

  static TextStyle displaySmall({double size = 13}) => TextStyle(
        fontFamily: display,
        fontSize: size,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      );

  // --- Technical body (IBM Plex Sans) ----------------------------------
  static const TextStyle body = TextStyle(
    fontFamily: sans,
    fontSize: 14,
    height: 1.42,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: sans,
    fontSize: 12.5,
    height: 1.35,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
  );

  static const TextStyle label = TextStyle(
    fontFamily: sans,
    fontSize: 12,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6,
  );

  // --- Data (IBM Plex Mono) --------------------------------------------
  static const TextStyle data = TextStyle(
    fontFamily: mono,
    fontSize: 12,
    height: 1.3,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
  );

  static const TextStyle dataStrong = TextStyle(
    fontFamily: mono,
    fontSize: 12,
    height: 1.3,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.4,
  );

  static const TextStyle dataBig = TextStyle(
    fontFamily: mono,
    fontSize: 20,
    height: 1.1,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  static const TextStyle dataTiny = TextStyle(
    fontFamily: mono,
    fontSize: 9.5,
    height: 1.25,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.7,
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
      color: color,
    );

Curve tech() => Mo.easeOutTech;