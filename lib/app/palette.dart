import 'package:flutter/material.dart';

/// Drishti-Transit Palette — Command-Center Ops-Room Aesthetic:
/// Deep navy/ink base (never pure black: #090E17 / #0F172A), crisp slate borders
/// (#1E293B / #26354D), confident electric cyan live accent (#00F5D4),
/// and a deliberate non-cartoonish severity scale (amber -> orange -> crimson red)
/// for alerts. Dark mode as primary.
class Dp {
  Dp._();

  /// Dark mode is primary.
  static bool isDark = true;

  // Command Navy Canvas & Slate Ladder (Dark - Primary)
  static const Color _canvasDark = Color(0xFF090E17);
  static const Color _canvasSoftDark = Color(0xFF0F172A);
  static const Color _fieldDark = Color(0xFF162238);
  static const Color _cardDark = Color(0xFF111C2E);
  static const Color _hairlineDark = Color(0xFF1F2F4A);
  static const Color _hairlineSoftDark = Color(0xFF18253A);
  static const Color _lineBrightDark = Color(0xFF2C4166);

  // Inks & Typography (Dark)
  static const Color _inkDark = Color(0xFFF1F5F9);
  static const Color _inkSoftDark = Color(0xFFCBD5E1);
  static const Color _textMutedDark = Color(0xFF8899AC);
  static const Color _textFaintDark = Color(0xFF5B6E84);

  // Light Mode Fallback
  static const Color _canvasLight = Color(0xFFF4F6F9);
  static const Color _canvasSoftLight = Color(0xFFFFFFFF);
  static const Color _fieldLight = Color(0xFFE9EDF2);
  static const Color _cardLight = Color(0xFFFFFFFF);
  static const Color _hairlineLight = Color(0xFFD3DBE5);
  static const Color _hairlineSoftLight = Color(0xFFE2E8F0);
  static const Color _lineBrightLight = Color(0xFFBAC7D5);

  static const Color _inkLight = Color(0xFF0F172A);
  static const Color _inkSoftLight = Color(0xFF334155);
  static const Color _textMutedLight = Color(0xFF64748B);
  static const Color _textFaintLight = Color(0xFF94A3B8);

  // Dynamic Theme Getters
  static Color get canvas => isDark ? _canvasDark : _canvasLight;
  static Color get canvasSoft => isDark ? _canvasSoftDark : _canvasSoftLight;
  static Color get card => isDark ? _cardDark : _cardLight;
  static Color get field => isDark ? _fieldDark : _fieldLight;
  static Color get hairline => isDark ? _hairlineDark : _hairlineLight;
  static Color get hairlineSoft => isDark ? _hairlineSoftDark : _hairlineSoftLight;
  static Color get lineBright => isDark ? _lineBrightDark : _lineBrightLight;

  // Surface aliases
  static Color get bg => canvas;
  static Color get surface => canvasSoft;
  static Color get raised => card;
  static Color get raised2 => field;
  static Color get line => hairline;

  // Inks & Typography
  static Color get primary => isDark ? const Color(0xFF00F5D4) : const Color(0xFF0284C7);
  static Color get onPrimary => isDark ? const Color(0xFF090E17) : Colors.white;
  static Color get ink => isDark ? _inkDark : _inkLight;
  static Color get inkSoft => isDark ? _inkSoftDark : _inkSoftLight;
  static Color get textMuted => isDark ? _textMutedDark : _textMutedLight;
  static Color get textFaint => isDark ? _textFaintDark : _textFaintLight;

  static Color get mist => textMuted;
  static Color get fog => textFaint;

  // Live Active Accent: Electric Cyan / Teal
  static const Color accent = Color(0xFF00F5D4);
  static const Color accentCyan = Color(0xFF00E5FF);
  static const Color accentGlow = Color(0x3300F5D4);
  static Color get signal => accent;
  static const Color signalDim = Color(0xFF00A892);
  static const Color onSignal = Color(0xFF090E17);

  // Brand highlight
  static Color get saffron => const Color(0xFFFF9933);
  static Color get indiaGreen => const Color(0xFF138808);
  static Color get chakraNavy => isDark ? const Color(0xFF38BDF8) : const Color(0xFF000080);

  // Official Indian National Tricolor Canvas Background Gradient
  static LinearGradient get tricolorGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: isDark
        ? const [
            Color(0x1FFF9933), // ambient Saffron glow at top
            Color(0xFF0A101E), // deep official navy body
            Color(0xFF080D18), // deep canvas
            Color(0x1F138808), // ambient India Green glow at bottom
          ]
        : const [
            Color(0x18FF9933), // gentle Saffron tint
            Color(0xFFF8FAFC), // crisp white body
            Color(0xFFF1F5F9), // clean slate
            Color(0x18138808), // gentle India Green tint
          ],
    stops: const [0.0, 0.24, 0.76, 1.0],
  );

  static LinearGradient get tricolorBarGradient => const LinearGradient(
    colors: [
      Color(0xFFFF9933),
      Color(0xFFFFFFFF),
      Color(0xFF138808),
    ],
    stops: [0.33, 0.66, 1.0],
  );

  // Corner Geometry tokens
  static const double rSm = 12.0;
  static const double rMd = 18.0;
  static const double rLg = 24.0;
  static const double rFull = 9999.0;

  // Non-cartoonish Alert Severity Scale:
  // Note/Watch: Tactical Amber (#F59E0B)
  // Alert/Elevated: Alert Orange (#F97316)
  // Critical: Crimson Red (#EF4444)
  static const Color note = Color(0xFF38BDF8); // Informational sky blue
  static const Color watch = Color(0xFFF59E0B); // Amber watch
  static const Color elevated = Color(0xFFF97316); // Orange alert
  static const Color critical = Color(0xFFEF4444); // Crimson critical

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
      severityColor(s).withValues(alpha: isDark ? 0.22 : 0.14);

  static Color get vehicleColor => isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B);

  // Heat map ramp
  static const Color heatLow = Color(0x0000F5D4);
  static const Color heatMid = Color(0x88F59E0B);
  static const Color heatHigh = Color(0xE6EF4444);
}

/// Official Government of India & National Heritage color constants
class GovColors {
  GovColors._();

  static const Color saffron = Color(0xFFFF9933);
  static const Color white = Color(0xFFFFFFFF);
  static const Color green = Color(0xFF138808);
  static const Color chakraNavy = Color(0xFF000080);
  static const Color chakraSky = Color(0xFF0284C7);

  static Color get saffronSoft => saffron.withValues(alpha: Dp.isDark ? 0.18 : 0.12);
  static Color get greenSoft => green.withValues(alpha: Dp.isDark ? 0.18 : 0.12);
}

/// Severity tier shared across models and alert UI.
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
        return 'Informational';
      case SeverityClass.watch:
        return 'Watch (Minor)';
      case SeverityClass.elevated:
        return 'Elevated Risk';
      case SeverityClass.critical:
        return 'Critical Defect';
    }
  }
}

/// Stochastic generator used for deterministic seed generation.
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