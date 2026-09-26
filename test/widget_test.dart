import 'package:drishti_transit/app/app.dart';
import 'package:drishti_transit/core/command_center.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('boots into mission with government masthead, dock tabs, and command map layer toggles', (tester) async {
    final center = CommandCenter(simulate: false);
    await tester.pumpWidget(DrishtiApp(center: center));
    await tester.pump(const Duration(milliseconds: 600));

    // Verify Government Masthead & 4-tab dock
    expect(find.text('DRISHTI-TRANSIT'), findsWidgets);
    expect(find.text('MISSION'), findsWidgets);
    expect(find.text('DETECTION'), findsWidgets);
    expect(find.text('COMMAND MAP'), findsWidgets);
    expect(find.text('ANALYTICS'), findsWidgets);

    // Switch to Command Map (Tab index 2)
    final mapTab = find.byKey(const ValueKey('dock_tab_COMMAND MAP'));
    expect(mapTab, findsOneWidget);
    await tester.tap(mapTab);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // High-contrast HEAT and CORRIDOR controls are present and visible on Command Map.
    expect(find.text('HEAT'), findsOneWidget);
    expect(find.text('CORRIDOR'), findsOneWidget);

    // Tapping HEAT toggles heatmap layer in CommandCenter.
    expect(center.showHeatmap, isTrue);
    await tester.tap(find.text('HEAT'));
    await tester.pump();
    expect(center.showHeatmap, isFalse);

    // Tapping CORRIDOR toggles transit corridors in CommandCenter.
    expect(center.showCorridors, isTrue);
    await tester.tap(find.text('CORRIDOR'));
    await tester.pump();
    expect(center.showCorridors, isFalse);

    // Unmount to dispose tickers/timers cleanly.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('navigates to settings and configures system default theme', (tester) async {
    final center = CommandCenter(simulate: false);
    await tester.pumpWidget(DrishtiApp(center: center));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Tap the settings button in GovMasthead
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

  testWidgets('command map page and its toggles switch to light mode styling when light mode is selected', (tester) async {
    final center = CommandCenter(simulate: false);
    center.setThemeMode(ThemeMode.light);
    await tester.pumpWidget(DrishtiApp(center: center));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Switch to Command Map
    final mapTab = find.byKey(const ValueKey('dock_tab_COMMAND MAP'));
    await tester.tap(mapTab);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Verify OpenStreetMap basemap tile layer is loaded in Light Mode
    expect(find.byKey(const ValueKey('osm_light')), findsOneWidget);
    expect(find.text('HEAT'), findsOneWidget);
    expect(find.text('CORRIDOR'), findsOneWidget);

    // Switch to Dark Mode dynamically
    center.setThemeMode(ThemeMode.dark);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Verify OpenStreetMap basemap tile layer is loaded in Dark Mode
    expect(find.byKey(const ValueKey('osm_dark')), findsOneWidget);

    // Clean unmount
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('switches to detection feed with live video stream overlay and controls', (tester) async {
    final center = CommandCenter(simulate: false);
    await tester.pumpWidget(DrishtiApp(center: center));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Switch to Detection Feed tab
    final detectionTab = find.byKey(const ValueKey('dock_tab_DETECTION'));
    await tester.tap(detectionTab);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Verify detection feed elements
    expect(find.text('LIVE ON-BUS INFERENCE LOG · SUB-METER GEO SYNC'), findsOneWidget);
    expect(find.text('RE-SCAN'), findsOneWidget);

    // Clean unmount
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });
}