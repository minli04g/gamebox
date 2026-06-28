import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:snake/src/snake_logic.dart';

void main() {
  group('Direction', () {
    test('isOpposite detects 180° pairs', () {
      expect(Direction.up.isOpposite(Direction.down), isTrue);
      expect(Direction.left.isOpposite(Direction.right), isTrue);
      expect(Direction.up.isOpposite(Direction.left), isFalse);
    });
  });

  group('SnakeState.step', () {
    test('moves the head one cell in the current direction', () {
      final s = SnakeState(size: 17, random: Random(1));
      final head = s.head;
      final dir = s.direction; // right by default
      s.step();
      expect(s.head.r, head.r + dir.dr);
      expect(s.head.c, head.c + dir.dc);
      // Length unchanged when not eating.
      expect(s.length, 3);
    });

    test('landing on food grows length by 1 and increments score', () {
      final s = SnakeState(size: 17, random: Random(1));
      // Place food directly ahead of the head (moving right).
      s.food = Point(s.head.r, s.head.c + 1);
      final lenBefore = s.length;
      s.step();
      expect(s.length, lenBefore + 1);
      expect(s.score, 1);
      expect(s.dead, isFalse);
    });

    test('moving into a wall sets dead', () {
      final s = SnakeState(size: 5, random: Random(1));
      // Drive the snake straight into the right wall.
      for (var i = 0; i < 10 && !s.dead; i++) {
        s.step();
      }
      expect(s.dead, isTrue);
    });
  });

  group('SnakeState.setDirection', () {
    test('ignores a direct 180° reversal', () {
      final s = SnakeState(size: 17, random: Random(1));
      // Default direction is right; requesting left must be ignored.
      s.setDirection(Direction.left);
      s.step();
      expect(s.direction, Direction.right);
    });

    test('accepts a perpendicular turn', () {
      final s = SnakeState(size: 17, random: Random(1));
      s.setDirection(Direction.up);
      s.step();
      expect(s.direction, Direction.up);
    });
  });
}
