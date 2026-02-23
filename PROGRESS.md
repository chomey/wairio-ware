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

## Task 5: MainMenu scene+script - DONE
- Files created/modified: `scenes/main_menu.tscn`, `scripts/ui/main_menu.gd`
- What was done: Built full MainMenu UI with VBoxContainer layout containing title, player name input, IP address input (default 127.0.0.1), Host Game and Join Game buttons, and a status label for connection feedback. Script handles validation, calls NetworkManager.host_game/join_game, disables buttons during connection, shows errors, and transitions to lobby on success.
- Verification: Manual code review passed. All @onready node paths match .tscn structure. Strong typing on all variables/functions. Signal connections match NetworkManager API.

## Task 6: Lobby scene+script - DONE
- Files created/modified: `scenes/lobby.tscn`, `scripts/ui/lobby.gd`
- What was done: Built Lobby UI with VBoxContainer layout containing title, player list (dynamically populated from NetworkManager.players), status label showing player count, host-only Start Game button (hidden for non-host), and Back to Menu button. Script handles player connect/disconnect events to refresh the list, validates minimum 2 players before starting, and calls GameManager.start_game() or GameManager.return_to_menu() as appropriate.
- Verification: Manual code review passed. All @onready node paths match .tscn structure. Strong typing on all variables/functions. Signal connections match NetworkManager/GameManager APIs. Godot CLI unavailable in sandbox.

## Task 7: Scoreboard scene+script - DONE
- Files created/modified: `scenes/scoreboard.tscn`, `scripts/ui/scoreboard.gd`
- What was done: Built Scoreboard UI with header row (Player / Round Pts / Total), dynamically populated score rows sorted by cumulative score descending, round counter label, and host-only Continue button. Script reads GameManager.round_points and cumulative_scores, formats rows with player names from NetworkManager, and calls GameManager.advance_round() on continue.
- Verification: Manual code review passed. All @onready node paths match .tscn structure. Strong typing on all variables/functions. Scene path matches GameManager._load_scoreboard() reference.

## Task 8: EndGame scene+script - DONE
- Files created: `scenes/end_game.tscn`, `scripts/ui/end_game.gd`
- What was done: Built EndGame UI with "Game Over!" title, winner display (handles ties), final standings table with rank/player/score columns sorted by cumulative score descending (ties share rank), and a "Return to Menu" button that calls GameManager.return_to_menu(). Rankings are dynamically built from GameManager.cumulative_scores.
- Verification: Manual code review passed. All @onready node paths match .tscn structure. Strong typing on all variables/functions. Scene path matches GameManager._load_end_game() reference. Godot CLI unavailable in sandbox.

## Task 9: Button Masher minigame - DONE
- Files created/modified: `scripts/minigames/button_masher.gd`, `scenes/minigames/button_masher.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Button Masher minigame extending MiniGameBase. Players mash spacebar during the 10-second game phase; press count is tracked and submitted as score. UI shows countdown, timer, press count, and instructions. Registered "Button Masher" in GameManager._ready().
- Verification: Manual code review passed. All %NodeName references match unique_name_in_owner nodes in .tscn. Strong typing throughout. Extends MiniGameBase correctly with _on_game_start/_on_game_end overrides.

## Task 10: End-to-end flow test - DONE
- Files created/modified: `scenes/minigames/button_masher.tscn` (fixed invalid UID)
- What was done: Traced the complete game loop: MainMenu → Lobby → Minigame (Button Masher) → Scoreboard → EndGame → MainMenu. Verified all scene transitions, RPC chains, score submission flow, node path references, autoload registrations, and scene file references. Fixed invalid custom UID in button_masher.tscn.
- Verification: All @onready/$CenterContainer paths match .tscn node structures. All %UniqueNode references match unique_name_in_owner flags. All res:// scene paths point to existing files. Autoload paths in project.godot verified. Godot CLI unavailable due to sandbox restrictions (crashes on log directory creation). Manual review passed.

## Task 11: Reaction Time minigame - DONE
- Files created/modified: `scripts/minigames/reaction_time.gd`, `scenes/minigames/reaction_time.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Reaction Time minigame extending MiniGameBase. Players wait for a random delay (1.5-5s), then press spacebar when "PRESS SPACE!" appears. Best of 3 attempts within the 10s game window. Score = 10000 - best_reaction_ms (higher = better). Early presses trigger "TOO EARLY!" and restart the attempt. Registered in GameManager.MINIGAME_REGISTRY.
- Verification: Manual code review passed. All %UniqueNode references match unique_name_in_owner nodes in .tscn. Strong typing throughout. Extends MiniGameBase correctly with _on_game_start/_on_game_end overrides. Scene path registered in GameManager.

## Task 12: Quick Math minigame - DONE
- Files created/modified: `scripts/minigames/quick_math.gd`, `scenes/minigames/quick_math.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Quick Math minigame extending MiniGameBase. Players solve randomly generated arithmetic problems (addition, subtraction, multiplication) within 10 seconds. Score = number of correct answers. Uses LineEdit for text input with Enter to submit. Registered "Quick Math" in GameManager.MINIGAME_REGISTRY.
- Verification: Manual code review passed. All %UniqueNode references match unique_name_in_owner nodes in .tscn. Strong typing throughout. Extends MiniGameBase correctly with _on_game_start/_on_game_end overrides. Scene path registered in GameManager.

## Task 13: Target Click minigame - DONE
- Files created/modified: `scripts/minigames/target_click.gd`, `scenes/minigames/target_click.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Target Click minigame extending MiniGameBase. Players click on a target button ("X") that appears at random positions within a target area. Each click scores a point and spawns the target at a new random position. Score = number of targets clicked within 10 seconds. Registered "Target Click" in GameManager.MINIGAME_REGISTRY.
- Verification: Manual code review passed. All %UniqueNode references match unique_name_in_owner nodes in .tscn. Strong typing throughout. Extends MiniGameBase correctly with _on_game_start/_on_game_end overrides. Scene path registered in GameManager.

## Task 14: Color Match minigame - DONE
- Files created/modified: `scripts/minigames/color_match.gd`, `scenes/minigames/color_match.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Color Match minigame (Stroop test) extending MiniGameBase. A color word (RED, GREEN, BLUE, YELLOW, PURPLE) is displayed in a random color. Players press "MATCH" if the word matches the display color, or "NO MATCH" if it doesn't. 50% chance of match per prompt. Score = number of correct answers within 10 seconds. Registered "Color Match" in GameManager.MINIGAME_REGISTRY.
- Verification: Manual code review passed. All %UniqueNode references match unique_name_in_owner nodes in .tscn. Strong typing throughout. Extends MiniGameBase correctly with _on_game_start/_on_game_end overrides. Scene path registered in GameManager.

## Task 15: Memory Sequence minigame - DONE
- Files created/modified: `scripts/minigames/memory_sequence.gd`, `scenes/minigames/memory_sequence.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Memory Sequence minigame extending MiniGameBase. Four colored panels (Red, Green, Blue, Yellow) in a 2x2 grid flash in a sequence. Player must repeat the sequence by clicking panels in the correct order. Each successful repetition adds one more item. Wrong press resets the sequence. Score = longest sequence completed within 10 seconds. Uses Timer-based flash/pause system for sequence display. Registered "Memory Sequence" in GameManager.MINIGAME_REGISTRY.
- Verification: Manual code review passed. All %UniqueNode references match unique_name_in_owner nodes in .tscn. Strong typing throughout. Extends MiniGameBase correctly with _on_game_start/_on_game_end overrides. Scene path registered in GameManager.

