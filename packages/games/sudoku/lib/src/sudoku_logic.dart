import 'dart:math';

enum Difficulty { easy, medium, hard }

extension DifficultyInfo on Difficulty {
  /// Number of pre-filled cells (givens) for each level.
  int get givens => switch (this) {
        Difficulty.easy => 40,
        Difficulty.medium => 32,
        Difficulty.hard => 26,
      };

  String get label => switch (this) {
        Difficulty.easy => '简单',
        Difficulty.medium => '中等',
        Difficulty.hard => '困难',
      };
}

/// A generated puzzle: the starting board ([givens], 0 = empty) and its unique
/// [solution].
class SudokuPuzzle {
  const SudokuPuzzle({required this.givens, required this.solution});

  final List<List<int>> givens;
  final List<List<int>> solution;
}

/// Pure Sudoku logic — generation, solving, validation. No Flutter, no I/O.
class Sudoku {
  Sudoku._();

  static const int n = 9;

  static List<List<int>> emptyGrid() =>
      List.generate(n, (_) => List.filled(n, 0));

  static List<List<int>> copy(List<List<int>> g) =>
      g.map((row) => List<int>.from(row)).toList();

  /// Whether placing [v] at ([r],[c]) violates no row/col/box rule.
  static bool isSafe(List<List<int>> g, int r, int c, int v) {
    for (var i = 0; i < n; i++) {
      if (g[r][i] == v || g[i][c] == v) return false;
    }
    final br = (r ~/ 3) * 3, bc = (c ~/ 3) * 3;
    for (var i = 0; i < 3; i++) {
      for (var j = 0; j < 3; j++) {
        if (g[br + i][bc + j] == v) return false;
      }
    }
    return true;
  }

  /// Fill an empty grid with a random complete valid solution.
  static List<List<int>> generatedSolution(Random rng) {
    final g = emptyGrid();
    _fill(g, rng);
    return g;
  }

  static bool _fill(List<List<int>> g, Random rng) {
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        if (g[r][c] == 0) {
          final candidates = [for (var v = 1; v <= 9; v++) v]..shuffle(rng);
          for (final v in candidates) {
            if (isSafe(g, r, c, v)) {
              g[r][c] = v;
              if (_fill(g, rng)) return true;
              g[r][c] = 0;
            }
          }
          return false;
        }
      }
    }
    return true;
  }

  /// Count solutions up to [limit] (used for uniqueness: limit 2 is enough).
  static int countSolutions(List<List<int>> grid, {int limit = 2}) {
    final g = copy(grid);
    var count = 0;
    bool solve() {
      for (var r = 0; r < n; r++) {
        for (var c = 0; c < n; c++) {
          if (g[r][c] == 0) {
            for (var v = 1; v <= 9; v++) {
              if (isSafe(g, r, c, v)) {
                g[r][c] = v;
                if (solve()) {
                  // propagate early-stop
                }
                g[r][c] = 0;
                if (count >= limit) return true;
              }
            }
            return false; // no valid value here -> dead end
          }
        }
      }
      count++; // a full grid -> one solution
      return count >= limit;
    }

    solve();
    return count;
  }

  /// Generate a puzzle with a unique solution at the given [difficulty].
  static SudokuPuzzle generate(Difficulty difficulty, Random rng) {
    final solution = generatedSolution(rng);
    final puzzle = copy(solution);
    final positions = [for (var i = 0; i < n * n; i++) i]..shuffle(rng);
    var remaining = n * n;
    final target = difficulty.givens;

    for (final pos in positions) {
      if (remaining <= target) break;
      final r = pos ~/ n, c = pos % n;
      if (puzzle[r][c] == 0) continue;
      final backup = puzzle[r][c];
      puzzle[r][c] = 0;
      if (countSolutions(puzzle, limit: 2) != 1) {
        puzzle[r][c] = backup; // removal broke uniqueness -> keep it
      } else {
        remaining--;
      }
    }
    return SudokuPuzzle(givens: puzzle, solution: solution);
  }

  /// True if the grid is completely filled and breaks no rule.
  static bool isComplete(List<List<int>> g) {
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        final v = g[r][c];
        if (v == 0) return false;
        g[r][c] = 0;
        final ok = isSafe(g, r, c, v);
        g[r][c] = v;
        if (!ok) return false;
      }
    }
    return true;
  }

  /// Coordinates that conflict with another filled cell (for error highlight).
  static Set<int> conflicts(List<List<int>> g) {
    final bad = <int>{};
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        final v = g[r][c];
        if (v == 0) continue;
        g[r][c] = 0;
        if (!isSafe(g, r, c, v)) bad.add(r * n + c);
        g[r][c] = v;
      }
    }
    return bad;
  }
}
