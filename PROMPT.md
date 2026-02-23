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
- [ ] Task 4: Register autoloads in project.godot, set main scene

### Phase 2: UI Screens
- [ ] Task 5: MainMenu scene+script - host/join buttons, name input, IP input
- [ ] Task 6: Lobby scene+script - player list, start button (host only), back button
- [ ] Task 7: Scoreboard scene+script - round scores, cumulative scores, continue button (host only)
- [ ] Task 8: EndGame scene+script - final standings, winner display, return to menu button

### Phase 3: First Mini-Game
- [ ] Task 9: Button Masher minigame - mash spacebar, count presses, 10s timer, extends MiniGameBase
- [ ] Task 10: End-to-end flow test - verify full game loop works: menu -> lobby -> countdown -> game -> scoreboard -> end

### Phase 4: More Mini-Games (one per task)
- [ ] Task 11: Reaction Time minigame
- [ ] Task 12: Quick Math minigame
- [ ] Task 13: Target Click minigame
- [ ] Task 14: Color Match minigame
- [ ] Task 15: Memory Sequence minigame
- [ ] Task 16: Dodge Falling minigame
- [ ] Task 17: Rhythm Tap minigame
```

## Rules for Each Task

### What to Build
- Follow the architecture in CLAUDE.md exactly (directory structure, naming, patterns)
- Use strongly typed GDScript everywhere
- Use ColorRect placeholders for all UI — no art assets
- Every .tscn scene must have its matching .gd script
- Every minigame extends MiniGameBase and registers itself in GameManager.MINIGAME_REGISTRY

### How to Verify
After completing each task, run:
```bash
godot --headless --check-only
```
If that is not available or errors, at minimum:
- Read back every file you created/modified and confirm no syntax errors
- Confirm all scene node paths referenced in scripts match the .tscn structure
- Confirm all autoload paths in project.godot point to real files

Fix any errors before marking the task done.

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
