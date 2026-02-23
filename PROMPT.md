# WarioParty - Autonomous Build Prompt

You are building a networked multiplayer Wario-Ware party game in Godot 4.3+ with GDScript.

Read CLAUDE.md for architecture and coding standards. Read PRD.md for full requirements.

## Task Tracking

A file called `TASKS.md` tracks all progress. On every iteration:
1. Read `TASKS.md` to see what's done and what's next
2. Pick the FIRST uncompleted task
3. Mark it `[IN PROGRESS]` and save the file
4. Do the work
5. Verify the work (see verification below)
6. Mark it `[DONE]` and save the file
7. Write a brief summary of what you did to `PROGRESS.md` (append, don't overwrite)

If `TASKS.md` does not exist, create it with the task list below.

## Task List (in order)

```
### Phase 1: Core Architecture
- [ ] Task 1: NetworkManager autoload - host/join/disconnect, player registry, RPC sync
- [ ] Task 2: GameManager autoload - score tracking, round progression, minigame registry, scene transitions
- [ ] Task 3: MiniGameBase class - countdown timer, game timer, score submission, _on_game_start/_on_game_end hooks
- [ ] Task 4: MainMenu scene+script - host/join buttons, name input, IP input. Register autoloads in project.godot, update main scene from default.tscn to main_menu.tscn, delete scenes/default.tscn

### Phase 2: UI Screens
- [ ] Task 5: Lobby scene+script - player list, start button (host only), back button
- [ ] Task 6: Scoreboard scene+script - round scores, cumulative scores, continue button (host only)
- [ ] Task 7: EndGame scene+script - final standings, winner display, return to menu button

### Phase 3: First Mini-Game
- [ ] Task 8: Button Masher minigame - mash spacebar, count presses, 10s timer, extends MiniGameBase
- [ ] Task 9: End-to-end flow test - verify full game loop works: menu -> lobby -> countdown -> game -> scoreboard -> end

### Phase 4: More Mini-Games (one per task)
- [ ] Task 10: Reaction Time minigame
- [ ] Task 11: Quick Math minigame
- [ ] Task 12: Target Click minigame
- [ ] Task 13: Color Match minigame
- [ ] Task 14: Memory Sequence minigame
- [ ] Task 15: Dodge Falling minigame
- [ ] Task 16: Rhythm Tap minigame
```

## Rules for Each Task

### What to Build
- Follow the architecture in CLAUDE.md exactly (directory structure, naming, patterns)
- Use strongly typed GDScript everywhere
- Use ColorRect placeholders for all UI — no art assets
- Every .tscn scene must have its matching .gd script
- Every minigame extends MiniGameBase and registers itself in GameManager.MINIGAME_REGISTRY

### How to Verify
After completing each task, run through this full checklist. Do NOT skip any step.

1. **Run Godot**: Execute the project headless to catch load/parse errors:
```bash
/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path . --quit-after 5 --log-file ./godot_test.log 2>&1
cat godot_test.log
rm -f godot_test.log
```
Ignore the CA certificate error (sandbox, harmless). Any other ERROR or crash means the task is NOT done — fix it first.

2. **Syntax check**: Read back every file you created or modified. Confirm no GDScript parse errors.
2. **Scene-script consistency**: Every `$NodePath` or `@onready var x = $Path` in a .gd file must match a node in the corresponding .tscn file.
3. **Autoload paths**: Every path in project.godot `[autoload]` must point to a file that exists.
4. **Registry integrity**: `GameManager._ready()` must ONLY register minigames whose .tscn AND .gd files exist in the project RIGHT NOW. Never register future/unbuilt minigames.
5. **Array bounds safety**: Any `array[index]` access must be guarded — verify the array cannot be empty at that point. Trace the code path that populates the array and confirm it runs before the access.
6. **RPC + state ordering**: If a function builds state then calls an RPC with `call_local`, the local RPC fires synchronously and may clobber the state. Verify this can't happen. Preferred pattern: server sets its own state directly, then uses RPC (without `call_local`) to sync clients only.
7. **Game flow trace**: Mentally walk through the full game path for the current state of the project:
   - menu → lobby (auto-start 5s) → start_game() → advance_round() → minigame scene loads → play until completion/timeout → score submit → scoreboard (auto-advance 5s) → next round or end game (auto-return 10s)
   - At each step, confirm no variable is empty/null/uninitialized when accessed
   - Confirm every `change_scene_to_file()` path points to an existing .tscn file
   - Verify that `mark_completed()` and `force_end_game()` paths correctly submit scores and transition
8. **Integration test**: Run `bash tests/run_integration.sh` to verify the full multiplayer flow end-to-end with simulated inputs.

If ANY check fails, fix the issue before marking the task done.

**CRITICAL**: Read CLAUDE.md "Known Pitfalls" section before writing any code. These are bugs that have already happened and MUST be avoided.

### How to Checkpoint Progress
After each completed task, append to `PROGRESS.md`:
```
## Task N: <name> - DONE
- Files created/modified: <list>
- What was done: <1-2 sentences>
- Verification: <pass/fail + details>
```

### Git Commits
After each task is verified:
```bash
git add -A && git commit -m "Task N: <short description>"
```

## Completion Signal

When ALL tasks in TASKS.md are marked `[DONE]`, output exactly:
```
<promise>COMPLETE</promise>
```

If there are still uncompleted tasks, do NOT output the completion signal. Just do one task per iteration and end your output normally.

## Important
- Do ONE task per iteration, then stop
- Always read TASKS.md first to know where you left off
- Always update TASKS.md and PROGRESS.md
- Always commit after each task
- If a task fails verification, fix it in the same iteration before marking done
- Do not skip tasks or reorder them
