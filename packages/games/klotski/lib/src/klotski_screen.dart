import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:game_core/game_core.dart';

import 'klotski_logic.dart';

const _accent = Color(0xFFD64550); // 曹操 crimson

class KlotskiScreen extends StatefulWidget {
  const KlotskiScreen({super.key, required this.ctx});

  final GameContext ctx;

  @override
  State<KlotskiScreen> createState() => _KlotskiScreenState();
}

class _KlotskiScreenState extends State<KlotskiScreen> {
  late KlotskiBoard _board = hengDaoLiMa();
  bool _solved = false;
  int? _best;

  GameStorage get _store => widget.ctx.storage;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final stats = await _store.getJson('stats');
    final save = await _store.getJson('save');
    setState(() {
      _best = stats?['bestMoves'] as int?;
      if (save != null && save['pieces'] != null) {
        _board = KlotskiBoard.fromJson(save.cast<String, dynamic>());
        _solved = _board.isSolved;
      }
    });
  }

  void _reset() {
    setState(() {
      _board = hengDaoLiMa();
      _solved = false;
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

  void _swipe(Piece p, Offset delta) {
    if (_solved) return;
    final moved = delta.dx.abs() > delta.dy.abs()
        ? _board.move(p, 0, delta.dx > 0 ? 1 : -1)
        : _board.move(p, delta.dy > 0 ? 1 : -1, 0);
    if (!moved) return;
    if (widget.ctx.settings.hapticsOn) HapticFeedback.selectionClick();
    setState(() {});
    _afterMove();
  }

  Future<void> _afterMove() async {
    if (!_board.isSolved) {
      _persist();
      return;
    }
    setState(() => _solved = true);
    final stats = await _store.getJson('stats') ?? {};
    final prev = stats['bestMoves'] as int?;
    final best = (prev == null || _board.moves < prev) ? _board.moves : prev;
    await _store.putJson('stats', {'bestMoves': best, 'solves': (stats['solves'] as int? ?? 0) + 1});
    await _unlock('solved');
    if (_board.moves <= 100) await _unlock('under100');
    await _store.delete('save');
    setState(() => _best = best);
    if (mounted) _winDialog();
  }

  void _winDialog() {
    showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('🎉 曹操突围！'),
        content: Text('用了 ${_board.moves} 步'
            '${_best == _board.moves ? ' · 新纪录！' : ''}'),
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

  @override
  Widget build(BuildContext context) {
    final tones = Theme.of(context).extension<GameBoxTones>()!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('华容道 · 横刀立马',
            style: TextStyle(fontWeight: FontWeight.w800, color: _accent)),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _pill('步数 ${_board.moves}', tones),
                      _pill('最佳 ${_best ?? '—'}', tones),
                      GestureDetector(
                          onTap: _reset, child: _pill('🔄 重来', tones)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildBoard(tones),
                ),
                const SizedBox(height: 10),
                Text('滑动方块，让曹操从下方出口突围',
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

  Widget _buildBoard(GameBoxTones tones) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cell = constraints.maxWidth / KlotskiBoard.cols;
        final boardW = cell * KlotskiBoard.cols;
        final boardH = cell * KlotskiBoard.rows;
        const gap = 3.0;
        return Column(
          children: [
            Container(
              width: boardW,
              height: boardH,
              decoration: BoxDecoration(
                color: tones.card,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Stack(
                children: [
                  for (final p in _board.pieces)
                    AnimatedPositioned(
                      key: ValueKey(p.id),
                      duration: const Duration(milliseconds: 130),
                      curve: Curves.easeOut,
                      left: p.c * cell,
                      top: p.r * cell,
                      width: p.w * cell,
                      height: p.h * cell,
                      child: Padding(
                        padding: const EdgeInsets.all(gap),
                        child: GestureDetector(
                          onPanEnd: (d) {
                            final v = d.velocity.pixelsPerSecond;
                            if (v.distance < 80) return;
                            _swipe(p, Offset(v.dx, v.dy));
                          },
                          child: _PieceView(piece: p),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // exit marker under the bottom-centre two cells
            SizedBox(
              width: boardW,
              height: 8,
              child: Row(
                children: [
                  SizedBox(width: cell),
                  Container(
                    width: cell * 2 - 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: _accent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PieceView extends StatelessWidget {
  const _PieceView({required this.piece});

  final Piece piece;

  @override
  Widget build(BuildContext context) {
    final color = Color(piece.colorValue);
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: FittedBox(
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Text(
            piece.label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: piece.isCaoCao ? 26 : 18,
              height: 1.05,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
