import 'dart:math';

enum MineDifficulty { easy, medium, hard }

extension MineDifficultyInfo on MineDifficulty {
  int get rows => switch (this) {
        MineDifficulty.easy => 9,
        MineDifficulty.medium => 12,
        MineDifficulty.hard => 18,
      };

  int get cols => switch (this) {
        MineDifficulty.easy => 9,
        MineDifficulty.medium => 12,
        MineDifficulty.hard => 12,
      };

  int get mines => switch (this) {
        MineDifficulty.easy => 10,
        MineDifficulty.medium => 30,
        MineDifficulty.hard => 60,
      };

  String get label => switch (this) {
        MineDifficulty.easy => '简单',
        MineDifficulty.medium => '中等',
        MineDifficulty.hard => '困难',
      };
}

class MineCell {
  MineCell({
    this.mine = false,
    this.revealed = false,
    this.flagged = false,
    this.adjacent = 0,
  });

  bool mine;
  bool revealed;
  bool flagged;
  int adjacent;
}

/// Pure Minesweeper logic — no Flutter, no I/O. Mines are placed lazily on the
/// first reveal so the first tap (and its neighbours) are always safe.
class MineBoard {
  MineBoard({
    required this.rows,
    required this.cols,
    required this.mineCount,
    List<List<MineCell>>? cells,
    this.minesPlaced = false,
    this.exploded = false,
  }) : cells = cells ??
            List.generate(rows, (_) => List.generate(cols, (_) => MineCell()));

  final int rows;
  final int cols;
  final int mineCount;
  final List<List<MineCell>> cells;
  bool minesPlaced;
  bool exploded;

  factory MineBoard.forDifficulty(MineDifficulty d) =>
      MineBoard(rows: d.rows, cols: d.cols, mineCount: d.mines);

  bool inBounds(int r, int c) => r >= 0 && r < rows && c >= 0 && c < cols;

  Iterable<Point<int>> neighbors(int r, int c) sync* {
    for (var dr = -1; dr <= 1; dr++) {
      for (var dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        final nr = r + dr, nc = c + dc;
        if (inBounds(nr, nc)) yield Point(nc, nr); // Point(x=col, y=row)
      }
    }
  }

  /// Place mines avoiding the first-clicked cell and its neighbours, then
  /// compute adjacency counts.
  void placeMines(int safeR, int safeC, Random rng) {
    final forbidden = <int>{safeR * cols + safeC};
    for (final p in neighbors(safeR, safeC)) {
      forbidden.add(p.y * cols + p.x);
    }
    final candidates = <int>[];
    for (var i = 0; i < rows * cols; i++) {
      if (!forbidden.contains(i)) candidates.add(i);
    }
    candidates.shuffle(rng);
    for (final idx in candidates.take(min(mineCount, candidates.length))) {
      cells[idx ~/ cols][idx % cols].mine = true;
    }
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (cells[r][c].mine) continue;
        var n = 0;
        for (final p in neighbors(r, c)) {
          if (cells[p.y][p.x].mine) n++;
        }
        cells[r][c].adjacent = n;
      }
    }
    minesPlaced = true;
  }

  /// Reveal ([r],[c]). Lazily places mines on the first reveal. Flood-fills
  /// zero-adjacency regions. Returns the cells newly revealed. Revealing a mine
  /// sets [exploded].
  List<Point<int>> reveal(int r, int c, Random rng) {
    if (!minesPlaced) placeMines(r, c, rng);
    final cell = cells[r][c];
    if (cell.revealed || cell.flagged) return const [];

    final newly = <Point<int>>[];
    if (cell.mine) {
      cell.revealed = true;
      exploded = true;
      newly.add(Point(c, r));
      return newly;
    }

    final stack = <Point<int>>[Point(c, r)];
    while (stack.isNotEmpty) {
      final p = stack.removeLast();
      final cc = cells[p.y][p.x];
      if (cc.revealed || cc.flagged || cc.mine) continue;
      cc.revealed = true;
      newly.add(p);
      if (cc.adjacent == 0) {
        for (final n in neighbors(p.y, p.x)) {
          final nc = cells[n.y][n.x];
          if (!nc.revealed && !nc.flagged && !nc.mine) stack.add(n);
        }
      }
    }
    return newly;
  }

  void toggleFlag(int r, int c) {
    final cell = cells[r][c];
    if (cell.revealed) return;
    cell.flagged = !cell.flagged;
  }

  int get flagsUsed {
    var n = 0;
    for (final row in cells) {
      for (final c in row) {
        if (c.flagged) n++;
      }
    }
    return n;
  }

  int get minesRemaining => mineCount - flagsUsed;

  /// Won when no mine has exploded and every non-mine cell is revealed.
  bool get isWon {
    if (exploded) return false;
    for (final row in cells) {
      for (final c in row) {
        if (!c.mine && !c.revealed) return false;
      }
    }
    return true;
  }

  void revealAllMines() {
    for (final row in cells) {
      for (final c in row) {
        if (c.mine) c.revealed = true;
      }
    }
  }

  /// Compact serialization: one int per cell packing flags + adjacency.
  Map<String, dynamic> toJson() => {
        'rows': rows,
        'cols': cols,
        'mineCount': mineCount,
        'minesPlaced': minesPlaced,
        'exploded': exploded,
        'cells': [
          for (final row in cells)
            [
              for (final c in row)
                (c.mine ? 1 : 0) |
                    (c.revealed ? 2 : 0) |
                    (c.flagged ? 4 : 0) |
                    (c.adjacent << 3)
            ]
        ],
      };

  factory MineBoard.fromJson(Map<String, dynamic> j) {
    final rows = j['rows'] as int, cols = j['cols'] as int;
    final raw = j['cells'] as List;
    final cells = List.generate(rows, (r) {
      final rr = raw[r] as List;
      return List.generate(cols, (c) {
        final v = rr[c] as int;
        return MineCell(
          mine: (v & 1) != 0,
          revealed: (v & 2) != 0,
          flagged: (v & 4) != 0,
          adjacent: v >> 3,
        );
      });
    });
    return MineBoard(
      rows: rows,
      cols: cols,
      mineCount: j['mineCount'] as int,
      cells: cells,
      minesPlaced: j['minesPlaced'] as bool? ?? true,
      exploded: j['exploded'] as bool? ?? false,
    );
  }
}
