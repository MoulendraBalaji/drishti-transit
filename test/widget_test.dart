import 'package:drishti_transit/app/app.dart';
import 'package:drishti_transit/core/command_center.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('boots through the splash into the command center', (tester) async {
    final center = CommandCenter();
    await tester.pumpWidget(DrishtiApp(center: center));

    // Splash boots and the router advances to the command center.
    await tester.pump(const Duration(milliseconds: 3200));
    await tester.pump(const Duration(milliseconds: 500));

    // Dock is up (command tab active by default), feed sheet visible.
    expect(find.text('EDGE'), findsOneWidget);
    expect(find.text('OPS FEED'), findsOneWidget);

    // Unmount to dispose tickers/timers cleanly (app owns the center).
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });
}