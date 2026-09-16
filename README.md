# Project Red Gate

A small single-player RPG prototype about exploration, command combat,
gear progression, and the mystery of the Red Gate — a Gate combination
that isn't in any catalogue.

Not an MMO. No accounts, no live service, no persistent online world.

## Status

Phase 6 (Boss + Polish) complete, plus a content-expansion pass and a
depth pass (monster packs, bigger dungeons, loot chests, a Gate
preview) driven by real playtest feedback on an exported build. See
`docs/PROGRESS.md`.

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

Once all 3 words are picked, a preview shows what's actually waiting —
level, size, likely monsters for a generated dungeon; a short flavor
line for the two hand-built destinations below — before you commit:

- `Cinder + Broken + Ember` — Cinderfall Woods, the one hand-crafted
  dungeon, now with two branches (north to the Cinder Wraith mini-boss,
  a new south one hiding a loot chest) and 5 monster-pack encounters.
- `Hollow + Undying + Ember` — the Red Gate, a fixed, distinctly
  red/black destination guarding the Ashen Warden (also unfleeable)
  and its guaranteed drop, the unique weapon **Cindermourn**.
- Any other well-formed combination generates a dungeon on the spot:
  the **Origin** word picks its visual theme (6 now — including the
  new Frost and Storm — and Verdant/Drowned each spawn their own
  themed enemy, Thornling/Brinewisp), the **Tone** word picks its enemy
  level (1-5, scaling difficulty and rewards — Ancient is the new
  hardest tier), and the **Sign** word picks how large/branching it is
  (0-3 side paths, now noticeably bigger with more fights and 1-2 loot
  chests per tier).

Most fights are now against a **pack** of 2-3 enemies, not one —
bosses stay solo. Attacking or using a single-target Skill lets you
pick who to hit when more than one enemy is alive; **Blazing Arc**, a
new universal skill, hits the whole pack at once.

The gold marker in Waymark opens the shop — spend battle gold on a
weapon, armor, an accessory, or a healing draught. Press `I` anywhere
to open your Inventory and equip what you've bought; equipped gear
changes your stats immediately, including in the very next fight, and
each item shows how it compares to whatever you currently have
equipped, plus its level requirement — gear above your level shows as
locked until you outlevel it. Enemies can also drop gear directly, with
better odds at tougher dungeons' loot tiers — 5 new items (Windward
Ring, Verdant Fang, Iron Buckler, Brinewoven Robe, Stormcaller Pendant)
join the original set, including the first gear that raises Magic
Power at all.

Combat now runs on a real stat system: damage uses a diminishing-returns
mitigation curve (defense always helps, never makes you unhittable),
elemental skills scale off Magic Power while physical ones scale off
Attack, and whichever side is faster (Speed) opens the battle. Some
weapons also have their own moveset — the Cinderfall Cleaver grants
**Cleave** and Cindermourn grants **Ashbrand**, each usable from the
Skill submenu only while that weapon is equipped.

Enemies no longer spam the same skill every turn — they alternate
basic attack and skill. The Ashen Warden **enrages at 50% HP**,
switching permanently to its stronger Cinderquake for the rest of the
fight. Every hit now has a screen-flash/shake and a sound cue (a
synthesized placeholder tone — this sandbox can't source real audio
assets, see `docs/ARCHITECTURE.md` Section 8a), and every dungeon is
dimmed with a soft light following the player, while Waymark stays
fully lit.

All tile art is deliberately placeholder (solid-color squares) — see
`docs/GAME_DESIGN.md` Section 7 on art direction.
