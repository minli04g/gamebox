import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import 'twenty_four_screen.dart';

class TwentyFourGame implements Game {
  const TwentyFourGame();

  @override
  GameDescriptor get descriptor => const GameDescriptor(
        id: 'twenty_four',
        name: '24点',
        description: '四则运算凑出 24',
        icon: Icons.calculate_rounded,
        accentColor: 0xFF2E9E5B,
        tags: ['益智', '数学'],
      );

  @override
  Widget buildGameScreen(BuildContext context, GameContext ctx) =>
      TwentyFourScreen(ctx: ctx);
}
