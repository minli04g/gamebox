import 'dart:math';

import 'package:bulls_cows/src/bulls_cows_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('score', () {
    test('a guess equal to the secret is 4A0B', () {
      const secret = [4, 7, 1, 9];
      expect(score(secret, secret), const Score(4, 0));
      expect(score(secret, secret).isWin, isTrue);
      expect(score(secret, secret).toString(), '4A0B');
    });

    test('secret [1,2,3,4] vs guess [1,3,2,5] is 1A2B', () {
      expect(score([1, 3, 2, 5], [1, 2, 3, 4]), const Score(1, 2));
    });

    test('no matching digits is 0A0B', () {
      expect(score([5, 6, 7, 8], [1, 2, 3, 4]), const Score(0, 0));
    });

    test('all correct digits in wrong places is 0A4B', () {
      expect(score([4, 3, 2, 1], [1, 2, 3, 4]), const Score(0, 4));
    });
  });

  group('generateSecret', () {
    test('yields four unique digits within 0..9', () {
      final rng = Random(3);
      for (var i = 0; i < 50; i++) {
        final s = generateSecret(rng);
        expect(s.length, 4);
        expect(s.every((d) => d >= 0 && d <= 9), isTrue);
        expect(s.toSet().length, 4);
      }
    });
  });

  group('isValidGuess', () {
    test('accepts four distinct digits, rejects others', () {
      expect(isValidGuess([0, 1, 2, 3]), isTrue);
      expect(isValidGuess([1, 1, 2, 3]), isFalse); // repeated digit
      expect(isValidGuess([1, 2, 3]), isFalse); // too short
      expect(isValidGuess([1, 2, 3, 4, 5]), isFalse); // too long
    });
  });
}
