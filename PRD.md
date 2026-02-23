# WarioParty - Product Requirements Document

## Overview
A networked multiplayer (2-N players) Wario-Ware styled party game. Players compete through rapid-fire mini-games, each lasting at most 10 seconds. Scores accumulate across rounds and a winner is declared at the end.

## Core Mechanics

### Networking
- One player hosts, others join via IP address
- ENetMultiplayerPeer, server-authoritative scoring
- All players see the same minigame simultaneously
- Server collects scores and advances the game

### Game Flow
1. **Main Menu**: Host Game / Join Game (name + IP input)
2. **Lobby**: Shows connected players. Host presses "Start" when ready.
3. **Mini-Game Round** (repeats for N rounds, default 5):
   a. 3-second countdown with minigame name displayed
   b. 10-second minigame plays
   c. Server collects all player scores
   d. Scoreboard shows round results + cumulative standings
4. **End Game**: Final scoreboard, winner announced, "Return to Menu" button

### Scoring
- Each minigame awards points based on player rank
- With N players: 1st place = N points, 2nd = N-1, ... last = 1 point
- Ties share the higher point value

### Mini-Games (build incrementally)
1. **Button Masher** - Mash spacebar as fast as possible. Score = press count.
2. **Reaction Time** - Screen flashes, press spacebar ASAP. Score = inverse of reaction time (ms).
3. **Memory Sequence** - Watch a color sequence, replay it. Score = correct steps.
4. **Dodge Falling** - Move left/right to dodge falling blocks. Score = survival time (ms).
5. **Target Click** - Click appearing targets. Score = targets hit.
6. **Quick Math** - Solve simple math problems. Score = correct answers.
7. **Color Match** - Press correct arrow for shown color. Score = correct matches.
8. **Rhythm Tap** - Tap spacebar in rhythm with pulses. Score = accuracy %.

## Technical Requirements
- Godot 4.3+, GDScript strongly typed
- All minigames extend a shared MiniGameBase class
- Server-authoritative: clients send raw scores, server ranks and awards points
- ColorRect-based placeholder UI (no art assets)
