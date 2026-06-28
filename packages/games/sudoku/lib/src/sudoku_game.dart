import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import 'sudoku_screen.dart';

class SudokuGame implements Game {
  const SudokuGame();

  @override
  GameDescriptor get descriptor => const GameDescriptor(
        id: 'sudoku',
        name: '数独',
        description: '经典 9×9 逻辑填数',
        icon: Icons.grid_on_rounded,
        accentColor: 0xFF4F46E5,
        tags: ['益智', '单人'],
      );

  @override
  Widget buildGameScreen(BuildContext context, GameContext ctx) =>
      SudokuScreen(ctx: ctx);
}
