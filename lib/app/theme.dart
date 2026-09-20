import 'package:flutter/material.dart';

import 'palette.dart';
import 'typography.dart';

/// Builds the Drishti ThemeData according to DESIGN-mobbin.md:
/// A gallery-white canvas, near-black ink, stadium-pill controls, and electric blue accent.
ThemeData buildDrishtiTheme() {
  final base = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    scaffoldBackgroundColor: Dp.canvas,
    fontFamily: AppText.sans,
    splashFactory: InkSparkle.splashFactory,
    colorScheme: const ColorScheme.light(
      primary: Dp.primary,
      onPrimary: Dp.onPrimary,
      surface: Dp.canvas,
      onSurface: Dp.ink,
      error: Dp.critical,
      onError: Colors.white,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Dp.accent,
      selectionColor: Color(0x330066FF),
      selectionHandleColor: Dp.accent,
    ),
    dividerColor: Dp.hairline,
    cardTheme: CardThemeData(
      color: Dp.canvas,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dp.rMd),
        side: const BorderSide(color: Dp.hairline),
      ),
    ),
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    hoverColor: Dp.canvasSoft,
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamily: AppText.sans,
      bodyColor: Dp.ink,
      displayColor: Dp.ink,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Dp.ink,
        textStyle: AppText.label,
        shape: const StadiumBorder(),
      ),
    ),
  );
}