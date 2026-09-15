# Project Red Gate

A small single-player RPG prototype about exploration, command combat,
gear progression, and the mystery of the Red Gate — a Gate combination
that isn't in any catalogue.

Not an MMO. No accounts, no live service, no persistent online world.

## Status

Phase 0 (Foundation) complete. See `docs/PROGRESS.md`.

## Start here

- `docs/GAME_DESIGN.md` — what the game is
- `docs/ARCHITECTURE.md` — how the systems fit together
- `docs/AGENT_CONTRACTS.md` — who owns what, and the fixed data schemas
- `docs/PROGRESS.md` — milestone log

## Running the project

Requires the [Godot 4.3+ editor](https://godotengine.org/download) (free,
open source).

```
godot4 --path .                              # open in editor
godot4 --headless --path . --quit-after 5    # headless smoke run
```

The current build boots straight to a placeholder Waymark (town) scene
that confirms the core autoload chain and scene-transition architecture
work end to end. There is no movement, combat, or Gate UI yet — see
`docs/PROGRESS.md` for what's next (Phase 1: Movement + World).
