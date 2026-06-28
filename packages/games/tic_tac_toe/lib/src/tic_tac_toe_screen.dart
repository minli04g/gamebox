import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:game_core/game_core.dart';

import 'tic_tac_toe_logic.dart';

const _accent = Color(0xFF7C5CFC);

class TicTacToeScreen extends StatefulWidget {
  const TicTacToeScreen({super.key, required this.ctx});

  final GameContext ctx;

  @override
  State<TicTacToeScreen> createState() => _TicTacToeScreenState();
}

class _TicTacToeScreenState extends State<TicTacToeScreen> {
  List<int> _board = List<int>.filled(9, 0);
  int _result = 0; // 0 ongoing, 1/2 winner, 3 draw
  bool _lock = false;
  Map<String, int> _record = {'wins': 0, 'losses': 0, 'draws': 0};

  GameStorage get _store => widget.ctx.storage;

  @override
  void initState() {
    super.initState();
    _store.getJson('record').then((r) {
      if (r != null && mounted) {
        setState(() => _record = r.map((k, v) => MapEntry(k, v as int)));
      }
    });
  }

  void _reset() => setState(() {
        _board = List<int>.filled(9, 0);
        _result = 0;
        _lock = false;
      });

  Future<void> _tap(int i) async {
    if (_lock || _board[i] != 0 || _result != 0) return;
    setState(() => _board[i] = 1);
    if (widget.ctx.settings.hapticsOn) HapticFeedback.selectionClick();
    if (_finish()) return;
    setState(() => _lock = true);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    final ai = bestMove(_board, 2);
    if (ai >= 0) setState(() => _board[ai] = 2);
    setState(() => _lock = false);
    _finish();
  }

  bool _finish() {
    final w = winner(_board);
    if (w == 0) return false;
    setState(() => _result = w);
    final key = w == 1 ? 'wins' : (w == 2 ? 'losses' : 'draws');
    _record[key] = (_record[key] ?? 0) + 1;
    _store.putJson('record', _record);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final tones = Theme.of(context).extension<GameBoxTones>()!;
    final status = switch (_result) {
      1 => '🎉 你赢了！',
      2 => '🤖 AI 赢了',
      3 => '平局',
      _ => _lock ? 'AI 思考中…' : '你的回合 (X)',
    };
    return Scaffold(
      appBar: AppBar(
        title: const Text('井字棋',
            style: TextStyle(fontWeight: FontWeight.w800, color: _accent)),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(status,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: tones.ink)),
                const SizedBox(height: 6),
                Text('胜 ${_record['wins']} · 负 ${_record['losses']} · 平 ${_record['draws']}',
                    style: TextStyle(color: tones.muted)),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    children: [
                      for (var i = 0; i < 9; i++) _cell(i, tones),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _reset,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    decoration: BoxDecoration(
                        color: _accent, borderRadius: BorderRadius.circular(14)),
                    child: const Text('重新开始',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cell(int i, GameBoxTones tones) {
    final v = _board[i];
    return GestureDetector(
      onTap: () => _tap(i),
      child: Container(
        decoration: BoxDecoration(
          color: tones.card,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: FittedBox(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              v == 1 ? '✕' : (v == 2 ? '◯' : ''),
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: v == 1 ? _accent : const Color(0xFFE05252),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
