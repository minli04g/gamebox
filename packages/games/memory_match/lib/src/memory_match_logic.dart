/// Pure 记忆翻牌 logic — no Flutter, no I/O.
library;

import 'dart:math';

/// Emoji shown on the eight pairs of card faces (index 0..7).
const List<String> kMemoryFaces = ['🍎', '🍋', '🍇', '🍓', '🍉', '🍑', '🥝', '🫐'];

/// A shuffled 4×4 deck: 16 cards holding each value 0..7 exactly twice.
List<int> buildDeck(Random rng) {
  final deck = <int>[
    for (var v = 0; v < 8; v++) ...[v, v]
  ];
  deck.shuffle(rng);
  return deck;
}

/// Two cards match when they carry the same value.
bool isMatch(int a, int b) => a == b;
