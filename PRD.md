# Project Plan

## Overview
Networked multiplayer game, consisting of a larger game loop and smaller mini games. Each mini game is worth the same amount of points, with each mini game having its own scoring criteria. 

Highest scoring players get the most points, for each game, summed at the end.

**Reference:** `PRD.md`

---

## Task List

```json
[
  {
    "category": "feature",
    “description”: “Home menu, with ‘Play’ and ‘Settings’”,
    “steps”: [
      “Create menu”,
      “Create network handshake from client to server”,
      “Create settings menu (empty for now)”,
      “Play button will be grayed out until player their name”
    ],
    “passes”: true
  }, 
  {
    "category": "feature",
    “description”: “Waiting room that shows who / how many players are ready to play”,
    “steps”: [
      “Interactive UI showing players and how many”
“Support cancel to go back to main menu”
    ],
    “passes”: true
  }, 
{
    "category": "feature",
    "description": “First game exists”,
    "steps": [
      “Create game where players have to press the space bar some arbitrary amount of time (from 3-10s), as close as possible to the specified time.”,
“Score game based on closeness”,
“Increment full game score”
    ],
    “passes”: true
  },
{
    "category": "feature",
    "description": “End game”,
    "steps": [
      “Sum game, present who won, put players back to lobby”
    ],
    "passes": false
  },
  {
    "category": "testing",
    "description": "Verify all components render correctly",
    "steps": [
      "Test responsive layouts",
      "Check console for errors",
      "Verify all links work"
    ],
    "passes": false
  }
]
