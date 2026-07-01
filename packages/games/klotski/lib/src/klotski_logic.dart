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

class PieceSpec {
  const PieceSpec({
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
  final int r;
  final int c;
  final int colorValue;

  Piece create() => Piece(
        id: id,
        label: label,
        w: w,
        h: h,
        r: r,
        c: c,
        colorValue: colorValue,
      );
}

class KlotskiLevel {
  const KlotskiLevel({
    required this.id,
    required this.name,
    required this.description,
    required List<PieceSpec> pieces,
  }) : _pieces = pieces;

  static const String defaultId = 'heng_dao_li_ma';

  static final List<KlotskiLevel> levels = [
    KlotskiLevel(
      id: defaultId,
      name: '横刀立马',
      description: '经典一横布局，最优 81 步',
      pieces: [
        _cao(0, 1),
        _v('zhang', '张飞', 0, 0),
        _v('zhao', '赵云', 0, 3),
        _v('ma', '马超', 2, 0),
        _v('huang', '黄忠', 2, 3),
        _h('guan', '关羽', 2, 1),
        _z('z1', 3, 1),
        _z('z2', 3, 2),
        _z('z3', 4, 0),
        _z('z4', 4, 3),
      ],
    ),
    KlotskiLevel(
      id: 'cha_chi_nan_fei',
      name: '插翅难飞',
      description: '二横布局，出口两侧仍被竖将封住',
      pieces: [
        _cao(0, 1),
        _v('zhang', '张飞', 0, 0),
        _h('guan', '关羽', 2, 0),
        _h('zhao', '赵云', 3, 1),
        _v('ma', '马超', 3, 0),
        _v('huang', '黄忠', 3, 3),
        _z('z1', 0, 3),
        _z('z2', 1, 3),
        _z('z3', 2, 2),
        _z('z4', 2, 3),
      ],
    ),
    KlotskiLevel(
      id: 'ceng_ceng_she_fang',
      name: '层层设防',
      description: '三横布局，层层横将挡在下路',
      pieces: [
        _cao(0, 1),
        _v('zhang', '张飞', 0, 0),
        _v('zhao', '赵云', 0, 3),
        _h('guan', '关羽', 2, 1),
        _h('ma', '马超', 3, 1),
        _h('huang', '黄忠', 4, 1),
        _z('z1', 2, 0),
        _z('z2', 2, 3),
        _z('z3', 3, 0),
        _z('z4', 3, 3),
      ],
    ),
    KlotskiLevel(
      id: 'shui_xie_bu_tong',
      name: '水泄不通',
      description: '四横布局，下方被横将完全压住',
      pieces: [
        _cao(0, 1),
        _v('zhao', '赵云', 0, 3),
        _h('guan', '关羽', 2, 0),
        _h('zhang', '张飞', 2, 2),
        _h('ma', '马超', 3, 0),
        _h('huang', '黄忠', 3, 2),
        _z('z1', 0, 0),
        _z('z2', 1, 0),
        _z('z3', 4, 0),
        _z('z4', 4, 3),
      ],
    ),
    KlotskiLevel(
      id: 'wu_heng_ding_shi',
      name: '五横定式',
      description: '五将全横，先把下方横将错开',
      pieces: [
        _cao(0, 1),
        _h('guan', '关羽', 2, 0),
        _h('zhang', '张飞', 2, 2),
        _h('ma', '马超', 3, 0),
        _h('huang', '黄忠', 3, 2),
        _h('zhao', '赵云', 4, 1),
        _z('z1', 0, 0),
        _z('z2', 0, 3),
        _z('z3', 1, 0),
        _z('z4', 1, 3),
      ],
    ),
    KlotskiLevel(
      id: 'tun_bing_dong_lu',
      name: '屯兵东路',
      description: '曹操偏左的一横变阵',
      pieces: [
        _cao(0, 0),
        _v('zhang', '张飞', 0, 2),
        _v('zhao', '赵云', 0, 3),
        _h('guan', '关羽', 2, 0),
        _v('ma', '马超', 3, 0),
        _v('huang', '黄忠', 3, 1),
        _z('z1', 2, 2),
        _z('z2', 2, 3),
        _z('z3', 3, 2),
        _z('z4', 3, 3),
      ],
    ),
    KlotskiLevel(
      id: 'shou_kou_ru_ping',
      name: '守口如瓶',
      description: '二横布局，横将直接堵住出口',
      pieces: [
        _cao(0, 1),
        _v('zhang', '张飞', 0, 0),
        _v('zhao', '赵云', 0, 3),
        _v('ma', '马超', 2, 1),
        _h('guan', '关羽', 4, 0),
        _h('huang', '黄忠', 4, 2),
        _z('z1', 2, 0),
        _z('z2', 2, 3),
        _z('z3', 3, 0),
        _z('z4', 3, 3),
      ],
    ),
  ];

  static KlotskiLevel get defaultLevel => levels.first;

  static KlotskiLevel byId(String? id) => levels.firstWhere(
        (level) => level.id == id,
        orElse: () => defaultLevel,
      );

  final String id;
  final String name;
  final String description;
  final List<PieceSpec> _pieces;

  int get horizontalGenerals =>
      _pieces.where((piece) => piece.w == 2 && piece.h == 1).length;

  String get category => switch (horizontalGenerals) {
        0 => '全竖局',
        1 => '一横局',
        2 => '二横局',
        3 => '三横局',
        4 => '四横局',
        5 => '五横局',
        _ => '$horizontalGenerals 横局',
      };

  KlotskiBoard createBoard() =>
      KlotskiBoard(pieces: [for (final p in _pieces) p.create()]);
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
KlotskiBoard hengDaoLiMa() => KlotskiLevel.defaultLevel.createBoard();

const int _caoColor = 0xFFD64550;
const int _generalColor = 0xFF4F86C6;
const int _guanColor = 0xFFE39A3B;
const int _soldierColor = 0xFF8C9BAB;

PieceSpec _cao(int r, int c) => PieceSpec(
      id: 'cao',
      label: '曹操',
      w: 2,
      h: 2,
      r: r,
      c: c,
      colorValue: _caoColor,
    );

PieceSpec _v(String id, String label, int r, int c) => PieceSpec(
      id: id,
      label: label,
      w: 1,
      h: 2,
      r: r,
      c: c,
      colorValue: _generalColor,
    );

PieceSpec _h(String id, String label, int r, int c) => PieceSpec(
      id: id,
      label: label,
      w: 2,
      h: 1,
      r: r,
      c: c,
      colorValue: id == 'guan' ? _guanColor : _generalColor,
    );

PieceSpec _z(String id, int r, int c) => PieceSpec(
      id: id,
      label: '卒',
      w: 1,
      h: 1,
      r: r,
      c: c,
      colorValue: _soldierColor,
    );
