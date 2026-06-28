import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:game_core/game_core.dart';

import 'snake_logic.dart';

const _accent = Color(0xFF84CC16);
const _gridSize = 17;
const _tick = Duration(milliseconds: 180);

class SnakeScreen extends StatefulWidget {
  const SnakeScreen({super.key, required this.ctx});

  final GameContext ctx;

  @override
  State<SnakeScreen> createState() => _SnakeScreenState();
}

class _SnakeScreenState extends State<SnakeScreen> {
  final SnakeState _state = SnakeState(size: _gridSize);
  Timer? _timer;
  int _best = 0;
  bool _running = false;

  GameStorage get _store => widget.ctx.storage;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _restore() async {
    final stats = await _store.getJson('stats');
    if (!mounted) return;
    setState(() => _best = (stats?['best'] as int?) ?? 0);
  }

  void _start() {
    _timer?.cancel();
    setState(() {
      _state.reset();
      _running = true;
    });
    _timer = Timer.periodic(_tick, (_) => _onTick());
  }

  void _onTick() {
    if (!_running) return;
    setState(_state.step);
    if (_state.dead) {
      _running = false;
      _timer?.cancel();
      if (widget.ctx.settings.hapticsOn) HapticFeedback.heavyImpact();
      _saveBest();
    }
  }

  Future<void> _saveBest() async {
    if (_state.score > _best) {
      setState(() => _best = _state.score);
      await _store.putJson('stats', {'best': _best});
    }
  }

  void _turn(Direction d) {
    if (!_running || _state.dead) return;
    final before = _state.direction;
    _state.setDirection(d);
    if (widget.ctx.settings.hapticsOn && _state.direction != before) {
      HapticFeedback.selectionClick();
    }
  }

  void _onPanEnd(DragEndDetails d) {
    final v = d.velocity.pixelsPerSecond;
    if (v.dx.abs() < 80 && v.dy.abs() < 80) return;
    if (v.dx.abs() > v.dy.abs()) {
      _turn(v.dx > 0 ? Direction.right : Direction.left);
    } else {
      _turn(v.dy > 0 ? Direction.down : Direction.up);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tones = Theme.of(context).extension<GameBoxTones>()!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('贪吃蛇',
            style: TextStyle(fontWeight: FontWeight.w800, color: _accent)),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _pill('得分 ${_state.score}', tones),
                      _pill('最佳 $_best', tones),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AspectRatio(
                    aspectRatio: 1,
                    child: GestureDetector(
                      onPanEnd: _onPanEnd,
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: tones.card,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: CustomPaint(
                              size: Size.infinite,
                              painter: _BoardPainter(
                                state: _state,
                                tones: tones,
                              ),
                            ),
                          ),
                          if (!_running && !_state.dead) _startOverlay(tones),
                          if (_state.dead) _gameOverOverlay(tones),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('滑动屏幕控制方向',
                      style: TextStyle(color: tones.muted, fontSize: 13)),
                ],
              ),
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

  Widget _startOverlay(GameBoxTones tones) => _overlay(
        title: '贪吃蛇',
        subtitle: '滑动控制，吃豆变长',
        buttonLabel: '开始',
        tones: tones,
      );

  Widget _gameOverOverlay(GameBoxTones tones) => _overlay(
        title: '游戏结束',
        subtitle: '得分 ${_state.score}'
            '${_state.score >= _best && _state.score > 0 ? ' · 新纪录！' : ''}',
        buttonLabel: '重新开始',
        tones: tones,
      );

  Widget _overlay({
    required String title,
    required String subtitle,
    required String buttonLabel,
    required GameBoxTones tones,
  }) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tones.card.withValues(alpha: 0.86),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: tones.ink)),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: tones.muted, fontSize: 14)),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _start,
              style: FilledButton.styleFrom(backgroundColor: _accent),
              child: Text(buttonLabel,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}

class _BoardPainter extends CustomPainter {
  _BoardPainter({required this.state, required this.tones});

  final SnakeState state;
  final GameBoxTones tones;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / state.size;
    final gap = cell * 0.08;

    // Food.
    final foodPaint = Paint()..color = const Color(0xFFEF4444);
    final fr = Rect.fromLTWH(
      state.food.c * cell + gap,
      state.food.r * cell + gap,
      cell - gap * 2,
      cell - gap * 2,
    );
    canvas.drawRRect(
        RRect.fromRectAndRadius(fr, Radius.circular(cell / 2)), foodPaint);

    // Snake.
    final headPaint = Paint()..color = _accent;
    final bodyPaint = Paint()..color = _accent.withValues(alpha: 0.7);
    for (var i = 0; i < state.body.length; i++) {
      final p = state.body[i];
      final rect = Rect.fromLTWH(
        p.c * cell + gap,
        p.r * cell + gap,
        cell - gap * 2,
        cell - gap * 2,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.22)),
        i == 0 ? headPaint : bodyPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BoardPainter oldDelegate) => true;
}
