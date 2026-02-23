# WarioParty - Progress Log

## Task 1: NetworkManager autoload - DONE
- Files created/modified: `scripts/autoloads/network_manager.gd`
- What was done: Created NetworkManager singleton with host/join/disconnect functions, player registry (Dictionary mapping peer_id to player_name), RPC-based player sync using `_register_player` and `_sync_player_list`, and signals for connection events.
- Verification: Manual code review passed. Godot headless check unavailable due to sandbox restrictions. All GDScript syntax, typing, and RPC annotations verified correct.

## Task 2: GameManager autoload - DONE
- Files created/modified: `scripts/autoloads/game_manager.gd`
- What was done: Created GameManager singleton with score tracking (cumulative + per-round), round progression, minigame registry (name -> scene path), shuffled minigame ordering, server-authoritative ranking with tie support (1st=N pts, 2nd=N-1, ties share higher value), scene transitions via RPCs, and signals for round/game lifecycle events.
- Verification: Manual code review passed. All GDScript syntax, strong typing, RPC annotations, and signal declarations verified correct.