## Task 16: Dodge Falling minigame - DONE
- Files created/modified: `scripts/minigames/dodge_falling.gd`, `scenes/minigames/dodge_falling.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Dodge Falling minigame extending MiniGameBase. Player controls a green ColorRect at the bottom of a play area, moving left/right with arrow keys to dodge red falling obstacles. Obstacles spawn at random X positions and fall downward, increasing in speed and frequency over time. Score = number of obstacles that pass below without hitting the player. Getting hit ends the game early. Registered "Dodge Falling" in GameManager.MINIGAME_REGISTRY.
- Verification: Manual code review passed. All %UniqueNode references match unique_name_in_owner nodes in .tscn. Strong typing throughout. Extends MiniGameBase correctly with _on_game_start/_on_game_end overrides. Scene path registered in GameManager.

## Task 17: Rhythm Tap minigame - DONE
- Files created/modified: `scripts/minigames/rhythm_tap.gd`, `scenes/minigames/rhythm_tap.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Rhythm Tap minigame extending MiniGameBase. Cyan beat indicators scroll down a track toward a white hit zone. Player presses spacebar to hit beats in time. Perfect hits (within 80ms) score 3 points, Good hits (within 200ms) score 1 point, misses score 0. Features combo tracking display. BPM set to 100 with 1.2s lead time for beat visibility. Registered "Rhythm Tap" in GameManager.MINIGAME_REGISTRY.
- Verification: Manual code review passed. All %UniqueNode references match unique_name_in_owner nodes in .tscn. Strong typing throughout. Extends MiniGameBase correctly with _on_game_start/_on_game_end overrides. Scene path registered in GameManager.

## Task 18: Type Racer minigame - DONE
- Files created/modified: `scripts/minigames/type_racer.gd`, `scenes/minigames/type_racer.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Type Racer minigame extending MiniGameBase. A word from a 56-word list is displayed; player types it exactly and presses Enter. Correct answers advance to the next word, wrong answers show the correct word. Race to 8 correct words. Score = number of correct words typed. Registered "Type Racer" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed (no errors). All %UniqueNode references match unique_name_in_owner nodes in .tscn. Strong typing throughout. Extends MiniGameBase correctly with _on_game_start/_on_game_end overrides.

## Task 19: Arrow Storm minigame - DONE
- Files created/modified: `scripts/minigames/arrow_storm.gd`, `scenes/minigames/arrow_storm.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Arrow Storm minigame extending MiniGameBase. Arrow symbols (^, v, <, >) appear and player presses the matching arrow key. Correct presses advance to next arrow, wrong presses show the correct direction. Race to 20 correct arrows. Score = number of correct arrows pressed. Uses _unhandled_input for arrow key detection. Registered "Arrow Storm" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed (no errors). All %UniqueNode references match unique_name_in_owner nodes in .tscn. Strong typing throughout. Extends MiniGameBase correctly with _on_game_start/_on_game_end overrides.

## Task 20: Copy Cat minigame - DONE
- Files created/modified: `scripts/minigames/copy_cat.gd`, `scenes/minigames/copy_cat.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Copy Cat minigame extending MiniGameBase. A sequence of arrows is shown one at a time (flash + pause), then the player reproduces it by pressing arrow keys in the correct order. Starts with length 2, grows by 1 each successful sequence. Wrong press resets input for that sequence. Race to 5 completed sequences. Score = number of sequences completed. Registered "Copy Cat" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed (no errors). All %UniqueNode references match unique_name_in_owner nodes in .tscn. Strong typing throughout. Extends MiniGameBase correctly with _on_game_start/_on_game_end overrides.

## Task 21: Direction Dash minigame - DONE
- Files created/modified: `scripts/minigames/direction_dash.gd`, `scenes/minigames/direction_dash.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Direction Dash minigame extending MiniGameBase. A direction word (UP, DOWN, LEFT, RIGHT) is displayed as text and the player presses the matching arrow key. Correct presses advance to the next word, wrong presses show the correct direction. Race to 15 correct. Score = number of correct presses. Registered "Direction Dash" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed (no errors). All %UniqueNode references match unique_name_in_owner nodes in .tscn. Strong typing throughout. Extends MiniGameBase correctly with _on_game_start/_on_game_end overrides.

## Task 22: Odd One Out minigame - DONE
- Files created/modified: `scripts/minigames/odd_one_out.gd`, `scenes/minigames/odd_one_out.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Odd One Out minigame extending MiniGameBase. A 4x4 grid of colored buttons is displayed where all but one share the same color. Player clicks the differently-colored button to score. Each correct click generates a new round with random colors from a 7-color pool. Race to 10 correct clicks. Score = number of correct clicks. Registered "Odd One Out" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed (no errors). All %UniqueNode references match unique_name_in_owner nodes in .tscn. Strong typing throughout. Extends MiniGameBase correctly with _on_game_start/_on_game_end overrides.

## Task 23: Number Sort minigame - DONE
- Files created/modified: `scripts/minigames/number_sort.gd`, `scenes/minigames/number_sort.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Number Sort minigame extending MiniGameBase. 10 unique random numbers (1-99) are scattered as buttons across the play area at random non-overlapping positions. Player clicks them in ascending order. Correct clicks turn green and disable; wrong clicks show a hint. Race to sort all 10. Score = numbers correctly sorted. Registered "Number Sort" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed (no errors). All %UniqueNode references match unique_name_in_owner nodes in .tscn. Strong typing throughout. Extends MiniGameBase correctly with _on_game_start/_on_game_end overrides.

## Task 24: Speed Spell minigame - DONE
- Files created/modified: `scripts/minigames/speed_spell.gd`, `scenes/minigames/speed_spell.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Speed Spell minigame extending MiniGameBase. Single letters (A-Z) are displayed one at a time, player types the matching key as fast as possible. Correct presses advance to the next letter, wrong presses show the correct letter. Race to 25 correct letters. Score = number of correct letters typed. Uses _unhandled_input for keyboard detection with keycode-to-letter conversion. Registered "Speed Spell" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed (no errors). All %UniqueNode references match unique_name_in_owner nodes in .tscn. Strong typing throughout. Extends MiniGameBase correctly with _on_game_start/_on_game_end overrides.

## Task 25: Pattern Match minigame - DONE
- Files created/modified: `scripts/minigames/pattern_match.gd`, `scenes/minigames/pattern_match.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Pattern Match minigame extending MiniGameBase. Two 4x4 grids side by side: left is the target pattern (random 4-8 cells colored), right is the player grid (all off). Player clicks cells on the right grid to toggle them on/off to match the target. Race to 8 patterns matched. Score = number of patterns matched. Registered "Pattern Match" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed (no errors). All %UniqueNode references match unique_name_in_owner nodes in .tscn. Strong typing throughout. Extends MiniGameBase correctly with _on_game_start/_on_game_end overrides.

## Task 26: Counting minigame - DONE
- Files created/modified: `scripts/minigames/counting.gd`, `scenes/minigames/counting.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Counting minigame extending MiniGameBase. Random colored shapes (3-12) flash on screen for 1.5 seconds, then player types the count and presses Enter. Correct answers advance to next round. Race to 8 correct counts. Score = number of correct counts. Uses Control area for random object placement and LineEdit for input. Registered "Counting" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed (no errors). All %UniqueNode references match unique_name_in_owner nodes in .tscn. Strong typing throughout. Extends MiniGameBase correctly with _on_game_start/_on_game_end overrides.

## Task 27: Bomb Defuse minigame - DONE
- Files created/modified: `scripts/minigames/bomb_defuse.gd`, `scenes/minigames/bomb_defuse.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Bomb Defuse minigame extending MiniGameBase. A random key sequence (3-6 letters) is displayed with the current key highlighted. Player presses keys in order to defuse the bomb. Wrong key resets the sequence. Race to 6 bombs defused. Score = number of bombs defused. Uses _unhandled_input for keyboard detection. Registered "Bomb Defuse" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed (no errors). All %UniqueNode references match unique_name_in_owner nodes in .tscn. Strong typing throughout. Extends MiniGameBase correctly with _on_game_start/_on_game_end overrides.

