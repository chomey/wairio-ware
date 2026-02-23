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
- [DONE] Task 40: Balancing Act minigame - Survival: keep a bar centered with left/right as it drifts (arrow keys, bar hits edge = eliminated)
- [DONE] Task 41: Floor is Lava minigame - Survival: platforms shrink/disappear, move to stay on solid ground (arrow keys, fall off = eliminated)
- [DONE] Task 42: Gravity Flip minigame - Survival: auto-scrolling platformer, press space to flip gravity (spacebar, hit obstacle = eliminated)
- [DONE] Task 43: Shrinking Arena minigame - Survival: play area shrinks over time, stay inside with arrow keys (arrow keys, touch boundary = eliminated)
- [DONE] Task 44: Hot Potato minigame - Survival: timer counts down, press space to throw, last holder loses (spacebar, holding when timer hits 0 = eliminated)
- [DONE] Task 45: Tightrope Walk minigame - Survival: character auto-walks, press left/right to balance (arrow keys, fall off = eliminated)
- [DONE] Task 46: Rising Water minigame - Survival: platforms at various heights, jump between them as water rises (arrow+space, submerged = eliminated)
- [DONE] Task 47: Minefield minigame - Survival: grid of cells, click to reveal safe/mine, clear a path across (mouse click, hit mine = eliminated)
- [DONE] Task 48: Asteroid Dodge minigame - Survival: ship moves in 2D, dodge asteroids from all sides (arrow keys, hit by asteroid = eliminated)
- [DONE] Task 49: Conveyor Chaos minigame - Survival: stand on conveyors moving in different directions, stay in bounds (arrow keys, pushed off edge = eliminated)
- [DONE] Task 50: Laser Dodge minigame - Survival: lasers sweep across arena in patterns, move to gaps (arrow keys, hit by laser = eliminated)
**Testing:** Each new minigame must pass `bash tests/run_integration.sh "<Minigame Name>"` after implementation.

### Phase 7: New Race Mini-Games (Tasks 51–78)
- [DONE] Task 51: Simon Says minigame - Race: repeat growing sequence of arrow key inputs, first to complete 10 rounds wins (arrow keys, 10 sequences)
- [DONE] Task 52: Whack-a-Mole minigame - Race: colored squares pop up randomly in a grid, click to whack (mouse click, 20 hits)
- [DONE] Task 53: Fruit Catcher minigame - Race: move basket left/right to catch falling items, avoid bad items (arrow keys, 15 caught)
- [DONE] Task 54: Treasure Dig minigame - Race: mash keys to dig through layers of dirt (spacebar, reach depth 10)
- [DONE] Task 55: Light Switch minigame - Race: grid of lights, click to toggle, match the target pattern (mouse click, 5 puzzles solved)
- [DONE] Task 56: Ice Breaker minigame - Race: tap spacebar with correct timing to break ice blocks in sequence (spacebar, 12 blocks broken)
- [ ] Task 57: Bubble Pop minigame - Race: bubbles float up with letters on them, type the letter to pop (keyboard, 20 popped)
- [ ] Task 58: Mirror Draw minigame - Race: arrow sequence shown, input it in reverse order (arrow keys, 8 sequences reversed)
- [ ] Task 59: Rotation Lock minigame - Race: rotating dial with pointer, press space when aligned with target (spacebar, 10 targets hit)
- [ ] Task 60: Word Chain minigame - Race: given a word, type a word starting with its last letter (keyboard, 8 chains)
- [ ] Task 61: Number Crunch minigame - Race: stream of numbers shown, press space only when the number is prime (spacebar, 12 correct)
- [ ] Task 62: Pipe Connect minigame - Race: rotate pipe tiles to connect start to end (mouse click, 5 puzzles solved)
- [ ] Task 63: Falling Letters minigame - Race: letters rain down, type them before they hit the bottom (keyboard, 25 typed)
- [ ] Task 64: Color Flood minigame - Race: fill a grid by selecting colors to expand from the corner, fewest moves = best score (mouse click, clear 5 boards)
- [ ] Task 65: Spot the Diff minigame - Race: two grids shown side-by-side, click the cell that differs (mouse click, 8 found)
- [ ] Task 66: Conveyor Sort minigame - Race: items slide across, press left/right to sort into correct bins (arrow keys, 15 sorted)
- [ ] Task 67: Hex Match minigame - Race: match hex color codes to displayed colors from multiple choices (mouse click, 10 matched)
- [ ] Task 68: Countdown Catch minigame - Race: timer counts down from random number, press space at exactly 0, closest to zero scores best (spacebar, best of 5 attempts)
- [ ] Task 69: Signal Flag minigame - Race: shown a flag pattern of colored squares, select the matching name (mouse click, 10 identified)
- [ ] Task 70: Speed Clicker minigame - Race: targets appear in sequence, click only GREEN ones, avoid RED ones (mouse click, 15 correct)
- [ ] Task 71: Digit Span minigame - Race: shown increasing sequences of digits, type them back from memory (keyboard, recall length 9)
- [ ] Task 72: Block Breaker minigame - Race: paddle bounces ball to break blocks above (arrow keys, 20 blocks broken)
- [ ] Task 73: Tug of War minigame - Race: mash spacebar to pull a rope marker to your side (spacebar, marker reaches end)
- [ ] Task 74: Anagram Solve minigame - Race: scrambled word shown, type the correct unscrambled word (keyboard, 8 solved)
- [ ] Task 75: Math Sign minigame - Race: equation missing an operator (+, -, *, /), press the correct key (keyboard, 12 correct)
- [ ] Task 76: Photo Memory minigame - Race: grid of icons shown briefly then hidden, click to reveal matching pairs (mouse click, clear board)
- [ ] Task 77: Greater Than minigame - Race: two numbers flash, press left or right arrow for the larger one (arrow keys, 15 correct)
- [ ] Task 78: Shadow Match minigame - Race: shown a silhouette, pick the matching shape from 4 options (mouse click, 10 matched)

