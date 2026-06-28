/// Pure Dart 贪吃蛇 (Snake) logic. No Flutter imports — fully testable.
library;

import 'dart:math';

/// A cell on the grid, identified by row/col. Equatable and hashable so it can
/// live in sets (used for fast self-collision and free-cell lookups).
class Point {
  const Point(this.r, this.c);

  final int r;
  final int c;

  @override
  bool operator ==(Object other) =>
      other is Point && other.r == r && other.c == c;

  @override
  int get hashCode => r * 31 + c;

  @override
  String toString() => '($r,$c)';
}

/// The four movement directions, each carrying its row/col delta.
enum Direction {
  up(-1, 0),
  down(1, 0),
  left(0, -1),
  right(0, 1);

  const Direction(this.dr, this.dc);

  final int dr;
  final int dc;

  /// Whether [other] is the exact 180° opposite of this direction.
  bool isOpposite(Direction other) => dr == -other.dr && dc == -other.dc;
}

/// Pure, mutable game state for Snake on a [size] x [size] grid.
///
/// [body] holds the snake's cells with the head first and the tail last.
class SnakeState {
  SnakeState({
    this.size = 17,
    Random? random,
  }) : _rng = random ?? Random() {
    reset();
  }

  final int size;
  final Random _rng;

  /// Head first, tail last.
  final List<Point> body = [];
  Direction direction = Direction.right;
  late Point food;
  int score = 0;
  bool dead = false;

  /// Pending direction queued via [setDirection]; applied on the next [step].
  Direction _pending = Direction.right;

  Point get head => body.first;
  int get length => body.length;

  /// Resets to the initial state: a short snake in the middle moving right.
  void reset() {
    final mid = size ~/ 2;
    body
      ..clear()
      ..addAll([
        Point(mid, mid),
        Point(mid, mid - 1),
        Point(mid, mid - 2),
      ]);
    direction = Direction.right;
    _pending = Direction.right;
    score = 0;
    dead = false;
    _spawnFood();
  }

  /// Queues a new direction. A direct 180° reversal is ignored so the snake
  /// cannot instantly turn back onto itself.
  void setDirection(Direction d) {
    if (dead) return;
    if (d.isOpposite(direction)) return;
    _pending = d;
  }

  /// Advances the snake one cell in the (queued) direction.
  ///
  /// - Moving onto the food grows the snake, spawns new food and bumps [score].
  /// - Otherwise the tail follows the head.
  /// - Hitting a wall or the snake's own body sets [dead] and changes nothing.
  void step() {
    if (dead) return;
    direction = _pending;
    final next = Point(head.r + direction.dr, head.c + direction.dc);

    // Wall collision.
    if (next.r < 0 || next.r >= size || next.c < 0 || next.c >= size) {
      dead = true;
      return;
    }

    final ate = next == food;
    // The tail cell is about to vacate (unless we grow), so it does not count
    // as a collision when we are not eating.
    final ignoreTail = !ate;
    for (var i = 0; i < body.length; i++) {
      if (ignoreTail && i == body.length - 1) continue;
      if (body[i] == next) {
        dead = true;
        return;
      }
    }

    body.insert(0, next);
    if (ate) {
      score += 1;
      _spawnFood();
    } else {
      body.removeLast();
    }
  }

  /// Places food on a random free cell. If the board is full the food is left
  /// on the head (the player has effectively won).
  void _spawnFood() {
    final occupied = body.toSet();
    final free = <Point>[];
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        final p = Point(r, c);
        if (!occupied.contains(p)) free.add(p);
      }
    }
    if (free.isEmpty) {
      food = head;
      return;
    }
    food = free[_rng.nextInt(free.length)];
  }
}
