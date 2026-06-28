import 'package:flutter_test/flutter_test.dart';
import 'package:klotski/src/klotski_logic.dart';

void main() {
  group('initial 横刀立马 layout', () {
    test('has 10 pieces and is not solved', () {
      final b = hengDaoLiMa();
      expect(b.pieces.length, 10);
      expect(b.isSolved, isFalse);
      expect(b.caoCao.r, 0);
      expect(b.caoCao.c, 1);
    });

    test('every cell except the two bottom-middle is occupied', () {
      final b = hengDaoLiMa();
      var occupied = 0;
      for (var r = 0; r < KlotskiBoard.rows; r++) {
        for (var c = 0; c < KlotskiBoard.cols; c++) {
          if (b.pieceAt(r, c) != null) occupied++;
        }
      }
      expect(occupied, 18); // 20 cells - 2 empty
      expect(b.pieceAt(4, 1), isNull);
      expect(b.pieceAt(4, 2), isNull);
    });

    test('曹操 is blocked in every direction at the start', () {
      final b = hengDaoLiMa();
      final cao = b.caoCao;
      expect(b.canMove(cao, 1, 0), isFalse); // down: 关羽
      expect(b.canMove(cao, -1, 0), isFalse); // up: out of bounds
      expect(b.canMove(cao, 0, -1), isFalse); // left: 张飞
      expect(b.canMove(cao, 0, 1), isFalse); // right: 赵云
    });
  });

  group('moves', () {
    test('a soldier slides down into the empty space', () {
      final b = hengDaoLiMa();
      final z1 = b.pieces.firstWhere((p) => p.id == 'z1'); // at (3,1)
      expect(b.canMove(z1, 1, 0), isTrue); // (4,1) is empty
      expect(b.move(z1, 1, 0), isTrue);
      expect(z1.r, 4);
      expect(b.moves, 1);
    });

    test('illegal move returns false and changes nothing', () {
      final b = hengDaoLiMa();
      final zhang = b.pieces.firstWhere((p) => p.id == 'zhang'); // (0,0) 1x2
      expect(b.move(zhang, 0, 1), isFalse); // right blocked by 曹操
      expect(zhang.r, 0);
      expect(zhang.c, 0);
      expect(b.moves, 0);
    });

    test('a piece cannot leave the board', () {
      final b = hengDaoLiMa();
      final zhang = b.pieces.firstWhere((p) => p.id == 'zhang');
      expect(b.canMove(zhang, -1, 0), isFalse); // would go above row 0
    });
  });

  group('win detection', () {
    test('isSolved when 曹操 reaches bottom centre', () {
      final b = hengDaoLiMa();
      b.caoCao
        ..r = 3
        ..c = 1;
      expect(b.isSolved, isTrue);
    });
  });

  group('serialization', () {
    test('round-trips board state', () {
      final b = hengDaoLiMa();
      final z1 = b.pieces.firstWhere((p) => p.id == 'z1');
      b.move(z1, 1, 0);
      final restored = KlotskiBoard.fromJson(b.toJson());
      expect(restored.moves, b.moves);
      expect(restored.pieces.length, b.pieces.length);
      final rz1 = restored.pieces.firstWhere((p) => p.id == 'z1');
      expect(rz1.r, z1.r);
      expect(rz1.c, z1.c);
      expect(restored.caoCao.label, '曹操');
    });
  });
}
