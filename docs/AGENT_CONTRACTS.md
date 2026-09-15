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

Owns: `scripts/combat/`, `data/skills/`.

Must consume (not redefine): `PlayerData` from Agent 3, `EnemyData`,
`LootTableData` and `EnemyScaler` from Agent 6, `DungeonProfile`-derived
`EncounterData` built by Agent 4's `GeneratedEncounterTrigger`,
equipment effects from Agent 3 (via `StatsCalculator`, wired in Phase 3).
Exposes the interface in ARCHITECTURE.md Section 6/6b/7a. Does not own
inventory UI or the command menu itself (Agent 5) — only the state
machine those UI elements drive.

Delivered in Phase 2:
- `BattleManager` (`scripts/combat/battle_manager.gd`) — full state
  machine: `start_battle()`, the five `player_*()` command methods,
  enemy turn resolution (always uses the enemy's first skill if it has
  one), victory/defeat/flee handling.
- `EncounterData` schema (`scripts/data/encounter_data.gd`) — single-
  enemy encounters (`enemy_id`, `can_flee`).
- 3 player skills (Ember Slash, Guard Break, Second Wind) and 3 enemy
  skills as `SkillData` rows in `data/skills/`.
- Real bug found and fixed by the Phase 2 headless self-test: moved
  `BattleManager`'s state init from `_ready()` to `_enter_tree()` so
  its child `BattleUI` never reads `enemy`/`player` as null — see
  ARCHITECTURE.md Section 6 for why.

Delivered in Phase 4:
- `BattleManager._win()` now rolls the defeated enemy's loot table (if
  any) and discovers its gate clue (if any) — see ARCHITECTURE.md
  Section 6b. `battle_won`'s signature grew two params
  (`loot_item_name`, `clue_discovered`); `BattleUI`'s handler was
  updated to match.

Delivered in Phase 5:
- Every stat read from `EnemyData` in combat math now goes through
  `EnemyScaler` (Agent 6) instead of the raw field, keyed by a new
  `enemy_level` field set from `EncounterData.level` — 1 for every
  hand-authored Phase 2-4 row (no behavior change for those), whatever
  a generated dungeon's `DungeonProfile.level` computed otherwise.
- `_enter_tree()` now checks `GameState.pending_generated_encounter`
  (an in-memory `EncounterData`, Agent 4) before falling back to the
  file-based `pending_encounter_id` path — both converge on the same
  `_start_with_encounter()`.
- `EquipmentData.bonus_damage_vs_family`/`bonus_damage_percent`/
  `mp_restore_on_kill` (Agent 3 schema, Agent 2 combat math) — Cindermourn's
  identity mechanics, see ARCHITECTURE.md Section 6.
- `EncounterData` gained `level: int` and `loot_table_id_override: String`
  (both additive/backward-compatible — see AGENT_CONTRACTS.md schema list).

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

Delivered in Phase 2:
- `Leveling` (`scripts/rpg/leveling.gd`) — minimal placeholder XP curve
  (`xp_to_next_level(level) = level * 20`) used by `BattleManager._win()`
  to grant XP and apply level-ups. Deliberately simple; real balancing
  is Phase 3/4 (GAME_DESIGN.md Section 27 — play and measure first).

Delivered in Phase 3:
- `StatsCalculator`, `EquipmentManager`, `Inventory` (`scripts/rpg/`) —
  see ARCHITECTURE.md Section 6a for the full interface. `BattleManager`
  (Agent 2) now calls `StatsCalculator` instead of reading `PlayerData`'s
  raw stat fields, so equipment bonuses are live in combat immediately.
- `ConsumableData extends ItemData` schema (`scripts/data/consumable_data.gd`).
- 4 items of shop content in `data/items/`: Rusted Shortsword,
  Traveler's Vest, Lucky Charm (all `EquipmentData`, matching the
  example progression table in GAME_DESIGN.md Section 11 exactly), and
  the Ember Draught consumable.
- `BattleManager.player_use_item()` now actually works (was a Phase 2
  stub that only reported "no items"): uses the first consumable in
  the inventory, heals it, removes it.

