# GameBox — Personal Game Collection · Design Spec

Date: 2026-06-28
Status: Approved (architecture sections 1–5)
UI mockup: Claude Design project `1e711a1f-e5ba-4b8b-9de2-71f368f0f428` (GameBox Screens.html)

## 1. Goal & Scope

A personal, cross-platform (iOS + Android) game collection app with **no server / fully
offline**. Ships with two games — **Sudoku** and **2048** — and is architected so adding
future games costs a new module + one registration line, touching no existing game.

### MVP requirements (self-defined)

- **Lobby/home**: grid of game cards, driven by a registry (icon, name, blurb, tags).
- **Games**: Sudoku (9×9, difficulty levels, validation, hints) and 2048 (4×4 swipe-merge).
- **Per-game persistence** (all local):
  - Save / continue (resume an unfinished game on relaunch)
  - High scores / stats (2048 best score; Sudoku best times, completions)
  - Achievements / unlocks (basic, per-game defined)
- **Global settings**: theme (light / dark / system), sound on/off.
- **Cross-platform**: one Dart codebase → iOS + Android, pixel-consistent.
- Non-goals (YAGNI): accounts, cloud sync, multiplayer, ads, in-app purchase,
  dynamic/hot-loaded game plugins.

### Identity

- App name: **GameBox** (游戏盒子)
- Bundle / application id: `top.fancytech.gamebox`
- Apple Team: `C9DKTHSYYB` (reuses fancytech signing assets)

## 2. Tech Stack

- **Flutter (stable)** — Skia self-drawn UI is ideal for grid/animation/gesture puzzle
  games; one codebase for both platforms; can adopt Flame later if a game needs a game loop.
- **State**: Riverpod for shell-level global settings; each game free to choose internally.
- **Navigation**: go_router, route table driven by the game registry.
- **Local storage**: Hive (lightweight, offline, fast, cross-platform).
- **Tooling**: Melos multi-package monorepo to enforce module isolation at the package boundary.

## 3. Architecture

### 3.1 Repository layout (Melos monorepo)

```
my_game_collection/
├─ melos.yaml
├─ packages/
│  ├─ game_core/              # contract layer — depended on by all, depends on no game
│  │   ├─ lib/
│  │   │   ├─ game_contract.dart   # Game interface + GameDescriptor + GameContext
│  │   │   ├─ storage/             # GameStorage abstraction + Hive impl + in-memory (tests)
│  │   │   ├─ settings/            # AppSettings + SettingsStore
│  │   │   ├─ widgets/             # shared UI (buttons, timer, dialogs, board cell)
│  │   │   └─ theme/               # global theme / palette
│  ├─ games/
│  │   ├─ sudoku/             # depends only on game_core
│  │   └─ game_2048/          # depends only on game_core
│  └─ app/                    # shell — depends on game_core + all games
│      ├─ lib/main.dart       # startup, game registration
│      ├─ lib/home/           # lobby grid
│      ├─ lib/settings/       # global settings page
│      ├─ ios/  android/      # platform projects (bundle id top.fancytech.gamebox)
```

Dependency direction is strictly one-way: `app → games → game_core`. Games are invisible
to each other; they communicate only through `game_core` interfaces.

### 3.2 Game contract

```dart
class GameDescriptor {
  final String id;           // unique, e.g. 'sudoku' — also the storage namespace
  final String name;         // display name
  final String description;  // one-line blurb
  final IconData icon;       // lobby icon
  final List<String> tags;   // ['puzzle','single']
}

abstract class Game {
  GameDescriptor get descriptor;
  Widget buildGameScreen(BuildContext context, GameContext ctx);
}

class GameContext {
  final GameStorage storage;   // pre-namespaced to game.id by the shell
  final AppSettings settings;  // read-only global settings
}
```

`GameContext` is the **only** dependency-injection channel. A game never imports Hive,
another game, or a global singleton. The `storage` it receives is already namespaced by
the shell to `game.id`, so cross-game data access and key collisions are impossible.

### 3.3 Storage layer

```dart
abstract class GameStorage {
  Future<void> putJson(String key, Map<String, dynamic> value);
  Future<Map<String, dynamic>?> getJson(String key);
  Future<void> delete(String key);
  Future<void> clear();        // only clears this game's namespace
}
```

Key conventions per game: `save` (current board), `stats` (best score/time/completions),
`achievements` (unlocked ids + progress). Global settings live in a separate `SettingsStore`,
owned by the shell, injected read-only into games. Backing impl: Hive box, per-game key
prefix (`<id>:<key>`). Swapping the backend (Hive → Isar → files) changes only `game_core`.

### 3.4 Shell: registration, navigation, state

```dart
final registeredGames = <Game>[
  SudokuGame(),
  Game2048(),
  // future: add one line here
];
```

Shell iterates the registry to render the lobby (from descriptors) and build go_router
routes (`/`, `/game/:id`, `/settings`). On tap it builds a namespaced `GameContext` and
navigates to `game.buildGameScreen(...)`. Riverpod holds global settings; settings changes
reactively refresh all screens.

### 3.5 Adding a new game (the payoff)

1. New package `packages/games/<name>/`, depends only on `game_core`.
2. Implement `class <Name>Game implements Game` (descriptor + buildGameScreen).
3. Read/write save/stats/achievements via `ctx.storage`.
4. Add one line to `registeredGames`.
   No existing game code is touched; lobby card, route, and isolated storage appear automatically.

## 4. Testing strategy

| Layer | What | Tooling |
|-------|------|---------|
| Unit | pure game logic: Sudoku generate/solve/validate, 2048 merge, win/lose | `flutter test` (plain Dart) |
| Contract | GameStorage namespace isolation, JSON round-trip | `flutter test` + in-memory storage |
| Widget | lobby render, tap-to-enter, key interactions | `flutter test` (widget tester) |

Core principle: game logic is separated from UI (e.g. 2048 `move(board, dir) -> board` is a
pure function), making the most valuable logic unit-testable without Flutter.

## 5. Delivery pipeline

- **Android**: built & tested locally on the Medium_Tablet emulator.
- **GitHub**: public repo under `minli04g`, code pushed.
- **iOS → TestFlight**: built in GitHub Actions on `macos-latest` (iOS can't build on the
  Windows dev box; public repo gets free macOS runner minutes). Pipeline mirrors the proven
  `mytvbox-ios` setup but adapted for Flutter:
  - fastlane `match` (appstore) using the shared `safebrowser-match-certs` repo + ASC API key
  - `flutter build` driven via `build_app` on `ios/Runner.xcworkspace`
  - `upload_to_testflight`
  - Apple app record created via fastlane `produce`; signing via `init_signing` lane.
  - Secrets (`ASC_*`, `MATCH_*`) sourced from `mytvbox-ios/ci-secrets.local.json`, set as
    GitHub Actions repo secrets.
