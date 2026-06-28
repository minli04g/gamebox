import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import 'gomoku_screen.dart';

class GomokuGame implements Game {
  const GomokuGame();

  @override
  GameDescriptor get descriptor => const GameDescriptor(
        id: 'gomoku',
        name: '五子棋',
        description: '对战 AI，五子连珠',
        icon: Icons.blur_circular,
        accentColor: 0xFF0EA5E9,
        tags: ['对战', '棋类'],
      );

  @override
  Widget buildGameScreen(BuildContext context, GameContext ctx) =>
      GomokuScreen(ctx: ctx);
}
