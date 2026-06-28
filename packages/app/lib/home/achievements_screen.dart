import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';

import '../registry.dart';
import '../state/app_providers.dart';

/// Friendly names for each game's achievement ids. Unknown ids fall back to
/// the raw id, so a game can ship achievements before they're catalogued here.
const Map<String, Map<String, String>> _catalog = {
  'sudoku': {'first_win': '首次通关', 'hard_win': '征服困难'},
  'game_2048': {'reach_2048': '拼出 2048'},
  'minesweeper': {'first_win': '首次扫雷', 'hard_win': '征服困难'},
  'klotski': {'solved': '成功突围', 'under100': '百步内通关'},
  'twenty_four': {'first': '首次凑成 24', 'no_hint': '不看提示通关'},
};

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tones = Theme.of(context).extension<GameBoxTones>()!;
    final box = ref.watch(gameBoxProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
        children: [
          Text('成就',
              style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.w900, color: tones.ink)),
          const SizedBox(height: 16),
          for (final game in registeredGames)
            _GameAchievements(
              game: game,
              storage:
                  HiveGameStorage(box: box, namespace: game.descriptor.id),
              tones: tones,
            ),
        ],
      ),
    );
  }
}

class _GameAchievements extends StatelessWidget {
  const _GameAchievements({
    required this.game,
    required this.storage,
    required this.tones,
  });

  final Game game;
  final GameStorage storage;
  final GameBoxTones tones;

  @override
  Widget build(BuildContext context) {
    final names = _catalog[game.descriptor.id] ?? const {};
    return FutureBuilder<Map<String, dynamic>?>(
      future: storage.getJson('achievements'),
      builder: (context, snap) {
        final unlocked = ((snap.data?['unlocked'] as List?) ?? const [])
            .map((e) => e as String)
            .toSet();
        if (names.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(game.descriptor.name,
                  style: TextStyle(
                      fontWeight: FontWeight.w800, color: tones.muted)),
            ),
            ...names.entries.map((e) {
              final got = unlocked.contains(e.key);
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: tones.card,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      got ? Icons.emoji_events : Icons.lock_outline,
                      color: got ? GameBoxColors.game2048 : tones.muted,
                    ),
                    const SizedBox(width: 12),
                    Text(e.value,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: got ? tones.ink : tones.muted)),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
