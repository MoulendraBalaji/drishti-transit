import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/analytics_screen.dart';
import '../screens/command_screen.dart';
import '../screens/incident_detail_screen.dart';
import '../screens/onboard_screen.dart';
import '../screens/shell.dart';
import '../screens/splash_screen.dart';
import '../ui/transitions.dart';

/// Drishti navigation — one custom page type ([DrishtiRoute]) everywhere so
/// no default Material transition ever appears, and a self-made three-tab
/// dock (StatefulShellRoute keeps each tab's state alive).
class AppRouter {
  AppRouter._();

  static const String command = '/command';
  static const String edge = '/edge';
  static const String insight = '/insight';
  static const String incident = '/command/incident/:id';

  static GoRouter build({required GlobalKey<NavigatorState> rootNavKey}) {
    return GoRouter(
      navigatorKey: rootNavKey,
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => DrishtiRoute(
            kind: RouteKind.iris,
            builder: (_) => const SplashScreen(),
          ),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => AppShell(shell: shell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: command,
                  pageBuilder: (context, state) => DrishtiRoute(
                    kind: RouteKind.enter,
                    builder: (_) => const CommandScreen(),
                  ),
                  routes: [
                    GoRoute(
                      path: 'incident/:id',
                      pageBuilder: (context, state) => DrishtiRoute(
                        kind: RouteKind.zoomIn,
                        builder: (_) => IncidentDetailScreen(
                            id: state.pathParameters['id']!),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: edge,
                  pageBuilder: (context, state) => DrishtiRoute(
                    kind: RouteKind.enter,
                    builder: (_) => const OnboardScreen(),
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: insight,
                  pageBuilder: (context, state) => DrishtiRoute(
                    kind: RouteKind.enter,
                    builder: (_) => const AnalyticsScreen(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}