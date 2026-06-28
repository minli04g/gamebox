import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:fifteen/src/fifteen_logic.dart';

void main() {
  group('isSolved', () {
    test('true for the ordered board', () {
      expect(isSolved([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 0]),
          isTrue);
    });

    test('false when the order is wrong', () {
      expect(isSolved([2, 1, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 0]),
          isFalse);
    });

    test('false when the blank is not last', () {
      expect(isSolved([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 0, 15]),
          isFalse);
    });
  });

  group('generateSolvable', () {
    test('returns a solvable, not-already-solved board', () {
      final rng = Random(7);
      for (var i = 0; i < 30; i++) {
        final board = generateSolvable(rng);
        expect(board.length, 16);
        // A valid permutation of 0..15.
        expect(board.toSet(), {for (var n = 0; n < 16; n++) n});
        expect(isSolved(board), isFalse);
        expect(_isSolvable(board), isTrue);
      }
    });
  });

  group('tapTile', () {
    test('slides a tile adjacent to the blank', () {
      // Blank at index 15; tile at index 14 is adjacent (same row).
      final board = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 0];
      final moved = tapTile(board, 14);
      expect(moved, isTrue);
      expect(board[15], 15);
      expect(board[14], 0);
    });

    test('slides a tile vertically adjacent to the blank', () {
      // Blank at index 15; tile at index 11 is directly above it.
      final board = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 0];
      final moved = tapTile(board, 11);
      expect(moved, isTrue);
      expect(board[15], 12);
      expect(board[11], 0);
    });

    test('does nothing for a non-adjacent tile', () {
      // Blank at index 15; tile at index 0 is far away.
      final board = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 0];
      final before = [...board];
      final moved = tapTile(board, 0);
      expect(moved, isFalse);
      expect(board, before);
    });

    test('does nothing when tapping the blank itself', () {
      final board = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 0];
      final before = [...board];
      expect(tapTile(board, 15), isFalse);
      expect(board, before);
    });
  });
}

/// Solvability check for a 4×4 sliding puzzle, used only by the tests.
///
/// For an even-width board the puzzle is solvable iff (inversions +
/// row-of-blank-from-bottom) is odd.
bool _isSolvable(List<int> board) {
  var inversions = 0;
  final tiles = [for (final t in board) if (t != 0) t];
  for (var i = 0; i < tiles.length; i++) {
    for (var j = i + 1; j < tiles.length; j++) {
      if (tiles[i] > tiles[j]) inversions++;
    }
  }
  final blankRowFromTop = board.indexOf(0) ~/ kSize;
  final blankRowFromBottom = kSize - blankRowFromTop;
  return (inversions + blankRowFromBottom).isOdd;
}
