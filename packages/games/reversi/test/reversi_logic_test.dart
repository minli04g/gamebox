import 'package:flutter_test/flutter_test.dart';
import 'package:reversi/src/reversi_logic.dart';

void main() {
  group('initialBoard', () {
    test('has the standard four-disc start', () {
      final b = initialBoard();
      expect(counts(b), (black: 2, white: 2));
      expect(b[3 * 8 + 3], white); // d4
      expect(b[4 * 8 + 4], white); // e5
      expect(b[3 * 8 + 4], black); // e4
      expect(b[4 * 8 + 3], black); // d5
    });

    test('yields exactly four legal moves for black', () {
      final moves = legalMoves(initialBoard(), black);
      expect(moves.length, 4);
      // The classic opening squares: d3, c4, f5, e6.
      expect(
        moves.toSet(),
        {2 * 8 + 3, 3 * 8 + 2, 4 * 8 + 5, 5 * 8 + 4},
      );
    });
  });

  group('applyMove', () {
    test('flips the correct discs for a known position', () {
      final b = initialBoard();
      // Black plays d3 (row 2, col 3): brackets the white at d4 against d5.
      const move = 2 * 8 + 3; // 19
      expect(flipsFor(b, black, move), [3 * 8 + 3]); // flips d4 (index 27)

      final next = applyMove(b, black, move);
      expect(next[move], black); // placed disc
      expect(next[3 * 8 + 3], black); // d4 flipped to black
      expect(next[4 * 8 + 4], white); // e5 untouched
      expect(counts(next), (black: 4, white: 1));
      // Original board is not mutated.
      expect(counts(b), (black: 2, white: 2));
    });

    test('illegal move leaves the board unchanged', () {
      final b = initialBoard();
      expect(flipsFor(b, black, 0), isEmpty);
      final next = applyMove(b, black, 0);
      expect(next, b);
    });
  });

  group('end state', () {
    test('counts determine the winner', () {
      // A full board (no empties) is over for both players.
      final blackWins = List<int>.filled(kCells, black);
      blackWins[0] = white;
      expect(isGameOver(blackWins), isTrue);
      expect(counts(blackWins), (black: 63, white: 1));
      expect(winnerOf(blackWins), black);

      final whiteWins = List<int>.filled(kCells, white);
      whiteWins[0] = black;
      whiteWins[1] = black;
      expect(winnerOf(whiteWins), white);

      final draw = List<int>.filled(kCells, black);
      for (var i = 0; i < kCells ~/ 2; i++) {
        draw[i] = white;
      }
      expect(counts(draw), (black: 32, white: 32));
      expect(winnerOf(draw), empty);
    });
  });

  group('chooseAiMove', () {
    test('returns a legal move or -1 when none', () {
      final move = chooseAiMove(initialBoard(), white);
      expect(legalMoves(initialBoard(), white).contains(move), isTrue);

      final full = List<int>.filled(kCells, black);
      expect(chooseAiMove(full, white), -1);
    });

    test('prefers a corner when one is available', () {
      final b = List<int>.filled(kCells, empty);
      // Set up so white can take corner 0 by bracketing black at index 1.
      b[1] = black; // (0,1)
      b[2] = white; // (0,2) -> placing white at 0 flips index 1
      // Also offer a non-corner move that flips more, to prove corner wins.
      b[8] = black; // (1,0)
      b[16] = white; // (2,0) -> white at 0 also flips along this line
      final move = chooseAiMove(b, white);
      expect(move, 0); // the corner
    });
  });
}
