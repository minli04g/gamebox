/// Pure Reversi/Othello rules — no Flutter imports.
///
/// The board is a flat `List<int>` of length 64 indexed `row * 8 + col`:
/// `0` empty, `1` human (black), `2` AI (white). Black moves first.
library;

/// Board side length.
const int kSize = 8;

/// Total cells.
const int kCells = kSize * kSize;

/// Empty cell value.
const int empty = 0;

/// Human player (black).
const int black = 1;

/// AI player (white).
const int white = 2;

/// The four board corners — strongest squares in Reversi.
const List<int> kCorners = [0, 7, 56, 63];

/// The eight step directions as (dRow, dCol) pairs.
const List<List<int>> _dirs = [
  [-1, -1], [-1, 0], [-1, 1],
  [0, -1], [0, 1],
  [1, -1], [1, 0], [1, 1],
];

/// The opponent of [player].
int opponentOf(int player) => player == black ? white : black;

/// The standard opening position: white on d4/e5, black on d5/e4.
List<int> initialBoard() {
  final b = List<int>.filled(kCells, empty);
  b[3 * kSize + 3] = white; // d4
  b[4 * kSize + 4] = white; // e5
  b[3 * kSize + 4] = black; // e4
  b[4 * kSize + 3] = black; // d5
  return b;
}

/// Discs that would be flipped if [player] placed at [index]. Empty when the
/// move is illegal (cell occupied, or it brackets nothing).
List<int> flipsFor(List<int> board, int player, int index) {
  if (index < 0 || index >= kCells || board[index] != empty) return const [];
  final opp = opponentOf(player);
  final row = index ~/ kSize;
  final col = index % kSize;
  final flips = <int>[];
  for (final d in _dirs) {
    final line = <int>[];
    var r = row + d[0];
    var c = col + d[1];
    while (r >= 0 && r < kSize && c >= 0 && c < kSize) {
      final i = r * kSize + c;
      final v = board[i];
      if (v == opp) {
        line.add(i);
      } else if (v == player) {
        if (line.isNotEmpty) flips.addAll(line);
        break;
      } else {
        break; // empty — no bracket
      }
      r += d[0];
      c += d[1];
    }
  }
  return flips;
}

/// All indices where [player] has a legal move (flips at least one disc).
List<int> legalMoves(List<int> board, int player) {
  final moves = <int>[];
  for (var i = 0; i < kCells; i++) {
    if (board[i] == empty && flipsFor(board, player, i).isNotEmpty) {
      moves.add(i);
    }
  }
  return moves;
}

/// Whether [player] has any legal move.
bool hasMove(List<int> board, int player) => legalMoves(board, player).isNotEmpty;

/// Applies [player]'s move at [index], returning a new board with the placed
/// disc and all bracketed discs flipped. Returns an unchanged copy if illegal.
List<int> applyMove(List<int> board, int player, int index) {
  final flips = flipsFor(board, player, index);
  final next = List<int>.of(board);
  if (flips.isEmpty) return next;
  next[index] = player;
  for (final i in flips) {
    next[i] = player;
  }
  return next;
}

/// Disc counts for both players.
({int black, int white}) counts(List<int> board) {
  var b = 0, w = 0;
  for (final v in board) {
    if (v == black) {
      b++;
    } else if (v == white) {
      w++;
    }
  }
  return (black: b, white: w);
}

/// The game is over when neither player can move.
bool isGameOver(List<int> board) =>
    !hasMove(board, black) && !hasMove(board, white);

/// Winner of a finished position: [black], [white], or `0` for a draw.
int winnerOf(List<int> board) {
  final c = counts(board);
  if (c.black > c.white) return black;
  if (c.white > c.black) return white;
  return empty;
}

/// Corner-weighted greedy choice for [player]: take a corner if available,
/// otherwise the move flipping the most discs. Returns `-1` when no move
/// exists. [tieBreaker], if given, picks among equally-scored moves.
int chooseAiMove(List<int> board, int player, {int Function(List<int>)? tieBreaker}) {
  final moves = legalMoves(board, player);
  if (moves.isEmpty) return -1;

  final corners = [for (final m in moves) if (kCorners.contains(m)) m];
  final pool = corners.isNotEmpty ? corners : moves;

  var best = pool.first;
  var bestFlips = flipsFor(board, player, best).length;
  final tied = <int>[best];
  for (final m in pool.skip(1)) {
    final f = flipsFor(board, player, m).length;
    if (f > bestFlips) {
      bestFlips = f;
      best = m;
      tied
        ..clear()
        ..add(m);
    } else if (f == bestFlips) {
      tied.add(m);
    }
  }
  if (tied.length > 1 && tieBreaker != null) return tieBreaker(tied);
  return best;
}
