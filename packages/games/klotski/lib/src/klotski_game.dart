import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import 'klotski_screen.dart';

class KlotskiGame implements Game {
  const KlotskiGame();

  @override
  GameDescriptor get descriptor => const GameDescriptor(
        id: 'klotski',
        name: '华容道',
        description: '滑动将领，助曹操突围',
        icon: Icons.grid_view_rounded,
        accentColor: 0xFFD64550,
        tags: ['益智', '单人'],
      );

  @override
  Widget buildGameScreen(BuildContext context, GameContext ctx) =>
      KlotskiScreen(ctx: ctx);
}
