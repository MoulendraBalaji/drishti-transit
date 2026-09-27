import 'package:drishti_transit/app/command_room_app.dart';
import 'package:drishti_transit/app/field_crew_app.dart';
import 'package:drishti_transit/core/command_center.dart';
import 'package:drishti_transit/core/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Mobile: boots into FieldCrewApp with Route, Verify, and Work Log tabs', (tester) async {
    // Default test window is 800x600 (mobile width < 900)
    final center = CommandCenter(simulate: false);
    await tester.pumpWidget(FieldCrewApp(center: center));
    await tester.pump();

    // The opening sequence owns the screen until it reports in.
    expect(find.text('TAP TO CONTINUE'), findsOneWidget);
    expect(find.byKey(const ValueKey('dock_tab_MY ROUTE')), findsOneWidget);

    // Let the cold-start choreography resolve, then lift the curtain.
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('TAP TO CONTINUE'), findsNothing);

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

  testWidgets('Mobile: a tap skips the opening sequence', (tester) async {
    final center = CommandCenter(simulate: false);
    await tester.pumpWidget(FieldCrewApp(center: center));
    await tester.pump();
    expect(find.text('TAP TO CONTINUE'), findsOneWidget);

    await tester.tapAt(const Offset(400, 300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('TAP TO CONTINUE'), findsNothing);
    expect(find.byKey(const ValueKey('dock_tab_MY WORK')), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('Mobile: settings screen lays out on a phone viewport', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final center = CommandCenter(simulate: false);
    await tester.pumpWidget(FieldCrewApp(center: center));
    await tester.pump();
    await tester.tapAt(const Offset(195, 400)); // skip the opening sequence
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    await tester.tap(find.byKey(const ValueKey('topbar_settings')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Field Settings'), findsOneWidget);
    expect(find.text('Proximity radar radius'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });

  for (final size in const [Size(360, 640), Size(430, 932)]) {
    for (final dark in [false, true]) {
      testWidgets('Mobile: ${size.width.toInt()}x${size.height.toInt()} '
          '${dark ? 'night patrol' : 'outdoor light'} lays out every screen', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final center = CommandCenter(simulate: false)
          ..setThemeMode(dark ? ThemeMode.dark : ThemeMode.light);
        await tester.pumpWidget(FieldCrewApp(center: center));
        await tester.pump();
        await tester.tapAt(Offset(size.width / 2, size.height / 2));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 700));

        for (final tab in const ['MY ROUTE', 'VERIFY & FIX', 'MY WORK']) {
          await tester.tap(find.byKey(ValueKey('dock_tab_$tab')));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 700));
          expect(tester.takeException(), isNull, reason: '$tab overflowed or threw');
        }

        await tester.tap(find.byKey(const ValueKey('topbar_settings')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 700));
        expect(tester.takeException(), isNull, reason: 'settings overflowed or threw');
        await tester.dragUntilVisible(
          find.text('End shift & sign out'),
          find.byType(ListView),
          const Offset(0, -120),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull, reason: 'settings footer overflowed');

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 100));
      });
    }
  }

  testWidgets('Web: boots into CommandRoomApp with workspaces and collapsible sidebar', (tester) async {
    // Set desktop screen size >= 900
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final center = CommandCenter(simulate: false);
    await tester.pumpWidget(CommandRoomApp(center: center));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Verify Web Workspaces
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

    // Web assigns alert to Maintenance Unit 04
    center.assignIncident(targetId, 'Maintenance Unit 04');
    final assignedEvent = center.byId(targetId);
    expect(assignedEvent?.status, IncidentStatus.assigned);
    expect(assignedEvent?.assignedCrew, 'Maintenance Unit 04');

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