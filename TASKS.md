# WarioParty - Task Tracker

### Phase 1: Core Architecture
- [DONE] Task 1: NetworkManager autoload - host/join/disconnect, player registry, RPC sync
- [DONE] Task 2: GameManager autoload - score tracking, round progression, minigame registry, scene transitions
- [DONE] Task 3: MiniGameBase class - countdown timer, game timer, score submission, _on_game_start/_on_game_end hooks
- [DONE] Task 4: Register autoloads in project.godot, set main scene

### Phase 2: UI Screens
- [DONE] Task 5: MainMenu scene+script - host/join buttons, name input, IP input
- [DONE] Task 6: Lobby scene+script - player list, start button (host only), back button
- [DONE] Task 7: Scoreboard scene+script - round scores, cumulative scores, continue button (host only)
- [DONE] Task 8: EndGame scene+script - final standings, winner display, return to menu button

### Phase 3: First Mini-Game
- [DONE] Task 9: Button Masher minigame - mash spacebar, count presses, 10s timer, extends MiniGameBase
- [DONE] Task 10: End-to-end flow test - verify full game loop works: menu -> lobby -> countdown -> game -> scoreboard -> end

### Phase 4: More Mini-Games (one per task)
- [DONE] Task 11: Reaction Time minigame
- [DONE] Task 12: Quick Math minigame
- [DONE] Task 13: Target Click minigame
- [DONE] Task 14: Color Match minigame
- [DONE] Task 15: Memory Sequence minigame
- [DONE] Task 16: Dodge Falling minigame
- [DONE] Task 17: Rhythm Tap minigame

### Phase 5: Expanded Mini-Games (Race Games)
- [DONE] Task 18: Type Racer minigame - Race: type displayed words exactly (keyboard, 8 words typed)
- [DONE] Task 19: Arrow Storm minigame - Race: press matching arrow keys as prompts appear (arrow keys, 20 correct arrows)
- [DONE] Task 20: Copy Cat minigame - Race: reproduce a shown sequence of arrow presses (arrow keys, 5 sequences)
- [DONE] Task 21: Direction Dash minigame - Race: press arrow matching displayed direction word UP/DOWN/LEFT/RIGHT (arrow keys, 15 correct)
- [DONE] Task 22: Odd One Out minigame - Race: grid of colored rects, click the different one (mouse click, 10 rounds)
- [DONE] Task 23: Number Sort minigame - Race: click scattered numbers in ascending order (mouse click, sort 10 numbers)
- [DONE] Task 24: Speed Spell minigame - Race: type single displayed letters as fast as possible (keyboard, 25 letters)
- [DONE] Task 25: Pattern Match minigame - Race: two grids shown, click cells to make them match (mouse click, 8 patterns)
- [DONE] Task 26: Counting minigame - Race: objects flash on screen briefly, type the count (keyboard, 8 correct counts)
- [DONE] Task 27: Bomb Defuse minigame - Race: press displayed key sequence to defuse bombs (keyboard, 6 bombs defused)
- [DONE] Task 28: Safe Cracker minigame - Race: guess 3-digit code with hot/cold hints after each attempt (keyboard, crack the code)
- [DONE] Task 29: Word Scramble minigame - Race: unscramble anagram, type correct word (keyboard, 5 words)
- [DONE] Task 30: Morse Decode minigame - Race: short/long beep patterns shown, type the letter (keyboard, 10 letters)
- [DONE] Task 31: Pixel Painter minigame - Race: fill in marked cells in a grid by clicking them (mouse click, fill 20 cells)
- [DONE] Task 32: Rapid Toggle minigame - Race: grid of dark squares, click to light them all up (mouse click, all 16 lit)
- [DONE] Task 33: Chain Reaction minigame - Race: click to place circles that expand and trigger others (mouse click, clear 30 targets)
- [DONE] Task 34: Shopping Cart minigame - Race: item+price shown, type running total (keyboard, 8 items totaled)
- [DONE] Task 35: Binary Convert minigame - Race: decimal number shown, type binary representation (keyboard, 8 conversions)
- [DONE] Task 36: Color Mixer minigame - Race: target color shown, click R/G/B buttons to match it (mouse click, 6 colors matched)
- [DONE] Task 37: Maze Solver minigame - Race: navigate a small grid maze with arrow keys (arrow keys, reach the exit)
- [DONE] Task 38: Path Tracer minigame - Race: numbered waypoints appear, click them in order (mouse click, 3 paths traced)
- [DONE] Task 39: Equation Builder minigame - Race: given a target number and operators, type the equation (keyboard, 5 equations)

