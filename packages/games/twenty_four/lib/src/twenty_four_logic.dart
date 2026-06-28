/// Pure 24点 logic — exact rational arithmetic so division never loses
/// precision (e.g. 8 ÷ (3 − 8 ÷ 3) = 24), plus a recursive solver used both to
/// generate guaranteed-solvable puzzles and to reveal a solution.
library;

import 'dart:math';

class Frac {
  const Frac._(this.n, this.d);

  final int n;
  final int d;

  factory Frac(int n, int d) {
    if (d == 0) throw ArgumentError('denominator must not be 0');
    var nn = n, dd = d;
    if (dd < 0) {
      nn = -nn;
      dd = -dd;
    }
    final g = _gcd(nn.abs(), dd);
    if (g > 1) {
      nn ~/= g;
      dd ~/= g;
    }
    return Frac._(nn, dd);
  }

  factory Frac.whole(int v) => Frac(v, 1);

  static int _gcd(int a, int b) {
    while (b != 0) {
      final t = a % b;
      a = b;
      b = t;
    }
    return a;
  }

  Frac operator +(Frac o) => Frac(n * o.d + o.n * d, d * o.d);
  Frac operator -(Frac o) => Frac(n * o.d - o.n * d, d * o.d);
  Frac operator *(Frac o) => Frac(n * o.n, d * o.d);
  Frac? operator /(Frac o) => o.n == 0 ? null : Frac(n * o.d, d * o.n);

  bool get isInt => d == 1;
  bool get is24 => d == 1 && n == 24;
  String get display => d == 1 ? '$n' : '$n/$d';
}

/// The four operators, in display order.
const List<String> kOps = ['+', '−', '×', '÷'];

Frac? applyOp(Frac a, Frac b, String op) => switch (op) {
      '+' => a + b,
      '−' => a - b,
      '×' => a * b,
      '÷' => a / b,
      _ => null,
    };

bool _can(List<Frac> xs) {
  if (xs.length == 1) return xs[0].is24;
  for (var i = 0; i < xs.length; i++) {
    for (var j = 0; j < xs.length; j++) {
      if (i == j) continue;
      final a = xs[i], b = xs[j];
      final rest = [
        for (var k = 0; k < xs.length; k++)
          if (k != i && k != j) xs[k]
      ];
      for (final op in kOps) {
        final r = applyOp(a, b, op);
        if (r != null && _can([...rest, r])) return true;
      }
    }
  }
  return false;
}

/// Whether 24 can be made from [nums] using + − × ÷ and grouping.
bool canMake24(List<int> nums) =>
    _can([for (final n in nums) Frac.whole(n)]);

class _Expr {
  _Expr(this.v, this.s);
  final Frac v;
  final String s;
}

_Expr? _solve(List<_Expr> xs) {
  if (xs.length == 1) return xs[0].v.is24 ? xs[0] : null;
  for (var i = 0; i < xs.length; i++) {
    for (var j = 0; j < xs.length; j++) {
      if (i == j) continue;
      final a = xs[i], b = xs[j];
      final rest = [
        for (var k = 0; k < xs.length; k++)
          if (k != i && k != j) xs[k]
      ];
      for (final op in kOps) {
        final r = applyOp(a.v, b.v, op);
        if (r == null) continue;
        final res = _solve([...rest, _Expr(r, '(${a.s} $op ${b.s})')]);
        if (res != null) return res;
      }
    }
  }
  return null;
}

/// A worked solution expression for [nums], or null if 24 is impossible.
/// The outer parentheses are stripped for readability.
String? solve24(List<int> nums) {
  final r = _solve([for (final n in nums) _Expr(Frac.whole(n), '$n')]);
  if (r == null) return null;
  var s = r.s;
  if (s.startsWith('(') && s.endsWith(')')) s = s.substring(1, s.length - 1);
  return s;
}

/// Four random cards (1..[maxCard]) that are guaranteed to make 24.
List<int> generateSolvable(Random rng, {int maxCard = 13}) {
  while (true) {
    final nums = [for (var i = 0; i < 4; i++) 1 + rng.nextInt(maxCard)];
    if (canMake24(nums)) return nums;
  }
}