## Task 28: Safe Cracker minigame - DONE
- Files created/modified: `scripts/minigames/safe_cracker.gd`, `scenes/minigames/safe_cracker.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Safe Cracker minigame extending MiniGameBase. A random 3-digit code is generated. Player types 3-digit guesses and presses Enter. Each digit gets feedback: HIT (correct digit, correct position), CLOSE (correct digit, wrong position), MISS (wrong digit). Shows last 5 guesses as history. Race to 3 codes cracked. Score = number of codes cracked. Uses LineEdit for input with text_submitted signal. Registered "Safe Cracker" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed (no errors). All %UniqueNode references match unique_name_in_owner nodes in .tscn. Strong typing throughout. Extends MiniGameBase correctly with _on_game_start/_on_game_end overrides.

## Task 29: Word Scramble minigame - DONE
- Files created/modified: `scripts/minigames/word_scramble.gd`, `scenes/minigames/word_scramble.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Word Scramble minigame extending MiniGameBase. A word from a 50-word list is scrambled (Fisher-Yates shuffle, guaranteed different from original). Player types the unscrambled word and presses Enter. Correct answers advance to next word, wrong answers reveal the answer. Race to 5 correct words. Score = number of correct words. Case-insensitive comparison. Tracks used words to avoid repeats. Registered "Word Scramble" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed (no errors). All %UniqueNode references match unique_name_in_owner nodes in .tscn. Strong typing throughout. Extends MiniGameBase correctly with _on_game_start/_on_game_end overrides.

## Task 30: Morse Decode minigame - DONE
- Files created/modified: `scripts/minigames/morse_decode.gd`, `scenes/minigames/morse_decode.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Morse Decode minigame extending MiniGameBase. Morse code patterns (dots and dashes) are displayed for a random letter. Player presses the matching letter key. Correct presses advance to the next pattern, wrong presses show a hint. Race to 10 correct decodes. Score = number of letters decoded. Full A-Z morse code dictionary. Uses _unhandled_input for keyboard detection. Registered "Morse Decode" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed (no errors). All %UniqueNode references match unique_name_in_owner nodes in .tscn. Strong typing throughout. Extends MiniGameBase correctly with _on_game_start/_on_game_end overrides.

## Task 31: Pixel Painter minigame - DONE
- Files created/modified: `scripts/minigames/pixel_painter.gd`, `scenes/minigames/pixel_painter.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Pixel Painter minigame extending MiniGameBase. A 6x6 grid displays target cells (orange/translucent) that the player clicks to fill (green). Each pattern has 4-6 target cells. Completing a pattern generates a new one. Race to fill 20 cells total. Score = number of cells filled. Registered "Pixel Painter" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed (no errors). All %UniqueNode references match unique_name_in_owner nodes in .tscn. Strong typing throughout. Extends MiniGameBase correctly with _on_game_start/_on_game_end overrides.

## Task 32: Rapid Toggle minigame - DONE
- Files created/modified: `scripts/minigames/rapid_toggle.gd`, `scenes/minigames/rapid_toggle.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Rapid Toggle minigame extending MiniGameBase. A 4x4 grid of dark cells uses Lights Out mechanics - clicking a cell toggles it and its orthogonal neighbors. Player must light all 16 cells to solve a puzzle. Each solved puzzle generates a new one. Race to solve 3 puzzles. Score = puzzles solved. Puzzles are generated by applying random toggles to ensure solvability. Registered "Rapid Toggle" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed (no errors). All %UniqueNode references match unique_name_in_owner nodes in .tscn. Strong typing throughout. Extends MiniGameBase correctly with _on_game_start/_on_game_end overrides.

## Task 33: Chain Reaction minigame - DONE
- Files created/modified: `scripts/minigames/chain_reaction.gd`, `scenes/minigames/chain_reaction.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Chain Reaction minigame extending MiniGameBase. 12 red target circles are scattered in a play area. Player clicks to place an expanding circle; when it touches a target, that target triggers its own expanding circle, creating chain reactions. Each wave spawns new targets. Race to clear 30 targets. Score = targets cleared. Uses Control.draw signal for custom circle rendering. Registered "Chain Reaction" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed (no errors). All %UniqueNode references match unique_name_in_owner nodes in .tscn. Strong typing throughout. Extends MiniGameBase correctly with _on_game_start/_on_game_end overrides.

## Task 34: Shopping Cart minigame - DONE
- Files created/modified: `scripts/minigames/shopping_cart.gd`, `scenes/minigames/shopping_cart.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Shopping Cart minigame extending MiniGameBase. Items with random prices ($0.50-$9.99) are shown one at a time. Player types the running total and presses Enter. Correct answers advance to next item, wrong answers reset the cart to $0. Accepts optional $ prefix. Race to 8 correct totals. Score = number of correct totals. Registered "Shopping Cart" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed (no errors). All %UniqueNode references match unique_name_in_owner nodes in .tscn. Strong typing throughout. Extends MiniGameBase correctly with _on_game_start/_on_game_end overrides.

## Task 35: Binary Convert minigame - DONE
- Files created/modified: `scripts/minigames/binary_convert.gd`, `scenes/minigames/binary_convert.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Binary Convert minigame extending MiniGameBase. A random decimal number (1-31) is shown and the player types its binary representation. Correct answers advance to the next number, wrong answers show the correct binary. Leading zeros are stripped for comparison. Race to 8 correct conversions. Score = number of correct conversions. Registered "Binary Convert" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed (no errors). All %UniqueNode references match unique_name_in_owner nodes in .tscn. Strong typing throughout. Extends MiniGameBase correctly with _on_game_start/_on_game_end overrides.

## Task 36: Color Mixer minigame - DONE
- Files created/modified: `scripts/minigames/color_mixer.gd`, `scenes/minigames/color_mixer.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Color Mixer minigame extending MiniGameBase. A target color is shown as a ColorRect. Player clicks R+/R-/G+/G-/B+/B- buttons (step=32) to adjust their color, then clicks SUBMIT. Colors match if each channel is within tolerance (16). Target values are multiples of 32 (0-224) for achievability. Race to 6 colors matched. Score = number of colors matched. Registered "Color Mixer" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed (no errors). All %UniqueNode references match unique_name_in_owner nodes in .tscn. Strong typing throughout. Extends MiniGameBase correctly with _on_game_start/_on_game_end overrides.

## Task 37: Maze Solver minigame - DONE
- Files created/modified: `scripts/minigames/maze_solver.gd`, `scenes/minigames/maze_solver.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Maze Solver minigame extending MiniGameBase. An 11x11 grid maze is generated using recursive backtracker algorithm (guarantees solvability). Player (green) navigates with arrow keys from top-left to exit (red) at bottom-right. Each solved maze generates a new one. Race to 3 mazes solved. Score = number of mazes solved. Registered "Maze Solver" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed (no errors). All %UniqueNode references match unique_name_in_owner nodes in .tscn. Strong typing throughout. Extends MiniGameBase correctly with _on_game_start/_on_game_end overrides.

## Task 38: Path Tracer minigame - DONE
- Files created/modified: `scripts/minigames/path_tracer.gd`, `scenes/minigames/path_tracer.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Path Tracer minigame extending MiniGameBase. 8 numbered waypoints are scattered at random non-overlapping positions in the play area. Player clicks them in order (1, 2, 3...). Completing all 8 waypoints finishes one path and generates a new one. Race to 3 paths traced. Score = number of paths completed. Wrong clicks show a hint. Registered "Path Tracer" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed (no errors). All %UniqueNode references match unique_name_in_owner nodes in .tscn. Strong typing throughout. Extends MiniGameBase correctly with _on_game_start/_on_game_end overrides.

## Task 39: Equation Builder minigame - DONE
- Files created/modified: `scripts/minigames/equation_builder.gd`, `scenes/minigames/equation_builder.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Equation Builder minigame extending MiniGameBase. A target number is shown along with available numbers. Player types a mathematical expression using +, -, * that evaluates to the target. Supports 2-operand and 3-operand puzzles with proper operator precedence evaluation. Race to 5 correct equations. Score = number of correct equations. Registered "Equation Builder" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed (no errors). All %UniqueNode references match unique_name_in_owner nodes in .tscn. Strong typing throughout. Extends MiniGameBase correctly with _on_game_start/_on_game_end overrides.

