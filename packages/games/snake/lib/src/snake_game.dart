import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import 'snake_screen.dart';

class SnakeGame implements Game {
  const SnakeGame();

  @override
  GameDescriptor get descriptor => const GameDescriptor(
        id: 'snake',
        name: '贪吃蛇',
        description: '滑动控制，吃豆变长',
        icon: Icons.gamepad,
        accentColor: 0xFF84CC16,
        tags: ['动作', '经典'],
      );

  @override
  Widget buildGameScreen(BuildContext context, GameContext ctx) =>
      SnakeScreen(ctx: ctx);
}
