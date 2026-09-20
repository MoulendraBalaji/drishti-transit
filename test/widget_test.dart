import 'package:drishti_transit/app/app.dart';
import 'package:drishti_transit/core/command_center.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('boots through the splash into the command center with floating dock and layer toggles', (tester) async {
    final center = CommandCenter();
    await tester.pumpWidget(DrishtiApp(center: center));

    // Splash boots and the router advances to the command center.
    await tester.pump(const Duration(milliseconds: 3200));
    await tester.pump(const Duration(milliseconds: 500));

    // Dock is up, feed sheet visible.
    expect(find.text('EDGE'), findsOneWidget);
    expect(find.text('OPS FEED'), findsOneWidget);

    // High-contrast HEAT, ROUTE, and CENTER controls are present and visible.
    expect(find.text('HEAT'), findsOneWidget);
    expect(find.text('ROUTE'), findsOneWidget);
    expect(find.text('CENTER'), findsOneWidget);

    // Tapping HEAT toggles heatmap layer in CommandCenter.
    expect(center.showHeatmap, isTrue);
    await tester.tap(find.text('HEAT'));
    await tester.pump();
    expect(center.showHeatmap, isFalse);

    // Tapping ROUTE toggles transit corridors in CommandCenter.
    expect(center.showCorridors, isTrue);
    await tester.tap(find.text('ROUTE'));
    await tester.pump();
    expect(center.showCorridors, isFalse);

    // Unmount to dispose tickers/timers cleanly.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('navigates to settings and configures system default theme', (tester) async {
    final center = CommandCenter();
    await tester.pumpWidget(DrishtiApp(center: center));

    // Fast-forward through splash
    await tester.pump(const Duration(milliseconds: 3200));
    await tester.pump(const Duration(milliseconds: 500));

    // Tap the top left Drishti brand / app icon to open settings
    final settingsBtn = find.byKey(const ValueKey('command_settings_button'));
    expect(settingsBtn, findsOneWidget);
    await tester.tap(settingsBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Verify Settings Screen is open
    expect(find.text('SYSTEM SETTINGS'), findsOneWidget);
    expect(find.text('APPEARANCE & THEME'), findsOneWidget);
    expect(find.text('SYSTEM'), findsOneWidget);
    expect(find.text('LIGHT'), findsOneWidget);
    expect(find.text('DARK'), findsOneWidget);

    // Select Light Mode
    await tester.tap(find.text('LIGHT'));
    await tester.pump();
    expect(center.themeMode, ThemeMode.light);

    // Select Dark Mode
    await tester.tap(find.text('DARK'));
    await tester.pump();
    expect(center.themeMode, ThemeMode.dark);

    // Select System Default
    await tester.tap(find.text('SYSTEM'));
    await tester.pump();
    expect(center.themeMode, ThemeMode.system);

    // Unmount cleanly
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('manages theme modes and system default settings in CommandCenter', (tester) async {
    final center = CommandCenter();
    expect(center.themeMode, ThemeMode.system);

    center.setThemeMode(ThemeMode.light);
    expect(center.themeMode, ThemeMode.light);
    expect(center.isDarkMode, isFalse);

    center.setThemeMode(ThemeMode.dark);
    expect(center.themeMode, ThemeMode.dark);
    expect(center.isDarkMode, isTrue);

    center.setThemeMode(ThemeMode.system);
    expect(center.themeMode, ThemeMode.system);

    center.dispose();
  });
}