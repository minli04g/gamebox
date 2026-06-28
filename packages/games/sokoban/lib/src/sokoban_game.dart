import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import 'sokoban_screen.dart';

class SokobanGame implements Game {
  const SokobanGame();

  @override
  GameDescriptor get descriptor => const GameDescriptor(
        id: 'sokoban',
        name: '推箱子',
        description: '把箱子推到目标点',
        icon: Icons.inventory_2,
        accentColor: 0xFFB45309,
        tags: ['解谜', '关卡'],
      );

  @override
  Widget buildGameScreen(BuildContext context, GameContext ctx) =>
      SokobanScreen(ctx: ctx);
}
