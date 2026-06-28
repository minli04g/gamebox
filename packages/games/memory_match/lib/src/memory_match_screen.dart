import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:game_core/game_core.dart';

import 'memory_match_logic.dart';

const _accent = Color(0xFFEC4899);

class MemoryMatchScreen extends StatefulWidget {
  const MemoryMatchScreen({super.key, required this.ctx});

  final GameContext ctx;

  @override
  State<MemoryMatchScreen> createState() => _MemoryMatchScreenState();
}

class _MemoryMatchScreenState extends State<MemoryMatchScreen> {
  List<int> _deck = [];
  final Set<int> _up = {}; // face-up but not yet matched
  final Set<int> _matched = {};
  int? _first;
  bool _lock = false;
  bool _started = false;
  int _moves = 0;
  int _elapsed = 0;
  int? _best;
  Timer? _timer;

  GameStorage get _store => widget.ctx.storage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final stats = await _store.getJson('stats');
    if (mounted) setState(() => _best = stats?['bestMoves'] as int?);
    _newGame();
  }

  void _newGame() {
    _timer?.cancel();
    setState(() {
      _deck = buildDeck(Random());
      _up.clear();
      _matched.clear();
      _first = null;
      _lock = false;
      _started = false;
      _moves = 0;
      _elapsed = 0;
    });
  }

  void _startTimer() {
    _started = true;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed++);
    });
  }

  void _tap(int i) {
    if (_lock || _matched.contains(i) || _up.contains(i)) return;
    if (!_started) _startTimer();
    if (widget.ctx.settings.hapticsOn) HapticFeedback.selectionClick();
    setState(() => _up.add(i));

    if (_first == null) {
      _first = i;
      return;
    }

    final a = _first!;
    final b = i;
    _moves++;
    if (isMatch(_deck[a], _deck[b])) {
      setState(() {
        _matched.addAll([a, b]);
        _up.clear();
        _first = null;
      });
      if (_matched.length == 16) _win();
    } else {
      _lock = true;
      Future.delayed(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        setState(() {
          _up.clear();
          _first = null;
          _lock = false;
        });
      });
    }
  }

  Future<void> _win() async {
    _timer?.cancel();
    final stats = await _store.getJson('stats') ?? {};
    final prev = stats['bestMoves'] as int?;
    final best = (prev == null || _moves < prev) ? _moves : prev;
    await _store.putJson('stats', {
      'bestMoves': best,
      'wins': (stats['wins'] as int? ?? 0) + 1,
    });
    if (mounted) setState(() => _best = best);
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('🎉 全部配对！'),
        content: Text('用了 $_moves 步 · ${_fmt(_elapsed)}'
            '${best == _moves ? ' · 新纪录！' : ''}'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(c);
              _newGame();
            },
            child: const Text('再来一局'),
          ),
        ],
      ),
    );
  }

  String _fmt(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final tones = Theme.of(context).extension<GameBoxTones>()!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('记忆翻牌',
            style: TextStyle(fontWeight: FontWeight.w800, color: _accent)),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _pill('步数 $_moves', tones),
                      _pill('⏱ ${_fmt(_elapsed)}', tones),
                      _pill('最佳 ${_best ?? '—'}', tones),
                      GestureDetector(
                          onTap: _newGame, child: _pill('🔄 重来', tones)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                    ),
                    itemCount: 16,
                    itemBuilder: (context, i) => _card(i, tones),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pill(String t, GameBoxTones tones) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: tones.card,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(t,
            style: TextStyle(fontWeight: FontWeight.w800, color: tones.ink)),
      );

  Widget _card(int i, GameBoxTones tones) {
    final faceUp = _up.contains(i) || _matched.contains(i);
    final matched = _matched.contains(i);
    return GestureDetector(
      onTap: () => _tap(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: faceUp
              ? (matched ? _accent.withValues(alpha: 0.15) : tones.card)
              : _accent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: matched ? _accent : Colors.transparent,
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: FittedBox(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              faceUp ? kMemoryFaces[_deck[i]] : '',
              style: const TextStyle(fontSize: 34),
            ),
          ),
        ),
      ),
    );
  }
}
