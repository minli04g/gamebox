import 'package:bulls_cows/bulls_cows.dart';
import 'package:fifteen/fifteen.dart';
import 'package:game_2048/game_2048.dart';
import 'package:game_core/game_core.dart';
import 'package:gomoku/gomoku.dart';
import 'package:klotski/klotski.dart';
import 'package:memory_match/memory_match.dart';
import 'package:minesweeper/minesweeper.dart';
import 'package:peg_solitaire/peg_solitaire.dart';
import 'package:reversi/reversi.dart';
import 'package:simon/simon.dart';
import 'package:snake/snake.dart';
import 'package:sokoban/sokoban.dart';
import 'package:sudoku/sudoku.dart';
import 'package:tic_tac_toe/tic_tac_toe.dart';
import 'package:twenty_four/twenty_four.dart';

/// The one place games are wired into the app. Adding a game = one line here.
const List<Game> registeredGames = <Game>[
  SudokuGame(),
  Game2048(),
  MinesweeperGame(),
  KlotskiGame(),
  TwentyFourGame(),
  TicTacToeGame(),
  GomokuGame(),
  ReversiGame(),
  SnakeGame(),
  MemoryMatchGame(),
  FifteenGame(),
  PegSolitaireGame(),
  BullsCowsGame(),
  SimonGame(),
  SokobanGame(),
];

Game? gameById(String id) {
  for (final g in registeredGames) {
    if (g.descriptor.id == id) return g;
  }
  return null;
}
