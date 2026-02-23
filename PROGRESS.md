# WarioParty - Progress Log

## Task 1: NetworkManager autoload - DONE
- Files created/modified: `scripts/autoloads/network_manager.gd`
- What was done: Created NetworkManager singleton with host/join/disconnect functions, player registry (Dictionary mapping peer_id to player_name), RPC-based player sync using `_register_player` and `_sync_player_list`, and signals for connection events.
- Verification: Manual code review passed. Godot headless check unavailable due to sandbox restrictions. All GDScript syntax, typing, and RPC annotations verified correct.

## Task 2: GameManager autoload - DONE
- Files created/modified: `scripts/autoloads/game_manager.gd`
- What was done: Created GameManager singleton with score tracking (cumulative + per-round), round progression, minigame registry (name -> scene path), shuffled minigame ordering, server-authoritative ranking with tie support (1st=N pts, 2nd=N-1, ties share higher value), scene transitions via RPCs, and signals for round/game lifecycle events.
- Verification: Manual code review passed. All GDScript syntax, strong typing, RPC annotations, and signal declarations verified correct.

## Task 3: MiniGameBase class - DONE
- Files created/modified: `scripts/mini_game_base.gd`
- What was done: Created MiniGameBase class (class_name MiniGameBase, extends Node) with 3-second countdown timer, 10-second game timer, virtual `_on_game_start()`/`_on_game_end()` hooks for subclasses, `submit_score()` that RPCs to server which delegates to GameManager, and signals for countdown/timer ticks.
- Verification: Manual code review passed. All GDScript syntax, strong typing, RPC annotations, signal declarations, and timer setup verified correct.

## Task 4: Register autoloads in project.godot, set main scene - DONE
- Files created/modified: `project.godot`, `scenes/main_menu.tscn`, `scripts/ui/main_menu.gd`, deleted `scenes/default.tscn`
- What was done: Added [autoload] section to project.godot registering NetworkManager and GameManager singletons. Changed main scene from default.tscn to main_menu.tscn. Created placeholder main_menu scene+script. Deleted unused default.tscn.
- Verification: Manual code review passed. Autoload paths point to existing files. Main scene path points to existing .tscn. Scene resource reference matches script path.
