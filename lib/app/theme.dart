import 'package:flutter/material.dart';

import 'palette.dart';
import 'typography.dart';

/// Builds the Drishti ThemeData — a command-center palette, our fonts wired
/// into the text theme, and none of the default Material chrome.
ThemeData buildDrishtiTheme() {
  final base = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: Dp.bg,
    fontFamily: AppText.sans,
    splashFactory: InkSparkle.splashFactory,
    colorScheme: const ColorScheme.dark(
      primary: Dp.signal,
      onPrimary: Dp.onSignal,
      surface: Dp.surface,
      onSurface: Dp.ink,
      error: Dp.critical,
      onError: Color(0xFF2B0A0C),
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Dp.signal,
      selectionColor: Color(0x4034E2B4),
      selectionHandleColor: Dp.signal,
    ),
    dividerColor: Dp.line,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    hoverColor: Colors.transparent,
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamily: AppText.sans,
      bodyColor: Dp.ink,
      displayColor: Dp.ink,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Dp.signal,
        textStyle: AppText.label,
      ),
    ),
  );
}