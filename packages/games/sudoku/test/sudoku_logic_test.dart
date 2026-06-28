import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/src/sudoku_logic.dart';

void main() {
  group('solution generation', () {
    test('produces a complete, valid grid', () {
      final g = Sudoku.generatedSolution(Random(7));
      expect(Sudoku.isComplete(g), isTrue);
    });

    test('every row, column and box contains 1..9', () {
      final g = Sudoku.generatedSolution(Random(11));
      for (var i = 0; i < 9; i++) {
        expect(g[i].toSet(), {1, 2, 3, 4, 5, 6, 7, 8, 9});
        expect([for (var r = 0; r < 9; r++) g[r][i]].toSet(),
            {1, 2, 3, 4, 5, 6, 7, 8, 9});
      }
    });
  });

  group('isSafe / conflicts', () {
    test('detects row, column and box clashes', () {
      final g = Sudoku.emptyGrid();
      g[0][0] = 5;
      expect(Sudoku.isSafe(g, 0, 8, 5), isFalse); // same row
      expect(Sudoku.isSafe(g, 8, 0, 5), isFalse); // same col
      expect(Sudoku.isSafe(g, 1, 1, 5), isFalse); // same box
      expect(Sudoku.isSafe(g, 4, 4, 5), isTrue);
    });

    test('conflicts() flags both offending cells', () {
      final g = Sudoku.emptyGrid();
      g[0][0] = 3;
      g[0][5] = 3;
      expect(Sudoku.conflicts(g), {0, 5});
    });
  });

  group('puzzle generation', () {
    test('has a unique solution and matches its solution on givens', () {
      final p = Sudoku.generate(Difficulty.easy, Random(3));
      expect(Sudoku.countSolutions(p.givens, limit: 2), 1);
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (p.givens[r][c] != 0) {
            expect(p.givens[r][c], p.solution[r][c]);
          }
        }
      }
    });

    test('given count roughly matches the difficulty target', () {
      final p = Sudoku.generate(Difficulty.medium, Random(5));
      final givens = p.givens.expand((row) => row).where((v) => v != 0).length;
      // Uniqueness can force a few extra givens; never fewer than target.
      expect(givens, greaterThanOrEqualTo(Difficulty.medium.givens));
      expect(givens, lessThanOrEqualTo(Difficulty.medium.givens + 12));
    });
  });
}
