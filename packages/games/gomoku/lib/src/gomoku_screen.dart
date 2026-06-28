import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:game_core/game_core.dart';

import 'gomoku_logic.dart';

const _accent = Color(0xFF0EA5E9); // sky blue
const int _N = 11; // 11x11 board fits a phone

class GomokuScreen extends StatefulWidget {
  const GomokuScreen({super.key, required this.ctx});

  final GameContext ctx;

  @override
  State<GomokuScreen> createState() => _GomokuScreenState();
}

class _GomokuScreenState extends State<GomokuScreen> {
  List<int> _board = List<int>.filled(_N * _N, 0);
  int _last = -1;
  int _winner = 0; // 0 none, 1 human, 2 AI, 3 draw
  bool _busy = false; // true while the AI is "thinking"
  int _wins = 0;
  int _losses = 0;

  GameStorage get _store => widget.ctx.storage;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final save = await _store.getJson('save');
    final stats = await _store.getJson('stats');
    setState(() {
      if (save != null && save['board'] != null) {
        _board = (save['board'] as List).map((e) => e as int).toList();
        _last = save['last'] as int? ?? -1;
        _winner = save['winner'] as int? ?? 0;
      }
      _wins = stats?['wins'] as int? ?? 0;
      _losses = stats?['losses'] as int? ?? 0;
    });
  }

  Future<void> _persist() async {
    await _store.putJson('save', {
      'board': _board,
      'last': _last,
      'winner': _winner,
    });
  }

  Future<void> _persistStats() async {
    await _store.putJson('stats', {'wins': _wins, 'losses': _losses});
  }

  void _newGame() {
    setState(() {
      _board = List<int>.filled(_N * _N, 0);
      _last = -1;
      _winner = 0;
      _busy = false;
    });
    _persist();
  }

  void _haptic() {
    if (widget.ctx.settings.hapticsOn) HapticFeedback.selectionClick();
  }

  Future<void> _tap(int idx) async {
    if (_busy || _winner != 0 || _board[idx] != 0) return;
    _haptic();
    setState(() {
      _board[idx] = 1;
      _last = idx;
    });
    if (checkWin(_board, _N, idx, 1)) {
      setState(() {
        _winner = 1;
        _wins++;
      });
      await _persistStats();
      await _persist();
      return;
    }
    if (!_board.contains(0)) {
      setState(() => _winner = 3);
      await _persist();
      return;
    }
    await _persist();
    await _aiTurn();
  }

  Future<void> _aiTurn() async {
    setState(() => _busy = true);
    await Future<void>.delayed(const Duration(milliseconds: 220));
    final move = aiMove(_board, _N);
    if (!mounted) return;
    if (move < 0) {
      setState(() {
        _winner = 3;
        _busy = false;
      });
      await _persist();
      return;
    }
    setState(() {
      _board[move] = 2;
      _last = move;
      _busy = false;
    });
    if (checkWin(_board, _N, move, 2)) {
      setState(() {
        _winner = 2;
        _losses++;
      });
      await _persistStats();
    } else if (!_board.contains(0)) {
      setState(() => _winner = 3);
    }
    await _persist();
  }

  String get _status {
    switch (_winner) {
      case 1:
        return '🎉 你赢了！';
      case 2:
        return '🤖 AI 赢了';
      case 3:
        return '平局';
      default:
        return _busy ? 'AI 思考中…' : '轮到你了（黑子）';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tones = Theme.of(context).extension<GameBoxTones>()!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('五子棋',
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
                      Text('胜 $_wins · 负 $_losses',
                          style: TextStyle(color: tones.muted, fontSize: 14)),
                      Text(_status,
                          style: TextStyle(
                              color: tones.ink,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AspectRatio(
                    aspectRatio: 1,
                    child: _boardView(tones),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _newGame,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: _accent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text('🔄 新对局',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _boardView(GameBoxTones tones) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: tones.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tones.muted.withValues(alpha: 0.25)),
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _N,
        ),
        itemCount: _N * _N,
        itemBuilder: (context, idx) => _cellView(idx, tones),
      ),
    );
  }

  Widget _cellView(int idx, GameBoxTones tones) {
    final v = _board[idx];
    final isLast = idx == _last;
    return GestureDetector(
      onTap: () => _tap(idx),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: tones.muted.withValues(alpha: 0.18),
            width: 0.5,
          ),
        ),
        alignment: Alignment.center,
        child: v == 0
            ? const SizedBox.shrink()
            : FractionallySizedBox(
                widthFactor: 0.8,
                heightFactor: 0.8,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: v == 1 ? const Color(0xFF1B1E27) : Colors.white,
                    border: Border.all(
                      color: isLast
                          ? _accent
                          : (v == 1
                              ? Colors.black
                              : tones.muted.withValues(alpha: 0.5)),
                      width: isLast ? 2 : 1,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
