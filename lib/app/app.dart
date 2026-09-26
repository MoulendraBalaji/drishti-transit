import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/command_center.dart';
import '../router/router.dart';
import 'palette.dart';
import 'theme.dart';

/// Drishti root widget — wires the single [CommandCenter] (the causal stream:
/// GPS -> edge-AI -> map/feed/analytics) to the custom router and theme.
class DrishtiApp extends StatefulWidget {
  const DrishtiApp({super.key, required this.center});
  final CommandCenter center;

  @override
  State<DrishtiApp> createState() => _DrishtiAppState();
}

class _DrishtiAppState extends State<DrishtiApp> {
  final _navKey = GlobalKey<NavigatorState>();
  late final GoRouter _router = AppRouter.build(rootNavKey: _navKey);

  @override
  void dispose() {
    widget.center.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.center,
      child: Selector<CommandCenter, (ThemeMode, bool)>(
        selector: (_, cc) => (cc.themeMode, cc.isDarkMode),
        builder: (context, themeState, _) {
          final themeMode = themeState.$1;
          final isDark = themeState.$2;
          Dp.isDark = isDark;

          return MaterialApp.router(
            key: ValueKey('material_app_${isDark ? 'dark' : 'light'}'),
            title: 'Drishti-Transit',
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