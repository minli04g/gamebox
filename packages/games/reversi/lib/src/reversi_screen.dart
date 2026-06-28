import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:game_core/game_core.dart';

import 'reversi_logic.dart';

const _accent = Color(0xFF475569); // slate

class ReversiScreen extends StatefulWidget {
  const ReversiScreen({super.key, required this.ctx});

  final GameContext ctx;

  @override
  State<ReversiScreen> createState() => _ReversiScreenState();
}

class _ReversiScreenState extends State<ReversiScreen> {
  List<int> _board = initialBoard();
  bool _busy = false; // true while the AI is "thinking"
  bool _over = false;
  String _status = '轮到你（黑）';
  int _wins = 0;
  int _losses = 0;

  GameStorage get _store => widget.ctx.storage;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final stats = await _store.getJson('stats');
    final save = await _store.getJson('save');
    if (!mounted) return;
    setState(() {
      _wins = stats?['wins'] as int? ?? 0;
      _losses = stats?['losses'] as int? ?? 0;
      if (save != null && save['board'] is List) {
        final raw = (save['board'] as List).map((e) => e as int).toList();
        if (raw.length == kCells) {
          _board = raw;
          _over = save['over'] as bool? ?? false;
        }
      }
    });
    _syncStatus();
  }

  Future<void> _persist() async {
    await _store.putJson('save', {'board': _board, 'over': _over});
  }

  Future<void> _saveStats() async {
    await _store.putJson('stats', {'wins': _wins, 'losses': _losses});
  }

  void _haptic() {
    if (widget.ctx.settings.hapticsOn) HapticFeedback.selectionClick();
  }

  void _newGame() {
    setState(() {
      _board = initialBoard();
      _over = false;
      _busy = false;
      _status = '轮到你（黑）';
    });
    _persist();
  }

  void _syncStatus() {
    if (isGameOver(_board)) {
      _finish();
    } else if (!hasMove(_board, black)) {
      setState(() => _status = '你无棋可下，AI 继续');
      _scheduleAi();
    } else {
      setState(() => _status = '轮到你（黑）');
    }
  }

  void _onTapCell(int index) {
    if (_busy || _over) return;
    if (_board[index] != empty) return;
    if (flipsFor(_board, black, index).isEmpty) return;
    _haptic();
    setState(() {
      _board = applyMove(_board, black, index);
    });
    _persist();
    _afterHuman();
  }

  void _afterHuman() {
    if (isGameOver(_board)) {
      _finish();
      return;
    }
    if (hasMove(_board, white)) {
      setState(() => _status = 'AI 思考中…');
      _scheduleAi();
    } else {
      // AI passes; back to human.
      setState(() => _status = 'AI 无棋可下，轮到你');
    }
  }

  void _scheduleAi() {
    setState(() => _busy = true);
    Timer(const Duration(milliseconds: 450), _aiTurn);
  }

  void _aiTurn() {
    if (!mounted) return;
    final move = chooseAiMove(_board, white);
    if (move >= 0) {
      setState(() => _board = applyMove(_board, white, move));
      _haptic();
    }
    _persist();
    setState(() => _busy = false);

    if (isGameOver(_board)) {
      _finish();
      return;
    }
    if (hasMove(_board, black)) {
      setState(() => _status = '轮到你（黑）');
    } else {
      // Human passes again; AI keeps going.
      setState(() => _status = '你无棋可下，AI 继续');
      _scheduleAi();
    }
  }

  Future<void> _finish() async {
    final w = winnerOf(_board);
    setState(() {
      _over = true;
      _busy = false;
      _status = w == black
          ? '你赢了！'
          : w == white
              ? 'AI 赢了'
              : '平局';
    });
    if (w == black) {
      _wins++;
    } else if (w == white) {
      _losses++;
    }
    await _saveStats();
    await _persist();
  }

  @override
  Widget build(BuildContext context) {
    final tones = Theme.of(context).extension<GameBoxTones>()!;
    final c = counts(_board);
    final legal = (_busy || _over) ? <int>{} : legalMoves(_board, black).toSet();

    return Scaffold(
      appBar: AppBar(
        title: const Text('黑白棋',
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  _scoreBar(c.black, c.white, tones),
                  const SizedBox(height: 8),
                  Text('胜 $_wins · 负 $_losses',
                      style: TextStyle(color: tones.muted, fontSize: 13)),
                  const SizedBox(height: 14),
                  _boardView(tones, legal),
                  const SizedBox(height: 14),
                  Text(_status,
                      style: TextStyle(
                          color: tones.ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 14),
                  _newGameButton(tones),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _scoreBar(int b, int w, GameBoxTones tones) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _scoreChip('你', b, Colors.black87, tones),
        const SizedBox(width: 20),
        _scoreChip('AI', w, Colors.white, tones),
      ],
    );
  }

  Widget _scoreChip(String label, int n, Color disc, GameBoxTones tones) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: tones.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tones.muted.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: disc,
              shape: BoxShape.circle,
              border: Border.all(color: tones.muted.withValues(alpha: 0.35)),
            ),
          ),
          const SizedBox(width: 8),
          Text('$label  $n',
              style: TextStyle(
                  color: tones.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _boardView(GameBoxTones tones, Set<int> legal) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFF2F6B43), // board green
          borderRadius: BorderRadius.circular(12),
        ),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: kCells,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: kSize,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
          ),
          itemBuilder: (context, i) => _cell(i, tones, legal.contains(i)),
        ),
      ),
    );
  }

  Widget _cell(int index, GameBoxTones tones, bool isLegal) {
    final v = _board[index];
    return GestureDetector(
      onTap: () => _onTapCell(index),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF3B8456),
          borderRadius: BorderRadius.circular(3),
        ),
        alignment: Alignment.center,
        child: v == empty
            ? (isLegal
                ? Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                  )
                : const SizedBox.shrink())
            : FractionallySizedBox(
                widthFactor: 0.78,
                heightFactor: 0.78,
                child: Container(
                  decoration: BoxDecoration(
                    color: v == black ? Colors.black87 : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _newGameButton(GameBoxTones tones) {
    return GestureDetector(
      onTap: _newGame,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          color: _accent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Text('新对局',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800)),
      ),
    );
  }
}
