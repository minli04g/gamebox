import 'package:game_2048/game_2048.dart';
import 'package:game_core/game_core.dart';
import 'package:klotski/klotski.dart';
import 'package:minesweeper/minesweeper.dart';
import 'package:sudoku/sudoku.dart';

/// The one place games are wired into the app. Adding a game = one line here.
const List<Game> registeredGames = <Game>[
  SudokuGame(),
  Game2048(),
  MinesweeperGame(),
  KlotskiGame(),
];

Game? gameById(String id) {
  for (final g in registeredGames) {
    if (g.descriptor.id == id) return g;
  }
  return null;
}
