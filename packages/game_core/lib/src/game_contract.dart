import 'package:flutter/widgets.dart';

import 'settings/app_settings.dart';
import 'storage/game_storage.dart';

/// Static metadata used by the shell to render the lobby and build routes.
/// A game exposes exactly one [GameDescriptor]; its [id] is also the storage
/// namespace, so it must be unique and stable across releases.
@immutable
class GameDescriptor {
  const GameDescriptor({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.accentColor,
    this.tags = const <String>[],
  });

  /// Unique, stable id. Also the storage namespace, e.g. 'sudoku'.
  final String id;

  /// Display name shown on the lobby card, e.g. '数独'.
  final String name;

  /// One-line blurb shown under the name.
  final String description;

  /// Lobby icon.
  final IconData icon;

  /// Optional accent color for the lobby card; falls back to the brand color.
  final int? accentColor;

  /// Free-form tags for future filtering, e.g. ['益智', '单人'].
  final List<String> tags;
}

/// The single dependency-injection channel handed to a game by the shell.
///
/// A game never imports Hive, another game, or a global singleton. The
/// [storage] it receives is already namespaced to its [GameDescriptor.id],
/// so cross-game access and key collisions are impossible. [settings] is the
/// read-only global app settings snapshot.
@immutable
class GameContext {
  const GameContext({required this.storage, required this.settings});

  final GameStorage storage;
  final AppSettings settings;
}

/// The contract every game implements. Intentionally tiny: metadata plus an
/// entry widget. Everything about how the game is built internally is private.
abstract class Game {
  GameDescriptor get descriptor;

  /// Build the game's root screen. The shell injects a namespaced [ctx].
  Widget buildGameScreen(BuildContext context, GameContext ctx);
}
