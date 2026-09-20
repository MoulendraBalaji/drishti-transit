import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/command_center.dart';
import '../router/router.dart';
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
      child: Consumer<CommandCenter>(
        builder: (context, cc, _) {
          return MaterialApp.router(
            title: 'Drishti',
            debugShowCheckedModeBanner: false,
            theme: buildDrishtiTheme(isDark: false),
            darkTheme: buildDrishtiTheme(isDark: true),
            themeMode: cc.themeMode,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}