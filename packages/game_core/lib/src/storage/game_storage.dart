/// A namespaced key/value store handed to a single game. Implementations bind
/// a fixed namespace, so a game can only ever read and write its own data.
///
/// Conventional keys per game:
///   - 'save'         current in-progress game (resume on relaunch)
///   - 'stats'        best score / time / completion counters
///   - 'achievements' unlocked ids + progress
abstract class GameStorage {
  /// The namespace this handle is bound to (a game's id).
  String get namespace;

  Future<void> putJson(String key, Map<String, dynamic> value);

  Future<Map<String, dynamic>?> getJson(String key);

  Future<void> delete(String key);

  /// Removes every key in this namespace only.
  Future<void> clear();
}
