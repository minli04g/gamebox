import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:game_core/game_core.dart';

import 'minesweeper_logic.dart';

const _accent = Color(0xFF14B8A6); // teal

class MinesweeperScreen extends StatefulWidget {
  const MinesweeperScreen({super.key, required this.ctx});

  final GameContext ctx;

  @override
  State<MinesweeperScreen> createState() => _MinesweeperScreenState();
}

class _MinesweeperScreenState extends State<MinesweeperScreen> {
  final Random _rng = Random();

  MineDifficulty _difficulty = MineDifficulty.easy;
  late MineBoard _board = MineBoard.forDifficulty(_difficulty);
  bool _flagMode = false;
  bool _finished = false;
  int _elapsed = 0;
  Timer? _timer;

  GameStorage get _store => widget.ctx.storage;

  @override
  void initState() {
    super.initState();
    _restoreOrNew();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_finished) return;
      setState(() => _elapsed++);
      if (_elapsed % 5 == 0) _persist();
    });
  }

  Future<void> _restoreOrNew() async {
    final save = await _store.getJson('save');
    if (save != null && save['board'] != null) {
      setState(() {
        _difficulty = MineDifficulty.values.firstWhere(
          (d) => d.name == save['difficulty'],
          orElse: () => MineDifficulty.easy,
        );
        _board = MineBoard.fromJson(save['board'] as Map<String, dynamic>);
        _elapsed = (save['elapsed'] as int?) ?? 0;
        _finished = _board.exploded || _board.isWon;
      });
    } else {
      _newGame(_difficulty);
    }
    if (!_finished) _startTimer();
  }

  void _newGame(MineDifficulty d) {
    setState(() {
      _difficulty = d;
      _board = MineBoard.forDifficulty(d);
      _elapsed = 0;
      _finished = false;
      _flagMode = false;
    });
    _persist();
    _startTimer();
  }

  Future<void> _persist() async {
    await _store.putJson('save', {
      'difficulty': _difficulty.name,
      'elapsed': _elapsed,
      'board': _board.toJson(),
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

  void _onTap(int r, int c) {
    if (_finished) return;
    final cell = _board.cells[r][c];
    setState(() {
      if (_flagMode) {
        _board.toggleFlag(r, c);
      } else if (cell.revealed) {
        // Tap a revealed number to chord-open its neighbours.
        _board.chord(r, c, _rng);
      } else {
        if (cell.flagged) return;
        _board.reveal(r, c, _rng);
      }
    });
    if (widget.ctx.settings.hapticsOn) HapticFeedback.selectionClick();
    _afterMove();
  }

  void _onLongPress(int r, int c) {
    if (_finished) return;
    setState(() => _board.toggleFlag(r, c));
    if (widget.ctx.settings.hapticsOn) HapticFeedback.selectionClick();
    _persist();
  }

  Future<void> _afterMove() async {
    if (_board.exploded) {
      setState(() {
        _board.revealAllMines();
        _finished = true;
      });
      _timer?.cancel();
      await _store.delete('save');
      if (mounted) _endDialog(false);
      return;
    }
    if (_board.isWon) {
      setState(() => _finished = true);
      _timer?.cancel();
      final stats = await _store.getJson('stats') ?? {};
      final best = (stats['bestSeconds'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      final prev = best[_difficulty.name] as int?;
      if (prev == null || _elapsed < prev) best[_difficulty.name] = _elapsed;
      await _store.putJson('stats', {
        'bestSeconds': best,
        'wins': (stats['wins'] as int? ?? 0) + 1,
      });
      await _unlock('first_win');
      if (_difficulty == MineDifficulty.hard) await _unlock('hard_win');
      await _store.delete('save');
      if (mounted) _endDialog(true);
      return;
    }
    _persist();
  }

  void _endDialog(bool won) {
    showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(won ? '🎉 扫雷成功！' : '💥 踩雷了'),
        content: Text(won ? '用时 ${_fmt(_elapsed)} · ${_difficulty.label}' : '再接再厉'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(c);
              _newGame(_difficulty);
            },
            child: const Text('再来一局'),
          ),
        ],
      ),
    );
  }

  String _fmt(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  Future<void> _pickDifficulty() async {
    final choice = await showModalBottomSheet<MineDifficulty>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final d in MineDifficulty.values)
              ListTile(
                title: Text('${d.label}  ·  ${d.cols}×${d.rows} · ${d.mines}雷'),
                trailing: d == _difficulty ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(c, d),
              ),
          ],
        ),
      ),
    );
    if (choice != null) _newGame(choice);
  }

  @override
  Widget build(BuildContext context) {
    final tones = Theme.of(context).extension<GameBoxTones>()!;
    return Scaffold(
      appBar: AppBar(
        title: TextButton(
          onPressed: _pickDifficulty,
          child: Text('扫雷 · ${_difficulty.label}',
              style: const TextStyle(
                  fontWeight: FontWeight.w800, color: _accent)),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text('⏱ ${_fmt(_elapsed)}',
                  style:
                      TextStyle(fontWeight: FontWeight.w700, color: tones.muted)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _pill('🚩 ${_board.minesRemaining}', tones),
                      GestureDetector(
                        onTap: () => setState(() => _flagMode = !_flagMode),
                        child: _pill(
                          _flagMode ? '🚩 标记中' : '⛏ 挖开中',
                          tones,
                          active: _flagMode,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _newGame(_difficulty),
                        child: _pill('🔄 新局', tones),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Center(child: _buildGrid(tones)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pill(String text, GameBoxTones tones, {bool active = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: active ? _accent.withValues(alpha: 0.15) : tones.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(text,
          style: TextStyle(
              fontWeight: FontWeight.w800,
              color: active ? _accent : tones.ink)),
    );
  }

  Widget _buildGrid(GameBoxTones tones) {
    return AspectRatio(
      aspectRatio: _board.cols / _board.rows,
      child: LayoutBuilder(
        builder: (context, c) {
          return GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _board.cols,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
            ),
            itemCount: _board.rows * _board.cols,
            itemBuilder: (context, i) {
              final r = i ~/ _board.cols, cc = i % _board.cols;
              return _CellView(
                cell: _board.cells[r][cc],
                tones: tones,
                onTap: () => _onTap(r, cc),
                onLongPress: () => _onLongPress(r, cc),
              );
            },
          );
        },
      ),
    );
  }
}

class _CellView extends StatelessWidget {
  const _CellView({
    required this.cell,
    required this.tones,
    required this.onTap,
    required this.onLongPress,
  });

  final MineCell cell;
  final GameBoxTones tones;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  static const _numberColors = <int, Color>{
    1: Color(0xFF1976D2),
    2: Color(0xFF388E3C),
    3: Color(0xFFD32F2F),
    4: Color(0xFF512DA8),
    5: Color(0xFF8D6E63),
    6: Color(0xFF0097A7),
    7: Color(0xFF455A64),
    8: Color(0xFF9E9E9E),
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Widget? child;
    Color bg;

    if (!cell.revealed) {
      bg = isDark ? const Color(0xFF3A3F4A) : const Color(0xFFCBD2DD);
      if (cell.flagged) {
        child = const FittedBox(child: Text('🚩'));
      }
    } else if (cell.mine) {
      bg = const Color(0xFFE57373);
      child = const FittedBox(child: Text('💣'));
    } else {
      bg = isDark ? const Color(0xFF22262E) : const Color(0xFFEFF1F5);
      if (cell.adjacent > 0) {
        child = FittedBox(
          child: Text(
            '${cell.adjacent}',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: _numberColors[cell.adjacent],
            ),
          ),
        );
      }
    }

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(3),
        child: child,
      ),
    );
  }
}
