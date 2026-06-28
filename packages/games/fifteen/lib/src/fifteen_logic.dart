/// Pure 数字华容道 (15-puzzle) logic — no Flutter imports.
///
/// The board is a [List<int>] of length 16 laid out row-major on a 4×4 grid.
/// Tiles are numbered 1..15 and the blank is 0. The solved board is
/// `[1, 2, …, 15, 0]`.
library;

import 'dart:math';

/// Side length of the puzzle (4×4).
const int kSize = 4;

/// Total number of cells, including the blank.
const int kCells = kSize * kSize;

/// The solved arrangement: 1..15 followed by the blank (0).
List<int> solvedBoard() => [for (var i = 1; i < kCells; i++) i]..add(0);

/// Whether [board] is fully solved (`[1..15, 0]`).
bool isSolved(List<int> board) {
  if (board.length != kCells) return false;
  for (var i = 0; i < kCells - 1; i++) {
    if (board[i] != i + 1) return false;
  }
  return board[kCells - 1] == 0;
}

/// Index of the blank (0) tile in [board].
int blankIndex(List<int> board) => board.indexOf(0);

/// Whether cells [a] and [b] are orthogonally adjacent on the grid.
bool areAdjacent(int a, int b) {
  final ra = a ~/ kSize, ca = a % kSize;
  final rb = b ~/ kSize, cb = b % kSize;
  return (ra == rb && (ca - cb).abs() == 1) ||
      (ca == cb && (ra - rb).abs() == 1);
}

/// The indices of cells orthogonally adjacent to [index].
List<int> neighborsOf(int index) {
  final r = index ~/ kSize, c = index % kSize;
  return [
    if (r > 0) index - kSize,
    if (r < kSize - 1) index + kSize,
    if (c > 0) index - 1,
    if (c < kSize - 1) index + 1,
  ];
}

/// Attempts to slide the tile at [index] into the blank.
///
/// Mutates [board] in place, swapping the tile with the blank only when
/// [index] is orthogonally adjacent to the blank. Returns whether a move
/// happened.
bool tapTile(List<int> board, int index) {
  if (index < 0 || index >= kCells) return false;
  if (board[index] == 0) return false;
  final blank = blankIndex(board);
  if (!areAdjacent(index, blank)) return false;
  board[blank] = board[index];
  board[index] = 0;
  return true;
}

/// Builds a guaranteed-solvable, not-already-solved board.
///
/// Starts from the solved board and applies several hundred random legal moves;
/// because every move is reversible the result is always solvable. In the
/// unlikely event the shuffle lands back on the solved board, one extra move is
/// applied so the returned board is never already solved.
List<int> generateSolvable(Random rng) {
  final board = solvedBoard();
  const moves = 500;
  for (var i = 0; i < moves; i++) {
    final options = neighborsOf(blankIndex(board));
    tapTile(board, options[rng.nextInt(options.length)]);
  }
  if (isSolved(board)) {
    final options = neighborsOf(blankIndex(board));
    tapTile(board, options[rng.nextInt(options.length)]);
  }
  return board;
}
