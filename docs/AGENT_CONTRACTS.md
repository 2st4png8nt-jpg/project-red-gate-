# AGENT_CONTRACTS.md — Project Red Gate

Owner: Lead / Architect
Status: Phase 0 (Foundation)

Defines each agent's ownership, boundaries, and the exact data
schemas/interfaces they must build against. Read this before touching
any shared system (CLAUDE.md Section 16/19).

---

## Delegation format (use this for every task handed to an agent)

```
OBJECTIVE:
SCOPE:
FILES/AREAS OWNED:
DEPENDENCIES:
ACCEPTANCE CRITERIA:
DO NOT CHANGE:
```

## Report format (use this when an agent finishes a task)

```
STATUS: COMPLETE / BLOCKED
IMPLEMENTED:
FILES CHANGED:
INTERFACES CHANGED:
TESTS:
KNOWN ISSUES:
FOLLOW-UP:
```

---

## AGENT 0 — Lead / Architect

Owns: `docs/GAME_DESIGN.md`, `docs/ARCHITECTURE.md`,
`docs/AGENT_CONTRACTS.md`, `docs/PROGRESS.md`. Reviews any change that
touches an autoload, a schema in `scripts/data/`, or a cross-system
interface listed in ARCHITECTURE.md. Does not personally implement every
feature; delegates bounded tasks.

## AGENT 1 — Core Systems

Owns: `scripts/core/`, `scripts/data/` (schema definitions only).

Delivered in Phase 0:
- `EventBus.gd`, `DataLoader.gd`, `GameState.gd`, `SceneManager.gd`,
  `SaveLoad.gd` (see ARCHITECTURE.md Section 3).
