# WarioParty - Networked Mini-Game Collection

## Technical Stack
- **Engine:** Godot 4.3+
- **Language:** GDScript (Strongly Typed)
- **Networking:** MultiplayerAPI (ENetMultiplayerPeer)

## Architecture

### Directory Structure
```
scenes/              # .tscn scene files
  main_menu.tscn
  lobby.tscn
  minigames/         # one .tscn per minigame
  scoreboard.tscn
  end_game.tscn
scripts/
  autoloads/         # singletons (GameManager, NetworkManager)
  minigames/         # one .gd per minigame, extends MiniGameBase
  ui/                # UI controller scripts
  mini_game_base.gd  # base class all minigames extend
tests/               # test files (test_*.gd)
```

### Autoloads (registered in project.godot)
- **GameManager** (`scripts/autoloads/game_manager.gd`): Game state, scores, minigame rotation, round progression. Server-authoritative.
- **NetworkManager** (`scripts/autoloads/network_manager.gd`): Host/join, peer connections, player registry.

### Mini-Game System
- All minigames extend `MiniGameBase` (scripts/mini_game_base.gd)
- MiniGameBase provides: 3s countdown, 10s timer, `_on_game_start()`, `_on_game_end()`, `submit_score()`
- Each minigame is a scene + script pair registered in GameManager.MINIGAME_REGISTRY
- Scoring: server ranks players, awards points (1st = N pts, 2nd = N-1, last = 1, where N = player count). Ties share the higher value.

### Game Flow
1. MainMenu -> Host or Join (enter name + IP)
2. Lobby -> player list, host clicks Start
3. GameManager picks random minigame -> 3s countdown -> 10s play -> server collects scores
4. Scoreboard -> round results + running totals, host clicks Continue
5. Repeat for N rounds (default 5) -> EndGame screen with winner -> Return to Menu

## Coding Standards
- **Typing:** Always explicit: `var x: int = 5`, `func foo() -> void:`
- **Signals:** Declare at top of scripts
- **Multiplayer:** Use `@rpc` annotations. Only server calculates scores.
- **Naming:** PascalCase for classes, snake_case for variables/functions
- **UI:** ColorRect placeholders. No art assets.

## Verification
- Parse check: `godot --headless --check-only`
- Scene loads without crash
- Game flow works end-to-end