Delivered in Phase 5:
- `EquipmentData` gained 3 structured fields — `bonus_damage_vs_family`,
  `bonus_damage_percent`, `mp_restore_on_kill` — for effects common
  enough to deserve real fields rather than parsing the existing
  opaque `special_effect_id` string. See AGENT_CONTRACTS.md's Open
  Interface Decisions Log for why.
- `data/items/cindermourn.tres`: the unique weapon, using all 3 new
  fields. Content-wise this sits in Agent 3's `data/items/`, same as
  every other equipment piece, even though it's exclusively awarded
  through Agent 6's Ashen Warden loot table.

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

Gate resolution logic itself (`gate_resolver.gd`) is data-driven — see
ARCHITECTURE.md Section 7. Phase 1-4 entered Cinderfall Woods through a
plain `MapTransitionArea` doorway in Town; Phase 5 replaced that
doorway's trigger with real Gate combination entry through `GateUI`.

Delivered in Phase 2:
- `EncounterTrigger` (`scripts/world/encounter_trigger.gd`) — one-shot
  walk-in trigger calling `SceneManager.go_to_battle(encounter_id)`,
  mirroring `MapTransitionArea`'s pattern.
- Three encounter triggers placed in Cinderfall Woods (two common
  enemies in the main corridor, the Cinder Wraith mini-boss in the
  branch alcove), each with a small colored marker so a playtester can
  see them coming (per QA/CHECKLIST.md).
- `SceneManager.go_to_battle()` implemented for real (was a Phase 1
  stub): sets `GameState.pending_encounter_id`, defers the scene change
  to `Battle.tscn`, and deliberately leaves `current_map_id` untouched
  so `BattleUI` can return the player to the same map after the fight.

Delivered in Phase 3:
- `ShopTrigger` (`scripts/world/shop_trigger.gd`) — re-enterable
  walk-in trigger (unlike `EncounterTrigger`, no one-shot guard: you
  can browse a shop as many times as you like) opening the Waymark
  shop, placed in Town.

Delivered in Phase 5:
- `GateResolver` + `DungeonProfile` (`scripts/gates/`) — see
  ARCHITECTURE.md Section 7/7a for the full contract. Removed the dead
  `data/gates/combinations/silent_marsh.tres` and `data/maps/silent_marsh.tres`
  rows (that combo was never built as a real scene; it now generates a
  Drowned-themed dungeon like any other combination — see GAME_DESIGN.md
  Section 7's design-supersession note).
- `GeneratedDungeon.tscn`/`generated_dungeon.gd` — the runtime-built
  map for any `GENERATED` Gate result, plus 2 new reusable props:
  `DoorwayTrigger.tscn` (a `MapTransitionArea` with no map-specific
  scene of its own) and `GeneratedEncounterMarker.tscn` (wraps
  `GeneratedEncounterTrigger`). Both exist so `generated_dungeon.gd`
  never has to dynamically attach a script to a bare `Area2D.new()` at
  runtime (fragile, and inconsistent with every other trigger in the
  project, which is a pre-authored scene) — it just instances and
  configures them like any other prefab.
- `GateTrigger` (`scripts/world/gate_trigger.gd`) — replaces
  `ToCinderfallWoods`'s `MapTransitionArea` in Town with a trigger that
  opens `GateUI` (Agent 5) instead of transitioning directly.
- `RedGate.tscn`/`red_gate.gd` — the Red Gate's hand-crafted map (not
  generated — see GAME_DESIGN.md Section 7), reusing the existing
  `EncounterTrigger` (file-based, `ashen_warden_encounter.tres`) rather
  than the new generated-dungeon machinery, since this is one fixed,
  designed destination, not a formula.
- New `art/tiles/`: `tile_verdant.svg`, `tile_drowned.svg`,
  `tile_hollow.svg` (the 3 remaining Origin themes) and
  `tile_redgate.svg`, all added as new sources in the shared
  `world_tileset.tres` (ids 3-6) rather than per-theme tileset files.

