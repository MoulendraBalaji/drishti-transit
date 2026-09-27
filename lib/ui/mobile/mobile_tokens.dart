import 'package:flutter/material.dart';

import '../../app/palette.dart';
import '../../app/typography.dart';

/// Mobile signal colours for the Field Crew terminal.
///
/// Resolves the ops palette per mode so every status colour (safe / caution /
/// danger / verified) keeps its meaning *and* its contrast when the terminal is
/// read in direct sunlight or at night on a rugged handheld.
class MSig {
  MSig._();

  static const Color saffron = Color(0xFFFF9933);
  static const Color indiaGreen = Color(0xFF138808);

  /// Interactive accent. Cyan on the dark ops-room theme, deep gov-portal blue
  /// outdoors, so accent-coloured text always clears contrast.
  static Color get accent => Dp.isDark ? Dp.accent : const Color(0xFF0284C7);

  /// Foreground that sits on top of [accent].
  static Color get onAccent => Dp.isDark ? const Color(0xFF04121A) : Colors.white;

  /// Picks the legible foreground for an arbitrary fill so every button, pill,
  /// and solid state keeps AA contrast in both modes.
  static Color onColor(Color bg) =>
      bg.computeLuminance() > 0.32 ? const Color(0xFF071019) : Colors.white;

  /// Soft accent fill.
  static Color accentFill(double a) => accent.withValues(alpha: a);

  /// Accent hairline/ring.
  static Color get accentRing => accent.withValues(alpha: Dp.isDark ? 0.55 : 0.40);

  static Color get online => Dp.isDark ? const Color(0xFF34D399) : const Color(0xFF15803D);
  static Color get offline => Dp.isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
  static Color get resolved => Dp.isDark ? const Color(0xFF34D399) : const Color(0xFF047857);
  static Color get verified => Dp.isDark ? const Color(0xFFA855F7) : const Color(0xFF7E22CE);
  static Color get assigned => Dp.isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1);
  static Color get info => Dp.isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1);
  static Color get pending => Dp.isDark ? const Color(0xFFF59E0B) : const Color(0xFFB45309);

  /// A hairline that survives both modes for raised/inset surfaces.
  static Color get insetLine => Dp.isDark ? Dp.hairlineSoft : Dp.hairlineSoft;
}

/// Mobile spacing scale — a 4pt rhythm sized for a 5–6" handheld.
class MSp {
  MSp._();

  static const double xs = 6;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;

  /// Horizontal page gutter.
  static const double gutter = 16;

  /// Minimum comfortable thumb target.
  static const double tap = 44;
}

/// MT — the Field Crew mobile type scale.
///
/// The Android terminal is a small, high-DPI canvas, so every text role gets an
/// explicit, legible size:
///  * [display] Fraunces for screen + big-number moments,
///  * [title] / [body] / [caption] IBM Plex Sans for everything a human reads,
///  * [eyebrow] / [data] IBM Plex Mono reserved for labels and real telemetry.
///
/// Nothing important lives at 8pt any more, and prose is never forced to caps.
class MT {
  MT._();

  /// Screen headline (Fraunces).
  static TextStyle display({double size = 21, Color? color}) => TextStyle(
        fontFamily: AppText.display,
        fontSize: size,
        height: 1.12,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: color ?? Dp.ink,
      );

  /// Card headline (IBM Plex Sans, title case).
  static TextStyle title({double size = 14.5, Color? color, FontWeight w = FontWeight.w700}) => TextStyle(
        fontFamily: AppText.sans,
        fontSize: size,
        height: 1.25,
        fontWeight: w,
        letterSpacing: 0,
        color: color ?? Dp.ink,
      );

  /// Readable body copy.
  static TextStyle body({double size = 12.5, Color? color}) => TextStyle(
        fontFamily: AppText.sans,
        fontSize: size,
        height: 1.45,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        color: color ?? Dp.textMuted,
      );

  /// Smallest sanctioned body size.
  static TextStyle caption({double size = 11, Color? color}) => TextStyle(
        fontFamily: AppText.sans,
        fontSize: size,
        height: 1.4,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: color ?? Dp.textMuted,
      );

  /// Uppercase mono section label / eyebrow.
  static TextStyle eyebrow({double size = 9.5, Color? color, double ls = 1.4}) =>
      monoTxt(size, color: color ?? Dp.textMuted, w: FontWeight.w800, ls: ls);

  /// Telemetry value (GPS, IDs, clocks, confidence).
  static TextStyle data({double size = 11, Color? color, FontWeight w = FontWeight.w600}) =>
      monoTxt(size, color: color ?? Dp.inkSoft, w: w, ls: 0.2);

  /// Big Fraunces figure.
  static TextStyle figure({double size = 24, Color? color}) => TextStyle(
        fontFamily: AppText.display,
        fontSize: size,
        height: 1.0,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: color ?? Dp.ink,
      );

  /// Button / action label.
  static TextStyle button({double size = 12.5, Color? color}) => TextStyle(
        fontFamily: AppText.sans,
        fontSize: size,
        height: 1.15,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
        color: color ?? Dp.ink,
      );

  /// Dock / tab label.
  static TextStyle tab({double size = 10, Color? color, FontWeight w = FontWeight.w700}) => TextStyle(
        fontFamily: AppText.sans,
        fontSize: size,
        height: 1.1,
        fontWeight: w,
        letterSpacing: 0.2,
        color: color ?? Dp.textMuted,
      );
}
