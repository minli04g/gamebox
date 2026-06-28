import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import 'fifteen_screen.dart';

class FifteenGame implements Game {
  const FifteenGame();

  @override
  GameDescriptor get descriptor => const GameDescriptor(
        id: 'fifteen',
        name: '数字华容道',
        description: '滑动数字，复原顺序',
        icon: Icons.apps,
        accentColor: 0xFFF97316,
        tags: ['滑块', '益智'],
      );

  @override
  Widget buildGameScreen(BuildContext context, GameContext ctx) =>
      FifteenScreen(ctx: ctx);
}
