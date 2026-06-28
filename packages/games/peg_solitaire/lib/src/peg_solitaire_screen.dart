import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:game_core/game_core.dart';

import 'peg_solitaire_logic.dart';

const _accent = Color(0xFFCA8A04);

class PegSolitaireScreen extends StatefulWidget {
  const PegSolitaireScreen({super.key, required this.ctx});

  final GameContext ctx;

  @override
  State<PegSolitaireScreen> createState() => _PegSolitaireScreenState();
}

class _PegSolitaireScreenState extends State<PegSolitaireScreen> {
  late PegBoard _board = PegBoard.initial();
  int? _selR, _selC;
  bool _ended = false;

  GameStorage get _store => widget.ctx.storage;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final save = await _store.getJson('save');
    if (save != null && save['cells'] != null) {
      setState(() {
        _board = PegBoard.fromJson(save.cast<String, dynamic>());
        _ended = !_board.hasMoves;
      });
    }
  }

  void _reset() {
    setState(() {
      _board = PegBoard.initial();
      _selR = null;
      _selC = null;
      _ended = false;
    });
    _persist();
  }

  Future<void> _persist() async => _store.putJson('save', _board.toJson());

  Future<void> _unlock(String id) async {
    final data = await _store.getJson('achievements');
    final unlocked = ((data?['unlocked'] as List?) ?? const [])
        .map((e) => e as String)
        .toSet();
    if (unlocked.add(id)) {
      await _store.putJson('achievements', {'unlocked': unlocked.toList()});
    }
  }

  void _tap(int r, int c) {
    if (_ended || !_board.valid(r, c)) return;
    final v = _board.cells[r][c];
    if (v == 1) {
      setState(() {
        _selR = r;
        _selC = c;
      });
      return;
    }
    // empty: try to jump the selected peg here
    if (_selR != null) {
      final m = _board.moveBetween(_selR!, _selC!, r, c);
      if (m != null) {
        setState(() {
          _board.apply(m);
          _selR = null;
          _selC = null;
        });
        if (widget.ctx.settings.hapticsOn) HapticFeedback.selectionClick();
        _persist();
        _afterMove();
        return;
      }
    }
    setState(() {
      _selR = null;
      _selC = null;
    });
  }

  Future<void> _afterMove() async {
    if (_board.hasMoves) return;
    setState(() => _ended = true);
    final left = _board.pegCount();
    final stats = await _store.getJson('stats') ?? {};
    final prevBest = stats['fewestLeft'] as int?;
    final best = (prevBest == null || left < prevBest) ? left : prevBest;
    await _store.putJson('stats', {'fewestLeft': best});
    if (_board.isWon) await _unlock('solo');
    if (_board.isWonCenter) await _unlock('center');
    if (mounted) {
      showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(_board.isWon ? '🎉 完美收官！' : '无路可走'),
          content: Text(_board.isWon
              ? (_board.isWonCenter ? '只剩一子，正好在天元！' : '只剩一子，漂亮！')
              : '还剩 $left 子，再来一局试试'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(c);
                _reset();
              },
              child: const Text('再来一局'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tones = Theme.of(context).extension<GameBoxTones>()!;
    final dests = <int>{};
    if (_selR != null) {
      for (final m in _board.legalMoves()) {
        if (m.fromR == _selR && m.fromC == _selC) dests.add(m.toR * 7 + m.toC);
      }
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('孔明棋',
            style: TextStyle(fontWeight: FontWeight.w800, color: _accent)),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _pill('剩 ${_board.pegCount()} 子', tones),
                      GestureDetector(
                          onTap: _reset, child: _pill('🔄 重新开始', tones)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: LayoutBuilder(
                      builder: (context, cns) {
                        return GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            mainAxisSpacing: 4,
                            crossAxisSpacing: 4,
                          ),
                          itemCount: 49,
                          itemBuilder: (context, i) {
                            final r = i ~/ 7, c = i % 7;
                            return _cell(r, c, dests.contains(i), tones);
                          },
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text('点一颗子，再点空位跳吃（隔一子跳到空处）',
                    style: TextStyle(color: tones.muted, fontSize: 13)),
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

  Widget _cell(int r, int c, bool isDest, GameBoxTones tones) {
    if (!_board.valid(r, c)) return const SizedBox.shrink();
    final v = _board.cells[r][c];
    final selected = _selR == r && _selC == c;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final holeColor = isDark ? const Color(0xFF2A2E36) : const Color(0xFFE7E3D6);
    return GestureDetector(
      onTap: () => _tap(r, c),
      child: Container(
        decoration: BoxDecoration(
          color: isDest ? _accent.withValues(alpha: 0.25) : holeColor,
          shape: BoxShape.circle,
          border: isDest ? Border.all(color: _accent, width: 2) : null,
        ),
        alignment: Alignment.center,
        child: v == 1
            ? FractionallySizedBox(
                widthFactor: 0.72,
                heightFactor: 0.72,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: selected
                          ? [const Color(0xFFFFD54F), _accent]
                          : [_accent, const Color(0xFF8A5A00)],
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                                color: _accent.withValues(alpha: 0.6),
                                blurRadius: 8)
                          ]
                        : null,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
