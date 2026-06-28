import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import 'memory_match_screen.dart';

class MemoryMatchGame implements Game {
  const MemoryMatchGame();

  @override
  GameDescriptor get descriptor => const GameDescriptor(
        id: 'memory_match',
        name: '记忆翻牌',
        description: '翻开配对，考验记忆',
        icon: Icons.style,
        accentColor: 0xFFEC4899,
        tags: ['记忆', '休闲'],
      );

  @override
  Widget buildGameScreen(BuildContext context, GameContext ctx) =>
      MemoryMatchScreen(ctx: ctx);
}
