import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:game_2048/src/board_2048.dart';

void main() {
  group('collapse / move', () {
    test('merges equal neighbours once, toward the edge', () {
      final board = [
        [2, 2, 2, 2],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ];
      final r = Board2048.move(board, SwipeDir.left);
      expect(r.board[0], [4, 4, 0, 0]);
      expect(r.gained, 8);
      expect(r.moved, isTrue);
    });

    test('does not double-merge a freshly merged tile', () {
      final board = [
        [4, 4, 4, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ];
      final r = Board2048.move(board, SwipeDir.left);
      expect(r.board[0], [8, 4, 0, 0]);
      expect(r.gained, 8);
    });

    test('right move pushes tiles to the right edge', () {
      final board = [
        [2, 0, 2, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ];
      final r = Board2048.move(board, SwipeDir.right);
      expect(r.board[0], [0, 0, 0, 4]);
    });

    test('up move merges columns toward the top', () {
      final board = [
        [2, 0, 0, 0],
        [2, 0, 0, 0],
        [4, 0, 0, 0],
        [4, 0, 0, 0],
      ];
      final r = Board2048.move(board, SwipeDir.up);
      expect([for (final row in r.board) row[0]], [4, 8, 0, 0]);
    });

    test('down move merges columns toward the bottom', () {
      final board = [
        [2, 0, 0, 0],
        [2, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ];
      final r = Board2048.move(board, SwipeDir.down);
      expect([for (final row in r.board) row[0]], [0, 0, 0, 4]);
    });

    test('reports moved=false when nothing changes', () {
      final board = [
        [2, 4, 2, 4],
        [4, 2, 4, 2],
        [2, 4, 2, 4],
        [4, 2, 4, 2],
      ];
      final r = Board2048.move(board, SwipeDir.left);
      expect(r.moved, isFalse);
      expect(r.gained, 0);
    });
  });

  group('spawn / game over', () {
    test('spawn fills exactly one empty cell', () {
      final board = Board2048.empty();
      final next = Board2048.spawn(board, Random(1));
      expect(Board2048.emptyCells(next).length, Board2048.size * Board2048.size - 1);
      expect(Board2048.highestTile(next), anyOf(2, 4));
    });

    test('newGame has two tiles', () {
      final board = Board2048.newGame(Random(2));
      final filled =
          Board2048.size * Board2048.size - Board2048.emptyCells(board).length;
      expect(filled, 2);
    });

    test('isGameOver true on a full board with no merges', () {
      final board = [
        [2, 4, 2, 4],
        [4, 2, 4, 2],
        [2, 4, 2, 4],
        [4, 2, 4, 2],
      ];
      expect(Board2048.isGameOver(board), isTrue);
    });

    test('isGameOver false when a merge is possible', () {
      final board = [
        [2, 2, 2, 4],
        [4, 2, 4, 2],
        [2, 4, 2, 4],
        [4, 2, 4, 2],
      ];
      expect(Board2048.isGameOver(board), isFalse);
    });
  });
}
