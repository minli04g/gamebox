import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import 'minesweeper_screen.dart';

class MinesweeperGame implements Game {
  const MinesweeperGame();

  @override
  GameDescriptor get descriptor => const GameDescriptor(
        id: 'minesweeper',
        name: '扫雷',
        description: '标记地雷，安全通关',
        icon: Icons.flag_rounded,
        accentColor: 0xFF14B8A6,
        tags: ['益智', '单人'],
      );

  @override
  Widget buildGameScreen(BuildContext context, GameContext ctx) =>
      MinesweeperScreen(ctx: ctx);
}
