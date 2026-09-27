import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/command_center.dart';
import 'command_room_app.dart';
import 'field_crew_app.dart';

/// DrishtiApp — Unified entry wrapper for tests or general embedding.
/// Dispatches to [CommandRoomApp] on Web and [FieldCrewApp] on Mobile.
class DrishtiApp extends StatefulWidget {
  const DrishtiApp({
    super.key,
    required this.center,
    this.forceWeb,
  });

  final CommandCenter center;
  final bool? forceWeb;

  @override
  State<DrishtiApp> createState() => _DrishtiAppState();
}

class _DrishtiAppState extends State<DrishtiApp> {
  @override
  void dispose() {
    widget.center.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = widget.forceWeb ??
        (kIsWeb || (MediaQuery.maybeSizeOf(context)?.width ?? 0) >= 900);
    return isWeb
        ? CommandRoomApp(center: widget.center)
        : FieldCrewApp(center: widget.center);
  }
}