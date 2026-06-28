import 'package:flutter/foundation.dart';

enum AppThemeMode { light, dark, system }

/// Immutable snapshot of global app settings. Games receive this read-only.
@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.soundOn = true,
    this.hapticsOn = true,
  });

  final AppThemeMode themeMode;
  final bool soundOn;
  final bool hapticsOn;

  AppSettings copyWith({
    AppThemeMode? themeMode,
    bool? soundOn,
    bool? hapticsOn,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      soundOn: soundOn ?? this.soundOn,
      hapticsOn: hapticsOn ?? this.hapticsOn,
    );
  }

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode.name,
        'soundOn': soundOn,
        'hapticsOn': hapticsOn,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      themeMode: AppThemeMode.values.firstWhere(
        (m) => m.name == json['themeMode'],
        orElse: () => AppThemeMode.system,
      ),
      soundOn: json['soundOn'] as bool? ?? true,
      hapticsOn: json['hapticsOn'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.themeMode == themeMode &&
      other.soundOn == soundOn &&
      other.hapticsOn == hapticsOn;

  @override
  int get hashCode => Object.hash(themeMode, soundOn, hapticsOn);
}
