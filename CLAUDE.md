# Godot Project Rules: Networked Mini-Games

## Technical Stack
- **Engine:** Godot 4.3+
- **Language:** GDScript (Strongly Typed)
- **Networking:** MultiplayerAPI (ENetMultiplayerPeer)

## Coding Standards
- **Signals:** Use `signal name(args)` at the top of scripts.
- **Typing:** Always use explicit types: `var x: int = 5` or `func _ready() -> void:`.
- **Multiplayer:** - Use `@rpc` annotations explicitly (`@rpc("any_peer", "call_local")`).
    - Authority: Only the Server (`multiplayer.is_server()`) should calculate scores.
- **Naming:** PascalCase for Classes, snake_case for variables/functions.

## The Ralph Loop (Iteration)
- **Validation:** Every new feature MUST include a simple `_test_feature()` function or a GUT test case.
- **Focus:** Logic first. Use ColorRects for UI placeholders; no complex assets yet.
