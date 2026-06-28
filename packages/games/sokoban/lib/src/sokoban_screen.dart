import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:game_core/game_core.dart';

import 'sokoban_logic.dart';

const _accent = Color(0xFFB45309); // amber / cardboard brown
const _boxOnTarget = Color(0xFF2BB673); // green when a box is settled

class SokobanScreen extends StatefulWidget {
  const SokobanScreen({super.key, required this.ctx});

  final GameContext ctx;

  @override
  State<SokobanScreen> createState() => _SokobanScreenState();
}

class _SokobanScreenState extends State<SokobanScreen> {
  late SokobanState _state;
  int _level = 0;
  int _highest = 0;
  Offset _drag = Offset.zero;

  GameStorage get _store => widget.ctx.storage;

  @override
  void initState() {
    super.initState();
    _state = SokobanState.parse(kSokobanLevels[0]);
    _restore();
  }

  Future<void> _restore() async {
    final save = await _store.getJson('progress');
    if (save != null) {
      final lvl = (save['level'] as int? ?? 0).clamp(0, kSokobanLevels.length - 1);
      final hi = (save['highest'] as int? ?? 0).clamp(0, kSokobanLevels.length - 1);
      setState(() {
        _highest = hi;
        _loadLevel(lvl, persist: false);
      });
    }
  }

  void _loadLevel(int i, {bool persist = true}) {
    _level = i;
    _state = SokobanState.parse(kSokobanLevels[i]);
    if (i > _highest) _highest = i;
    if (persist) _persist();
  }

  Future<void> _persist() async {
    await _store.putJson('progress', {'level': _level, 'highest': _highest});
  }

  void _move(Dir d) {
    if (_state.isSolved) return;
    if (_state.move(d)) {
      if (widget.ctx.settings.hapticsOn) HapticFeedback.selectionClick();
      setState(() {});
      if (_state.isSolved) _onSolved();
    }
  }

  void _onSolved() {
    if (widget.ctx.settings.hapticsOn) HapticFeedback.mediumImpact();
    final next = (_level + 1) % kSokobanLevels.length;
    if (next > _highest) {
      _highest = next;
      _persist();
    }
    showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('🎉 过关！'),
        content: Text('用了 ${_state.moves} 步'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(c);
              setState(() => _loadLevel(next));
            },
            child: const Text('下一关'),
          ),
        ],
      ),
    );
  }

  void _undo() => setState(() => _state.undo());
  void _reset() => setState(() => _state.reset());
  void _next() => setState(() => _loadLevel((_level + 1) % kSokobanLevels.length));

  void _onPanEnd(DragEndDetails _) {
    final dx = _drag.dx, dy = _drag.dy;
    _drag = Offset.zero;
    if (dx.abs() < 16 && dy.abs() < 16) return;
    if (dx.abs() > dy.abs()) {
      _move(dx > 0 ? Dir.right : Dir.left);
    } else {
      _move(dy > 0 ? Dir.down : Dir.up);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tones = Theme.of(context).extension<GameBoxTones>()!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('推箱子',
            style: TextStyle(fontWeight: FontWeight.w800, color: _accent)),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('第 ${_level + 1} 关 · 步数 ${_state.moves}',
                      style: TextStyle(color: tones.muted, fontSize: 14)),
                  const SizedBox(height: 16),
                  _board(tones),
                  const SizedBox(height: 24),
                  _pad(tones),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _action('↩ 撤销', _state.canUndo ? _undo : null, tones),
                      const SizedBox(width: 12),
                      _action('🔄 重来', _reset, tones),
                      const SizedBox(width: 12),
                      _action('⏭ 下一关', _next, tones),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _board(GameBoxTones tones) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final avail = constraints.maxWidth.isFinite ? constraints.maxWidth : 360.0;
        final cell = min(avail / _state.cols, 52.0);
        return GestureDetector(
          onPanStart: (_) => _drag = Offset.zero,
          onPanUpdate: (d) => _drag += d.delta,
          onPanEnd: _onPanEnd,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: tones.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: tones.muted.withValues(alpha: 0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var r = 0; r < _state.rows; r++)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var c = 0; c < _state.cols; c++)
                        _cell(Pos(r, c), cell, tones),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _cell(Pos p, double s, GameBoxTones tones) {
    final wall = _state.isWall(p);
    final target = _state.isTarget(p);
    final box = _state.isBox(p);
    final player = _state.isPlayer(p);

    Color bg = tones.card;
    Widget? child;

    if (wall) {
      bg = tones.ink.withValues(alpha: 0.85);
    } else if (box) {
      final settled = target;
      child = Container(
        decoration: BoxDecoration(
          color: settled ? _boxOnTarget : _accent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: (settled ? _boxOnTarget : _accent).withValues(alpha: 0.6),
              width: 2),
        ),
        child: Icon(
          settled ? Icons.check_rounded : Icons.inventory_2,
          color: Colors.white,
          size: s * 0.5,
        ),
      );
    } else if (player) {
      child = Container(
        decoration: BoxDecoration(
          color: target ? _boxOnTarget : _accent,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.person, color: Colors.white, size: s * 0.55),
      );
    } else if (target) {
      child = Center(
        child: Container(
          width: s * 0.28,
          height: s * 0.28,
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.35),
            shape: BoxShape.circle,
          ),
        ),
      );
    }

    return Container(
      width: s,
      height: s,
      padding: EdgeInsets.all(s * 0.06),
      child: Container(
        decoration: BoxDecoration(
          color: wall ? bg : tones.card,
          borderRadius: BorderRadius.circular(4),
        ),
        child: child,
      ),
    );
  }

  Widget _pad(GameBoxTones tones) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _arrow(Icons.keyboard_arrow_up, Dir.up, tones),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _arrow(Icons.keyboard_arrow_left, Dir.left, tones),
            const SizedBox(width: 56),
            _arrow(Icons.keyboard_arrow_right, Dir.right, tones),
          ],
        ),
        _arrow(Icons.keyboard_arrow_down, Dir.down, tones),
      ],
    );
  }

  Widget _arrow(IconData icon, Dir d, GameBoxTones tones) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: GestureDetector(
        onTap: () => _move(d),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: _accent, size: 32),
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
          border: Border.all(color: tones.muted.withValues(alpha: 0.2)),
        ),
        child: Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color:
                    disabled ? tones.muted.withValues(alpha: 0.4) : tones.ink)),
      ),
    );
  }
}
