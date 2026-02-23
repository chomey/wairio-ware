# WarioParty - Task Tracker

### Phase 1: Core Architecture
- [DONE] Task 1: NetworkManager autoload - host/join/disconnect, player registry, RPC sync
- [DONE] Task 2: GameManager autoload - score tracking, round progression, minigame registry, scene transitions
- [DONE] Task 3: MiniGameBase class - countdown timer, game timer, score submission, _on_game_start/_on_game_end hooks
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
