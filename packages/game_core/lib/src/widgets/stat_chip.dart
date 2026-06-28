import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Small rounded label used for best-score / best-time badges.
class StatChip extends StatelessWidget {
  const StatChip({super.key, required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tones = Theme.of(context).extension<GameBoxTones>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: (color ?? GameBoxColors.brand).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: color ?? tones?.ink,
        ),
      ),
    );
  }
}
