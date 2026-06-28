/// Pure 华容道 (Klotski) logic — no Flutter, no I/O. A 4×5 board holds blocks of
/// four sizes; a block slides one cell at a time into empty space. The puzzle is
/// solved when the 2×2 block (曹操) reaches the bottom-centre exit.
library;

class Piece {
  Piece({
    required this.id,
    required this.label,
    required this.w,
    required this.h,
    required this.r,
    required this.c,
    required this.colorValue,
  });

  final String id;
  final String label;
  final int w;
  final int h;
  int r; // top-left row
  int c; // top-left col
  final int colorValue;

  bool get isCaoCao => w == 2 && h == 2;

  Piece copy() => Piece(
        id: id,
        label: label,
        w: w,
        h: h,
        r: r,
        c: c,
        colorValue: colorValue,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'w': w,
        'h': h,
        'r': r,
        'c': c,
        'color': colorValue,
      };

  factory Piece.fromJson(Map<String, dynamic> j) => Piece(
        id: j['id'] as String,
        label: j['label'] as String,
        w: j['w'] as int,
        h: j['h'] as int,
        r: j['r'] as int,
        c: j['c'] as int,
        colorValue: j['color'] as int,
      );
}

class KlotskiBoard {
  KlotskiBoard({required this.pieces, this.moves = 0});

  static const int cols = 4;
  static const int rows = 5;

  final List<Piece> pieces;
  int moves;

  List<List<String?>> _grid() {
    final g = List.generate(rows, (_) => List<String?>.filled(cols, null));
    for (final p in pieces) {
      for (var dr = 0; dr < p.h; dr++) {
        for (var dc = 0; dc < p.w; dc++) {
          g[p.r + dr][p.c + dc] = p.id;
        }
      }
    }
    return g;
  }

  bool _free(List<List<String?>> g, int r, int c, String selfId) {
    if (r < 0 || r >= rows || c < 0 || c >= cols) return false;
    final occ = g[r][c];
    return occ == null || occ == selfId;
  }

  /// Whether [p] can slide one cell by ([dr],[dc]) (exactly one of them ±1).
  bool canMove(Piece p, int dr, int dc) {
    final g = _grid();
    for (var i = 0; i < p.h; i++) {
      for (var j = 0; j < p.w; j++) {
        if (!_free(g, p.r + i + dr, p.c + j + dc, p.id)) return false;
      }
    }
    return true;
  }

  /// Slide [p] by one cell if legal. Returns true and increments [moves] on a
  /// successful move.
  bool move(Piece p, int dr, int dc) {
    if (!canMove(p, dr, dc)) return false;
    p.r += dr;
    p.c += dc;
    moves++;
    return true;
  }

  /// How many cells [p] can slide in unit direction ([dr],[dc]) before being
  /// blocked. Does not mutate the board.
  int maxSlide(Piece p, int dr, int dc) {
    final sr = p.r, sc = p.c;
    var steps = 0;
    while (canMove(p, dr, dc)) {
      p.r += dr;
      p.c += dc;
      steps++;
    }
    p.r = sr;
    p.c = sc;
    return steps;
  }

  /// Slide [p] up to [cells] cells in unit direction ([dr],[dc]). Returns the
  /// number of cells actually moved (each counts toward [moves]).
  int slide(Piece p, int dr, int dc, int cells) {
    var done = 0;
    for (var i = 0; i < cells; i++) {
      if (!move(p, dr, dc)) break;
      done++;
    }
    return done;
  }

  Piece? pieceAt(int r, int c) {
    for (final p in pieces) {
      if (r >= p.r && r < p.r + p.h && c >= p.c && c < p.c + p.w) return p;
    }
    return null;
  }

  Piece get caoCao => pieces.firstWhere((p) => p.isCaoCao);

  /// Solved when 曹操 occupies the bottom-centre (rows 3-4, cols 1-2).
  bool get isSolved {
    final cao = caoCao;
    return cao.r == 3 && cao.c == 1;
  }

  KlotskiBoard copy() =>
      KlotskiBoard(pieces: [for (final p in pieces) p.copy()], moves: moves);

  Map<String, dynamic> toJson() => {
        'moves': moves,
        'pieces': [for (final p in pieces) p.toJson()],
      };

  factory KlotskiBoard.fromJson(Map<String, dynamic> j) => KlotskiBoard(
        moves: j['moves'] as int? ?? 0,
        pieces: [
          for (final p in (j['pieces'] as List))
            Piece.fromJson((p as Map).cast<String, dynamic>())
        ],
      );
}

/// The iconic 横刀立马 starting layout (optimal solution: 81 moves).
///
/// ```
/// 张 曹 曹 赵
/// 张 曹 曹 赵
/// 马 关 关 黄
/// 马 卒 卒 黄
/// 卒 .  .  卒
/// ```
KlotskiBoard hengDaoLiMa() => KlotskiBoard(pieces: [
      Piece(id: 'cao', label: '曹操', w: 2, h: 2, r: 0, c: 1, colorValue: 0xFFD64550),
      Piece(id: 'zhang', label: '张飞', w: 1, h: 2, r: 0, c: 0, colorValue: 0xFF4F86C6),
      Piece(id: 'zhao', label: '赵云', w: 1, h: 2, r: 0, c: 3, colorValue: 0xFF4F86C6),
      Piece(id: 'ma', label: '马超', w: 1, h: 2, r: 2, c: 0, colorValue: 0xFF4F86C6),
      Piece(id: 'huang', label: '黄忠', w: 1, h: 2, r: 2, c: 3, colorValue: 0xFF4F86C6),
      Piece(id: 'guan', label: '关羽', w: 2, h: 1, r: 2, c: 1, colorValue: 0xFFE39A3B),
      Piece(id: 'z1', label: '卒', w: 1, h: 1, r: 3, c: 1, colorValue: 0xFF8C9BAB),
      Piece(id: 'z2', label: '卒', w: 1, h: 1, r: 3, c: 2, colorValue: 0xFF8C9BAB),
      Piece(id: 'z3', label: '卒', w: 1, h: 1, r: 4, c: 0, colorValue: 0xFF8C9BAB),
      Piece(id: 'z4', label: '卒', w: 1, h: 1, r: 4, c: 3, colorValue: 0xFF8C9BAB),
    ]);
