/// Pure Sokoban logic — no Flutter imports.
///
/// Levels are ASCII grids using the classic charset:
///   '#' wall   ' ' floor   '.' target   '$' box   '*' box-on-target
///   '@' player '+' player-on-target
library;

/// A four-way move direction.
enum Dir { up, down, left, right }

/// An immutable grid coordinate (row, col).
class Pos {
  const Pos(this.r, this.c);

  final int r;
  final int c;

  Pos step(Dir d) => switch (d) {
        Dir.up => Pos(r - 1, c),
        Dir.down => Pos(r + 1, c),
        Dir.left => Pos(r, c - 1),
        Dir.right => Pos(r, c + 1),
      };

  @override
  bool operator ==(Object other) =>
      other is Pos && other.r == r && other.c == c;

  @override
  int get hashCode => Object.hash(r, c);

  @override
  String toString() => '($r,$c)';
}

class _Snapshot {
  _Snapshot(this.boxes, this.player, this.moves);
  final Set<Pos> boxes;
  final Pos player;
  final int moves;
}

/// Mutable Sokoban game state, parsed from an ASCII level.
class SokobanState {
  SokobanState({
    required this.source,
    required this.rows,
    required this.cols,
    required this.walls,
    required this.targets,
    required Set<Pos> boxes,
    required this.player,
  }) : boxes = boxes;

  /// The original ASCII rows this state was parsed from (used by [reset]).
  final List<String> source;
  final int rows;
  final int cols;
  final Set<Pos> walls;
  final Set<Pos> targets;

  Set<Pos> boxes;
  Pos player;
  int moves = 0;

  final List<_Snapshot> _history = [];

  /// Parse a level from ASCII [grid] rows.
  factory SokobanState.parse(List<String> grid) {
    final walls = <Pos>{};
    final targets = <Pos>{};
    final boxes = <Pos>{};
    Pos? player;
    final rows = grid.length;
    var cols = 0;
    for (var r = 0; r < rows; r++) {
      final line = grid[r];
      if (line.length > cols) cols = line.length;
      for (var c = 0; c < line.length; c++) {
        final p = Pos(r, c);
        switch (line[c]) {
          case '#':
            walls.add(p);
          case '.':
            targets.add(p);
          case r'$':
            boxes.add(p);
          case '*':
            boxes.add(p);
            targets.add(p);
          case '@':
            player = p;
          case '+':
            player = p;
            targets.add(p);
          case ' ':
            break;
          default:
            break;
        }
      }
    }
    if (player == null) {
      throw ArgumentError('level has no player (@ or +)');
    }
    return SokobanState(
      source: List<String>.unmodifiable(grid),
      rows: rows,
      cols: cols,
      walls: walls,
      targets: targets,
      boxes: boxes,
      player: player,
    );
  }

  bool isWall(Pos p) => walls.contains(p);
  bool isTarget(Pos p) => targets.contains(p);
  bool isBox(Pos p) => boxes.contains(p);
  bool isPlayer(Pos p) => player == p;

  bool get canUndo => _history.isNotEmpty;

  /// Every box rests on a target (and there is at least one box).
  bool get isSolved =>
      boxes.isNotEmpty && boxes.every((b) => targets.contains(b));

  void _snapshot() {
    _history.add(_Snapshot(Set<Pos>.from(boxes), player, moves));
  }

  /// Attempt to move the player one cell in [d].
  ///
  /// Walks into floor/target, or pushes a single box if the cell beyond it is
  /// free. Never pushes two boxes at once, into a wall, or off the grid.
  /// Returns true if the state changed.
  bool move(Dir d) {
    if (isSolved) return false;
    final next = player.step(d);
    if (walls.contains(next)) return false;
    if (boxes.contains(next)) {
      final beyond = next.step(d);
      if (walls.contains(beyond) || boxes.contains(beyond)) return false;
      _snapshot();
      boxes.remove(next);
      boxes.add(beyond);
      player = next;
      moves++;
      return true;
    }
    _snapshot();
    player = next;
    moves++;
    return true;
  }

  /// Revert the last move. Returns false if there is nothing to undo.
  bool undo() {
    if (_history.isEmpty) return false;
    final s = _history.removeLast();
    boxes = s.boxes;
    player = s.player;
    moves = s.moves;
    return true;
  }

  /// Reset to the level's initial layout.
  void reset() {
    final fresh = SokobanState.parse(source);
    boxes = fresh.boxes;
    player = fresh.player;
    moves = 0;
    _history.clear();
  }
}

/// Small, phone-sized, hand-verified solvable levels.
const List<List<String>> kSokobanLevels = [
  // 0 — one push to the right.
  [
    '#####',
    r'#@$.#',
    '#####',
  ],
  // 1 — two pushes upward.
  [
    '######',
    '#.   #',
    '#    #',
    r'#$   #',
    '#@   #',
    '######',
  ],
  // 2 — two boxes, walk around to the second.
  [
    '#######',
    '#@    #',
    r'#$   $#',
    '#.   .#',
    '#######',
  ],
  // 3 — two boxes, push left then up.
  [
    '#######',
    '#  .  #',
    r'#  $  #',
    r'#.$@  #',
    '#######',
  ],
];
