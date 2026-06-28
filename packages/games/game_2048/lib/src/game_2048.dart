import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import 'game_2048_screen.dart';

class Game2048 implements Game {
  const Game2048();

  @override
  GameDescriptor get descriptor => const GameDescriptor(
        id: 'game_2048',
        name: '2048',
        description: '滑动合并，凑出 2048',
        icon: Icons.grid_view_rounded,
        accentColor: 0xFFF2A03D,
        tags: ['益智', '单人'],
      );

  @override
  Widget buildGameScreen(BuildContext context, GameContext ctx) =>
      Game2048Screen(ctx: ctx);
}
