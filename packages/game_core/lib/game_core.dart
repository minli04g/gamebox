/// GameBox core: the contract every game implements, plus shared
/// storage, settings and theming. This package depends on no game.
library game_core;

export 'src/game_contract.dart';
export 'src/storage/game_storage.dart';
export 'src/storage/hive_game_storage.dart';
export 'src/storage/memory_game_storage.dart';
export 'src/settings/app_settings.dart';
export 'src/settings/settings_store.dart';
export 'src/theme/app_theme.dart';
export 'src/widgets/stat_chip.dart';
