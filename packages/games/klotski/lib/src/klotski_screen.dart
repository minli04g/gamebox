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

  // Live drag state. The dragged piece follows the finger along one locked
  // axis, clamped to the cells it can legally reach, then snaps on release.
  double _cell = 0;
  String? _dragId;
  int _dragAxis = 0; // 0 = undecided, 1 = horizontal, 2 = vertical
  double _dragOnAxis = 0; // pixels along the locked axis (clamped)
  double _pendDx = 0, _pendDy = 0; // accumulated until the axis locks
  double _limMin = 0, _limMax = 0; // travel limits in pixels

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

  void _onPanStart(Piece p) {
    if (_solved) return;
    _dragId = p.id;
    _dragAxis = 0;
    _dragOnAxis = 0;
    _pendDx = 0;
    _pendDy = 0;
    _limMin = 0;
    _limMax = 0;
  }

  void _onPanUpdate(Piece p, DragUpdateDetails d) {
    if (_dragId != p.id || _cell == 0) return;
    if (_dragAxis == 0) {
      _pendDx += d.delta.dx;
      _pendDy += d.delta.dy;
      if (_pendDx.abs() < 4 && _pendDy.abs() < 4) return;
      if (_pendDx.abs() >= _pendDy.abs()) {
        _dragAxis = 1;
        _limMax = _board.maxSlide(p, 0, 1) * _cell;
        _limMin = -_board.maxSlide(p, 0, -1) * _cell;
        _dragOnAxis = _pendDx;
      } else {
        _dragAxis = 2;
        _limMax = _board.maxSlide(p, 1, 0) * _cell;
        _limMin = -_board.maxSlide(p, -1, 0) * _cell;
        _dragOnAxis = _pendDy;
      }
    } else {
      _dragOnAxis += _dragAxis == 1 ? d.delta.dx : d.delta.dy;
    }
    setState(() => _dragOnAxis = _dragOnAxis.clamp(_limMin, _limMax));
  }

  void _onPanEnd(Piece p, DragEndDetails d) {
    if (_dragId != p.id) return;
    final axis = _dragAxis;
    var cells = axis == 0 ? 0 : (_dragOnAxis / _cell).round();
    // Quick flick: register one cell even if the finger barely travelled.
    if (cells == 0 && axis != 0) {
      final v = axis == 1
          ? d.velocity.pixelsPerSecond.dx
          : d.velocity.pixelsPerSecond.dy;
      if (v.abs() > 250) cells = v > 0 ? 1 : -1;
    }
    final dr = axis == 2 ? (cells > 0 ? 1 : -1) : 0;
    final dc = axis == 1 ? (cells > 0 ? 1 : -1) : 0;
    var moved = 0;
    setState(() {
      if (axis != 0 && cells != 0) {
        moved = _board.slide(p, dr, dc, cells.abs());
      }
      _dragId = null;
      _dragAxis = 0;
      _dragOnAxis = 0;
      _pendDx = 0;
      _pendDy = 0;
    });
    if (moved > 0) {
      if (widget.ctx.settings.hapticsOn) HapticFeedback.selectionClick();
      _afterMove();
    }
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
        _cell = cell;
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
                    () {
                      final dragging = _dragId == p.id;
                      var left = p.c * cell, top = p.r * cell;
                      if (dragging && _dragAxis == 1) left += _dragOnAxis;
                      if (dragging && _dragAxis == 2) top += _dragOnAxis;
                      return AnimatedPositioned(
                        key: ValueKey(p.id),
                        // No animation while the finger is dragging this piece
                        // (1:1 follow); animate the snap on release.
                        duration: Duration(milliseconds: dragging ? 0 : 130),
                        curve: Curves.easeOut,
                        left: left,
                        top: top,
                        width: p.w * cell,
                        height: p.h * cell,
                        child: Padding(
                          padding: const EdgeInsets.all(gap),
                          child: GestureDetector(
                            onPanStart: (_) => _onPanStart(p),
                            onPanUpdate: (d) => _onPanUpdate(p, d),
                            onPanEnd: (d) => _onPanEnd(p, d),
                            child: _PieceView(piece: p),
                          ),
                        ),
                      );
                    }(),
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
