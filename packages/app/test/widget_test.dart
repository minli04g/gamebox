import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:gamebox/home/lobby_screen.dart';

void main() {
  testWidgets('lobby shows the title and a card per registered game',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const LobbyScreen(),
      ),
    );

    // Title plus the first few cards. Later cards (and the coming-soon card)
    // scroll off-screen with 15 games in the lazy grid, so we don't assert them.
    expect(find.text('GameBox'), findsOneWidget);
    expect(find.text('数独'), findsOneWidget);
    expect(find.text('2048'), findsOneWidget);
  });
}
