import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:twenty_four/src/twenty_four_logic.dart';

void main() {
  group('Frac', () {
    test('reduces and normalises sign', () {
      expect(Frac(2, 4).display, '1/2');
      expect(Frac(6, 3).display, '2');
      expect(Frac(1, -2).display, '-1/2');
    });

    test('division by zero yields null', () {
      expect(Frac.whole(3) / Frac.whole(0), isNull);
    });

    test('exact fraction arithmetic', () {
      // 3 - 8/3 = 1/3 ; 8 / (1/3) = 24
      final inner = Frac.whole(3) - (Frac.whole(8) / Frac.whole(3))!;
      expect(inner.display, '1/3');
      final result = Frac.whole(8) / inner;
      expect(result!.is24, isTrue);
    });
  });

  group('canMake24', () {
    test('simple solvable set', () {
      expect(canMake24([4, 4, 4, 4]), isTrue); // 4*4+4+4
    });

    test('fraction-only solution is found', () {
      expect(canMake24([3, 3, 8, 8]), isTrue); // 8/(3-8/3)
      expect(canMake24([1, 5, 5, 5]), isTrue); // 5*(5-1/5)
    });

    test('impossible set', () {
      expect(canMake24([1, 1, 1, 1]), isFalse);
    });
  });

  group('solve24', () {
    test('returns an expression for solvable sets, null otherwise', () {
      expect(solve24([3, 3, 8, 8]), isNotNull);
      expect(solve24([1, 1, 1, 1]), isNull);
    });
  });

  group('generateSolvable', () {
    test('always returns a solvable set of four cards', () {
      final rng = Random(7);
      for (var i = 0; i < 30; i++) {
        final nums = generateSolvable(rng);
        expect(nums.length, 4);
        expect(nums.every((n) => n >= 1 && n <= 13), isTrue);
        expect(canMake24(nums), isTrue);
      }
    });
  });
}
