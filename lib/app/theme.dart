import 'package:flutter/material.dart';

import 'palette.dart';
import 'typography.dart';

/// Builds the Drishti-Transit ThemeData:
/// Restrained, dark command-center aesthetic.
/// Deep navy/ink base (#090E17), crisp slate borders (#1F2F4A),
/// electric cyan live accent (#00F5D4), and no Material 3 defaults.
ThemeData buildDrishtiTheme({bool isDark = true}) {
  final bg = isDark ? const Color(0xFF090E17) : const Color(0xFFF4F6F9);
  final surface = isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFFFF);
  final cardBg = isDark ? const Color(0xFF111C2E) : const Color(0xFFFFFFFF);
  final ink = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
  final border = isDark ? const Color(0xFF1F2F4A) : const Color(0xFFD3DBE5);
  final hover = isDark ? const Color(0xFF162238) : const Color(0xFFE9EDF2);

  final base = ThemeData(
    brightness: isDark ? Brightness.dark : Brightness.light,
    useMaterial3: true,
    scaffoldBackgroundColor: bg,
    fontFamily: AppText.sans,
    colorScheme: isDark
        ? ColorScheme.dark(
            primary: Dp.accent,
            onPrimary: const Color(0xFF090E17),
            surface: surface,
            onSurface: const Color(0xFFF1F5F9),
            error: Dp.critical,
            onError: Colors.white,
          )
        : ColorScheme.light(
            primary: const Color(0xFF0284C7),
            onPrimary: Colors.white,
            surface: surface,
            onSurface: const Color(0xFF0F172A),
            error: Dp.critical,
            onError: Colors.white,
          ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Dp.accent,
      selectionColor: Color(0x3300F5D4),
      selectionHandleColor: Dp.accent,
    ),
    dividerColor: border,
    cardTheme: CardThemeData(
      color: cardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dp.rMd),
        side: BorderSide(color: border, width: 1.0),
      ),
    ),
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    hoverColor: hover,
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamily: AppText.sans,
      bodyColor: ink,
      displayColor: ink,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: ink,
        textStyle: AppText.label,
        shape: const StadiumBorder(),
      ),
    ),
  );
}