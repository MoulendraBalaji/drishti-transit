import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/web/command_room_shell.dart';
import '../ui/transitions.dart';

/// Command Room Dedicated Router:
/// Scope: Only city authority & fleet command center routes.
/// Zero links, imports, or definitions for on-ground field worker screens.
class CommandRoomRouter {
  CommandRoomRouter._();

  static const String home = '/';

  static GoRouter build({required GlobalKey<NavigatorState> rootNavKey}) {
    return GoRouter(
      navigatorKey: rootNavKey,
      initialLocation: home,
      routes: [
        GoRoute(
          path: home,
          pageBuilder: (context, state) => DrishtiRoute(
            kind: RouteKind.enter,
            builder: (_) => const CommandRoomShell(),
          ),
        ),
      ],
    );
  }
}
