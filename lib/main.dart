import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/command_center.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final center = CommandCenter();
  runApp(DrishtiApp(center: center));
}