import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:game_core/game_core.dart';

import 'simon_logic.dart';

const _accent = Color(0xFF9333EA);
const _padColors = [
  Color(0xFF22C55E), // green
  Color(0xFFEF4444), // red
  Color(0xFF3B82F6), // blue
  Color(0xFFEAB308), // yellow
];

enum _Phase { idle, playing, input, over }

class SimonScreen extends StatefulWidget {
  const SimonScreen({super.key, required this.ctx});

  final GameContext ctx;

  @override
  State<SimonScreen> createState() => _SimonScreenState();
}

class _SimonScreenState extends State<SimonScreen> {
  final Random _rng = Random();

  List<int> _seq = [];
  List<int> _input = [];
  _Phase _phase = _Phase.idle;
  int _lit = -1;
  int _best = 0;
  Timer? _timer;

  GameStorage get _store => widget.ctx.storage;

  @override
  void initState() {
    super.initState();
    _loadBest();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadBest() async {
    final s = await _store.getJson('stats');
    if (mounted) setState(() => _best = (s?['best'] as int?) ?? 0);
  }

  void _start() {
    _timer?.cancel();
    setState(() {
      _seq = [];
      _input = [];
    });
    _nextRound();
  }

  void _nextRound() {
    setState(() {
      _seq = extendSequence(_seq, _rng);
      _input = [];
    });
    _playback();
  }

  void _playback() {
    setState(() {
      _phase = _Phase.playing;
      _lit = -1;
    });
    var i = 0;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 650), (t) {
      if (i >= _seq.length) {
        t.cancel();
        if (mounted) {
          setState(() {
            _lit = -1;
            _phase = _Phase.input;
          });
        }
        return;
      }
      final pad = _seq[i];
      setState(() => _lit = pad);
      Future.delayed(const Duration(milliseconds: 380), () {
        if (mounted && _phase == _Phase.playing) setState(() => _lit = -1);
      });
      i++;
    });
  }

  void _tap(int pad) {
    if (_phase != _Phase.input) return;
    if (widget.ctx.settings.hapticsOn) HapticFeedback.selectionClick();
    setState(() {
      _lit = pad;
      _input = [..._input, pad];
    });
    Future.delayed(const Duration(milliseconds: 160), () {
      if (mounted && _phase == _Phase.input) setState(() => _lit = -1);
    });

    final p = checkInput(_seq, _input);
    if (!p.correct) {
      _gameOver();
      return;
    }
    if (p.complete) {
      _roundCleared();
    }
  }

  Future<void> _roundCleared() async {
    setState(() => _phase = _Phase.playing); // lock input during the pause
    if (_seq.length > _best) {
      await _store.putJson('stats', {'best': _seq.length});
      if (mounted) setState(() => _best = _seq.length);
    }
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _nextRound();
    });
  }

  void _gameOver() {
    _timer?.cancel();
    setState(() => _phase = _Phase.over);
  }

  String _statusText() => switch (_phase) {
        _Phase.idle => '记住亮起的顺序，再依次点出来',
        _Phase.playing => '看仔细…',
        _Phase.input => '轮到你了',
        _Phase.over => '结束啦！最远到第 $_best 关',
      };

  @override
  Widget build(BuildContext context) {
    final tones = Theme.of(context).extension<GameBoxTones>()!;
    final showStart = _phase == _Phase.idle || _phase == _Phase.over;
    return Scaffold(
      appBar: AppBar(
        title: const Text('记忆色块',
            style: TextStyle(fontWeight: FontWeight.w800, color: _accent)),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _pill('第 ${_seq.length} 关', tones),
                    const SizedBox(width: 12),
                    _pill('最佳 $_best', tones),
                  ],
                ),
                const SizedBox(height: 22),
                Text(_statusText(),
                    style: TextStyle(color: tones.muted, fontSize: 15)),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: GridView.count(
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      children: [for (var i = 0; i < 4; i++) _pad(i)],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (showStart)
                  FilledButton(
                    onPressed: _start,
                    style: FilledButton.styleFrom(backgroundColor: _accent),
                    child: Text(_phase == _Phase.over ? '再来一局' : '开始'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pill(String text, GameBoxTones tones) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: tones.card,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(text,
            style: TextStyle(fontWeight: FontWeight.w800, color: tones.ink)),
      );

  Widget _pad(int i) {
    final lit = _lit == i;
    final base = _padColors[i];
    return GestureDetector(
      onTap: () => _tap(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 110),
        decoration: BoxDecoration(
          color: lit ? base : base.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(18),
          boxShadow: lit
              ? [BoxShadow(color: base.withValues(alpha: 0.55), blurRadius: 18)]
              : null,
        ),
      ),
    );
  }
}
