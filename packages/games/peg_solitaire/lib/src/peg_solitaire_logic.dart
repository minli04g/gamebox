/// Pure 孔明棋 (English peg solitaire) logic — no Flutter, no I/O.
///
/// The board is a 7×7 grid whose four 2×2 corners are invalid, leaving a
/// 33-hole plus/cross. Cells are: -1 invalid, 0 empty, 1 peg. A move jumps a
/// peg two cells orthogonally over an adjacent peg into an empty hole, removing
/// the jumped-over peg.
library;

class PegMove {
  const PegMove(
      this.fromR, this.fromC, this.toR, this.toC, this.midR, this.midC);

  final int fromR, fromC, toR, toC, midR, midC;
}

class PegBoard {
  PegBoard(this.cells);

  static const int size = 7;
  static const int center = 3;

  static const List<List<int>> _dirs = [
    [-1, 0],
    [1, 0],
    [0, -1],
    [0, 1],
  ];

  final List<List<int>> cells;

  /// Standard start: every valid hole holds a peg except the centre.
  factory PegBoard.initial() {
    final cells = List.generate(
      size,
      (r) => List.generate(size, (c) {
        if (_isCorner(r, c)) return -1;
        if (r == center && c == center) return 0;
        return 1;
      }),
    );
    return PegBoard(cells);
  }

  static bool _isCorner(int r, int c) =>
      (r < 2 || r > 4) && (c < 2 || c > 4);

  bool valid(int r, int c) =>
      r >= 0 && r < size && c >= 0 && c < size && cells[r][c] != -1;

  int pegCount() {
    var n = 0;
    for (final row in cells) {
      for (final v in row) {
        if (v == 1) n++;
      }
    }
    return n;
  }

  List<PegMove> legalMoves() {
    final moves = <PegMove>[];
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (cells[r][c] != 1) continue;
        for (final d in _dirs) {
          final mr = r + d[0], mc = c + d[1];
          final tr = r + 2 * d[0], tc = c + 2 * d[1];
          if (valid(mr, mc) &&
              valid(tr, tc) &&
              cells[mr][mc] == 1 &&
              cells[tr][tc] == 0) {
            moves.add(PegMove(r, c, tr, tc, mr, mc));
          }
        }
      }
    }
    return moves;
  }

  /// The legal move jumping the peg at ([fr],[fc]) to ([tr],[tc]), or null.
  PegMove? moveBetween(int fr, int fc, int tr, int tc) {
    for (final m in legalMoves()) {
      if (m.fromR == fr && m.fromC == fc && m.toR == tr && m.toC == tc) {
        return m;
      }
    }
    return null;
  }

  void apply(PegMove m) {
    cells[m.fromR][m.fromC] = 0;
    cells[m.midR][m.midC] = 0;
    cells[m.toR][m.toC] = 1;
  }

  bool get hasMoves => legalMoves().isNotEmpty;

  /// Solved when a single peg remains.
  bool get isWon => pegCount() == 1;

  /// The perfect finish: the one remaining peg sits on the centre.
  bool get isWonCenter => pegCount() == 1 && cells[center][center] == 1;

  PegBoard copy() => PegBoard([for (final row in cells) [...row]]);

  Map<String, dynamic> toJson() => {'cells': cells};

  factory PegBoard.fromJson(Map<String, dynamic> j) => PegBoard([
        for (final row in (j['cells'] as List))
          [for (final v in (row as List)) v as int]
      ]);
}
