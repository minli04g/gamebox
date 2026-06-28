/// Pure 猜数字 (Bulls and Cows / 1A2B) logic — no Flutter, no I/O.
///
/// The secret is four DISTINCT digits 0-9 (a leading zero is allowed). A guess
/// is scored as a [Score] of (A, B), where A = digits in the correct position
/// and B = correct digits in the wrong position. Displayed as `xAyB`.
library;

import 'dart:math';

/// Number of digits in a secret / guess.
const int kCodeLength = 4;

/// The result of scoring a guess: [a] bulls and [b] cows.
class Score {
  const Score(this.a, this.b);

  /// Correct digit in the correct position.
  final int a;

  /// Correct digit in the wrong position.
  final int b;

  /// Whether this score is a full solve (all bulls).
  bool get isWin => a == kCodeLength && b == 0;

  @override
  bool operator ==(Object other) =>
      other is Score && other.a == a && other.b == b;

  @override
  int get hashCode => Object.hash(a, b);

  @override
  String toString() => '${a}A${b}B';
}

/// A secret of [kCodeLength] distinct digits 0-9 (the first digit may be 0).
List<int> generateSecret(Random rng) {
  final digits = List<int>.generate(10, (i) => i)..shuffle(rng);
  return digits.take(kCodeLength).toList();
}

/// Whether [guess] is a legal entry: exactly [kCodeLength] digits 0-9, all
/// distinct.
bool isValidGuess(List<int> guess) {
  if (guess.length != kCodeLength) return false;
  if (guess.any((d) => d < 0 || d > 9)) return false;
  return guess.toSet().length == kCodeLength;
}

/// Scores [guess] against [secret], returning bulls (A) and cows (B).
Score score(List<int> guess, List<int> secret) {
  var a = 0;
  var b = 0;
  for (var i = 0; i < guess.length; i++) {
    if (i < secret.length && guess[i] == secret[i]) {
      a++;
    } else if (secret.contains(guess[i])) {
      b++;
    }
  }
  return Score(a, b);
}
