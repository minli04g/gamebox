import 'dart:convert';

import 'package:hive/hive.dart';

import 'app_settings.dart';

/// Persists [AppSettings] to a Hive box. Owned by the shell, never by a game.
class SettingsStore {
  SettingsStore(this._box);

  final Box<String> _box;
  static const _key = 'app_settings';

  AppSettings load() {
    final raw = _box.get(_key);
    if (raw == null) return const AppSettings();
    try {
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const AppSettings();
    }
  }

  Future<void> save(AppSettings settings) async {
    await _box.put(_key, jsonEncode(settings.toJson()));
  }
}
