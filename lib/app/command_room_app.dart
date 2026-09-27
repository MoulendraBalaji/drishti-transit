import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/command_center.dart';
import '../router/command_room_router.dart';
import 'palette.dart';
import 'theme.dart';

/// Top-level Application Widget for Command Room (Web / Desktop).
///
/// Scope: Purpose-built for city authorities and transit operations controllers.
/// Contains ONLY:
/// - City-wide live map
/// - Fleet-wide live camera feed
/// - Incident triage & dispatch
/// - Fleet-wide analytics
/// - Historical explorer & audit export
/// - Severity alert configuration
/// - Command Room settings
///
/// Completely independent top-level widget with its own router, theme, and navigation shell.
class CommandRoomApp extends StatefulWidget {
  const CommandRoomApp({super.key, this.center});
  final CommandCenter? center;

  @override
  State<CommandRoomApp> createState() => _CommandRoomAppState();
}

class _CommandRoomAppState extends State<CommandRoomApp> {
  late final CommandCenter _center = widget.center ?? CommandCenter();
  final _navKey = GlobalKey<NavigatorState>();
  late final GoRouter _router = CommandRoomRouter.build(rootNavKey: _navKey);

  @override
  void dispose() {
    widget.center?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _center,
      child: Selector<CommandCenter, (ThemeMode, bool)>(
        selector: (_, cc) => (cc.themeMode, cc.isDarkMode),
        builder: (context, themeState, _) {
          final themeMode = themeState.$1;
          final isDark = themeState.$2;
          Dp.isDark = isDark;

          return MaterialApp.router(
            key: ValueKey('command_room_app_${isDark ? 'dark' : 'light'}'),
            title: 'Drishti-Transit Command Center',
            debugShowCheckedModeBanner: false,
            theme: buildDrishtiTheme(isDark: false),
            darkTheme: buildDrishtiTheme(isDark: true),
            themeMode: themeMode,
            themeAnimationDuration: const Duration(milliseconds: 300),
            themeAnimationCurve: Curves.easeInOutCubic,
            scrollBehavior: const MaterialScrollBehavior().copyWith(
              dragDevices: {
                PointerDeviceKind.mouse,
                PointerDeviceKind.touch,
                PointerDeviceKind.stylus,
                PointerDeviceKind.trackpad,
              },
            ),
            routerConfig: _router,
            builder: (context, child) {
              Dp.isDark = Theme.of(context).brightness == Brightness.dark;
              return child!;
            },
          );
        },
      ),
    );
  }
}
