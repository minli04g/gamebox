import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import 'simon_screen.dart';

class SimonGame implements Game {
  const SimonGame();

  @override
  GameDescriptor get descriptor => const GameDescriptor(
        id: 'simon',
        name: '记忆色块',
        description: '记住并重复亮起的顺序',
        icon: Icons.widgets,
        accentColor: 0xFF9333EA,
        tags: ['记忆'],
      );

  @override
  Widget buildGameScreen(BuildContext context, GameContext ctx) =>
      SimonScreen(ctx: ctx);
}
