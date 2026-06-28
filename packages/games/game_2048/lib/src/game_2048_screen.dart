import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:game_core/game_core.dart';

import 'board_2048.dart';

class Game2048Screen extends StatefulWidget {
  const Game2048Screen({super.key, required this.ctx});

  final GameContext ctx;

  @override
  State<Game2048Screen> createState() => _Game2048ScreenState();
}

class _Game2048ScreenState extends State<Game2048Screen> {
  final Random _rng = Random();
  List<List<int>> _board = Board2048.empty();
  int _score = 0;
  int _best = 0;
  bool _won = false;
  Offset _drag = Offset.zero;

  GameStorage get _store => widget.ctx.storage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stats = await _store.getJson('stats');
    final save = await _store.getJson('save');
    setState(() {
      _best = (stats?['best'] as int?) ?? 0;
      if (save != null && save['board'] != null) {
        _board = (save['board'] as List)
            .map((row) => (row as List).map((v) => v as int).toList())
            .toList();
        _score = (save['score'] as int?) ?? 0;
        _won = Board2048.hasReached(_board, 2048);
      } else {
        _board = Board2048.newGame(_rng);
      }
    });
  }

  Future<void> _persist() async {
    await _store.putJson('save', {'board': _board, 'score': _score});
    if (_score > _best) {
      _best = _score;
      await _store.putJson('stats', {'best': _best});
    }
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

  void _newGame() {
    setState(() {
      _board = Board2048.newGame(_rng);
      _score = 0;
      _won = false;
    });
    _persist();
  }

  void _swipe(SwipeDir dir) {
    final result = Board2048.move(_board, dir);
    if (!result.moved) return;
    if (widget.ctx.settings.hapticsOn) HapticFeedback.selectionClick();
    setState(() {
      _board = Board2048.spawn(result.board, _rng);
      _score += result.gained;
      if (!_won && Board2048.hasReached(_board, 2048)) {
        _won = true;
        _unlock('reach_2048');
        _showWonDialog();
      }
    });
    _persist();
    if (Board2048.isGameOver(_board)) _showGameOver();
  }

  void _showWonDialog() {
    showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('🎉 2048!'),
        content: const Text('你拼出了 2048，可以继续挑战更高分。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('继续'),
          ),
        ],
      ),
    );
  }

  void _showGameOver() {
    showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('游戏结束'),
        content: Text('本局得分 $_score'),
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
        title: const Text('2048',
            style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            tooltip: '新游戏',
            onPressed: _newGame,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
              Row(
                children: [
                  _scoreBox('分数', _score, tones),
                  const SizedBox(width: 12),
                  _scoreBox('最高', _best, tones),
                ],
              ),
              const SizedBox(height: 18),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: GestureDetector(
                      onPanStart: (_) => _drag = Offset.zero,
                      onPanUpdate: (d) => _drag += d.delta,
                      onPanEnd: (_) {
                        const threshold = 16.0;
                        if (_drag.distance < threshold) return;
                        if (_drag.dx.abs() > _drag.dy.abs()) {
                          _swipe(_drag.dx > 0 ? SwipeDir.right : SwipeDir.left);
                        } else {
                          _swipe(_drag.dy > 0 ? SwipeDir.down : SwipeDir.up);
                        }
                      },
                      child: _BoardView(board: _board),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('滑动合并相同数字，凑出 2048',
                  style: TextStyle(color: tones.muted, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _scoreBox(String label, int value, GameBoxTones tones) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: tones.card,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w800,
                    color: tones.muted)),
            Text('$value',
                style: TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w800, color: tones.ink)),
          ],
        ),
      ),
    );
  }
}

class _BoardView extends StatelessWidget {
  const _BoardView({required this.board});

  final List<List<int>> board;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFBBADA0),
        borderRadius: BorderRadius.circular(22),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          const n = Board2048.size;
          const gap = 12.0;
          final cell = (c.maxWidth - gap * (n - 1)) / n;
          return Stack(
            children: [
              for (var y = 0; y < n; y++)
                for (var x = 0; x < n; x++)
                  Positioned(
                    left: x * (cell + gap),
                    top: y * (cell + gap),
                    width: cell,
                    height: cell,
                    child: _Tile(value: board[y][x], size: cell),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.value, required this.size});

  final int value;
  final double size;

  static const _bg = <int, Color>{
    0: Color(0xFFCDC1B4),
    2: Color(0xFFEEE4DA),
    4: Color(0xFFEDE0C8),
    8: Color(0xFFF2B179),
    16: Color(0xFFF59563),
    32: Color(0xFFF67C5F),
    64: Color(0xFFF65E3B),
    128: Color(0xFFEDCF72),
    256: Color(0xFFEDCC61),
    512: Color(0xFFEDC850),
    1024: Color(0xFFEDC53F),
    2048: Color(0xFFEDC22E),
  };

  @override
  Widget build(BuildContext context) {
    final color = _bg[value] ?? const Color(0xFF3C3A32);
    final light = value > 4;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 90),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: value == 0
          ? null
          : FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  '$value',
                  style: TextStyle(
                    fontSize: size * 0.38,
                    fontWeight: FontWeight.w800,
                    color: light ? Colors.white : const Color(0xFF776E65),
                  ),
                ),
              ),
            ),
    );
  }
}