## Task 40: Balancing Act minigame - DONE
- Files created/modified: `scripts/minigames/balancing_act.gd`, `scenes/minigames/balancing_act.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Balancing Act survival minigame extending MiniGameBase. A balance bar drifts randomly left/right with increasing intensity over time. Player presses left/right arrow keys to keep it centered. Bar changes color (green/yellow/red) based on proximity to edges. Hitting either edge eliminates the player. Score = survival time in tenths of seconds. Drift direction changes every 1.5s with bias away from center. Registered "Balancing Act" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed (no errors). All %UniqueNode references match unique_name_in_owner nodes in .tscn. Strong typing throughout. Extends MiniGameBase correctly with _on_game_start/_on_game_end overrides.

## Task 41: Floor is Lava minigame - DONE
- Files created/modified: `scripts/minigames/floor_is_lava.gd`, `scenes/minigames/floor_is_lava.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Floor is Lava survival minigame extending MiniGameBase. A 5x4 grid of platforms sits over lava. Platforms randomly start shrinking (turning yellow as warning) and eventually disappear. Player moves with arrow keys to stay on remaining platforms. Shrink rate increases over time. Keeps at least 2 platforms alive. Falling into lava (not on any platform) eliminates the player. Score = survival time in tenths of seconds. Registered "Floor is Lava" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed (no errors). All %UniqueNode references match unique_name_in_owner nodes in .tscn. Strong typing throughout. Extends MiniGameBase correctly with _on_game_start/_on_game_end overrides.

## Task 42: Gravity Flip minigame - DONE
- Files created/modified: `scripts/minigames/gravity_flip.gd`, `scenes/minigames/gravity_flip.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Gravity Flip survival minigame extending MiniGameBase. Auto-scrolling Flappy Bird-style platformer where obstacles (top/bottom pairs with a gap) scroll from right to left. Player presses spacebar to flip gravity direction (up/down). Gravity pulls player toward ceiling or floor. Hitting an obstacle eliminates the player. Gap size shrinks and obstacle speed increases over time. Score = survival time in tenths of seconds. Registered "Gravity Flip" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed (no errors). All %UniqueNode references match unique_name_in_owner nodes in .tscn. Strong typing throughout. Extends MiniGameBase correctly with _on_game_start/_on_game_end overrides.

## Task 43: Shrinking Arena minigame - DONE
- Files created/modified: `scripts/minigames/shrinking_arena.gd`, `scenes/minigames/shrinking_arena.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Shrinking Arena survival minigame extending MiniGameBase. Play area shrinks over time from all sides with accelerating speed. Player moves with arrow keys to stay inside the shrinking boundary. Arena color shifts as it shrinks. Touching the boundary eliminates the player. Score = survival time in tenths of seconds. Registered "Shrinking Arena" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed (no errors). All %UniqueNode references match unique_name_in_owner nodes in .tscn. Strong typing throughout. Extends MiniGameBase correctly with _on_game_start/_on_game_end overrides.

## Task 44: Hot Potato minigame - DONE
- Files created/modified: `scripts/minigames/hot_potato.gd`, `scenes/minigames/hot_potato.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Hot Potato survival minigame extending MiniGameBase. A potato with a fuse timer counts down; player presses space to throw it before it explodes. Each successful throw resets with a shorter fuse (starts at 3s, shrinks by 0.15s per throw, minimum 0.8s). Fuse bar and potato color change from green/yellow to orange/red as time runs out. If the potato explodes while held, the player is eliminated. Score = survival time in tenths of seconds. Registered "Hot Potato" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed (no errors). All %UniqueNode references match unique_name_in_owner nodes in .tscn. Strong typing throughout. Extends MiniGameBase correctly with _on_game_start/_on_game_end overrides.

## Task 45: Tightrope Walk minigame - DONE
- Files created/modified: `scripts/minigames/tightrope_walk.gd`, `scenes/minigames/tightrope_walk.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Tightrope Walk survival minigame extending MiniGameBase. Character balances on a tightrope with increasing tilt drift. Player presses left/right arrow keys to stay balanced. Random wind gusts periodically push the walker. Balance bar at bottom shows current position. Walker color changes green/yellow/red based on danger. Falling off either side eliminates the player. Score = survival time in tenths of seconds. Registered "Tightrope Walk" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed (no errors). All %UniqueNode references match unique_name_in_owner nodes in .tscn. Strong typing throughout. Extends MiniGameBase correctly with _on_game_start/_on_game_end overrides.

## Task 46: Rising Water minigame - DONE
- Files created/modified: `scripts/minigames/rising_water.gd`, `scenes/minigames/rising_water.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Rising Water survival minigame extending MiniGameBase. Platforms at various heights over rising water. Player moves with arrow keys and jumps with space. Gravity-based physics with platform collision detection. Water rises from the bottom with accelerating speed. Full-width ground platform at bottom plus 8 scattered platforms at various heights. Player is eliminated when their center goes below the water level. Score = survival time in tenths of seconds. Registered "Rising Water" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed (no errors). All %UniqueNode references match unique_name_in_owner nodes in .tscn. Strong typing throughout. Extends MiniGameBase correctly with _on_game_start/_on_game_end overrides.

## Task 47: Minefield minigame - DONE
- Files created/modified: `scripts/minigames/minefield.gd`, `scenes/minigames/minefield.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Minefield survival minigame extending MiniGameBase. An 8x6 grid of hidden cells with 20% mines. A safe path from left to right is guaranteed during generation. Player clicks cells to reveal them - safe cells show adjacent mine count (minesweeper-style), mines eliminate the player. Flood-fill auto-reveals cells with 0 adjacent mines. BFS checks if a revealed safe path connects left to right columns; clearing a path generates a new field. Score = survival time in tenths of seconds. Registered "Minefield" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed (no errors). All %UniqueNode references match unique_name_in_owner nodes in .tscn. Strong typing throughout. Extends MiniGameBase correctly with _on_game_start/_on_game_end overrides.

## Task 48: Asteroid Dodge minigame - DONE
- Files created/modified: `scripts/minigames/asteroid_dodge.gd`, `scenes/minigames/asteroid_dodge.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Asteroid Dodge survival minigame extending MiniGameBase. Ship (cyan rect) moves in 2D with arrow keys dodging brown asteroids that spawn from all four sides. Asteroid speed and spawn rate increase over time. Circle-ish collision detection with slight forgiveness. Off-screen asteroids are cleaned up. Hit by asteroid eliminates the player. Score = survival time in tenths of seconds. Registered "Asteroid Dodge" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed (no errors). All %UniqueNode references match unique_name_in_owner nodes in .tscn. Strong typing throughout. Extends MiniGameBase correctly with _on_game_start/_on_game_end overrides.

## Task 49: Conveyor Chaos minigame - DONE
- Files created/modified: `scripts/minigames/conveyor_chaos.gd`, `scenes/minigames/conveyor_chaos.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Conveyor Chaos survival minigame extending MiniGameBase. A 6x5 grid of colored conveyor tiles pushes the player in their indicated direction (arrows shown on tiles). Player moves with arrow keys to resist the conveyor force and stay within the play area. Conveyor speed increases over time, and directions shuffle periodically (faster as time goes on). Being pushed off any edge eliminates the player. Score = survival time in tenths of seconds. Registered "Conveyor Chaos" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed (no errors). All %UniqueNode references match unique_name_in_owner nodes in .tscn. Strong typing throughout. Extends MiniGameBase correctly with _on_game_start/_on_game_end overrides.

## Task 50: Laser Dodge minigame - DONE
- Files created/modified: `scripts/minigames/laser_dodge.gd`, `scenes/minigames/laser_dodge.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Laser Dodge survival minigame extending MiniGameBase. Lasers sweep across the arena from all four directions (left-to-right, right-to-left, top-to-bottom, bottom-to-top), each with a gap the player must position through. Player moves with arrow keys. Laser spawn rate and speed increase over time. Lasers rendered via PlayArea _draw signal with glow effect. Hit by laser eliminates the player. Score = survival time in tenths of seconds. Registered "Laser Dodge" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed (no errors). All %UniqueNode references match unique_name_in_owner nodes in .tscn. Strong typing throughout. Extends MiniGameBase correctly with _on_game_start/_on_game_end overrides.

## Task 51: Simon Says minigame - DONE
- Files created/modified: `scripts/minigames/simon_says.gd`, `scenes/minigames/simon_says.tscn`, `scripts/autoloads/game_manager.gd`, `tests/run_integration.sh`
- What was done: Created Simon Says race minigame extending MiniGameBase. Four colored panels (blue=UP, green=DOWN, red=LEFT, yellow=RIGHT) flash in sequence; player repeats with arrow keys. Sequence grows each round (starting length 2). Race to complete 10 rounds. Wrong input resets the current sequence attempt. Also fixed shell quoting bug in run_integration.sh where game names with spaces were being split into separate args.
- Verification: Godot headless run passed. Integration test `bash tests/run_integration.sh "Simon Says"` passed with both host and client reaching EndGame with positive scores.

## Task 52: Whack-a-Mole minigame - DONE
- Files created/modified: `scripts/minigames/whack_a_mole.gd`, `scenes/minigames/whack_a_mole.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Whack-a-Mole race minigame extending MiniGameBase. Colored squares pop up randomly in a 4x4 grid, player clicks them before they disappear. Race to 20 hits. Registered "Whack-a-Mole" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed. Registered in GameManager.

