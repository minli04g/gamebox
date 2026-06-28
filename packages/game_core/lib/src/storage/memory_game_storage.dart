import 'dart:convert';

import 'game_storage.dart';

/// In-memory [GameStorage] for tests. Multiple instances can share one
/// [backing] map to prove that different namespaces never collide.
class MemoryGameStorage implements GameStorage {
  MemoryGameStorage({required this.namespace, Map<String, String>? backing})
      : _backing = backing ?? <String, String>{};

  final Map<String, String> _backing;

  @override
  final String namespace;

  String _k(String key) => '$namespace:$key';

  @override
  Future<void> putJson(String key, Map<String, dynamic> value) async {
    _backing[_k(key)] = jsonEncode(value);
  }

  @override
  Future<Map<String, dynamic>?> getJson(String key) async {
    final raw = _backing[_k(key)];
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  @override
  Future<void> delete(String key) async {
    _backing.remove(_k(key));
  }

  @override
  Future<void> clear() async {
    _backing.removeWhere((k, _) => k.startsWith('$namespace:'));
  }
}
