import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import 'bulls_cows_screen.dart';

class BullsCowsGame implements Game {
  const BullsCowsGame();

  @override
  GameDescriptor get descriptor => const GameDescriptor(
        id: 'bulls_cows',
        name: '猜数字',
        description: '1A2B 推理猜密码',
        icon: Icons.pin,
        accentColor: 0xFF2563EB,
        tags: ['推理', '益智'],
      );

  @override
  Widget buildGameScreen(BuildContext context, GameContext ctx) =>
      BullsCowsScreen(ctx: ctx);
}
