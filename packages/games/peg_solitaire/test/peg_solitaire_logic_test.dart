import 'package:flutter_test/flutter_test.dart';
import 'package:peg_solitaire/src/peg_solitaire_logic.dart';

void main() {
  group('initial board', () {
    test('has 32 pegs with the centre empty', () {
      final b = PegBoard.initial();
      expect(b.pegCount(), 32);
      expect(b.cells[PegBoard.center][PegBoard.center], 0);
    });

    test('the four 2x2 corners are invalid', () {
      final b = PegBoard.initial();
      expect(b.valid(0, 0), isFalse);
      expect(b.valid(0, 6), isFalse);
      expect(b.valid(6, 0), isFalse);
      expect(b.valid(6, 6), isFalse);
      expect(b.valid(0, 3), isTrue); // top of the cross
      expect(b.valid(3, 0), isTrue); // left of the cross
    });

    test('has legal moves at the start', () {
      expect(PegBoard.initial().hasMoves, isTrue);
    });
  });

  group('moves', () {
    test('a legal jump removes the jumped peg and reduces the count', () {
      final b = PegBoard.initial();
      // (3,1) peg can jump over (3,2) peg into the empty centre (3,3).
      final m = b.moveBetween(3, 1, 3, 3);
      expect(m, isNotNull);
      b.apply(m!);
      expect(b.pegCount(), 31);
      expect(b.cells[3][1], 0); // source now empty
      expect(b.cells[3][2], 0); // jumped peg removed
      expect(b.cells[3][3], 1); // landed
    });

    test('cannot jump where there is no peg to jump over', () {
      final b = PegBoard.initial();
      // (1,3) -> (3,3): the middle (2,3) is a peg and (3,3) is empty -> legal.
      expect(b.moveBetween(1, 3, 3, 3), isNotNull);
      // (0,3) -> (2,3): (2,3) is a peg, not empty -> illegal.
      expect(b.moveBetween(0, 3, 2, 3), isNull);
    });
  });

  group('win / stuck', () {
    test('a single peg is detected as won and the board has no moves', () {
      final empty = List.generate(
          PegBoard.size, (_) => List.filled(PegBoard.size, 0));
      final b = PegBoard(empty);
      b.cells[3][3] = 1;
      expect(b.isWon, isTrue);
      expect(b.isWonCenter, isTrue);
      expect(b.hasMoves, isFalse);
    });

    test('three separated pegs are a stuck, non-winning position', () {
      final b = PegBoard(List.generate(
          PegBoard.size, (_) => List.filled(PegBoard.size, 0)));
      // Pegs with no adjacent peg to jump over.
      b.cells[3][2] = 1;
      b.cells[1][3] = 1;
      b.cells[5][3] = 1;
      expect(b.pegCount(), 3);
      expect(b.isWon, isFalse);
      expect(b.hasMoves, isFalse);
    });
  });

  group('serialization', () {
    test('round-trips', () {
      final b = PegBoard.initial();
      b.apply(b.moveBetween(3, 1, 3, 3)!);
      final r = PegBoard.fromJson(b.toJson());
      expect(r.pegCount(), b.pegCount());
      for (var i = 0; i < PegBoard.size; i++) {
        expect(r.cells[i], b.cells[i]);
      }
    });
  });
}
