import 'package:flutter_test/flutter_test.dart';
import 'package:gomoku/src/gomoku_logic.dart';

const int N = 11;

List<int> _empty() => List<int>.filled(N * N, 0);

int _idx(int row, int col) => row * N + col;

void main() {
  group('checkWin', () {
    test('detects horizontal five-in-a-row', () {
      final b = _empty();
      for (var c = 0; c < 5; c++) {
        b[_idx(3, c)] = 1;
      }
      expect(checkWin(b, N, _idx(3, 4), 1), isTrue);
    });

    test('detects vertical five-in-a-row', () {
      final b = _empty();
      for (var r = 0; r < 5; r++) {
        b[_idx(r, 2)] = 2;
      }
      expect(checkWin(b, N, _idx(4, 2), 2), isTrue);
    });

    test('detects ↘ diagonal five-in-a-row', () {
      final b = _empty();
      for (var i = 0; i < 5; i++) {
        b[_idx(i, i)] = 1;
      }
      expect(checkWin(b, N, _idx(4, 4), 1), isTrue);
    });

    test('detects ↙ diagonal five-in-a-row', () {
      final b = _empty();
      for (var i = 0; i < 5; i++) {
        b[_idx(i, 8 - i)] = 1;
      }
      expect(checkWin(b, N, _idx(4, 4), 1), isTrue);
    });

    test('rejects a mere four-in-a-row', () {
      final b = _empty();
      for (var c = 0; c < 4; c++) {
        b[_idx(3, c)] = 1;
      }
      expect(checkWin(b, N, _idx(3, 3), 1), isFalse);
    });
  });

  group('aiMove', () {
    test('returns a legal empty cell', () {
      final b = _empty();
      b[_idx(5, 5)] = 1;
      final move = aiMove(b, N);
      expect(move, inInclusiveRange(0, N * N - 1));
      expect(b[move], 0);
    });

    test('blocks the opponent open four-in-a-row', () {
      final b = _empty();
      // Human (player 1) has four in a row at row 5, cols 3..6.
      // Open ends are col 2 (idx 57) and col 7 (idx 62).
      for (var c = 3; c <= 6; c++) {
        b[_idx(5, c)] = 1;
      }
      final move = aiMove(b, N);
      expect(move, anyOf(_idx(5, 2), _idx(5, 7)));
    });

    test('takes its own winning move when available', () {
      final b = _empty();
      // AI (player 2) already has four in a row; it should complete five.
      for (var c = 1; c <= 4; c++) {
        b[_idx(7, c)] = 2;
      }
      final move = aiMove(b, N);
      expect(move, anyOf(_idx(7, 0), _idx(7, 5)));
      b[move] = 2;
      expect(checkWin(b, N, move, 2), isTrue);
    });
  });
}
