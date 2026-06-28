/// Pure Simon (记忆色块) logic — no Flutter, no I/O.
library;

import 'dart:math';

/// Returns a new sequence with one extra random pad (0..3) appended.
List<int> extendSequence(List<int> seq, Random rng) => [...seq, rng.nextInt(4)];

/// The state of the player's input relative to the target sequence.
class SimonProgress {
  const SimonProgress({required this.correct, required this.complete});

  /// Whether [input] is a valid prefix of the target so far.
  final bool correct;

  /// Whether [input] reproduces the entire target.
  final bool complete;
}

/// Checks the player's [input] against the [target] sequence.
SimonProgress checkInput(List<int> target, List<int> input) {
  if (input.length > target.length) {
    return const SimonProgress(correct: false, complete: false);
  }
  for (var i = 0; i < input.length; i++) {
    if (input[i] != target[i]) {
      return const SimonProgress(correct: false, complete: false);
    }
  }
  return SimonProgress(correct: true, complete: input.length == target.length);
}
