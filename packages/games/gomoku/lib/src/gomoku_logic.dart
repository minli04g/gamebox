/// Pure 五子棋 (Gomoku) logic — board is a flat `List<int>` of length N*N
/// (0 empty, 1 human/black, 2 AI/white). No Flutter imports so it can be unit
/// tested directly. Provides [checkWin] to detect five-in-a-row and [aiMove],
/// a line-pattern heuristic that both completes the AI's own lines and blocks
/// the opponent's open fours/threes.
library;

/// The four line directions, as (dRow, dCol): horizontal, vertical, and both
/// diagonals.
const List<List<int>> _dirs = [
  [0, 1], // horizontal
  [1, 0], // vertical
  [1, 1], // ↘ diagonal
  [1, -1], // ↙ diagonal
];

/// Counts consecutive [player] stones stepping from (row,col) along (dr,dc),
/// excluding the starting cell itself.
int _run(List<int> board, int N, int row, int col, int dr, int dc, int player) {
  var r = row + dr, c = col + dc, n = 0;
  while (r >= 0 && r < N && c >= 0 && c < N && board[r * N + c] == player) {
    n++;
    r += dr;
    c += dc;
  }
  return n;
}

/// Whether the stone just placed by [player] at [lastIndex] forms a line of
/// five or more in any of the four directions.
bool checkWin(List<int> board, int N, int lastIndex, int player) {
  if (lastIndex < 0 || lastIndex >= board.length) return false;
  final row = lastIndex ~/ N;
  final col = lastIndex % N;
  for (final d in _dirs) {
    final total = 1 +
        _run(board, N, row, col, d[0], d[1], player) +
        _run(board, N, row, col, -d[0], -d[1], player);
    if (total >= 5) return true;
  }
  return false;
}

/// Maps a would-be line of [count] stones with [openEnds] open ends (0..2) to
/// a heuristic score.
int _patternScore(int count, int openEnds) {
  if (count >= 5) return 1000000; // five — winning
  switch (count) {
    case 4:
      return openEnds == 2
          ? 100000 // open four — unstoppable
          : openEnds == 1
              ? 10000 // four
              : 0;
    case 3:
      return openEnds == 2
          ? 1000 // open three
          : openEnds == 1
              ? 100
              : 0;
    case 2:
      return openEnds == 2
          ? 100
          : openEnds == 1
              ? 10
              : 0;
    case 1:
      return openEnds == 2
          ? 10
          : openEnds == 1
              ? 1
              : 0;
    default:
      return 0;
  }
}

/// Heuristic score for [player] hypothetically placing a stone at the empty
/// cell [idx], summed over all four directions.
int lineScore(List<int> board, int N, int idx, int player) {
  final row = idx ~/ N;
  final col = idx % N;
  var score = 0;
  for (final d in _dirs) {
    final dr = d[0], dc = d[1];
    final fwd = _run(board, N, row, col, dr, dc, player);
    final bwd = _run(board, N, row, col, -dr, -dc, player);
    final count = 1 + fwd + bwd;

    // An end is "open" when the cell just past the run is on-board and empty.
    var open = 0;
    final fr = row + (fwd + 1) * dr, fc = col + (fwd + 1) * dc;
    if (fr >= 0 && fr < N && fc >= 0 && fc < N && board[fr * N + fc] == 0) {
      open++;
    }
    final br = row - (bwd + 1) * dr, bc = col - (bwd + 1) * dc;
    if (br >= 0 && br < N && bc >= 0 && bc < N && board[br * N + bc] == 0) {
      open++;
    }
    score += _patternScore(count, open);
  }
  return score;
}

/// Picks the AI's (player 2) move on [board]: scores every empty cell by
/// combining its own attacking value with the defensive value of denying the
/// human (player 1) the same cell, and returns the index of the best one.
/// Returns -1 only when the board is full.
int aiMove(List<int> board, int N) {
  var best = -1;
  var bestScore = -1;
  for (var idx = 0; idx < board.length; idx++) {
    if (board[idx] != 0) continue;
    final attack = lineScore(board, N, idx, 2);
    final defense = lineScore(board, N, idx, 1);
    // Slight bias toward central cells breaks ties toward stronger play.
    final row = idx ~/ N, col = idx % N;
    final centerBonus = (N - (row - N ~/ 2).abs() - (col - N ~/ 2).abs());
    // Weight: take own offense fully, defend opponent threats almost as much.
    final score = attack * 10 + (defense * 9) + centerBonus;
    if (score > bestScore) {
      bestScore = score;
      best = idx;
    }
  }
  return best;
}
