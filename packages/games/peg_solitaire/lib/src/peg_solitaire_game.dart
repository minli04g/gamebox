import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import 'peg_solitaire_screen.dart';

class PegSolitaireGame implements Game {
  const PegSolitaireGame();

  @override
  GameDescriptor get descriptor => const GameDescriptor(
        id: 'peg_solitaire',
        name: '孔明棋',
        description: '跳吃棋子，只留一颗',
        icon: Icons.radio_button_checked,
        accentColor: 0xFFCA8A04,
        tags: ['益智', '解谜'],
      );

  @override
  Widget buildGameScreen(BuildContext context, GameContext ctx) =>
      PegSolitaireScreen(ctx: ctx);
}
