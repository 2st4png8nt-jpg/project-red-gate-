# Project Red Gate

A small single-player RPG prototype about exploration, command combat,
gear progression, and the mystery of the Red Gate — a Gate combination
that isn't in any catalogue.

Not an MMO. No accounts, no live service, no persistent online world.

## Status

Phase 5 (Gates) complete, plus a post-Phase-5 systems-depth pass
(mitigation-based damage, speed initiative, weapon movesets,
level-gated gear). See `docs/PROGRESS.md`.

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
keys. The purple marker opens **the Gates** — pick one word each for
Origin, Tone, and Sign, and Open Gate. Almost every combination leads
somewhere:

- `Cinder + Broken + Ember` — Cinderfall Woods, the one hand-crafted
  dungeon (branching path, two common enemies, the Cinder Wraith
  mini-boss who won't let you flee and drops a Gate clue).
- `Hollow + Undying + Ember` — the Red Gate, a fixed, distinctly
  red/black destination guarding the Ashen Warden (also unfleeable)
  and its guaranteed drop, the unique weapon **Cindermourn**.
- Any other well-formed combination generates a dungeon on the spot:
  the **Origin** word picks its visual theme, the **Tone** word picks
  its enemy level (1-4, scaling difficulty and rewards), and the
  **Sign** word picks how large/branching it is (0-3 side paths).

The gold marker in Waymark opens the shop — spend battle gold on a
weapon, armor, an accessory, or a healing draught. Press `I` anywhere
to open your Inventory and equip what you've bought; equipped gear
changes your stats immediately, including in the very next fight, and
each item shows how it compares to whatever you currently have
equipped, plus its level requirement — gear above your level shows as
locked until you outlevel it. Enemies can also drop gear directly, with
better odds at tougher dungeons' loot tiers.

Combat now runs on a real stat system: damage uses a diminishing-returns
mitigation curve (defense always helps, never makes you unhittable),
elemental skills scale off Magic Power while physical ones scale off
Attack, and whichever side is faster (Speed) opens the battle. Some
weapons also have their own moveset — the Cinderfall Cleaver grants
**Cleave** and Cindermourn grants **Ashbrand**, each usable from the
Skill submenu only while that weapon is equipped.

All tile art is deliberately placeholder (solid-color squares) — see
`docs/GAME_DESIGN.md` Section 7 on art direction.
