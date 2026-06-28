import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import 'reversi_screen.dart';

class ReversiGame implements Game {
  const ReversiGame();

  @override
  GameDescriptor get descriptor => const GameDescriptor(
        id: 'reversi',
        name: '黑白棋',
        description: '翻转棋子，多者获胜',
        icon: Icons.circle,
        accentColor: 0xFF475569,
        tags: ['对战', '棋类'],
      );

  @override
  Widget buildGameScreen(BuildContext context, GameContext ctx) =>
      ReversiScreen(ctx: ctx);
}
