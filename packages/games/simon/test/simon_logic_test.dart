import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:simon/src/simon_logic.dart';

void main() {
  group('extendSequence', () {
    test('appends exactly one pad in range 0..3 and keeps the prefix', () {
      final rng = Random(1);
      var seq = <int>[];
      for (var i = 0; i < 50; i++) {
        final next = extendSequence(seq, rng);
        expect(next.length, seq.length + 1);
        expect(next.last, inInclusiveRange(0, 3));
        expect(next.sublist(0, seq.length), seq);
        seq = next;
      }
    });
  });

  group('checkInput', () {
    final target = [0, 2, 1, 3];

    test('accepts a correct partial input', () {
      final p = checkInput(target, [0, 2]);
      expect(p.correct, isTrue);
      expect(p.complete, isFalse);
    });

    test('accepts a correct complete input', () {
      final p = checkInput(target, [0, 2, 1, 3]);
      expect(p.correct, isTrue);
      expect(p.complete, isTrue);
    });

    test('rejects a wrong input', () {
      final p = checkInput(target, [0, 1]);
      expect(p.correct, isFalse);
      expect(p.complete, isFalse);
    });

    test('rejects input longer than the target', () {
      final p = checkInput(target, [0, 2, 1, 3, 0]);
      expect(p.correct, isFalse);
    });

    test('empty input is a valid (incomplete) prefix', () {
      final p = checkInput(target, []);
      expect(p.correct, isTrue);
      expect(p.complete, isFalse);
    });
  });
}
