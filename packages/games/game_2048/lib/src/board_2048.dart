import 'dart:math';

/// Swipe directions. Tiles merge *toward* the named edge.
enum SwipeDir { up, down, left, right }

/// Result of a single [Board2048.move].
class MoveResult {
  const MoveResult({
    required this.board,
    required this.gained,
    required this.moved,
  });

  final List<List<int>> board;
  final int gained;
  final bool moved;
}

/// Pure 2048 board logic. No Flutter, no I/O, fully unit-testable.
///
/// A board is a [size]×[size] grid of ints where 0 is an empty cell.
class Board2048 {
  Board2048._();

  static const int size = 4;

  static List<List<int>> empty() =>
      List.generate(size, (_) => List.filled(size, 0));

  static List<List<int>> copy(List<List<int>> board) =>
      board.map((row) => List<int>.from(row)).toList();

  /// Coordinates of each line, ordered so index 0 is the cell tiles merge into.
  static List<List<Point<int>>> _lineCoords(SwipeDir dir) {
    final lines = <List<Point<int>>>[];
    for (var i = 0; i < size; i++) {
      final coords = <Point<int>>[];
      for (var j = 0; j < size; j++) {
        coords.add(switch (dir) {
          SwipeDir.left => Point(j, i), // (x=col, y=row)
          SwipeDir.right => Point(size - 1 - j, i),
          SwipeDir.up => Point(i, j),
          SwipeDir.down => Point(i, size - 1 - j),
        });
      }
      lines.add(coords);
    }
    return lines;
  }

  /// Collapse one line toward index 0: drop zeros, merge equal neighbours once.
  static (List<int>, int) _collapse(List<int> line) {
    final nums = line.where((x) => x != 0).toList();
    final out = <int>[];
    var gained = 0;
    for (var i = 0; i < nums.length; i++) {
      if (i + 1 < nums.length && nums[i] == nums[i + 1]) {
        final merged = nums[i] * 2;
        out.add(merged);
        gained += merged;
        i++; // consume the merged partner
      } else {
        out.add(nums[i]);
      }
    }
    while (out.length < size) {
      out.add(0);
    }
    return (out, gained);
  }

  static MoveResult move(List<List<int>> board, SwipeDir dir) {
    final result = empty();
    final lines = _lineCoords(dir);
    var gained = 0;
    var moved = false;

    for (final coords in lines) {
      final line = [for (final p in coords) board[p.y][p.x]];
      final (collapsed, g) = _collapse(line);
      gained += g;
      for (var k = 0; k < size; k++) {
        final p = coords[k];
        result[p.y][p.x] = collapsed[k];
        if (collapsed[k] != line[k]) moved = true;
      }
    }
    return MoveResult(board: result, gained: gained, moved: moved);
  }

  static List<Point<int>> emptyCells(List<List<int>> board) {
    final cells = <Point<int>>[];
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        if (board[y][x] == 0) cells.add(Point(x, y));
      }
    }
    return cells;
  }

  /// Place a new tile (2 with 90% probability, else 4) on a random empty cell.
  /// Returns a new board; if the board is full, returns it unchanged.
  static List<List<int>> spawn(List<List<int>> board, Random rng) {
    final cells = emptyCells(board);
    if (cells.isEmpty) return board;
    final next = copy(board);
    final cell = cells[rng.nextInt(cells.length)];
    next[cell.y][cell.x] = rng.nextDouble() < 0.9 ? 2 : 4;
    return next;
  }

  /// A fresh starting board with two tiles.
  static List<List<int>> newGame(Random rng) =>
      spawn(spawn(empty(), rng), rng);

  static bool canMove(List<List<int>> board) {
    if (emptyCells(board).isNotEmpty) return true;
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        final v = board[y][x];
        if (x + 1 < size && board[y][x + 1] == v) return true;
        if (y + 1 < size && board[y + 1][x] == v) return true;
      }
    }
    return false;
  }

  static bool isGameOver(List<List<int>> board) => !canMove(board);

  static int highestTile(List<List<int>> board) {
    var best = 0;
    for (final row in board) {
      for (final v in row) {
        if (v > best) best = v;
      }
    }
    return best;
  }

  static bool hasReached(List<List<int>> board, int target) =>
      highestTile(board) >= target;
}
