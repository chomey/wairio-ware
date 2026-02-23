# WarioParty - Networked Mini-Game Collection

## Technical Stack
- **Engine:** Godot 4.6.1 mono
- **Godot CLI:** `/Applications/Godot_mono.app/Contents/MacOS/Godot`
- **Language:** GDScript (Strongly Typed)
- **Networking:** MultiplayerAPI (ENetMultiplayerPeer)

## Running Godot from CLI
```bash
# Run the game headless (for validation/testing):
/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path . --quit-after 5 --log-file ./godot_test.log 2>&1

# IMPORTANT: Always use --log-file pointing to the project directory.
# Without it, Godot crashes trying to write logs to a sandboxed path.
# Always clean up: rm -f godot_test.log after checking output.

# The CA certificate error is harmless (sandbox blocks keychain), ignore it.
```

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
- MiniGameBase provides: 3s countdown, 10s timer, `_on_game_start()`, `_on_game_end()`, `submit_score()`, `mark_completed()`, `force_end_game()`
- Each minigame is a scene + script pair registered in GameManager.MINIGAME_REGISTRY
- Scoring: server ranks players, awards points (1st = N pts, 2nd = N-1, last = 1, where N = player count). Ties share the higher value.

### Per-Player Completion & Early End
- **Race games** (ButtonMasher, ReactionTime, QuickMath, TargetClick, ColorMatch, RhythmTap): players call `mark_completed(score)` when hitting a target count. First to finish gets the highest score.
- **Survival games** (DodgeFalling, MemorySequence): players call `mark_completed(score)` when eliminated. Last standing gets the highest score.
- When N-1 of N players have submitted scores, GameManager calls `force_end_game()` RPC to end the game for the remaining player, who submits their current progress.
- Completion targets: ButtonMasher=30, ReactionTime=3 attempts, QuickMath=10, TargetClick=15, ColorMatch=12, RhythmTap=12 hits, MemorySequence=wrong press, DodgeFalling=hit by obstacle.

### Game Flow (Auto-Flow)
1. MainMenu -> Host or Join (enter name + IP)
2. Lobby -> player list, auto-starts 5s countdown when 2+ players connected
3. GameManager picks random minigame -> 3s countdown -> play until completion or 10s timeout -> server collects scores
4. Scoreboard -> round results + running totals, auto-advances after 5s
5. Repeat for N rounds (default 5) -> EndGame screen with winner -> auto-returns to menu after 10s

## Coding Standards
- **Typing:** Always explicit: `var x: int = 5`, `func foo() -> void:`
- **Signals:** Declare at top of scripts
- **Multiplayer:** Use `@rpc` annotations. Only server calculates scores.
- **Naming:** PascalCase for classes, snake_case for variables/functions
- **UI:** ColorRect placeholders. No art assets.

## Known Pitfalls (MUST follow)

### Typed Arrays and RPC
- RPC parameters arrive as untyped `Array`/`Dictionary`. NEVER assign directly to a typed array.
- `Dictionary.keys()` returns untyped `Array`. Cast explicitly before using with typed arrays.
- When an RPC with `call_local` modifies state that the caller reads immediately after, the local call executes **synchronously** and will clobber state. Either: (a) don't use `call_local` if the server needs the data right after, or (b) have the server set its own state directly and only use the RPC for clients.

### Minigame Registry
- ONLY register minigames that have BOTH a .tscn scene file AND a .gd script file actually committed to the project.
- GameManager._ready() must NOT register minigames that don't exist yet. Add registrations only in the task that creates the minigame.
- Before starting the game, validate that all registered minigame scene files exist.

### RPC + State Ordering
- When `start_game()` builds state and then calls an RPC with `call_local`, the local RPC fires synchronously and can clear/reset the state you just built.
- Pattern: server builds state → server calls `advance_round()` → only then RPCs sync state to clients (without `call_local` on the setup RPC, or set server state before the RPC).

### RPC Self-Call
- Host (peer_id=1) calling `rpc_id(1, ...)` without `call_local` fails silently. When the server needs to call its own RPC target, call the function directly instead (e.g., `submit_player_score(...)` instead of `submit_player_score.rpc_id(1, ...)`).

### Peer Cleanup
- Always call `_peer.close()` before nulling the peer in `disconnect_game()`. Also call `disconnect_game()` at the start of `host_game()`/`join_game()` to clean up stale connections.

## Verification Checklist
1. **Syntax**: Read back every file, confirm no parse errors
2. **Scene-Script consistency**: Every node path in .gd matches the .tscn tree
3. **Autoload paths**: All paths in project.godot point to existing files
4. **Registry integrity**: Every minigame in MINIGAME_REGISTRY has a real .tscn and .gd file
5. **Array bounds**: Any indexed access (`array[i]`) must verify the array is non-empty and index is in range
6. **RPC state safety**: If an RPC is `call_local` and the caller reads state after, verify the local call doesn't clobber that state
7. **Game flow trace**: Mentally trace the full path: menu → lobby → start_game → advance_round → minigame scene loads → score submit → scoreboard → next round. Confirm no step accesses empty/uninitialized data
8. **Integration test**: Run `bash tests/run_integration.sh`. Both host and client must reach EndGame with non-zero scores.