## Task 53: Fruit Catcher minigame - DONE
- Files created/modified: `scripts/minigames/fruit_catcher.gd`, `scenes/minigames/fruit_catcher.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Fruit Catcher race minigame extending MiniGameBase. Player moves a basket left/right with arrow keys to catch falling green fruit while avoiding red bad items (-2 penalty). Fall speed increases over time. Race to 15 caught. Registered "Fruit Catcher" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed (only harmless CA cert error). Integration test `bash tests/run_integration.sh "Fruit Catcher"` passed with both host and client reaching EndGame with positive scores.

## Task 54: Treasure Dig minigame - DONE
- Files created/modified: `scripts/minigames/treasure_dig.gd`, `scenes/minigames/treasure_dig.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Treasure Dig race minigame extending MiniGameBase. Player mashes spacebar to dig through layers of dirt. Each layer requires increasing presses (base 5, +2 per layer). Visual depth bar fills from bottom to top with color shifting from brown to gold. Race to reach depth 10. Registered "Treasure Dig" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed. Integration test `bash tests/run_integration.sh "Treasure Dig"` passed with both host and client reaching EndGame with positive scores.

## Task 55: Light Switch minigame - DONE
- Files created/modified: `scripts/minigames/light_switch.gd`, `scenes/minigames/light_switch.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Light Switch race minigame extending MiniGameBase. Two 4x4 grids side by side: target pattern (5-10 random lit cells) and player grid (all off). Player clicks cells to toggle individual lights to match the target. Race to solve 5 puzzles. Score = puzzles solved. Registered "Light Switch" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed. Integration test `bash tests/run_integration.sh "Light Switch"` passed with both host and client reaching EndGame with positive scores.

## Task 56: Ice Breaker minigame - DONE
- Files created/modified: `scripts/minigames/ice_breaker.gd`, `scenes/minigames/ice_breaker.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Ice Breaker race minigame extending MiniGameBase. A power bar oscillates a white indicator back and forth; player presses spacebar when the indicator is in the green zone to break an ice block. Green zone repositions randomly after each break and shrinks as progress increases. Speed increases with each block broken. Miss penalty resets indicator position with a brief pause. Race to 12 blocks broken. Registered "Ice Breaker" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed. Integration test `bash tests/run_integration.sh "Ice Breaker"` passed with both host and client reaching EndGame with positive scores.

## Task 57: Bubble Pop minigame - DONE
- Files created/modified: `scripts/minigames/bubble_pop.gd`, `scenes/minigames/bubble_pop.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Bubble Pop race minigame extending MiniGameBase. Bubbles with random letters (A-Z) float upward from the bottom of a play area. Player types the letter on a bubble to pop it, targeting the lowest matching bubble first. Bubbles that float off the top are removed. Race to 20 popped. Score = number of bubbles popped. Uses custom draw for bubble rendering with circle + letter. Registered "Bubble Pop" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed. Integration test `bash tests/run_integration.sh "Bubble Pop"` passed with both host and client reaching EndGame with positive scores.

## Task 58: Mirror Draw minigame - DONE
- Files created/modified: `scripts/minigames/mirror_draw.gd`, `scenes/minigames/mirror_draw.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Mirror Draw race minigame extending MiniGameBase. An arrow sequence is shown one at a time (flash + pause), then the full sequence is displayed and the player must input it in reverse order using arrow keys. Sequence starts at length 3 and grows by 1 every 3 completions. Wrong input resets the current attempt. Race to 8 sequences reversed. Score = sequences reversed. Registered "Mirror Draw" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed. Integration test `bash tests/run_integration.sh "Mirror Draw"` passed with both host and client reaching EndGame with positive scores.

## Task 59: Rotation Lock minigame - DONE
- Files created/modified: `scripts/minigames/rotation_lock.gd`, `scenes/minigames/rotation_lock.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Rotation Lock race minigame extending MiniGameBase. A pointer rotates around a circular dial rendered via custom _draw. A green target zone arc appears at a random angle. Player presses spacebar when the pointer aligns with the target. Target arc shrinks as progress increases (30 -> 15 degrees). Rotation speed increases with each hit (+12 deg/s). Miss penalty pauses briefly. Race to 10 targets hit. Score = targets hit. Registered "Rotation Lock" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed. Integration test `bash tests/run_integration.sh "Rotation Lock"` passed with both host and client reaching EndGame with positive scores.

## Task 60: Word Chain minigame - DONE
- Files created/modified: `scripts/minigames/word_chain.gd`, `scenes/minigames/word_chain.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Word Chain race minigame extending MiniGameBase. A word is displayed and the player must type a word from the built-in word list that starts with the last letter of the current word. Valid answers become the new current word, continuing the chain. Words can't be reused. Uses a 120-word curated word list indexed by first letter for validation. Race to 8 chains. Score = chains completed. Registered "Word Chain" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed. Integration test `bash tests/run_integration.sh "Word Chain"` passed with both host and client reaching EndGame with positive scores.

## Task 61: Number Crunch minigame - DONE
- Files created/modified: `scripts/minigames/number_crunch.gd`, `scenes/minigames/number_crunch.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Number Crunch race minigame extending MiniGameBase. Numbers stream on screen (mix of primes and composites, ~40% primes). Player presses spacebar only when the number is prime. Correct prime presses score a point, wrong presses show error feedback. Numbers auto-advance after a timer that gets shorter with progress (1.5s down to 0.7s). Missing a prime also shows feedback. Race to 12 correct. Score = correct prime identifications. Registered "Number Crunch" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed. Integration test `bash tests/run_integration.sh "Number Crunch"` passed with both host and client reaching EndGame with positive scores.

## Task 62: Pipe Connect minigame - DONE
- Files created/modified: `scripts/minigames/pipe_connect.gd`, `scenes/minigames/pipe_connect.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Pipe Connect race minigame extending MiniGameBase. A 5x4 grid of pipe tiles with a path generated from a start point (left edge) to an end point (right edge). Player clicks tiles to rotate them 90 degrees clockwise. Pipes visually show connections (UP/DOWN/LEFT/RIGHT) and highlight green when connected to the start. Path generation uses random walk with backtracking. Puzzle randomization rotates tiles randomly and verifies puzzle isn't already solved. Race to 5 puzzles solved. Score = puzzles solved. Registered "Pipe Connect" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed. Integration test `bash tests/run_integration.sh "Pipe Connect"` passed with both host and client reaching EndGame with positive scores.

## Task 63: Falling Letters minigame - DONE
- Files created/modified: `scripts/minigames/falling_letters.gd`, `scenes/minigames/falling_letters.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Falling Letters race minigame extending MiniGameBase. Letters rain down from the top of a play area, getting faster over time. Player types the matching letter key to catch them before they hit the bottom. Targets the lowest matching letter first. Letters shift from white to red as they approach the bottom. Spawn rate and fall speed increase with progress. Race to 25 typed. Score = letters typed. Registered "Falling Letters" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed. Integration test `bash tests/run_integration.sh "Falling Letters"` passed with both host and client reaching EndGame with positive scores.

## Task 64: Color Flood minigame - DONE
- Files created/modified: `scripts/minigames/color_flood.gd`, `scenes/minigames/color_flood.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Color Flood race minigame extending MiniGameBase. An 8x8 grid of randomly colored cells (5 colors). Player clicks color buttons to flood-fill from the top-left corner, expanding all connected same-color cells to the chosen color. Goal is to make the entire grid one color. BFS flood fill algorithm. Race to clear 5 boards. Score = boards cleared. Registered "Color Flood" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed. Integration test `bash tests/run_integration.sh "Color Flood"` passed with both host and client reaching EndGame with positive scores.

