# Tower RPG — Vertical Slice Prototype

Design reference derived from the user's "TOWER RPG — VERTICAL SLICE
PROTOTYPE" specification v0.1. This file tracks the decisions actually
made during implementation; the full spec is the source of truth for
anything not covered here.

## Core identity

- Real-time party-combat RPG. Player directly controls one character;
  AI controls the rest of the party.
- Inspired by .hack gameplay philosophy and Tower of God's "Position"
  concept — original terminology, characters, and world only.
- Deliberate, readable combat. Not twitch-action, not dodge/parry-centric.

## Positions (permanent character identity)

Five Positions, each a battlefield role, not a class in the traditional
sense:

1. **Fisherman** — direct physical engagement.
2. **Spear Bearer** — ranged precision.
3. **Scout** — information gathering / stealth.
4. **Light Bearer** — battlefield command / devices.
5. **Wave Controller** — energy manipulation.

A character's Position is permanent. The player's character is
**Adaptive** (flexible, intentionally less specialized than any fixed
build). AI companions are fixed **Specialists**.

**Hard boundary (non-negotiable):** equipment may enhance a Position's
expression but must never let a character cross into another
Position's domain. A Fisherman weapon can grant "Counter+"; it can
never grant "Lighthouse Deployment" (a Light Bearer tool). A Wave
Controller item can grant "Lightning Burst"; it can never turn the
character into a Scout.

## Equipment

Exactly 3 slots: **Weapon**, **Armor**, **Boots**. Equipment-derived
skills are not permanently learned — unequip the item and the skill
leaves the available pool immediately.

## Skills

- Three types: **ACTIVE** (manual), **PASSIVE** (auto-modifier),
  **TRIGGER** (condition-based). Prototype prioritizes ACTIVE.
- A character's available skill pool can exceed 5. The player selects
  a **max 5 active loadout** from that pool between encounters.

## SP economy (resource, not cooldowns)

- Basic attack is always available — the player is never fully
  helpless — and generates SP (+5 per hit, current data value).
- Skills consume SP (roughly 15-70 depending on tier).
- Max SP: 100 (tunable; current `CharacterData.max_sp` default).
- No skill cooldowns. SP is the only gate.

## Combat feel

Real-time movement (WASD), camera follows the player, mouse-driven
targeting, LMB basic attack, 1-5 for skill activation (once skills
exist). Target switching, hit reactions, and stagger are part of later
phases — not yet implemented.

## Party AI + commands

Party members fight autonomously (choose targets, move, attack, use
skills). Player issues one of 4 high-level commands: Focus Target,
Aggressive, Defensive, Hold Position. Not yet implemented (Phase 6).

## Loot (hybrid, not pure random)

Weighted by floor/environment, enemy type, dungeon/area, difficulty
condition, and player behavior, plus a random roll. At least 3 loot
families from the spec: Shadow, Blood, Precision. Equipment starts
unidentified ("???") and is revealed via an Identify action. 5-tier
rarity (Common/Uncommon/Rare/Epic/Relic) — rarity shapes property
count/unusual-property chance/presentation, not raw power directly.
Not yet implemented (Phases 9-10).

## Explicitly out of scope for this prototype

Story, dialogue, cutscenes, lore, voice acting, gacha, monetization,
multiplayer, PvP, 100 floors, final art, elaborate animations,
crafting, trading economy, guilds, social systems, endgame, complex
procedural generation.

## First Playable Target (spec Section 39)

1 player (Adaptive Fisherman) + 2 AI companions (1 ranged, 1
support/control Position) + ≥5 weapons/armor/boots each + 15-20 total
skills + 5 enemy types (4 normal + 1 elite + 1 mini boss) + 1 small
dungeon + ≥3 loot families + full UI suite (HP/SP, target info, skill
bar, party status, inventory, equipment screen, skill loadout,
identify screen).

## Build order (spec Section 40) — tracked as tasks #59-70

1. Movement + camera + basic combat *(done — this pass)*
2. Targeting + enemy AI
3. HP + SP
4. Skills
5. Five-skill loadout
6. Party AI + commands
7. Equipment
8. Equipment-derived skills
9. Loot generation
10. Identification
11. Dungeon
12. Mini boss
13. Polish / balancing

Per the spec's own Section 41, stop after the first playable build and
answer the 8 playtest questions before adding more content. See
`PROGRESS.md` for current status.
