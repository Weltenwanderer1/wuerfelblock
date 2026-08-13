import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'app.dart';
import 'services/game_repository.dart';
import 'services/locale_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WakelockPlus.enable();
  final preferences = await SharedPreferences.getInstance();
  runApp(
    WuerfelblockApp(
      repository: SharedPreferencesGameRepository(preferences),
      localeController: LocaleController(preferences),
    ),
  );
}
