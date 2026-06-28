import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:sokoban/src/sokoban_logic.dart';

/// BFS over (player, boxes) states to confirm a level is actually solvable.
bool isSolvable(List<String> grid) {
  final s = SokobanState.parse(grid);
  String key(Pos player, Set<Pos> boxes) {
    final list = boxes.map((b) => '${b.r},${b.c}').toList()..sort();
    return '${player.r},${player.c}|${list.join(';')}';
  }

  bool solved(Set<Pos> boxes) => boxes.every((b) => s.targets.contains(b));

  final start = (player: s.player, boxes: s.boxes);
  if (solved(start.boxes)) return true;

  final seen = <String>{key(start.player, start.boxes)};
  final queue = Queue<({Pos player, Set<Pos> boxes})>()..add(start);

  while (queue.isNotEmpty) {
    final cur = queue.removeFirst();
    for (final d in Dir.values) {
      final next = cur.player.step(d);
      if (s.walls.contains(next)) continue;
      Set<Pos> boxes = cur.boxes;
      if (cur.boxes.contains(next)) {
        final beyond = next.step(d);
        if (s.walls.contains(beyond) || cur.boxes.contains(beyond)) continue;
        boxes = Set<Pos>.from(cur.boxes)
          ..remove(next)
          ..add(beyond);
      }
      final k = key(next, boxes);
      if (!seen.add(k)) continue;
      if (solved(boxes)) return true;
      queue.add((player: next, boxes: boxes));
    }
  }
  return false;
}

void main() {
  group('parse', () {
    test('reads player, box and target positions', () {
      final s = SokobanState.parse(const [
        '#####',
        r'#@$.#',
        '#####',
      ]);
      expect(s.rows, 3);
      expect(s.cols, 5);
      expect(s.player, const Pos(1, 1));
      expect(s.boxes, {const Pos(1, 2)});
      expect(s.targets, {const Pos(1, 3)});
      expect(s.walls.contains(const Pos(0, 0)), isTrue);
    });

    test('* is box-on-target and + is player-on-target', () {
      final s = SokobanState.parse(const [
        '####',
        r'#+*#',
        '####',
      ]);
      expect(s.player, const Pos(1, 1));
      expect(s.boxes, {const Pos(1, 2)});
      expect(s.targets, {const Pos(1, 1), const Pos(1, 2)});
    });

    test('throws without a player', () {
      expect(() => SokobanState.parse(const ['###', '# #', '###']),
          throwsArgumentError);
    });
  });

  group('move', () {
    test('moving into a wall does nothing', () {
      final s = SokobanState.parse(const [
        '###',
        '#@#',
        '###',
      ]);
      expect(s.move(Dir.up), isFalse);
      expect(s.move(Dir.left), isFalse);
      expect(s.player, const Pos(1, 1));
      expect(s.moves, 0);
    });

    test('walking into floor works', () {
      final s = SokobanState.parse(const [
        '####',
        '#@ #',
        '####',
      ]);
      expect(s.move(Dir.right), isTrue);
      expect(s.player, const Pos(1, 2));
      expect(s.moves, 1);
    });

    test('pushing a box into floor works', () {
      final s = SokobanState.parse(const [
        '#####',
        r'#@$ #',
        '#####',
      ]);
      expect(s.move(Dir.right), isTrue);
      expect(s.player, const Pos(1, 2));
      expect(s.boxes, {const Pos(1, 3)});
    });

    test('pushing a box into a wall is blocked', () {
      final s = SokobanState.parse(const [
        '####',
        r'#@$#',
        '####',
      ]);
      expect(s.move(Dir.right), isFalse);
      expect(s.player, const Pos(1, 1));
      expect(s.boxes, {const Pos(1, 2)});
    });

    test('pushing two boxes at once is blocked', () {
      final s = SokobanState.parse(const [
        '######',
        r'#@$$ #',
        '######',
      ]);
      expect(s.move(Dir.right), isFalse);
      expect(s.boxes, {const Pos(1, 2), const Pos(1, 3)});
    });
  });

  group('isSolved', () {
    test('true when all boxes on targets after one push', () {
      final s = SokobanState.parse(const [
        '#####',
        r'#@$.#',
        '#####',
      ]);
      expect(s.isSolved, isFalse);
      expect(s.move(Dir.right), isTrue);
      expect(s.boxes, {const Pos(1, 3)});
      expect(s.isSolved, isTrue);
    });
  });

  group('undo / reset', () {
    test('undo reverts the last move', () {
      final s = SokobanState.parse(const [
        '#####',
        r'#@$ #',
        '#####',
      ]);
      s.move(Dir.right);
      expect(s.moves, 1);
      expect(s.undo(), isTrue);
      expect(s.player, const Pos(1, 1));
      expect(s.boxes, {const Pos(1, 2)});
      expect(s.moves, 0);
      expect(s.undo(), isFalse);
    });

    test('reset restores the initial layout', () {
      final s = SokobanState.parse(const [
        '#####',
        r'#@$ #',
        '#####',
      ]);
      s.move(Dir.right);
      s.reset();
      expect(s.player, const Pos(1, 1));
      expect(s.boxes, {const Pos(1, 2)});
      expect(s.moves, 0);
      expect(s.canUndo, isFalse);
    });
  });

  group('built-in levels', () {
    test('every level parses with a player and equal boxes/targets', () {
      for (final lvl in kSokobanLevels) {
        final s = SokobanState.parse(lvl);
        expect(s.boxes.isNotEmpty, isTrue);
        expect(s.boxes.length, s.targets.length);
      }
    });

    test('every built-in level is solvable', () {
      for (var i = 0; i < kSokobanLevels.length; i++) {
        expect(isSolvable(kSokobanLevels[i]), isTrue,
            reason: 'level $i is not solvable');
      }
    });
  });
}
