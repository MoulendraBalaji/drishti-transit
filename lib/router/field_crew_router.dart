import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/mobile/field_crew_settings_screen.dart';
import '../screens/mobile/field_crew_shell.dart';
import '../ui/transitions.dart';

/// Field Crew Dedicated Router:
/// Scope: Only on-ground field worker routes (Shell with Route, Verify, Work, and Settings).
/// Zero links, imports, or definitions for central command views.
class FieldCrewRouter {
  FieldCrewRouter._();

  static const String home = '/';
  static const String settings = '/settings';

  static GoRouter build({required GlobalKey<NavigatorState> rootNavKey}) {
    return GoRouter(
      navigatorKey: rootNavKey,
      initialLocation: home,
      routes: [
        GoRoute(
          path: home,
          pageBuilder: (context, state) => DrishtiRoute(
            kind: RouteKind.enter,
            builder: (_) => const FieldCrewShell(),
          ),
        ),
        GoRoute(
          path: settings,
          pageBuilder: (context, state) => DrishtiRoute(
            kind: RouteKind.zoomIn,
            builder: (_) => const FieldCrewSettingsScreen(),
          ),
        ),
      ],
    );
  }
}
