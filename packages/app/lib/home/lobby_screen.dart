import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';
import 'package:go_router/go_router.dart';

import '../registry.dart';

/// The lobby: a grid of game cards built from the registry descriptors.
class LobbyScreen extends StatelessWidget {
  const LobbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tones = Theme.of(context).extension<GameBoxTones>()!;
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 8),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('GameBox',
                      style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: tones.ink)),
                  const SizedBox(height: 2),
                  Text('挑选一个游戏开始 · 全部离线',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: tones.muted)),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
            sliver: SliverGrid(
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.95,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  if (i < registeredGames.length) {
                    return _GameCard(
                        descriptor: registeredGames[i].descriptor, tones: tones);
                  }
                  return _ComingSoonCard(tones: tones);
                },
                childCount: registeredGames.length + 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.descriptor, required this.tones});

  final GameDescriptor descriptor;
  final GameBoxTones tones;

  @override
  Widget build(BuildContext context) {
    final accent = descriptor.accentColor != null
        ? Color(descriptor.accentColor!)
        : GameBoxColors.brand;
    return Material(
      color: tones.card,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => context.push('/game/${descriptor.id}'),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(descriptor.icon, color: Colors.white, size: 28),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(descriptor.name,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: tones.ink)),
                  const SizedBox(height: 2),
                  Text(descriptor.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: tones.muted)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComingSoonCard extends StatelessWidget {
  const _ComingSoonCard({required this.tones});

  final GameBoxTones tones;

  @override
  Widget build(BuildContext context) {
    return DottedBorderBox(
      color: tones.muted.withValues(alpha: 0.4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add, size: 30, color: tones.muted),
          const SizedBox(height: 6),
          Text('更多游戏',
              style: TextStyle(
                  fontWeight: FontWeight.w800, color: tones.muted)),
          Text('即将到来',
              style: TextStyle(fontSize: 11, color: tones.muted)),
        ],
      ),
    );
  }
}

/// A lightweight dashed-border container (avoids a third-party dependency).
class DottedBorderBox extends StatelessWidget {
  const DottedBorderBox({super.key, required this.child, required this.color});

  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRectPainter(color: color),
      child: Center(child: child),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  _DashedRectPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(24),
    );
    final path = Path()..addRRect(rrect);
    const dash = 6.0, gap = 5.0;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(
          metric.extractPath(d, d + dash),
          paint,
        );
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRectPainter old) => old.color != color;
}
