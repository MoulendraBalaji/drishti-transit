import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/analytics_screen.dart';
import '../screens/command_screen.dart';
import '../screens/detection_feed_screen.dart';
import '../screens/mission_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/shell.dart';
import '../ui/transitions.dart';

/// Drishti-Transit router — 4 screens, nothing more:
/// A) Home / Mission (/mission)
/// B) Detection Feed (/feed)
/// C) Command Map (/map)
/// D) Analytics (/analytics)
///
/// Backed by StatefulShellRoute.indexedStack to preserve state between tabs,
/// and DrishtiRoute for custom scale+fade+vertical slide transitions app-wide.
class AppRouter {
  AppRouter._();

  static const String mission = '/mission';
  static const String feed = '/feed';
  static const String map = '/map';
  static const String analytics = '/analytics';

  static GoRouter build({required GlobalKey<NavigatorState> rootNavKey}) {
    return GoRouter(
      navigatorKey: rootNavKey,
      initialLocation: mission,
      routes: [
        // Redirect root directly to Mission
        GoRoute(
          path: '/',
          redirect: (_, _) => mission,
        ),
        // Aliases for compatibility
        GoRoute(
          path: '/command',
          redirect: (_, _) => map,
        ),
        GoRoute(
          path: '/edge',
          redirect: (_, _) => feed,
        ),
        GoRoute(
          path: '/insight',
          redirect: (_, _) => analytics,
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => DrishtiRoute(
            kind: RouteKind.zoomIn,
            builder: (_) => const SettingsScreen(),
          ),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => AppShell(shell: shell),
          branches: [
            // Branch 0: Screen A — Home / Mission
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: mission,
                  pageBuilder: (context, state) => DrishtiRoute(
                    kind: RouteKind.enter,
                    builder: (_) => MissionScreen(
                      onNavigateToTab: (index) {
                        // handled via shell
                      },
                    ),
                  ),
                ),
              ],
            ),
            // Branch 1: Screen B — Detection Feed
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: feed,
                  pageBuilder: (context, state) => DrishtiRoute(
                    kind: RouteKind.enter,
                    builder: (_) => const DetectionFeedScreen(),
                  ),
                ),
              ],
            ),
            // Branch 2: Screen C — Command Map
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: map,
                  pageBuilder: (context, state) => DrishtiRoute(
                    kind: RouteKind.enter,
                    builder: (_) => const CommandScreen(),
                  ),
                ),
              ],
            ),
            // Branch 3: Screen D — Analytics
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: analytics,
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