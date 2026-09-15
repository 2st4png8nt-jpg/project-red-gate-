# Project Red Gate

A small single-player RPG prototype about exploration, command combat,
gear progression, and the mystery of the Red Gate — a Gate combination
that isn't in any catalogue.

Not an MMO. No accounts, no live service, no persistent online world.

## Status

Phase 3 (Progression) complete. See `docs/PROGRESS.md`.

## Controls

- Move: WASD or arrow keys
- Battle: click command buttons (Attack / Skill / Item / Defend / Run)
- `I`: open/close Inventory (equip/unequip gear)

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

The current build boots to Waymark (town): walk around with WASD/arrow
keys, and walk into the doorway on the east wall to reach Cinderfall
Woods (the prototype's first dungeon, with a branching side path). Walk
into its west doorway to return to Waymark. Three orange/red markers in
Cinderfall Woods start a battle: two common enemies in the main
corridor, and the Cinder Wraith mini-boss (who won't let you flee) in
the branch alcove to the north.

The gold marker in Waymark opens the shop — spend battle gold on a
weapon, armor, an accessory, or a healing draught. Press `I` anywhere
to open your Inventory and equip what you've bought; equipped gear
changes your stats immediately, including in the very next fight.
There is no loot from combat or a Gate UI yet — see `docs/PROGRESS.md`
for what's next (Phase 4: Loot).

All tile art is deliberately placeholder (solid-color squares) — see
`docs/GAME_DESIGN.md` Section 7 on art direction.