## AGENT 5 — UI / UX

Owns: `scripts/ui/`, `scenes/ui/`.

Not started in Phase 0 beyond what Boot/Town minimally need (if
anything — Phase 0's bootable prototype may ship with zero custom UI).
UI reads state from systems; it must not contain core game logic.

Delivered in Phase 2:
- `BattleUI` (`scripts/ui/battle_ui.gd` + `scenes/ui/BattleUI.tscn`) —
  command menu (Attack/Skill/Item/Defend/Run), a skill submenu built
  from `data/skills/`, HP/MP display, a message log, and the
  post-battle victory/defeat/flee transitions back to the world. Reads
  `BattleManager` only through its signals and public fields (`enemy`,
  `enemy_hp`, `player`) — never calls into its private `_win()`/`_lose()`
  methods or touches damage math.

Delivered in Phase 3:
- `InventoryUI` (`scripts/ui/inventory_ui.gd` + `scenes/ui/InventoryUI.tscn`)
  — equip/unequip screen, a child of `Player.tscn` (present in every
  map), toggled by the `I` key. Mutates `GameState.player` only through
  `EquipmentManager`/`Inventory` calls, per ARCHITECTURE.md Section 6a.
- `ShopUI` (`scripts/ui/shop_ui.gd` + `scenes/ui/ShopUI.tscn`) — buy
  screen instanced by `town.gd`, reading which items are for sale from
  an exported `item_ids` list (data, not a hardcoded switch statement).

Delivered in Phase 4:
- `InventoryUI` item rows now show a comparison string (`_format_comparison()`)
  against whatever's currently in that item's slot, e.g. `vs. equipped: ATK+8`.
  Reads `EquipmentData` bonus fields directly via `Resource.get(field)`;
  does not duplicate `StatsCalculator`'s logic.

Delivered in Phase 5:
- `GateUI` (`scripts/ui/gate_ui.gd` + `scenes/ui/GateUI.tscn`) — the
  payoff screen: 3 `OptionButton`s populated from `data/gates/keywords/`
  (data-driven, no hardcoded word list in the script), calls
  `GateResolver.resolve()` on Open Gate, and branches on the result
  type to call `SceneManager.go_to_map()` (known/special) or
  `go_to_generated_dungeon()` (generated) — never builds a dungeon
  itself. Also shows every discovered clue's hint text, looked up from
  `data/gates/clues/*.tres` (Agent 4) by id. Instanced by `town.gd` and
  opened by the new `GateTrigger`, replacing the old direct-to-Cinderfall-
  Woods doorway.

## AGENT 6 — Enemy / Content

Owns: `data/enemies/`, `data/encounters/`, `data/loot/`, `scripts/enemies/`.

Not started in Phase 0. `EnemyData` schema is defined by Agent 1/Lead
now so Agent 3/Agent 2 can see its shape; content authoring is Phase 2/4.

Delivered in Phase 2:
- `EnemyData` rows for the three Cinderfall Woods enemies from
  GAME_DESIGN.md: Ember Wisp, Bramble Husk, and the mini-boss Cinder
  Wraith (each with one `SkillData` reference — see Agent 2's Phase 2
  delivery for the skill rows themselves).
- `EncounterData` rows pairing each enemy into a single-enemy
  encounter; the Cinder Wraith's has `can_flee = false`.
- Silent Marsh's enemies (Tideling, Hollow Stalker) are deferred
  indefinitely — Silent Marsh as a distinct hand-authored map is
  superseded by Phase 5's generation system (GAME_DESIGN.md Section 7),
  so there is no longer a specific place these would need to go; a
  future "add real per-Origin monster variety to generated dungeons"
  pass could revive the concept, but nothing calls for it yet.

Delivered in Phase 4:
- `LootTableData` schema + `LootRoller` (`scripts/enemies/loot_roller.gd`,
  static) — see ARCHITECTURE.md Section 6b.
- `data/loot/cinderfall_common_loot.tres` (60% chance, weighted 4:1
  between the Ember Draught and the new Cinderfall Cleaver) wired to
  both Ember Wisp and Bramble Husk via `loot_table_id`.
- `data/loot/cinder_wraith_loot.tres` (100% chance, the new Ashcinder
  Guard) wired to the Cinder Wraith, whose row also got a new
  `gate_clue_id = "cinder_wraith_note"` — the "boss drop confirms the
  final keyword" discovery source from GAME_DESIGN.md Section 8. The
  Gate UI that makes that clue *mean* anything to the player is still
  Phase 5; this only makes `GameState.known_gate_clues` accumulate it.
- Two new items in `data/items/`: Cinderfall Cleaver (uncommon weapon,
  a Cinderfall Woods drop) and Ashcinder Guard (rare armor, the Cinder
  Wraith's signature reward) — the first Uncommon/Rare gear actually
  reachable in the world, versus Phase 3's Common-only shop stock.
- `scripts/enemies/` now holds `loot_roller.gd`; still no per-enemy
  behavior scripts beyond "use `skill_ids[0]`" — not needed until enemy
  AI grows beyond Phase 2's single-skill default.

Delivered in Phase 5:
- `EnemyScaler` (`scripts/enemies/enemy_scaler.gd`, static) — see
  ARCHITECTURE.md Section 7a. Computes scaled stats without mutating
  the shared cached `EnemyData` resource (would corrupt every other
  battle using that same enemy).
- The Ashen Warden: `EnemyData` (family `"ashen"`, 70 HP, the
  prototype's hardest fight), its `Ashfall` skill, and
  `ashen_warden_loot.tres` (100% chance, guaranteed Cindermourn) — the
  content half of the Red Gate; Agent 4 owns the map it lives in.
- `ashen_warden_encounter.tres` — a normal file-based `EncounterData`
  (not the generated-dungeon machinery), since the Red Gate is one
  fixed destination, not a formula.
- `generated_low_loot.tres`/`generated_mid_loot.tres`/`generated_high_loot.tres`
  — the 3 level-tiered loot tables generated dungeons roll from
  (`generated_mid_loot` mirrors `cinderfall_common_loot`'s values but
  is its own file, to keep generated-dungeon loot content separate
  from Cinderfall-Woods-specific naming).

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
- `special_effect_id: String` — reserved for future one-off/scripted
  effects; empty for every current item
- `bonus_damage_vs_family: String` — added Phase 5; matches `EnemyData.family`, empty = no bonus
- `bonus_damage_percent: float` — added Phase 5; e.g. `0.15` = +15% damage vs. that family
- `mp_restore_on_kill: int` — added Phase 5

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
- `gate_clue_id: String` — added Phase 4; discovered via `GameState.discover_clue()` on defeat if non-empty

### `GateKeywordData` (scripts/data/gate_keyword_data.gd)
- `word: String`
- `category: String` — one of `"origin" | "tone" | "sign"`

### `GateCombinationData` (scripts/data/gate_combination_data.gd)
- `origin: String`
- `tone: String`
- `sign: String`
- `result_type: String` — one of `"known" | "special"` (Phase 5: a
  triple that doesn't match any row here, but is otherwise well-formed,
  now resolves to `GENERATED` — see ARCHITECTURE.md Section 7 — rather
  than `"unknown"`; malformed input still resolves to `"invalid"` and
  is never stored as a row; `"locked"` was in the original Phase 0
  enum but is unused and removed — every catalogued row is always
  reachable)
- `destination_map_id: String` — set on both `"known"` and `"special"`
  rows (the Red Gate's own row carries `"red_gate"` here directly,
  rather than the resolver hardcoding it — simpler than the two-rows-
  need-different-treatment plan originally sketched in Phase 0)

### `MapData` (scripts/data/map_data.gd)
- `id: String`
- `display_name: String`
- `is_special: bool`
- `encounter_table_id: String`
- `scene_path: String`

### `PlayerData` (scripts/rpg/player_data.gd)
See Agent 3 section above for the full field list.

### `EncounterData` (scripts/data/encounter_data.gd) — added Phase 2
- `id: String`
- `enemy_id: String`
- `can_flee: bool`
- `level: int` — added Phase 5; scales the enemy via `EnemyScaler`. Defaults to
  1 (no change) — every hand-authored Phase 2-4 row is unaffected.
- `loot_table_id_override: String` — added Phase 5; if set, used instead
  of the enemy's own `loot_table_id` (generated dungeons, whose loot
  tier depends on dungeon level, not the fixed enemy)

### `GateClueData` (scripts/data/gate_clue_data.gd) — added Phase 5
- `id: String`
- `hint_text: String` — player-facing; `GameState.known_gate_clues`
  only ever stores the opaque id, `GateUI` looks up this text to display

### `ConsumableData extends ItemData` (scripts/data/consumable_data.gd) — added Phase 3
- `heal_hp: int`
- `heal_mp: int`

### `LootTableData` (scripts/data/loot_table_data.gd) — added Phase 4
- `id: String`
- `drop_chance: float` — 0..1
- `item_ids: Array[String]`
- `weights: Array[int]` — parallel to `item_ids`

---

## Open Interface Decisions Log

Record any ambiguity resolved by the Lead Agent here, so no other agent
re-litigates it (CLAUDE.md Section 19).

- **2026-09-15 (Phase 0)** — Decided the Red Gate's destination map id
  is fixed (`"red_gate"`) rather than stored per-combination-row.
  **Superseded in Phase 5**: the row stores `destination_map_id` for
  both `"known"` and `"special"` types uniformly — simpler than
  special-casing the resolver, and no real cost since there is still
  only ever one special row.
- **2026-09-15** — Decided equipment bonuses are computed on read
  (`StatsCalculator`) rather than applied by mutating `PlayerData`'s
  base stats when a piece is equipped/unequipped. Mutate-on-equip would
  need every future path that changes equipment to remember to reverse
  the mutation symmetrically (drop-and-replace, unequip-for-a-trade,
  future loot auto-equip) — a single source of truth for "what does
  this player currently have equipped" is worth the extra function
  calls in hot paths like `BattleManager`.
- **2026-09-15 (Phase 5)** — Decided every well-formed Gate combination
  should generate a real destination, not resolve to "Unknown" unless
  specifically catalogued (the original Phase 0 plan). Requested
  explicitly by the project owner, matching the *.hack*-inspired brief:
  the mystery is in not knowing which words to pick, not in the game
  refusing combinations it doesn't recognize. This removed the
  `UNKNOWN`/`LOCKED` `GateResolver` results and the `"locked"` value
  from `GateCombinationData.result_type`'s enum.
- **2026-09-15 (Phase 5)** — Decided a generated dungeon's physical
  layout comes from one of 4 fixed templates (chosen by `branch_tier`),
  not a unique randomly-generated maze per word combination. This
  sandbox has no display, so a broken random layout (unreachable
  branch, sealed spawn) could only be caught logically, not by eye — a
  small fixed set of pre-verified templates keeps every generable
  dungeon provably reachable (see the Phase 5 BFS self-test in
  PROGRESS.md) while the words still control level, theme, and loot.
  Revisit if/when a human has verified template variety looks
  repetitive in actual play.
- **2026-09-15 (Phase 5)** — Decided Cindermourn's specific effects
  (bonus damage vs. a family, MP restore on kill) get dedicated
  `EquipmentData` fields rather than being encoded into the existing
  `special_effect_id` string and parsed. These are reusable, structured
  mechanics (a future item could easily want "bonus vs. family X" too);
  `special_effect_id` remains for genuinely one-off effects that
  wouldn't justify a dedicated field.
- **2026-09-15 (Phase 5)** — Decided generated dungeons reuse the
  existing 2 common enemies (scaled by `EnemyScaler`) rather than
  authoring unique monsters per Origin theme. CLAUDE.md scopes the
  whole prototype to "3-5 enemy types"; 4 Origins x however many
  Tone/Sign combinations would blow well past that for content that's
  mostly reused stat blocks anyway. Revisit only after the vertical
  slice is proven fun and more content is explicitly in scope.