- Schema classes in `scripts/data/` (empty of content — content is
  Agent 3/4/6's job).

Does not own combat UI or battle logic.

## AGENT 2 — Combat

Owns: `scripts/combat/`.

Must consume (not redefine): `PlayerData` from Agent 3, `EnemyData` from
Agent 6, equipment effects from Agent 3. Exposes the interface in
ARCHITECTURE.md Section 6. Does not own inventory UI (Agent 5).

Not started in Phase 0 — Phase 2.

## AGENT 3 — RPG / Gear

Owns: `scripts/rpg/`, `data/items/`, `data/characters/`.

Delivered in Phase 0:
- `PlayerData.gd` Resource: `level:int, xp:int, max_hp:int, hp:int,
  max_mp:int, mp:int, attack:int, defense:int, magic_power:int,
  speed:int, gold:int, equipped_weapon:EquipmentData,
  equipped_armor:EquipmentData, equipped_accessory:EquipmentData,
  inventory:Array[ItemData]`.
- Uses `ItemData`/`EquipmentData` schemas from `scripts/data/`
  (owned jointly with Agent 1 — Agent 1 defines the base `ItemData`
  shape since Core Systems needs it for save/load; Agent 3 defines
  `EquipmentData`'s extra fields since gear is Agent 3's domain).

Full leveling math, inventory UI hookup, and equipment comparison are
Phase 3/4 work, not Phase 0.

## AGENT 4 — World / Gate

Owns: `scripts/world/`, `scripts/gates/`, `data/maps/`, `data/gates/`.

Delivered in Phase 0:
- `MapData.gd`, `GateKeywordData.gd`, `GateCombinationData.gd` schemas.
- `data/gates/keywords.tres`-style content seeded with the Section 6
  keyword pool from GAME_DESIGN.md (content only, resolver logic is
  Phase 5).
- Town scene placeholder (`scenes/world/Town.tscn`) proving Boot -> Town
  works (superseded by the real Phase 1 scene below).

Delivered in Phase 1:
- `Player.gd` / `Player.tscn` — real 4-directional movement, collision,
  and a following `Camera2D` with settable limits (see ARCHITECTURE.md
  Section 5a).
- `RectMapBuilder` — shared static utility any map controller uses to
  paint its `TileMapLayer` ground and spawn `Obstacle` colliders from a
  list of open-area rectangles.
- `MapTransitionArea` — generic doorway trigger, a Phase 1 stand-in for
  the Phase 5 Gate-driven entry point.
- `Town.tscn`/`town.gd` rebuilt with a real tilemap, border collision,
  and a doorway to Cinderfall Woods.
- `CinderfallWoods.tscn`/`cinderfall_woods.gd` — the prototype's first
  real dungeon: a main corridor plus one branching alcove (the
  "bonus loot area" exploration pillar from GAME_DESIGN.md Section 7),
  and a doorway back to Waymark.
- Shared placeholder tile art (`art/tiles/`) + `world_tileset.tres`,
  owned jointly with Agent 7 (Agent 7 replaces the placeholder SVGs
  with real pixel art later without touching `RectMapBuilder` or any
  map controller).

Gate resolution logic itself (`gate_resolver.gd`) is data-driven and
scheduled for Phase 5, but its schema and contract are fixed now
(ARCHITECTURE.md Section 7) so nothing downstream has to guess. Normal
maps are currently entered through a plain `MapTransitionArea` doorway
in Town — Phase 5 replaces that doorway's trigger with real Gate
combination entry (the destination logic does not change).

## AGENT 5 — UI / UX

Owns: `scripts/ui/`, `scenes/ui/`.

Not started in Phase 0 beyond what Boot/Town minimally need (if
anything — Phase 0's bootable prototype may ship with zero custom UI).
UI reads state from systems; it must not contain core game logic.

## AGENT 6 — Enemy / Content

Owns: `data/enemies/`, `data/encounters/`, `scripts/enemies/`.

Not started in Phase 0. `EnemyData` schema is defined by Agent 1/Lead
now so Agent 3/Agent 2 can see its shape; content authoring is Phase 2/4.

## AGENT 7 — Art / Presentation

Owns: `art/`, `assets/`, `scenes/world/` presentation layer.

Phase 0: no art required beyond a placeholder project icon and a solid
color/ColorRect stand-in for the player and ground in Town.tscn.
Placeholder art must not block system development.

## AGENT 8 — Audio

Owns: `audio/`, `scripts/audio/`.

Not started in Phase 0.

## AGENT 9 — QA / Playtest

Owns: `tests/`, `docs/QA/`.

Phase 0 deliverable: a QA checklist stub (`docs/QA/CHECKLIST.md`)
covering the Phase 0 exit criteria (boot with no errors, Town loads,
autoloads present). QA never silently fixes another agent's system —
report to Lead Agent.

---

## Fixed Data Schemas (Phase 0)

These field lists are the contract. Adding a field is a minor, backwards
-compatible change (update this doc). Removing/renaming a field is a
cross-agent interface change (Lead Agent must approve and update
ARCHITECTURE.md Section 8 save-data notes if it affects save data).

### `ItemData` (scripts/data/item_data.gd)
- `id: String`
- `display_name: String`
- `description: String`
- `rarity: String` — one of `"common" | "uncommon" | "rare" | "unique"`
- `level_requirement: int`
- `value: int`
- `source: String` — free text, e.g. `"Waymark shop"`, `"Cinderfall Woods drop"`

### `EquipmentData extends ItemData` (scripts/data/equipment_data.gd)
- `slot: String` — one of `"weapon" | "armor" | "accessory"`
- `attack_bonus: int`
- `defense_bonus: int`
- `magic_power_bonus: int`
- `speed_bonus: int`
- `max_hp_bonus: int`
- `max_mp_bonus: int`
- `special_effect_id: String` — empty string if none; combat reads this
  by id, it never contains logic itself

### `SkillData` (scripts/data/skill_data.gd)
- `id: String`
- `display_name: String`
- `mp_cost: int`
- `power: int`
- `target_type: String` — `"single_enemy" | "self" | "all_enemies"`
- `element: String` — free text, e.g. `"ember"`, `"physical"`

### `EnemyData` (scripts/data/enemy_data.gd)
- `id: String`
- `display_name: String`
- `family: String` — e.g. `"ashen"`, used for equipment effects like Cindermourn's
- `max_hp: int`
- `attack: int`
- `defense: int`
- `magic_power: int`
- `speed: int`
- `xp_reward: int`
- `gold_reward: int`
- `skill_ids: Array[String]`
- `loot_table_id: String`

### `GateKeywordData` (scripts/data/gate_keyword_data.gd)
- `word: String`
- `category: String` — one of `"origin" | "tone" | "sign"`

### `GateCombinationData` (scripts/data/gate_combination_data.gd)
- `origin: String`
- `tone: String`
- `sign: String`
- `result_type: String` — one of `"known" | "special" | "locked"`
  (anything not listed resolves to `"unknown"` at runtime, and
  malformed input to `"invalid"` — those two are never stored as rows)
- `destination_map_id: String` — empty for `"special"` rows, which
  instead resolve to the hardcoded Red Gate map id in the resolver
  contract, not duplicated per-row

### `MapData` (scripts/data/map_data.gd)
- `id: String`
- `display_name: String`
- `is_special: bool`
- `encounter_table_id: String`
- `scene_path: String`

### `PlayerData` (scripts/rpg/player_data.gd)
See Agent 3 section above for the full field list.

---

## Open Interface Decisions Log

Record any ambiguity resolved by the Lead Agent here, so no other agent
re-litigates it (CLAUDE.md Section 19).

- **2026-09-15** — Decided the Red Gate's destination map id is fixed
  (`"red_gate"`) rather than stored per-combination-row, since there is
  exactly one special destination in the prototype. Revisit only if a
  second special map is added.