### Phase 6: Expanded Mini-Games (Survival Games)
- [ ] Task 40: Balancing Act minigame - Survival: keep a bar centered with left/right as it drifts (arrow keys, bar hits edge = eliminated)
- [ ] Task 41: Floor is Lava minigame - Survival: platforms shrink/disappear, move to stay on solid ground (arrow keys, fall off = eliminated)
- [ ] Task 42: Gravity Flip minigame - Survival: auto-scrolling platformer, press space to flip gravity (spacebar, hit obstacle = eliminated)
- [ ] Task 43: Shrinking Arena minigame - Survival: play area shrinks over time, stay inside with arrow keys (arrow keys, touch boundary = eliminated)
- [ ] Task 44: Hot Potato minigame - Survival: timer counts down, press space to throw, last holder loses (spacebar, holding when timer hits 0 = eliminated)
- [ ] Task 45: Tightrope Walk minigame - Survival: character auto-walks, press left/right to balance (arrow keys, fall off = eliminated)
- [ ] Task 46: Rising Water minigame - Survival: platforms at various heights, jump between them as water rises (arrow+space, submerged = eliminated)
- [ ] Task 47: Minefield minigame - Survival: grid of cells, click to reveal safe/mine, clear a path across (mouse click, hit mine = eliminated)
- [ ] Task 48: Asteroid Dodge minigame - Survival: ship moves in 2D, dodge asteroids from all sides (arrow keys, hit by asteroid = eliminated)
- [ ] Task 49: Conveyor Chaos minigame - Survival: stand on conveyors moving in different directions, stay in bounds (arrow keys, pushed off edge = eliminated)
- [ ] Task 50: Laser Dodge minigame - Survival: lasers sweep across arena in patterns, move to gaps (arrow keys, hit by laser = eliminated)
- [ ] Task 51: Falling Blocks minigame - Survival: tetris-like blocks fall, move/rotate to not let them stack to top (arrow+space, stack reaches top = eliminated)

### Phase 7: Expanded Mini-Games (Score-Maximizer Games)
- [ ] Task 52: Fishing minigame - Score: cast line with space, wait for bite, press space at right moment (spacebar, fish caught by timing)
- [ ] Task 53: Whack-a-Mole minigame - Score: targets pop up in grid cells briefly, click to whack (mouse click, moles whacked)
- [ ] Task 54: Coin Grab minigame - Score: coins and bombs spawn, click coins +1 avoid bombs -3 (mouse click, net coins)
- [ ] Task 55: Bouncer minigame - Score: paddle at bottom, ball bounces, break bricks above (arrow keys, bricks broken)
- [ ] Task 56: Snake minigame - Score: classic snake, eat food to grow, don't hit yourself or walls (arrow keys, length reached)
- [ ] Task 57: Treasure Dig minigame - Score: grid of cells, click to dig, some have treasure some empty (mouse click, treasure found)
- [ ] Task 58: Fruit Slicer minigame - Score: fruits move across screen, click to slice, avoid bombs (mouse click, fruits sliced)
- [ ] Task 59: Stacker minigame - Score: blocks auto-slide, press space to drop and stack aligned (spacebar, tower height)
