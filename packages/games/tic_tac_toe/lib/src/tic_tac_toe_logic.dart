/// Pure tic-tac-toe logic with an unbeatable minimax AI.
/// Board: List<int> length 9, 0 = empty, 1 = human (X), 2 = AI (O).
library;

import 'dart:math';

const List<List<int>> kLines = [
  [0, 1, 2], [3, 4, 5], [6, 7, 8], // rows
  [0, 3, 6], [1, 4, 7], [2, 5, 8], // cols
  [0, 4, 8], [2, 4, 6], // diagonals
];

/// 1 or 2 = that player won; 3 = draw; 0 = game still ongoing.
int winner(List<int> b) {
  for (final l in kLines) {
    final a = b[l[0]];
    if (a != 0 && a == b[l[1]] && a == b[l[2]]) return a;
  }
  return b.every((c) => c != 0) ? 3 : 0;
}

/// Indices of the empty cells on [b].
List<int> legalMoves(List<int> b) =>
    [for (var i = 0; i < 9; i++) if (b[i] == 0) i];

/// Best move index for [player] via depth-aware minimax (prefers faster wins
/// and slower losses), making the AI unbeatable.
int bestMove(List<int> b, int player) {
  var bestScore = -1000, bestIdx = -1;
  for (final i in legalMoves(b)) {
    final nb = [...b]..[i] = player;
    final s = _minimax(nb, player == 1 ? 2 : 1, player, 1);
    if (s > bestScore) {
      bestScore = s;
      bestIdx = i;
    }
  }
  return bestIdx;
}

int _minimax(List<int> b, int turn, int me, int depth) {
  final w = winner(b);
  if (w == me) return 100 - depth;
  if (w == 3) return 0;
  if (w != 0) return depth - 100;
  final scores = [
    for (final i in legalMoves(b))
      _minimax([...b]..[i] = turn, turn == 1 ? 2 : 1, me, depth + 1)
  ];
  return turn == me ? scores.reduce(max) : scores.reduce(min);
}
