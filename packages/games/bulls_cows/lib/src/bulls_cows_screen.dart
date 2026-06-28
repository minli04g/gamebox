import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:game_core/game_core.dart';

import 'bulls_cows_logic.dart';

const _accent = Color(0xFF2563EB);

class _Guess {
  _Guess(this.digits, this.score);
  final List<int> digits;
  final Score score;
}

class BullsCowsScreen extends StatefulWidget {
  const BullsCowsScreen({super.key, required this.ctx});

  final GameContext ctx;

  @override
  State<BullsCowsScreen> createState() => _BullsCowsScreenState();
}

class _BullsCowsScreenState extends State<BullsCowsScreen> {
  final Random _rng = Random();

  List<int> _secret = [];
  List<int> _input = [];
  final List<_Guess> _history = [];
  bool _won = false;
  int? _best;

  GameStorage get _store => widget.ctx.storage;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final stats = await _store.getJson('stats');
    final save = await _store.getJson('save');
    setState(() {
      _best = stats?['best'] as int?;
      if (save != null && save['secret'] != null) {
        _secret = _ints(save['secret']);
        _input = _ints(save['input']);
        _history
          ..clear()
          ..addAll([
            for (final h in (save['history'] as List))
              _Guess(_ints(h['g']), Score(h['a'] as int, h['b'] as int))
          ]);
        _won = _history.any((h) => h.score.isWin);
      } else {
        _secret = generateSecret(_rng);
      }
    });
  }

  List<int> _ints(Object? raw) =>
      ((raw as List?) ?? const []).map((e) => e as int).toList();

  void _newGame() {
    setState(() {
      _secret = generateSecret(_rng);
      _input = [];
      _history.clear();
      _won = false;
    });
    _store.delete('save');
  }

  Future<void> _persist() async {
    await _store.putJson('save', {
      'secret': _secret,
      'input': _input,
      'history': [
        for (final h in _history)
          {'g': h.digits, 'a': h.score.a, 'b': h.score.b}
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

  void _tapDigit(int d) {
    if (_won || _input.length >= kCodeLength || _input.contains(d)) return;
    setState(() => _input = [..._input, d]);
  }

  void _backspace() {
    if (_input.isEmpty) return;
    setState(() => _input = _input.sublist(0, _input.length - 1));
  }

  Future<void> _submit() async {
    if (_won) return;
    if (!isValidGuess(_input)) {
      _toast('请输入 4 位不重复的数字');
      return;
    }
    final s = score(_input, _secret);
    if (widget.ctx.settings.hapticsOn) HapticFeedback.selectionClick();
    setState(() {
      _history.insert(0, _Guess(_input, s));
      _input = [];
    });
    if (s.isWin) {
      setState(() => _won = true);
      final stats = await _store.getJson('stats') ?? {};
      final prev = stats['best'] as int?;
      final tries = _history.length;
      final best = (prev == null || tries < prev) ? tries : prev;
      await _store.putJson('stats',
          {'best': best, 'solves': (stats['solves'] as int? ?? 0) + 1});
      await _unlock('first');
      if (tries <= 6) await _unlock('sharp');
      await _store.delete('save');
      setState(() => _best = best);
      if (mounted) _winDialog(tries);
    } else {
      _persist();
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 2),
      ));
  }

  void _winDialog(int tries) {
    showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('🎉 猜中了！'),
        content: Text('答案 ${_secret.join()} · 用了 $tries 次'
            '${_best == tries ? ' · 新纪录！' : ''}'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(c);
              _newGame();
            },
            child: const Text('重新开始'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tones = Theme.of(context).extension<GameBoxTones>()!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('猜数字',
            style: TextStyle(fontWeight: FontWeight.w800, color: _accent)),
        actions: [
          TextButton(onPressed: _newGame, child: const Text('重新开始')),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('猜 4 位不重复数字',
                          style: TextStyle(color: tones.muted, fontSize: 14)),
                      _pill('最佳 ${_best ?? '—'}', tones),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _inputRow(tones),
                const SizedBox(height: 12),
                Expanded(child: _historyList(tones)),
                _pad(tones),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pill(String t, GameBoxTones tones) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
            color: tones.card, borderRadius: BorderRadius.circular(12)),
        child: Text(t,
            style: TextStyle(fontWeight: FontWeight.w800, color: tones.ink)),
      );

  Widget _inputRow(GameBoxTones tones) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < kCodeLength; i++)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            width: 52,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tones.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: i == _input.length && !_won
                    ? _accent
                    : tones.muted.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: Text(
              i < _input.length ? '${_input[i]}' : '',
              style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.w900, color: tones.ink),
            ),
          ),
      ],
    );
  }

  Widget _historyList(GameBoxTones tones) {
    if (_history.isEmpty) {
      return Center(
        child: Text('输入一个猜测开始',
            style: TextStyle(color: tones.muted.withValues(alpha: 0.7))),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _history.length,
      itemBuilder: (context, i) {
        final h = _history[i];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(h.digits.join(),
                  style: TextStyle(
                      fontSize: 22,
                      letterSpacing: 6,
                      fontWeight: FontWeight.w700,
                      color: tones.ink)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10)),
                child: Text('${h.score.a}A${h.score.b}B',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, color: _accent)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _pad(GameBoxTones tones) {
    Widget key(String label, VoidCallback? onTap,
        {Color? bg, Color? fg, int flex = 1}) {
      return Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: bg ?? tones.card,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(label,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: fg ?? tones.ink)),
            ),
          ),
        ),
      );
    }

    Widget digit(int d) {
      final used = _input.contains(d) || _won;
      return key('$d', used ? null : () => _tapDigit(d),
          fg: used ? tones.muted.withValues(alpha: 0.35) : tones.ink);
    }

    final canSubmit = isValidGuess(_input) && !_won;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Column(
        children: [
          Row(children: [for (final d in [1, 2, 3, 4, 5]) digit(d)]),
          Row(children: [for (final d in [6, 7, 8, 9, 0]) digit(d)]),
          Row(
            children: [
              key('⌫ 删除', _input.isEmpty ? null : _backspace),
              key('确定', canSubmit ? _submit : null,
                  bg: canSubmit ? _accent : _accent.withValues(alpha: 0.3),
                  fg: Colors.white),
            ],
          ),
        ],
      ),
    );
  }
}