### Phase 8: New Survival Mini-Games (Tasks 79–100)
- [ ] Task 79: Stack Tower minigame - Survival: moving block slides back and forth, press space to drop and stack, miss = eliminated (spacebar, miss the stack = eliminated)
- [ ] Task 80: Cliff Hanger minigame - Survival: character slides toward cliff edge, tap to brake, overshoot = eliminated (spacebar, fall off edge = eliminated)
- [ ] Task 81: Voltage Surge minigame - Survival: bar fluctuates, hold space to charge, release before overload (spacebar, overload = eliminated)
- [ ] Task 82: Wrecking Ball minigame - Survival: swinging ball sweeps across screen, jump or duck to dodge (space/down, hit = eliminated)
- [ ] Task 83: Gravity Well minigame - Survival: player orbits a center point, arrow keys adjust orbit, drift off screen = eliminated (arrow keys, off screen = eliminated)
- [ ] Task 84: Thermal Rise minigame - Survival: character floats upward through gaps in platforms, hit a platform = eliminated (arrow keys, hit platform = eliminated)
- [ ] Task 85: Rail Grind minigame - Survival: character on rails, press up/down to switch tracks to avoid obstacles (arrow keys, hit obstacle = eliminated)
- [ ] Task 86: Wind Runner minigame - Survival: wind gusts push player, counter with arrow keys to stay in bounds (arrow keys, blown off = eliminated)
- [ ] Task 87: Pinball Bounce minigame - Survival: ball bounces around, move paddle to keep it alive, miss = eliminated (arrow keys, miss ball = eliminated)
- [ ] Task 88: Snake Grow minigame - Survival: classic snake movement, eat dots to grow, don't hit walls or yourself (arrow keys, crash = eliminated)
- [ ] Task 89: Tornado Dodge minigame - Survival: tornadoes wander the arena, move to avoid them (arrow keys, touched = eliminated)
- [ ] Task 90: Platform Jump minigame - Survival: platforms scroll left, jump between them, fall off screen = eliminated (arrow+space, fall = eliminated)
- [ ] Task 91: Decoy Detect minigame - Race: group of moving dots, click the one that moves differently (mouse click, 10 spotted)
- [ ] Task 92: Sinking Ship minigame - Survival: ship fills with water, plug leaks by clicking them, ship sinks = eliminated (mouse click, ship sinks = eliminated)
- [ ] Task 93: Flag Raise minigame - Race: tap spacebar with correct rhythm to raise flag smoothly, off-rhythm resets (spacebar, flag reaches top)
- [ ] Task 94: Bumper Cars minigame - Survival: move in arena, AI bumper cars roam, knocked out of bounds = eliminated (arrow keys, out of bounds = eliminated)
- [ ] Task 95: Flip Memory minigame - Race: grid of face-down cards, flip two at a time looking for matches (mouse click, all pairs found)
- [ ] Task 96: Firewalk minigame - Survival: floor tiles randomly ignite, move to safe tiles (arrow keys, standing on fire = eliminated)
- [ ] Task 97: Rocket Launch minigame - Race: hold space to charge power meter, release in green zone, best of 5 attempts (spacebar, closest to center)
- [ ] Task 98: Frequency Match minigame - Race: a tone plays as visual pattern, select the matching frequency bar (mouse click, 10 matched)
- [ ] Task 99: Symbol Match minigame - Race: grid of symbols, find and click matching pairs (mouse click, 8 pairs cleared)
- [ ] Task 100: Capital Quiz minigame - Race: country name shown, type its capital city (keyboard, 8 correct)
