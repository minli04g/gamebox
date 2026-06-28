import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import 'tic_tac_toe_screen.dart';

class TicTacToeGame implements Game {
  const TicTacToeGame();

  @override
  GameDescriptor get descriptor => const GameDescriptor(
        id: 'tic_tac_toe',
        name: '井字棋',
        description: '和 AI 对弈，先连成一线者胜',
        icon: Icons.grid_3x3,
        accentColor: 0xFF7C5CFC,
        tags: ['对战'],
      );

  @override
  Widget buildGameScreen(BuildContext context, GameContext ctx) =>
      TicTacToeScreen(ctx: ctx);
}
