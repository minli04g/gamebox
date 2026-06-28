# GameBox 游戏盒子

A personal, **offline**, cross-platform (iOS + Android) game collection built with Flutter.
Ships with **Sudoku** and **2048**, and is architected so adding a new game costs a new
module plus one registration line.

## Architecture

Melos multi-package monorepo. Dependency direction is strictly one-way:
`app → games → game_core`. Games never see each other.

```
packages/
  game_core/        # Game contract, GameStorage (Hive), settings, theme
  games/
    sudoku/         # depends only on game_core
    game_2048/      # depends only on game_core
  app/              # shell: registry, lobby, settings, router (depends on all)
```

- **Contract** — every game implements `Game` (a `GameDescriptor` + `buildGameScreen`).
- **Storage** — the shell hands each game a `GameStorage` pre-namespaced to its id, so
  cross-game access and key collisions are impossible. Hive-backed, JSON values.
- **State** — Riverpod for global settings; each game manages its own internal state.
- **Routing** — go_router, routes derived from the registry.

See `docs/superpowers/specs/2026-06-28-game-collection-design.md` for the full design.

## Develop

```bash
dart pub global activate melos
melos bootstrap          # pub get across all packages
melos run test           # unit + widget tests
cd packages/app
flutter run              # run on a connected device/emulator
```

> First-time setup in mainland China uses the official mirror:
> `FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn`,
> `PUB_HOSTED_URL=https://pub.flutter-io.cn`.

## Adding a game

1. Create `packages/games/<name>/`, depending only on `game_core`.
2. Implement `class <Name>Game implements Game`.
3. Read/write `save` / `stats` / `achievements` via `ctx.storage`.
4. Add one line to `registeredGames` in `packages/app/lib/registry.dart`.

## iOS / TestFlight

iOS is built in GitHub Actions on a `macos-latest` runner (see `.github/workflows/ios.yml`)
with fastlane (`match` + `upload_to_testflight`). The app is fully offline; no backend.
