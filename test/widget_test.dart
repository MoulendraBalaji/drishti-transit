import 'package:drishti_transit/app/app.dart';
import 'package:drishti_transit/core/command_center.dart';
import 'package:drishti_transit/core/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Mobile: boots into Field Operations App with Route, Verify, and Work Log tabs', (tester) async {
    // Default test window is 800x600 (mobile width < 900)
    final center = CommandCenter(simulate: false);
    await tester.pumpWidget(DrishtiApp(center: center));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Verify Mobile Field Operation tabs exist in dock
    expect(find.byKey(const ValueKey('dock_tab_MY ROUTE')), findsOneWidget);
    expect(find.byKey(const ValueKey('dock_tab_VERIFY & FIX')), findsOneWidget);
    expect(find.byKey(const ValueKey('dock_tab_MY WORK')), findsOneWidget);

    // Verify Mobile Route Header and Manual Flag FAB
    expect(find.text('FLAG DEFECT'), findsOneWidget);

    // Switch to Verify & Fix Tab
    final verifyTab = find.byKey(const ValueKey('dock_tab_VERIFY & FIX'));
    await tester.tap(verifyTab);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('ON-SITE VERIFY & RESOLVE WORKFLOW'), findsOneWidget);

    // Switch to My Work Log Tab
    final workTab = find.byKey(const ValueKey('dock_tab_MY WORK'));
    await tester.tap(workTab);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('MY ACTIVITY LOG · FIELD CREW 04'), findsOneWidget);

    // Clean unmount
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('Web: boots into Command & Control Dashboard with 5 workspaces and collapsible sidebar', (tester) async {
    // Set desktop screen size >= 900
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final center = CommandCenter(simulate: false);
    await tester.pumpWidget(DrishtiApp(center: center));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Verify 5 Web Workspaces
    expect(find.text('FLEET MAP'), findsWidgets);
    expect(find.text('ASSIGN & DISPATCH'), findsWidgets);
    expect(find.text('FLEET ANALYTICS'), findsWidgets);
    expect(find.text('AUDIT & EXPORT'), findsWidgets);
    expect(find.text('ALERT CONFIG'), findsWidgets);

    // Switch to Assign & Dispatch
    await tester.tap(find.text('ASSIGN & DISPATCH'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('MUNICIPAL TRIAGE & DISPATCH CONSOLE'), findsOneWidget);
    expect(find.text('1. NEW ALERTS'), findsOneWidget);
    expect(find.text('2. ASSIGNED'), findsOneWidget);

    // Switch to Fleet Analytics
    await tester.tap(find.text('FLEET ANALYTICS'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('PUNE METROPOLITAN FLEET ANALYTICS'), findsOneWidget);

    // Switch to Audit & Export
    await tester.tap(find.text('AUDIT & EXPORT'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('HISTORICAL AUDIT & MUNICIPAL REPORT EXPORT'), findsOneWidget);
    expect(find.text('EXPORT MUNICIPAL AUDIT REPORT'), findsOneWidget);

    // Switch to Alert Config
    await tester.tap(find.text('ALERT CONFIG'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('EDGE-AI SEVERITY THRESHOLDS & CORRIDOR CONFIGURATION'), findsOneWidget);

    // Test Collapsible Sidebar Menu Button
    expect(find.text('MENU'), findsOneWidget);
    await tester.tap(find.text('MENU'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Clean unmount
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('CommandCenter: cross-platform shared pipeline, verify, resolve, and offline queue', (tester) async {
    final center = CommandCenter(simulate: false);
    final targetId = center.incidents.first.id;

    // Web assigns alert to Field Crew 04
    center.assignIncident(targetId, 'Field Crew 04');
    final assignedEvent = center.byId(targetId);
    expect(assignedEvent?.status, IncidentStatus.assigned);
    expect(assignedEvent?.assignedCrew, 'Field Crew 04');

    // Mobile field crew verifies alert on-site
    center.verifyIncident(targetId, confirmed: true);
    final verifiedEvent = center.byId(targetId);
    expect(verifiedEvent?.status, IncidentStatus.verified);

    // Mobile marks resolved
    center.resolveIncident(targetId, remark: 'Asphalt patched');
    final resolvedEvent = center.byId(targetId);
    expect(resolvedEvent?.status, IncidentStatus.resolved);
    expect(resolvedEvent?.resolutionNote, 'Asphalt patched');
    expect(center.myResolvedToday.any((e) => e.id == targetId), isTrue);

    // Offline tolerance test
    center.toggleFieldOffline();
    expect(center.isFieldOffline, isTrue);

    // Perform action while offline -> queued
    center.resolveIncident(targetId, remark: 'Second offline update');
    expect(center.pendingSyncCount, 1);

    // Reconnecting triggers auto-sync
    center.toggleFieldOffline();
    expect(center.isFieldOffline, isFalse);
    expect(center.pendingSyncCount, 0);

    center.dispose();
  });

  testWidgets('CommandCenter: theme mode switching and state', (tester) async {
    final center = CommandCenter(simulate: false);
    expect(center.themeMode, ThemeMode.system);

    center.setThemeMode(ThemeMode.light);
    expect(center.themeMode, ThemeMode.light);
    expect(center.isDarkMode, isFalse);

    center.setThemeMode(ThemeMode.dark);
    expect(center.themeMode, ThemeMode.dark);
    expect(center.isDarkMode, isTrue);

    center.dispose();
  });
}