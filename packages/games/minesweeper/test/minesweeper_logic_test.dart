import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:minesweeper/src/minesweeper_logic.dart';

void main() {
  group('mine placement', () {
    test('places exactly mineCount mines, first tap and neighbours safe', () {
      final b = MineBoard(rows: 9, cols: 9, mineCount: 10);
      b.reveal(4, 4, Random(1)); // first reveal places mines

      var mines = 0;
      for (final row in b.cells) {
        for (final c in row) {
          if (c.mine) mines++;
        }
      }
      expect(mines, 10);
      expect(b.cells[4][4].mine, isFalse);
      for (final p in b.neighbors(4, 4)) {
        expect(b.cells[p.y][p.x].mine, isFalse);
      }
    });

    test('first reveal never explodes', () {
      for (var seed = 0; seed < 20; seed++) {
        final b = MineBoard(rows: 9, cols: 9, mineCount: 10);
        b.reveal(0, 0, Random(seed));
        expect(b.exploded, isFalse);
      }
    });
  });

  group('adjacency', () {
    test('counts neighbouring mines correctly', () {
      final b = MineBoard(rows: 3, cols: 3, mineCount: 0);
      b.cells[0][0].mine = true;
      b.cells[2][2].mine = true;
      // compute adjacents the way placeMines does
      for (var r = 0; r < 3; r++) {
        for (var c = 0; c < 3; c++) {
          if (b.cells[r][c].mine) continue;
          var n = 0;
          for (final p in b.neighbors(r, c)) {
            if (b.cells[p.y][p.x].mine) n++;
          }
          b.cells[r][c].adjacent = n;
        }
      }
      expect(b.cells[1][1].adjacent, 2); // center touches both corners
      expect(b.cells[0][1].adjacent, 1);
      expect(b.cells[2][1].adjacent, 1);
    });
  });

  group('reveal flood fill', () {
    test('revealing an empty region opens connected zero cells', () {
      final b = MineBoard(rows: 5, cols: 5, mineCount: 0);
      // No mines at all -> first reveal floods the entire board.
      final newly = b.reveal(2, 2, Random(0));
      expect(newly.length, 25);
      expect(b.isWon, isTrue);
    });

    test('flagged cells are not revealed', () {
      final b = MineBoard(rows: 5, cols: 5, mineCount: 0);
      b.reveal(0, 0, Random(0)); // places (no) mines, floods all
      // re-make a fresh board to test flag blocking before reveal
      final b2 = MineBoard(rows: 3, cols: 3, mineCount: 0);
      b2.minesPlaced = true;
      b2.toggleFlag(1, 1);
      final newly = b2.reveal(1, 1, Random(0));
      expect(newly, isEmpty);
      expect(b2.cells[1][1].revealed, isFalse);
    });
  });

  group('win / lose', () {
    test('revealing a mine explodes and blocks win', () {
      final b = MineBoard(rows: 3, cols: 3, mineCount: 0);
      b.minesPlaced = true;
      b.cells[0][0].mine = true;
      b.reveal(0, 0, Random(0));
      expect(b.exploded, isTrue);
      expect(b.isWon, isFalse);
    });

    test('flag counters track remaining mines', () {
      final b = MineBoard(rows: 4, cols: 4, mineCount: 5);
      b.minesPlaced = true;
      b.toggleFlag(0, 0);
      b.toggleFlag(0, 1);
      expect(b.flagsUsed, 2);
      expect(b.minesRemaining, 3);
    });
  });

  group('chord', () {
    MineBoard threeByThreeOneMine() {
      final b = MineBoard(rows: 3, cols: 3, mineCount: 1);
      b.minesPlaced = true;
      b.cells[0][0].mine = true;
      for (var r = 0; r < 3; r++) {
        for (var c = 0; c < 3; c++) {
          if (b.cells[r][c].mine) continue;
          var n = 0;
          for (final p in b.neighbors(r, c)) {
            if (b.cells[p.y][p.x].mine) n++;
          }
          b.cells[r][c].adjacent = n;
        }
      }
      return b;
    }

    test('opens unflagged neighbours when flags satisfy the number', () {
      final b = threeByThreeOneMine();
      b.reveal(1, 1, Random(0)); // center has adjacent 1, reveals only itself
      b.toggleFlag(0, 0); // flag the actual mine
      b.chord(1, 1, Random(0));
      expect(b.exploded, isFalse);
      expect(b.isWon, isTrue); // all 8 non-mine cells now revealed
    });

    test('does nothing when flag count != number', () {
      final b = threeByThreeOneMine();
      b.reveal(1, 1, Random(0));
      final newly = b.chord(1, 1, Random(0)); // no flags placed yet
      expect(newly, isEmpty);
      expect(b.cells[0][1].revealed, isFalse);
    });

    test('a wrong flag makes chord explode', () {
      final b = threeByThreeOneMine();
      b.reveal(1, 1, Random(0));
      b.toggleFlag(0, 1); // wrong flag (no mine here)
      b.chord(1, 1, Random(0)); // flags==1==number, opens (0,0) which is a mine
      expect(b.exploded, isTrue);
    });
  });

  group('serialization', () {
    test('round-trips board state', () {
      final b = MineBoard(rows: 6, cols: 6, mineCount: 6);
      b.reveal(3, 3, Random(42));
      b.toggleFlag(0, 0);
      final restored = MineBoard.fromJson(b.toJson());
      expect(restored.rows, b.rows);
      expect(restored.minesPlaced, isTrue);
      for (var r = 0; r < b.rows; r++) {
        for (var c = 0; c < b.cols; c++) {
          expect(restored.cells[r][c].mine, b.cells[r][c].mine);
          expect(restored.cells[r][c].revealed, b.cells[r][c].revealed);
          expect(restored.cells[r][c].flagged, b.cells[r][c].flagged);
          expect(restored.cells[r][c].adjacent, b.cells[r][c].adjacent);
        }
      }
    });
  });
}
