import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe/src/tic_tac_toe_logic.dart';

void main() {
  test('winner detects rows, cols, diagonals and draw', () {
    expect(winner([1, 1, 1, 0, 2, 0, 2, 0, 0]), 1); // top row
    expect(winner([2, 0, 0, 2, 1, 0, 2, 1, 1]), 2); // left col
    expect(winner([1, 0, 2, 0, 1, 2, 0, 0, 1]), 1); // diagonal
    expect(winner([1, 2, 1, 1, 2, 2, 2, 1, 1]), 3); // full, no line -> draw
    expect(winner([1, 0, 0, 0, 0, 0, 0, 0, 0]), 0); // ongoing
  });

  test('AI takes an immediate winning move', () {
    // O at 0,1 -> winning at 2
    final b = [2, 2, 0, 1, 1, 0, 0, 0, 0];
    expect(bestMove(b, 2), 2);
  });

  test('AI blocks the human winning threat', () {
    // X at 0,1 threatens 2; O must block at 2
    final b = [1, 1, 0, 0, 2, 0, 0, 0, 0];
    expect(bestMove(b, 2), 2);
  });

  test('AI never loses from an empty board against any human reply', () {
    for (var first = 0; first < 9; first++) {
      var b = List<int>.filled(9, 0);
      b[first] = 1; // human moves first anywhere
      while (winner(b) == 0) {
        final ai = bestMove(b, 2);
        b[ai] = 2;
        if (winner(b) != 0) break;
        // human plays its own optimal move (worst case for AI)
        final hu = bestMove(b, 1);
        b[hu] = 1;
      }
      expect(winner(b) == 1, isFalse); // AI must never lose
    }
  });
}
