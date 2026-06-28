import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:game_core/game_core.dart';

import 'sudoku_logic.dart';

class SudokuScreen extends StatefulWidget {
  const SudokuScreen({super.key, required this.ctx});

  final GameContext ctx;

  @override
  State<SudokuScreen> createState() => _SudokuScreenState();
}

class _SudokuScreenState extends State<SudokuScreen> {
  final Random _rng = Random();

  Difficulty _difficulty = Difficulty.medium;
  List<List<int>> _givens = Sudoku.emptyGrid();
  List<List<int>> _solution = Sudoku.emptyGrid();
  List<List<int>> _grid = Sudoku.emptyGrid();
  final Map<int, Set<int>> _notes = {};
  final List<_Move> _undo = [];

  int? _selected; // r*9 + c
  bool _noteMode = false;
  bool _loading = true;
  int _elapsed = 0;
  Timer? _timer;

  GameStorage get _store => widget.ctx.storage;

  @override
  void initState() {
    super.initState();
    _restoreOrGenerate();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed++);
      if (_elapsed % 5 == 0) _persist();
    });
  }

  Future<void> _restoreOrGenerate() async {
    final save = await _store.getJson('save');
    if (save != null && save['givens'] != null) {
      setState(() {
        _difficulty = Difficulty.values.firstWhere(
          (d) => d.name == save['difficulty'],
          orElse: () => Difficulty.medium,
        );
        _givens = _grid2d(save['givens']);
        _solution = _grid2d(save['solution']);
        _grid = _grid2d(save['current']);
        _elapsed = (save['elapsed'] as int?) ?? 0;
        _notes.clear();
        final notes = (save['notes'] as Map?) ?? {};
        notes.forEach((k, v) {
          _notes[int.parse(k as String)] =
              (v as List).map((e) => e as int).toSet();
        });
        _loading = false;
      });
      _startTimer();
    } else {
      await _generate(_difficulty);
    }
  }

  Future<void> _generate(Difficulty difficulty) async {
    setState(() => _loading = true);
    _timer?.cancel();
    // Yield a frame so the spinner shows before the (CPU-heavy) generation.
    await Future<void>.delayed(const Duration(milliseconds: 16));
    final puzzle = Sudoku.generate(difficulty, _rng);
    setState(() {
      _difficulty = difficulty;
      _givens = puzzle.givens;
      _solution = puzzle.solution;
      _grid = Sudoku.copy(puzzle.givens);
      _notes.clear();
      _undo.clear();
      _selected = null;
      _elapsed = 0;
      _loading = false;
    });
    _persist();
    _startTimer();
  }

  List<List<int>> _grid2d(dynamic raw) => (raw as List)
      .map((row) => (row as List).map((v) => v as int).toList())
      .toList();

  Future<void> _persist() async {
    await _store.putJson('save', {
      'difficulty': _difficulty.name,
      'givens': _givens,
      'solution': _solution,
      'current': _grid,
      'elapsed': _elapsed,
      'notes': {
        for (final e in _notes.entries)
          if (e.value.isNotEmpty) e.key.toString(): e.value.toList(),
      },
    });
  }

  bool _isGiven(int r, int c) => _givens[r][c] != 0;

  void _selectCell(int r, int c) {
    setState(() => _selected = r * 9 + c);
  }

  void _input(int value) {
    final sel = _selected;
    if (sel == null) return;
    final r = sel ~/ 9, c = sel % 9;
    if (_isGiven(r, c)) return;

    if (_noteMode) {
      setState(() {
        final set = _notes.putIfAbsent(sel, () => <int>{});
        if (!set.add(value)) set.remove(value);
      });
      _persist();
      return;
    }

    _undo.add(_Move(sel, _grid[r][c], Set<int>.from(_notes[sel] ?? {})));
    setState(() {
      _grid[r][c] = _grid[r][c] == value ? 0 : value;
      _notes[sel]?.clear();
    });
    if (widget.ctx.settings.hapticsOn) HapticFeedback.selectionClick();
    _persist();
    _checkWin();
  }

  void _erase() {
    final sel = _selected;
    if (sel == null) return;
    final r = sel ~/ 9, c = sel % 9;
    if (_isGiven(r, c)) return;
    _undo.add(_Move(sel, _grid[r][c], Set<int>.from(_notes[sel] ?? {})));
    setState(() {
      _grid[r][c] = 0;
      _notes[sel]?.clear();
    });
    _persist();
  }

  void _undoMove() {
    if (_undo.isEmpty) return;
    final m = _undo.removeLast();
    final r = m.cell ~/ 9, c = m.cell % 9;
    setState(() {
      _grid[r][c] = m.value;
      _notes[m.cell] = m.notes;
    });
    _persist();
  }

  void _hint() {
    final sel = _selected;
    if (sel == null) return;
    final r = sel ~/ 9, c = sel % 9;
    if (_isGiven(r, c)) return;
    _undo.add(_Move(sel, _grid[r][c], Set<int>.from(_notes[sel] ?? {})));
    setState(() {
      _grid[r][c] = _solution[r][c];
      _notes[sel]?.clear();
    });
    _persist();
    _checkWin();
  }

  Future<void> _checkWin() async {
    if (!Sudoku.isComplete(_grid)) return;
    _timer?.cancel();
    // best time
    final stats = await _store.getJson('stats') ?? {};
    final perLevel = (stats['bestSeconds'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
    final prev = perLevel[_difficulty.name] as int?;
    if (prev == null || _elapsed < prev) {
      perLevel[_difficulty.name] = _elapsed;
    }
    final completions = (stats['completions'] as int? ?? 0) + 1;
    await _store.putJson('stats', {
      'bestSeconds': perLevel,
      'completions': completions,
    });
    await _unlock('first_win');
    if (_difficulty == Difficulty.hard) await _unlock('hard_win');
    await _store.delete('save');
    if (mounted) _showWin();
  }

  Future<void> _unlock(String id) async {
    final data = await _store.getJson('achievements');
    final unlocked =
        ((data?['unlocked'] as List?) ?? const []).map((e) => e as String).toSet();
    if (unlocked.add(id)) {
      await _store.putJson('achievements', {'unlocked': unlocked.toList()});
    }
  }

  void _showWin() {
    showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('🎉 完成！'),
        content: Text('用时 ${_fmt(_elapsed)} · 难度 ${_difficulty.label}'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(c);
              _generate(_difficulty);
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
    final choice = await showModalBottomSheet<Difficulty>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final d in Difficulty.values)
              ListTile(
                title: Text(d.label),
                trailing: d == _difficulty ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(c, d),
              ),
          ],
        ),
      ),
    );
    if (choice != null) _generate(choice);
  }

  @override
  Widget build(BuildContext context) {
    final tones = Theme.of(context).extension<GameBoxTones>()!;
    return Scaffold(
      appBar: AppBar(
        title: TextButton(
          onPressed: _pickDifficulty,
          child: Text('数独 · ${_difficulty.label}',
              style: const TextStyle(
                  fontWeight: FontWeight.w800, color: GameBoxColors.sudoku)),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text('⏱ ${_fmt(_elapsed)}',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: tones.muted)),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildGrid(tones),
                    const SizedBox(height: 18),
                    _buildPad(tones),
                    const SizedBox(height: 14),
                    _buildTools(tones),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildGrid(GameBoxTones tones) {
    final conflicts = Sudoku.conflicts(_grid);
    final selR = _selected == null ? -1 : _selected! ~/ 9;
    final selC = _selected == null ? -1 : _selected! % 9;
    final selVal = _selected == null ? 0 : _grid[selR][selC];

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: tones.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: GameBoxColors.sudoku, width: 2),
        ),
        padding: const EdgeInsets.all(4),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 9),
          itemCount: 81,
          itemBuilder: (context, i) {
            final r = i ~/ 9, c = i % 9;
            final v = _grid[r][c];
            final given = _isGiven(r, c);
            final isSel = i == _selected;
            final isPeer = !isSel && (r == selR || c == selC ||
                (r ~/ 3 == selR ~/ 3 && c ~/ 3 == selC ~/ 3));
            final sameVal = v != 0 && v == selVal && !isSel;
            final isConflict = conflicts.contains(i);

            Color bg = Colors.transparent;
            if (isSel) {
              bg = GameBoxColors.sudoku.withValues(alpha: 0.18);
            } else if (sameVal) {
              bg = GameBoxColors.sudoku.withValues(alpha: 0.12);
            } else if (isPeer && _selected != null) {
              bg = GameBoxColors.sudoku.withValues(alpha: 0.05);
            }

            return GestureDetector(
              onTap: () => _selectCell(r, c),
              child: Container(
                decoration: BoxDecoration(
                  color: bg,
                  border: Border(
                    right: BorderSide(
                      color: (c % 3 == 2 && c != 8)
                          ? GameBoxColors.sudoku
                          : tones.muted.withValues(alpha: 0.2),
                      width: (c % 3 == 2 && c != 8) ? 1.5 : 0.5,
                    ),
                    bottom: BorderSide(
                      color: (r % 3 == 2 && r != 8)
                          ? GameBoxColors.sudoku
                          : tones.muted.withValues(alpha: 0.2),
                      width: (r % 3 == 2 && r != 8) ? 1.5 : 0.5,
                    ),
                  ),
                ),
                alignment: Alignment.center,
                child: v != 0
                    ? Text(
                        '$v',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: given ? FontWeight.w900 : FontWeight.w600,
                          color: isConflict
                              ? Colors.red
                              : given
                                  ? tones.ink
                                  : GameBoxColors.sudoku,
                        ),
                      )
                    : _buildNotes(i, tones),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotes(int cell, GameBoxTones tones) {
    final notes = _notes[cell];
    if (notes == null || notes.isEmpty) return const SizedBox.shrink();
    return GridView.count(
      crossAxisCount: 3,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        for (var v = 1; v <= 9; v++)
          Center(
            child: Text(
              notes.contains(v) ? '$v' : '',
              style: TextStyle(fontSize: 8, color: tones.muted),
            ),
          ),
      ],
    );
  }

  Widget _buildPad(GameBoxTones tones) {
    return Row(
      children: [
        for (var n = 1; n <= 9; n++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: GestureDetector(
                onTap: () => _input(n),
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: tones.card,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text('$n',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: GameBoxColors.sudoku)),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTools(GameBoxTones tones) {
    Widget tool(IconData icon, String label, VoidCallback onTap,
        {bool active = false}) {
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 54,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              color: active
                  ? GameBoxColors.sudoku.withValues(alpha: 0.12)
                  : tones.card,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 18,
                    color: active ? GameBoxColors.sudoku : tones.ink),
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: active ? GameBoxColors.sudoku : tones.muted)),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        tool(Icons.undo, '撤销', _undoMove),
        tool(Icons.backspace_outlined, '擦除', _erase),
        tool(Icons.edit_outlined, '笔记',
            () => setState(() => _noteMode = !_noteMode),
            active: _noteMode),
        tool(Icons.lightbulb_outline, '提示', _hint),
      ],
    );
  }
}

class _Move {
  _Move(this.cell, this.value, this.notes);
  final int cell;
  final int value;
  final Set<int> notes;
}