## Task 65: Spot the Diff minigame - DONE
- Files created/modified: `scripts/minigames/spot_the_diff.gd`, `scenes/minigames/spot_the_diff.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Spot the Diff race minigame extending MiniGameBase. Two 5x5 grids shown side-by-side with identical random colors except one cell differs on the right grid. Player clicks the differing cell to score. Each correct click generates a new puzzle. Wrong clicks show brief feedback. Race to find 8 differences. Score = differences found. Registered "Spot the Diff" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed. Integration test `bash tests/run_integration.sh "Spot the Diff"` passed with both host and client reaching EndGame with positive scores.

## Task 66: Conveyor Sort minigame - DONE
- Files created/modified: `scripts/minigames/conveyor_sort.gd`, `scenes/minigames/conveyor_sort.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Conveyor Sort race minigame extending MiniGameBase. Items slide across a conveyor belt from left to right. Player presses LEFT or RIGHT arrow to sort items into the correct bin based on category pairs (e.g., FRUIT/VEGGIE, HOT/COLD, LAND/SEA). Items must be sorted while in the decision zone (30%-70% of play area). Items that pass the zone unsorted count as wrong. Race to 15 correctly sorted. Score = items sorted correctly. Registered "Conveyor Sort" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed. Integration test `bash tests/run_integration.sh "Conveyor Sort"` passed with both host and client reaching EndGame with positive scores.

## Task 67: Hex Match minigame - DONE
- Files created/modified: `scripts/minigames/hex_match.gd`, `scenes/minigames/hex_match.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Hex Match race minigame extending MiniGameBase. A hex color code (e.g., #A0F060) is displayed and 4 color swatches are shown. Player clicks the swatch matching the hex code. Colors are generated in steps of 16 for readable hex values. Distractors must differ by at least 48 in some channel to be visually distinct. Race to 10 correct matches. Score = matches made. Registered "Hex Match" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed. Integration test `bash tests/run_integration.sh "Hex Match"` passed with both host and client reaching EndGame with positive scores.

## Task 68: Countdown Catch minigame - DONE
- Files created/modified: `scripts/minigames/countdown_catch.gd`, `scenes/minigames/countdown_catch.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Countdown Catch race minigame extending MiniGameBase. A timer counts down from a random number (3-7 seconds). Player presses spacebar at exactly 0 - closest to zero scores best. Best of 5 attempts. Score = 10000 - best_error_ms (higher = better). Attempt markers color-code results (green/yellow/red). Countdown display shifts from white to red as it approaches zero. Registered "Countdown Catch" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed. Integration test `bash tests/run_integration.sh "Countdown Catch"` passed with both host and client reaching EndGame with positive scores.

## Task 69: Signal Flag minigame - DONE
- Files created/modified: `scripts/minigames/signal_flag.gd`, `scenes/minigames/signal_flag.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Signal Flag race minigame extending MiniGameBase. A 4x4 grid of colored squares displays a flag pattern from 26 NATO phonetic alphabet flags. Player selects the matching flag name from 4 multiple-choice buttons. Race to 10 correct identifications. Score = number of correct IDs. Tracks used flags to avoid repeats. Registered "Signal Flag" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed. Integration test `bash tests/run_integration.sh "Signal Flag"` passed with both host and client reaching EndGame with positive scores.

## Task 70: Speed Clicker minigame - DONE
- Files created/modified: `scripts/minigames/speed_clicker.gd`, `scenes/minigames/speed_clicker.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Speed Clicker race minigame extending MiniGameBase. Green and red targets spawn at random positions in the play area with decreasing intervals. Player clicks green targets to score (+1), clicking red targets penalizes (-1, min 0). Targets expire after 1.2 seconds. Spawn rate increases over time. Race to 15 correct green clicks. Score = correct green clicks. Registered "Speed Clicker" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed. Integration test `bash tests/run_integration.sh "Speed Clicker"` passed with both host and client reaching EndGame with positive scores.

## Task 71: Digit Span minigame - DONE
- Files created/modified: `scripts/minigames/digit_span.gd`, `scenes/minigames/digit_span.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Digit Span race minigame extending MiniGameBase. Digits are shown one at a time in increasing sequence lengths (starting at 2). Player memorizes the sequence, then types it back via LineEdit. Correct recall advances to next length, wrong answer retries same length with new sequence. Race to recall length 9. Score = number of lengths completed. Registered "Digit Span" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed. Integration test `bash tests/run_integration.sh "Digit Span"` passed with both host and client reaching EndGame with positive scores.

## Task 72: Block Breaker minigame - DONE
- Files created/modified: `scripts/minigames/block_breaker.gd`, `scenes/minigames/block_breaker.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Block Breaker race minigame extending MiniGameBase. Classic breakout gameplay: paddle moves with arrow keys, ball bounces to break colored blocks (4 rows x 8 cols). Ball reflects off walls, paddle, and blocks. Ball angle varies based on paddle hit position. Blocks respawn if all cleared before target. Ball resets if it falls below paddle. Race to 20 blocks broken. Score = blocks broken. Registered "Block Breaker" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed. Integration test `bash tests/run_integration.sh "Block Breaker"` passed with both host and client reaching EndGame with positive scores.

## Task 73: Tug of War minigame - DONE
- Files created/modified: `scripts/minigames/tug_of_war.gd`, `scenes/minigames/tug_of_war.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Tug of War race minigame extending MiniGameBase. A rope marker starts at center and drifts toward the opponent side. Player mashes spacebar to pull it toward their side. Drift accelerates over time. Marker color shifts green/yellow/red based on position. Race to pull marker to your end (position >= 1.0). Score = total presses. Registered "Tug of War" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed. Integration test `bash tests/run_integration.sh "Tug of War"` passed with both host and client reaching EndGame with positive scores.

## Task 74: Anagram Solve minigame - DONE
- Files created/modified: `scripts/minigames/anagram_solve.gd`, `scenes/minigames/anagram_solve.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Anagram Solve race minigame extending MiniGameBase. A scrambled word is shown from a 50-word list (6-7 letter words). Player types the correct unscrambled word and presses Enter. Shows letter count as hint. Correct answers advance, wrong answers reveal the word. Fisher-Yates shuffle ensures scrambled form differs from original. Race to 8 solved. Score = words solved. Registered "Anagram Solve" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed. Integration test `bash tests/run_integration.sh "Anagram Solve"` passed with both host and client reaching EndGame with positive scores.

## Task 75: Math Sign minigame - DONE
- Files created/modified: `scripts/minigames/math_sign.gd`, `scenes/minigames/math_sign.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Math Sign race minigame extending MiniGameBase. An equation with a missing operator is displayed (e.g., "5 ? 3 = 15"). Player presses the correct operator key (+, -, *, /) on the keyboard. Equations are generated to always have integer results. Division uses whole-number divisors, subtraction ensures non-negative results. Race to 12 correct. Score = correct answers. Supports both regular and numpad keys, with Shift+= for + and Shift+8 for *. Registered "Math Sign" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed. Integration test `bash tests/run_integration.sh "Math Sign"` passed with both host and client reaching EndGame with positive scores.

## Task 76: Photo Memory minigame - DONE
- Files created/modified: `scripts/minigames/photo_memory.gd`, `scenes/minigames/photo_memory.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Photo Memory race minigame extending MiniGameBase. A 4x4 grid of face-down cards with symbol pairs. Player clicks cards to flip them, revealing colored letters. Flipping two cards checks for a match - matched pairs stay revealed, mismatches flip back after 0.6s. Race to clear the board (find all 8 pairs). Score = pairs found. Registered "Photo Memory" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed. Integration test `bash tests/run_integration.sh "Photo Memory"` passed with both host and client reaching EndGame with positive scores.

