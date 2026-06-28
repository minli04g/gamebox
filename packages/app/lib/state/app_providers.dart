import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';
import 'package:hive/hive.dart';

/// Single Hive box holding every game's namespaced data. Overridden in main().
final gameBoxProvider = Provider<Box<String>>(
  (ref) => throw UnimplementedError('gameBoxProvider must be overridden'),
);

/// Settings persistence. Overridden in main().
final settingsStoreProvider = Provider<SettingsStore>(
  (ref) => throw UnimplementedError('settingsStoreProvider must be overridden'),
);

/// Reactive global settings.
final settingsProvider =
    StateNotifierProvider<SettingsController, AppSettings>((ref) {
  return SettingsController(ref.watch(settingsStoreProvider));
});

class SettingsController extends StateNotifier<AppSettings> {
  SettingsController(this._store) : super(_store.load());

  final SettingsStore _store;

  void setThemeMode(AppThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _store.save(state);
  }

  void setSound(bool on) {
    state = state.copyWith(soundOn: on);
    _store.save(state);
  }

  void setHaptics(bool on) {
    state = state.copyWith(hapticsOn: on);
    _store.save(state);
  }
}

/// Builds the namespaced [GameContext] the shell injects into a game.
GameContext gameContextFor(WidgetRef ref, Game game) {
  final box = ref.read(gameBoxProvider);
  final settings = ref.read(settingsProvider);
  return GameContext(
    storage: HiveGameStorage(box: box, namespace: game.descriptor.id),
    settings: settings,
  );
}
