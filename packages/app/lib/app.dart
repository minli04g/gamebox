import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';
import 'package:go_router/go_router.dart';

import 'home/home_shell.dart';
import 'game_host.dart';
import 'state/app_providers.dart';

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeShell(),
    ),
    GoRoute(
      path: '/game/:id',
      builder: (context, state) =>
          GameHost(gameId: state.pathParameters['id']!),
    ),
  ],
);

class GameBoxApp extends ConsumerWidget {
  const GameBoxApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return MaterialApp.router(
      title: 'GameBox',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: switch (settings.themeMode) {
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
        AppThemeMode.system => ThemeMode.system,
      },
      routerConfig: _router,
    );
  }
}
