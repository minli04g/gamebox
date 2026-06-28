import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:game_core/game_core.dart';

import 'twenty_four_logic.dart';

const _accent = Color(0xFF2E9E5B); // fresh green

class _Card {
  _Card(this.id, this.value, this.expr);
  final String id;
  final Frac value;
  final String expr;
  _Card copy() => _Card(id, value, expr);
}

class TwentyFourScreen extends StatefulWidget {
  const TwentyFourScreen({super.key, required this.ctx});

  final GameContext ctx;

  @override
  State<TwentyFourScreen> createState() => _TwentyFourScreenState();
}

class _TwentyFourScreenState extends State<TwentyFourScreen> {
  final Random _rng = Random();

  List<int> _origin = [];
  List<_Card> _cards = [];
  String? _selId;
  String? _op;
  final List<List<_Card>> _history = [];
  bool _usedHint = false;
  int _idc = 0;

  GameStorage get _store => widget.ctx.storage;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final save = await _store.getJson('save');
    if (save != null && save['origin'] != null) {
      setState(() {
        _origin = (save['origin'] as List).map((e) => e as int).toList();
        _usedHint = save['usedHint'] as bool? ?? false;
        _cards = [
          for (final c in (save['cards'] as List))
            _Card(c['id'] as String, Frac((c['n'] as int), (c['d'] as int)),
                c['expr'] as String)
        ];
        _idc = save['idc'] as int? ?? _cards.length;
      });
    } else {
      _newGame();
    }
  }

  void _newGame() {
    _origin = generateSolvable(_rng);
    _usedHint = false;
    _resetToOrigin();
  }

  void _resetToOrigin() {
    setState(() {
      _idc = 0;
      _history.clear();
      _selId = null;
      _op = null;
      _cards = [
        for (final v in _origin) _Card('c${_idc++}', Frac.whole(v), '$v')
      ];
    });
    _persist();
  }

  Future<void> _persist() async {
    await _store.putJson('save', {
      'origin': _origin,
      'usedHint': _usedHint,
      'idc': _idc,
      'cards': [
        for (final c in _cards)
          {'id': c.id, 'n': c.value.n, 'd': c.value.d, 'expr': c.expr}
      ],
    });
  }

  Future<void> _unlock(String id) async {
    final data = await _store.getJson('achievements');
    final unlocked = ((data?['unlocked'] as List?) ?? const [])
        .map((e) => e as String)
        .toSet();
    if (unlocked.add(id)) {
      await _store.putJson('achievements', {'unlocked': unlocked.toList()});
    }
  }

  void _tapCard(_Card c) {
    if (_selId == c.id) {
      setState(() => _selId = null);
      return;
    }
    if (_selId == null || _op == null) {
      setState(() => _selId = c.id);
      return;
    }
    _combine(_selId!, _op!, c.id);
  }

  void _tapOp(String op) {
    if (_selId == null) {
      _toast('先选一张牌，再选运算符');
      return;
    }
    setState(() => _op = op);
  }

  void _combine(String aId, String op, String bId) {
    final a = _cards.firstWhere((c) => c.id == aId);
    final b = _cards.firstWhere((c) => c.id == bId);
    final r = applyOp(a.value, b.value, op);
    if (r == null) {
      _toast('不能除以 0');
      setState(() => _op = null);
      return;
    }
    _history.add([for (final c in _cards) c.copy()]);
    final card = _Card('c${_idc++}', r, '(${a.expr} $op ${b.expr})');
    setState(() {
      _cards = [
        for (final c in _cards)
          if (c.id != aId && c.id != bId) c,
        card,
      ];
      _selId = null;
      _op = null;
    });
    if (widget.ctx.settings.hapticsOn) HapticFeedback.selectionClick();
    _persist();
    if (_cards.length == 1) _check();
  }

  void _undo() {
    if (_history.isEmpty) return;
    setState(() {
      _cards = _history.removeLast();
      _selId = null;
      _op = null;
    });
    _persist();
  }

  Future<void> _check() async {
    final last = _cards.single;
    if (last.value.is24) {
      final stats = await _store.getJson('stats') ?? {};
      await _store.putJson('stats', {
        'solves': (stats['solves'] as int? ?? 0) + 1,
      });
      await _unlock('first');
      if (!_usedHint) await _unlock('no_hint');
      if (mounted) {
        showDialog<void>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('🎉 凑成 24！'),
            content: Text(_strip(last.expr)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(c);
                  _newGame();
                },
                child: const Text('换一组'),
              ),
            ],
          ),
        );
      }
    } else {
      _toast('得到 ${last.value.display}，没凑成 24', action: '撤销', onAction: _undo);
    }
  }

  String _strip(String s) =>
      (s.startsWith('(') && s.endsWith(')')) ? s.substring(1, s.length - 1) : s;

  void _toast(String msg, {String? action, VoidCallback? onAction}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 2),
        action: action != null
            ? SnackBarAction(label: action, onPressed: onAction ?? () {})
            : null,
      ));
  }

  Future<void> _hint() async {
    _usedHint = true;
    _persist();
    final sol = solve24(_origin);
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('提示'),
        content: Text(sol == null ? '这组无解' : '一种解法：\n${_strip(sol)} = 24'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('知道了')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tones = Theme.of(context).extension<GameBoxTones>()!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('24点',
            style: TextStyle(fontWeight: FontWeight.w800, color: _accent)),
        actions: [
          TextButton(onPressed: _hint, child: const Text('提示')),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('用 + − × ÷ 把四个数凑成 24',
                    style: TextStyle(color: tones.muted, fontSize: 14)),
                const SizedBox(height: 28),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 14,
                  runSpacing: 14,
                  children: [for (final c in _cards) _cardView(c, tones)],
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [for (final op in kOps) _opButton(op, tones)],
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _action('↩ 撤销', _history.isEmpty ? null : _undo, tones),
                    const SizedBox(width: 12),
                    _action('🔄 重来', _resetToOrigin, tones),
                    const SizedBox(width: 12),
                    _action('🎲 换一组', _newGame, tones),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cardView(_Card c, GameBoxTones tones) {
    final selected = _selId == c.id;
    return GestureDetector(
      onTap: () => _tapCard(c),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 74,
        height: 100,
        decoration: BoxDecoration(
          color: selected ? _accent : tones.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? _accent : tones.muted.withValues(alpha: 0.25),
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: FittedBox(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              c.value.display,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: selected ? Colors.white : tones.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _opButton(String op, GameBoxTones tones) {
    final active = _op == op;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: () => _tapOp(op),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: active ? _accent : _accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text(op,
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: active ? Colors.white : _accent)),
        ),
      ),
    );
  }

  Widget _action(String label, VoidCallback? onTap, GameBoxTones tones) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: tones.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: disabled ? tones.muted.withValues(alpha: 0.4) : tones.ink)),
      ),
    );
  }
}
