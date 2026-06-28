import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';

import '../state/app_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tones = Theme.of(context).extension<GameBoxTones>()!;
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
        children: [
          Text('设置',
              style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.w900, color: tones.ink)),
          _section('外观', tones),
          _card(tones, [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('主题',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: tones.ink)),
                _ThemeSegment(
                  value: settings.themeMode,
                  onChanged: controller.setThemeMode,
                  tones: tones,
                ),
              ],
            ),
          ]),
          _section('声音', tones),
          _card(tones, [
            _toggleRow('音效', settings.soundOn, controller.setSound, tones),
            Divider(height: 20, color: tones.muted.withValues(alpha: 0.15)),
            _toggleRow('震动反馈', settings.hapticsOn, controller.setHaptics, tones),
          ]),
          _section('关于', tones),
          _card(tones, [
            _infoRow('版本', '1.0.0', tones),
            Divider(height: 20, color: tones.muted.withValues(alpha: 0.15)),
            _infoRow('数据与隐私', '全部存于本机', tones),
          ]),
        ],
      ),
    );
  }

  Widget _section(String t, GameBoxTones tones) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
        child: Text(t.toUpperCase(),
            style: TextStyle(
                fontSize: 12,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w800,
                color: tones.muted)),
      );

  Widget _card(GameBoxTones tones, List<Widget> children) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tones.card,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(children: children),
      );

  Widget _toggleRow(
      String label, bool value, ValueChanged<bool> onChanged, GameBoxTones tones) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(fontWeight: FontWeight.w700, color: tones.ink)),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }

  Widget _infoRow(String label, String value, GameBoxTones tones) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(fontWeight: FontWeight.w700, color: tones.ink)),
        Text(value, style: TextStyle(color: tones.muted)),
      ],
    );
  }
}

class _ThemeSegment extends StatelessWidget {
  const _ThemeSegment({
    required this.value,
    required this.onChanged,
    required this.tones,
  });

  final AppThemeMode value;
  final ValueChanged<AppThemeMode> onChanged;
  final GameBoxTones tones;

  @override
  Widget build(BuildContext context) {
    const labels = {
      AppThemeMode.light: '浅色',
      AppThemeMode.dark: '深色',
      AppThemeMode.system: '跟随',
    };
    return SegmentedButton<AppThemeMode>(
      segments: [
        for (final e in labels.entries)
          ButtonSegment(value: e.key, label: Text(e.value)),
      ],
      selected: {value},
      showSelectedIcon: false,
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}
