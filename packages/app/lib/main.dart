import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'state/app_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final gameBox = await Hive.openBox<String>('gamebox');
  final settingsBox = await Hive.openBox<String>('settings');
  final settingsStore = SettingsStore(settingsBox);

  runApp(
    ProviderScope(
      overrides: [
        gameBoxProvider.overrideWithValue(gameBox),
        settingsStoreProvider.overrideWithValue(settingsStore),
      ],
      child: const GameBoxApp(),
    ),
  );
}