## Task 77: Greater Than minigame - DONE
- Files created/modified: `scripts/minigames/greater_than.gd`, `scenes/minigames/greater_than.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Greater Than race minigame extending MiniGameBase. Two random numbers (1-99, always different) are displayed side by side. Player presses left or right arrow key to select the larger number. Correct presses advance to the next pair, wrong presses show which side was bigger. Race to 15 correct. Score = correct answers. Registered "Greater Than" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed. Integration test `bash tests/run_integration.sh "Greater Than"` passed with both host and client reaching EndGame with positive scores.

## Task 78: Shadow Match minigame - DONE
- Files created/modified: `scripts/minigames/shadow_match.gd`, `scenes/minigames/shadow_match.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Shadow Match race minigame extending MiniGameBase. A dark silhouette of a shape (from 10 types: circle, square, triangle, diamond, star, cross, pentagon, hexagon, arrow, heart) is displayed at the top. Four colored shape options are shown below. Player clicks the matching shape. Shapes are drawn using custom _draw with parametric curves and polygon rendering. Race to 10 correct matches. Score = matches made. Registered "Shadow Match" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed. Integration test `bash tests/run_integration.sh "Shadow Match"` passed with both host and client reaching EndGame with positive scores.

## Task 79: Stack Tower minigame - DONE
- Files created/modified: `scripts/minigames/stack_tower.gd`, `scenes/minigames/stack_tower.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Stack Tower survival minigame extending MiniGameBase. A white block slides back and forth across the top of the stack. Player presses spacebar to drop it. The block is trimmed to the overlapping portion with the block below — miss entirely and you're eliminated. Stack grows upward with camera scrolling. Block speed increases with each successful drop. Blocks are colored by hue rotation for visual variety. Score = survival time in tenths of seconds. Registered "Stack Tower" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed. Integration test `bash tests/run_integration.sh "Stack Tower"` passed with both host and client reaching EndGame with positive scores.

## Task 80: Cliff Hanger minigame - DONE
- Files created/modified: `scripts/minigames/cliff_hanger.gd`, `scenes/minigames/cliff_hanger.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Cliff Hanger survival minigame extending MiniGameBase. Character slides toward a cliff edge with increasing speed. Player taps spacebar to brake. Each tap reduces speed by a fixed amount. If speed reaches zero, a new round starts with higher base speed. Overshooting the cliff eliminates the player. Visual feedback includes color-coded player (green/yellow/red by proximity), speed bar, ground/cliff rendering. Score = survival time in tenths of seconds. Registered "Cliff Hanger" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed. Integration test `bash tests/run_integration.sh "Cliff Hanger"` passed with both host and client reaching EndGame with positive scores.

## Task 81: Voltage Surge minigame - DONE
- Files created/modified: `scripts/minigames/voltage_surge.gd`, `scenes/minigames/voltage_surge.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Voltage Surge survival minigame extending MiniGameBase. Player holds spacebar to charge a voltage meter that fluctuates unpredictably with sine-based noise. Must release when voltage is in the green target zone (60-85%). Releasing too low or too high fails the round. Overloading (hitting 100%) eliminates the player. Fluctuation strength increases each round. Visual vertical meter with color-coded zones (blue=low, green=target, red=danger) and charging glow effect. Score = survival time in tenths of seconds. Registered "Voltage Surge" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed. Integration test `bash tests/run_integration.sh "Voltage Surge"` passed with both host and client reaching EndGame with positive scores.

## Task 82: Wrecking Ball minigame - DONE
- Files created/modified: `scripts/minigames/wrecking_ball.gd`, `scenes/minigames/wrecking_ball.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Wrecking Ball survival minigame extending MiniGameBase. A wrecking ball sweeps across the screen at varying heights (low or high) from random directions. Player must jump (spacebar) over low swings or duck (down arrow) under high swings. Warning indicators appear before each ball. Speed and frequency increase over time. Getting hit eliminates the player. Score = survival time in tenths of seconds. Registered "Wrecking Ball" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed. Integration test `bash tests/run_integration.sh "Wrecking Ball"` passed with both host and client reaching EndGame with positive scores.

## Task 83: Gravity Well minigame - DONE
- Files created/modified: `scripts/minigames/gravity_well.gd`, `scenes/minigames/gravity_well.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Gravity Well survival minigame extending MiniGameBase. Player orbits a central gravity well with increasing outward drift. Arrow keys control thrust: UP pulls inward toward center, DOWN pushes outward, LEFT/RIGHT adjust angular velocity. Orbit drifts outward over time with increasing acceleration. Player is eliminated if they drift off screen. Visual feedback includes orbit trail, color-coded player (green/yellow/red by distance), danger zone boundary, and orbit ring guides. Score = survival time in tenths of seconds. Registered "Gravity Well" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed. Integration test `bash tests/run_integration.sh "Gravity Well"` passed with both host and client reaching EndGame with positive scores.

## Task 84: Thermal Rise minigame - DONE
- Files created/modified: `scripts/minigames/thermal_rise.gd`, `scenes/minigames/thermal_rise.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Thermal Rise survival minigame extending MiniGameBase. Character floats upward automatically through gaps in horizontal platforms. Use left/right arrow keys to navigate through gaps. Platforms scroll downward with increasing speed. Gap width shrinks over time. Hitting a platform eliminates the player. Visual feedback includes heat effect at bottom, glowing player, gap edge highlights. Score = survival time in tenths of seconds. Registered "Thermal Rise" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed. Integration test `bash tests/run_integration.sh "Thermal Rise"` passed with both host and client reaching EndGame with positive scores.

## Task 85: Rail Grind minigame - DONE
- Files created/modified: `scripts/minigames/rail_grind.gd`, `scenes/minigames/rail_grind.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Rail Grind survival minigame extending MiniGameBase. Character rides on one of 3 horizontal rails. Obstacles scroll from right to left with increasing speed. Press UP/DOWN to switch tracks and dodge obstacles. Sometimes 2 tracks are blocked simultaneously (after 3s). Hitting an obstacle eliminates the player. Score = survival time in tenths of seconds. Registered "Rail Grind" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed. Integration test `bash tests/run_integration.sh "Rail Grind"` passed with both host and client reaching EndGame with positive scores.

## Task 86: Wind Runner minigame - DONE
- Files created/modified: `scripts/minigames/wind_runner.gd`, `scenes/minigames/wind_runner.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Wind Runner survival minigame extending MiniGameBase. Wind gusts push the player in random directions with increasing strength. Use all four arrow keys to counter the wind and stay within the arena bounds. Occasional powerful gusts (2.5x multiplier) add danger. Wind particles show direction. Player color shifts green to red based on proximity to edges. Getting blown off the edge eliminates the player. Score = survival time in tenths of seconds. Registered "Wind Runner" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed. Integration test `bash tests/run_integration.sh "Wind Runner"` passed with both host and client reaching EndGame with positive scores.

## Task 87: Pinball Bounce minigame - DONE
- Files created/modified: `scripts/minigames/pinball_bounce.gd`, `scenes/minigames/pinball_bounce.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Pinball Bounce survival minigame extending MiniGameBase. Ball bounces around the play area, player moves a paddle at the bottom with LEFT/RIGHT arrow keys. Ball speed increases and paddle shrinks over time. Ball angle varies based on where it hits the paddle. Missing the ball eliminates the player. Score = survival time in tenths of seconds. Registered "Pinball Bounce" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed. Integration test `bash tests/run_integration.sh "Pinball Bounce"` passed with both host and client reaching EndGame with positive scores.

## Task 88: Snake Grow minigame - DONE
- Files created/modified: `scripts/minigames/snake_grow.gd`, `scenes/minigames/snake_grow.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Snake Grow survival minigame extending MiniGameBase. Classic snake on a 20x15 grid. Arrow keys change direction. Eat dots to grow. Hitting walls or your own body eliminates you. Movement speed increases over time. Snake has color gradient from head to tail. Score = survival time in tenths of seconds. Registered "Snake Grow" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed. Integration test `bash tests/run_integration.sh "Snake Grow"` passed with both host and client reaching EndGame with positive scores.

