import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:game_core/game_core.dart';

import 'fifteen_logic.dart';

const _accent = Color(0xFFF97316); // warm orange

class FifteenScreen extends StatefulWidget {
  const FifteenScreen({super.key, required this.ctx});

  final GameContext ctx;

  @override
  State<FifteenScreen> createState() => _FifteenScreenState();
}

class _FifteenScreenState extends State<FifteenScreen> {
  final Random _rng = Random();

  List<int> _board = solvedBoard();
  int _moves = 0;
  int? _best;
  bool _solvedShown = false;

  GameStorage get _store => widget.ctx.storage;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final best = await _store.getJson('best');
    final save = await _store.getJson('save');
    setState(() {
      _best = best?['moves'] as int?;
    });
    if (save != null && save['board'] != null) {
      final board = (save['board'] as List).map((e) => e as int).toList();
      if (board.length == kCells) {
        setState(() {
          _board = board;
          _moves = save['moves'] as int? ?? 0;
          _solvedShown = isSolved(board);
        });
        return;
      }
    }
    _newGame();
  }

  void _newGame() {
    setState(() {
      _board = generateSolvable(_rng);
      _moves = 0;
      _solvedShown = false;
    });
    _persist();
  }

  Future<void> _persist() async {
    await _store.putJson('save', {'board': _board, 'moves': _moves});
  }

  Future<void> _saveBest() async {
    if (_best == null || _moves < _best!) {
      setState(() => _best = _moves);
      await _store.putJson('best', {'moves': _moves});
    }
  }

  void _tap(int index) {
    if (_solvedShown) return;
    final board = [..._board];
    if (!tapTile(board, index)) return;
    if (widget.ctx.settings.hapticsOn) HapticFeedback.selectionClick();
    setState(() {
      _board = board;
      _moves++;
    });
    _persist();
    if (isSolved(_board)) {
      _solvedShown = true;
      _saveBest().then((_) {
        if (mounted) _showWin();
      });
    }
  }

  void _showWin() {
    showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('🎉 复原成功！'),
        content: Text('用了 $_moves 步'
            '${_best != null ? '\n最佳：$_best 步' : ''}'),
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

  @override
  Widget build(BuildContext context) {
    final tones = Theme.of(context).extension<GameBoxTones>()!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('数字华容道',
            style: TextStyle(fontWeight: FontWeight.w800, color: _accent)),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('滑动数字，从 1 到 15 排好顺序',
                      style: TextStyle(color: tones.muted, fontSize: 14)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _stat('步数', '$_moves', tones),
                      const SizedBox(width: 14),
                      _stat('最佳', _best == null ? '—' : '$_best', tones),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _grid(tones),
                  const SizedBox(height: 24),
                  _action('🔄 重新开始', _newGame, tones),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, String value, GameBoxTones tones) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: tones.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(color: tones.muted, fontSize: 12)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  color: tones.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _grid(GameBoxTones tones) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = min(constraints.maxWidth, 400.0);
        const gap = 8.0;
        final tile = (side - gap * (kSize - 1)) / kSize;
        return SizedBox(
          width: side,
          height: side,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: kCells,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: kSize,
              mainAxisSpacing: gap,
              crossAxisSpacing: gap,
            ),
            itemBuilder: (context, i) => _tile(i, tile, tones),
          ),
        );
      },
    );
  }

  Widget _tile(int index, double size, GameBoxTones tones) {
    final value = _board[index];
    if (value == 0) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: tones.muted.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
      );
    }
    return GestureDetector(
      onTap: () => _tap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: _accent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: _accent.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: FittedBox(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              '$value',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _action(String label, VoidCallback onTap, GameBoxTones tones) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: tones.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label,
            style: TextStyle(fontWeight: FontWeight.w700, color: tones.ink)),
      ),
    );
  }
}
