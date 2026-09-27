import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/command_room_app.dart';
import 'app/field_crew_app.dart';
import 'core/command_center.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final center = CommandCenter();

  // Platform-based bootstrap: Web runs CommandRoomApp, Android/Mobile runs FieldCrewApp.
  // Build-time developer preview flags (never runtime user toggles):
  // e.g. flutter run -d chrome --dart-define=FIELD_CREW_PREVIEW=true
  const previewFieldCrew = bool.fromEnvironment('FIELD_CREW_PREVIEW', defaultValue: false);
  const previewCommandRoom = bool.fromEnvironment('COMMAND_ROOM_PREVIEW', defaultValue: false);

  final isCommandRoom = previewCommandRoom || (kIsWeb && !previewFieldCrew);

  runApp(
    isCommandRoom
        ? CommandRoomApp(center: center)
        : FieldCrewApp(center: center),
  );
}