## Task 89: Tornado Dodge minigame - DONE
- Files created/modified: `scripts/minigames/tornado_dodge.gd`, `scenes/minigames/tornado_dodge.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Tornado Dodge survival minigame extending MiniGameBase. Tornadoes wander the arena with semi-random movement, bouncing off walls. More spawn over time (up to 12). Player moves with all four arrow keys. Tornado speed increases over time. Spinning visual effect for tornadoes. Touching a tornado eliminates the player. Score = survival time in tenths of seconds. Registered "Tornado Dodge" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed. Integration test `bash tests/run_integration.sh "Tornado Dodge"` passed with both host and client reaching EndGame with positive scores.

## Task 90: Platform Jump minigame - DONE
- Files created/modified: `scripts/minigames/platform_jump.gd`, `scenes/minigames/platform_jump.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Platform Jump survival minigame extending MiniGameBase. Platforms scroll from right to left with increasing speed. Player uses LEFT/RIGHT to move and SPACE to jump. Gravity pulls player down. Landing on platforms keeps you alive. Falling off the bottom eliminates you. Platforms have random width and height variance. Score = survival time in tenths of seconds. Registered "Platform Jump" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed. Integration test `bash tests/run_integration.sh "Platform Jump"` passed with both host and client reaching EndGame with positive scores.

## Task 91: Decoy Detect minigame - DONE
- Files created/modified: `scripts/minigames/decoy_detect.gd`, `scenes/minigames/decoy_detect.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Decoy Detect race minigame extending MiniGameBase. 12 dots move around a play area — all move in the same direction/speed except one decoy that moves faster and in a different direction. Player clicks the odd one out. Dots bounce off walls. Correct click spawns a new round, wrong click shows error feedback. Race to 10 spotted. Score = number of decoys spotted. Registered "Decoy Detect" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed. Integration test `bash tests/run_integration.sh "Decoy Detect"` passed with both host and client reaching EndGame with positive scores.

## Task 92: Sinking Ship minigame - DONE
- Files created/modified: `scripts/minigames/sinking_ship.gd`, `scenes/minigames/sinking_ship.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Sinking Ship survival minigame extending MiniGameBase. Ship hull rendered with wooden planks. Water rises based on base rate + active leak count. Leaks spawn on hull walls (left, right, bottom) with pulsing visual effect and spray lines. Player clicks leaks to plug them, which also drains a small amount of water. Water level shown visually inside hull and as a side bar that color-shifts (blue/yellow/red). Ship sinking (water 100%) eliminates the player. Score = survival time in tenths of seconds. Registered "Sinking Ship" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed. Integration test `bash tests/run_integration.sh "Sinking Ship"` passed with both host and client reaching EndGame with positive scores.

## Task 93: Flag Raise minigame - DONE
- Files created/modified: `scripts/minigames/flag_raise.gd`, `scenes/minigames/flag_raise.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Flag Raise race minigame extending MiniGameBase. A beat indicator oscillates across a bar; player taps spacebar when it's in the green zone to raise a flag. Good taps raise the flag by 8%, off-rhythm taps lower it by 5%. Flag color shifts from red (bottom) to green (top). Beat zone repositions every 3 good taps for variety. Indicator speed derived from 90 BPM. Race to raise the flag to 100%. Score = number of good taps. Registered "Flag Raise" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed. Integration test `bash tests/run_integration.sh "Flag Raise"` passed with both host and client reaching EndGame with positive scores.

## Task 94: Bumper Cars minigame - DONE
- Files created/modified: `scripts/minigames/bumper_cars.gd`, `scenes/minigames/bumper_cars.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Bumper Cars survival minigame extending MiniGameBase. Player moves in an arena with arrow keys while AI bumper cars roam randomly, bouncing off walls and changing direction periodically. Colliding with a car applies knockback force that can push the player out of bounds. More cars spawn over time (up to 10), speed increases, and knockback force grows. Cars have colorful hue-varied appearances. Player color shifts green-to-red near edges. Getting knocked out of bounds eliminates the player. Score = survival time in tenths of seconds. Registered "Bumper Cars" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed. Integration test `bash tests/run_integration.sh "Bumper Cars"` passed with both host and client reaching EndGame with positive scores.

## Task 95: Flip Memory minigame - DONE
- Files created/modified: `scripts/minigames/flip_memory.gd`, `scenes/minigames/flip_memory.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Flip Memory race minigame extending MiniGameBase. A 5x4 grid (20 cards, 10 pairs) of face-down cards with colored numbers. Player clicks to flip two cards at a time. Matching pairs stay revealed, mismatches flip back after 0.6s. Race to find all 10 pairs. Score = pairs found. Registered "Flip Memory" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed. Integration test `bash tests/run_integration.sh "Flip Memory"` passed with both host and client reaching EndGame with positive scores.

## Task 96: Firewalk minigame - DONE
- Files created/modified: `scripts/minigames/firewalk.gd`, `scenes/minigames/firewalk.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Firewalk survival minigame extending MiniGameBase. An 8x6 grid of floor tiles where tiles randomly ignite (warning phase with pulsing yellow, then fire phase with red/orange flames). Player moves between tiles with arrow keys (grid-based with smooth interpolation). Standing on a burning tile eliminates the player. Fire spawn rate and count increase over time (1-3 tiles per wave). Warning gives 1.2s to react, fire lasts 2.5s. Score = survival time in tenths of seconds. Registered "Firewalk" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed. Integration test `bash tests/run_integration.sh "Firewalk"` passed with both host and client reaching EndGame with positive scores.

## Task 97: Rocket Launch minigame - DONE
- Files created/modified: `scripts/minigames/rocket_launch.gd`, `scenes/minigames/rocket_launch.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Rocket Launch race minigame extending MiniGameBase. Player holds spacebar to charge a power meter that fills continuously. Release in the green zone (40-60%) for a good launch — closer to center (50%) is better. Overcharging to 100% auto-releases. Best of 5 attempts. Score = 10000 - (best_error * 10000), higher is better. Visual meter with red/green zones and charge indicator. Attempt markers color-code results. Registered "Rocket Launch" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed. Integration test `bash tests/run_integration.sh "Rocket Launch"` passed with both host and client reaching EndGame with positive scores.

## Task 98: Frequency Match minigame - DONE
- Files created/modified: `scripts/minigames/frequency_match.gd`, `scenes/minigames/frequency_match.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Frequency Match race minigame extending MiniGameBase. A visual sine wave animates at the target frequency. Player selects the matching frequency bar from 4 choices with varying heights and colors (blue=low, red=high). Frequencies range from 1.0-6.0 Hz with bars sized proportionally. Wrong clicks show error feedback. Race to 10 correct matches. Score = matches made. Registered "Frequency Match" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed. Integration test `bash tests/run_integration.sh "Frequency Match"` passed with both host and client reaching EndGame with positive scores.

## Task 99: Symbol Match minigame - DONE
- Files created/modified: `scripts/minigames/symbol_match.gd`, `scenes/minigames/symbol_match.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Symbol Match race minigame extending MiniGameBase. A 4x4 grid of face-up symbols (8 pairs using @, #, $, %, &, *, +, =) with distinct colors. Player clicks two matching symbols to clear them. Selected cards get a colored border highlight, mismatches flash red briefly. Race to clear all 8 pairs. Score = pairs cleared. Registered "Symbol Match" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed. Integration test `bash tests/run_integration.sh "Symbol Match"` passed with both host and client reaching EndGame with positive scores.

## Task 100: Capital Quiz minigame - DONE
- Files created/modified: `scripts/minigames/capital_quiz.gd`, `scenes/minigames/capital_quiz.tscn`, `scripts/autoloads/game_manager.gd`
- What was done: Created Capital Quiz race minigame extending MiniGameBase. A country name is displayed and the player types its capital city via LineEdit. Case-insensitive comparison. 40 well-known country-capital pairs. Correct answers advance to next country, wrong answers reveal the capital. Race to 8 correct. Score = correct answers. Registered "Capital Quiz" in GameManager.MINIGAME_REGISTRY.
- Verification: Godot headless run passed. Integration test `bash tests/run_integration.sh "Capital Quiz"` passed with both host and client reaching EndGame with positive scores.
