import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:memory_match/memory_match.dart';

void main() {
  test('deck has 16 cards with each value 0..7 exactly twice', () {
    final deck = buildDeck(Random(1));
    expect(deck.length, 16);
    for (var v = 0; v < 8; v++) {
      expect(deck.where((x) => x == v).length, 2, reason: 'value $v');
    }
  });

  test('same seed yields the same order', () {
    expect(buildDeck(Random(42)), buildDeck(Random(42)));
  });

  test('is a permutation of the canonical multiset', () {
    final sorted = buildDeck(Random(7))..sort();
    expect(sorted, [0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7]);
  });

  test('two seeds give different orderings but the same multiset', () {
    final a = buildDeck(Random(1));
    final b = buildDeck(Random(2));
    expect(a, isNot(equals(b)), reason: 'orderings should differ');
    expect(a.toList()..sort(), b.toList()..sort());
  });

  test('isMatch is true only for equal values', () {
    expect(isMatch(3, 3), isTrue);
    expect(isMatch(0, 7), isFalse);
  });

  test('there are 8 distinct face emoji', () {
    expect(kMemoryFaces.length, 8);
    expect(kMemoryFaces.toSet().length, 8);
  });
}
