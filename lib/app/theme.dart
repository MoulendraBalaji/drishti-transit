import 'package:flutter/material.dart';

import 'palette.dart';
import 'typography.dart';

/// Builds the Drishti ThemeData according to DESIGN-mobbin.md:
/// Light: gallery-white canvas (#FFFFFF), near-black ink (#121417), stadium-pill controls, electric blue accent.
/// Dark: obsidian charcoal canvas (#0D1117), crisp white ink (#F0F6FC), elevated cards (#161B22), hairline borders (#30363D).
ThemeData buildDrishtiTheme({bool isDark = false}) {
  final bg = isDark ? const Color(0xFF0D1117) : const Color(0xFFFFFFFF);
  final surface = isDark ? const Color(0xFF161B22) : const Color(0xFFFFFFFF);
  final ink = isDark ? const Color(0xFFF0F6FC) : const Color(0xFF121417);
  final onPrimary = isDark ? const Color(0xFF0D1117) : const Color(0xFFFFFFFF);
  final border = isDark ? const Color(0xFF30363D) : const Color(0xFFE2E4E8);
  final hover = isDark ? const Color(0xFF21262D) : const Color(0xFFF7F8FA);

  final base = ThemeData(
    brightness: isDark ? Brightness.dark : Brightness.light,
    useMaterial3: true,
    scaffoldBackgroundColor: bg,
    fontFamily: AppText.sans,
    splashFactory: InkSparkle.splashFactory,
    colorScheme: isDark
        ? ColorScheme.dark(
            primary: ink,
            onPrimary: onPrimary,
            surface: surface,
            onSurface: ink,
            error: Dp.critical,
            onError: Colors.white,
          )
        : ColorScheme.light(
            primary: ink,
            onPrimary: onPrimary,
            surface: surface,
            onSurface: ink,
            error: Dp.critical,
            onError: Colors.white,
          ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Dp.accent,
      selectionColor: Color(0x330066FF),
      selectionHandleColor: Dp.accent,
    ),
    dividerColor: border,
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dp.rMd),
        side: BorderSide(color: border),
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