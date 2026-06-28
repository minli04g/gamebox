import 'package:flutter/material.dart';

/// GameBox palette, mirrored from the Claude Design mockup.
class GameBoxColors {
  GameBoxColors._();

  static const brand = Color(0xFF5B6CFF);
  static const sudoku = Color(0xFF4F46E5);
  static const game2048 = Color(0xFFF2A03D);
  static const success = Color(0xFF2BB673);

  // Light surfaces.
  static const lightBg = Color(0xFFF4F5F7);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightInk = Color(0xFF1B1E27);
  static const lightMuted = Color(0xFF707684);
  static const lightLine = Color(0xFFE7E9EF);

  // Dark surfaces.
  static const darkBg = Color(0xFF12141A);
  static const darkCard = Color(0xFF1B1E27);
  static const darkInk = Color(0xFFF2F3F7);
  static const darkMuted = Color(0xFF9AA0AD);
  static const darkLine = Color(0xFF2A2E38);
}

class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? GameBoxColors.darkBg : GameBoxColors.lightBg;
    final card = isDark ? GameBoxColors.darkCard : GameBoxColors.lightCard;
    final ink = isDark ? GameBoxColors.darkInk : GameBoxColors.lightInk;
    final muted = isDark ? GameBoxColors.darkMuted : GameBoxColors.lightMuted;

    final scheme = ColorScheme.fromSeed(
      seedColor: GameBoxColors.brand,
      brightness: brightness,
    ).copyWith(
      surface: bg,
      primary: GameBoxColors.brand,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
    );

    return base.copyWith(
      cardColor: card,
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: true,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: ink,
        displayColor: ink,
      ),
      extensions: <ThemeExtension<dynamic>>[
        GameBoxTones(card: card, ink: ink, muted: muted),
      ],
    );
  }
}

/// Extra tonal colors not covered by [ColorScheme], available via
/// `Theme.of(context).extension<GameBoxTones>()`.
@immutable
class GameBoxTones extends ThemeExtension<GameBoxTones> {
  const GameBoxTones({
    required this.card,
    required this.ink,
    required this.muted,
  });

  final Color card;
  final Color ink;
  final Color muted;

  @override
  GameBoxTones copyWith({Color? card, Color? ink, Color? muted}) =>
      GameBoxTones(
        card: card ?? this.card,
        ink: ink ?? this.ink,
        muted: muted ?? this.muted,
      );

  @override
  GameBoxTones lerp(ThemeExtension<GameBoxTones>? other, double t) {
    if (other is! GameBoxTones) return this;
    return GameBoxTones(
      card: Color.lerp(card, other.card, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
    );
  }
}
