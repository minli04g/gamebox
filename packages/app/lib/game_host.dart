import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'registry.dart';
import 'state/app_providers.dart';

/// Resolves a game by id, builds its namespaced context, and hosts its screen.
class GameHost extends ConsumerWidget {
  const GameHost({super.key, required this.gameId});

  final String gameId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = gameById(gameId);
    if (game == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('未找到游戏: $gameId')),
      );
    }
    final ctx = gameContextFor(ref, game);
    return game.buildGameScreen(context, ctx);
  }
}
