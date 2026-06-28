import 'dart:convert';

import 'package:hive/hive.dart';

import 'game_storage.dart';

/// Hive-backed [GameStorage]. All games share one Hive box; isolation comes
/// from prefixing every key with `'<namespace>:'`. Values are stored as JSON
/// strings to sidestep Hive's nested-map typing quirks and keep saves portable.
class HiveGameStorage implements GameStorage {
  HiveGameStorage({required Box<String> box, required this.namespace})
      : _box = box;

  final Box<String> _box;

  @override
  final String namespace;

  String _k(String key) => '$namespace:$key';

  String get _prefix => '$namespace:';

  @override
  Future<void> putJson(String key, Map<String, dynamic> value) async {
    await _box.put(_k(key), jsonEncode(value));
  }

  @override
  Future<Map<String, dynamic>?> getJson(String key) async {
    final raw = _box.get(_k(key));
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  @override
  Future<void> delete(String key) async {
    await _box.delete(_k(key));
  }

  @override
  Future<void> clear() async {
    final keys = _box.keys
        .whereType<String>()
        .where((k) => k.startsWith(_prefix))
        .toList();
    await _box.deleteAll(keys);
  }
}
