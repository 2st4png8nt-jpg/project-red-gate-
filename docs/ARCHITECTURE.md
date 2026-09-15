# ARCHITECTURE.md — Project Red Gate

Owner: Lead / Architect
Status: Phase 4 (Loot)

This document is the technical source of truth. It describes how the
systems fit together and where the boundaries between agent-owned areas
are. Update it whenever a cross-system interface changes.

---

## 1. Engine & Toolchain

- **Engine:** Godot 4.3 (stable), GDScript.
- **Why:** free, open-source, first-class 2D pixel-art + tilemap
  support, UI-heavy menu systems are native (Control nodes), exports to
  desktop, no paid middleware required.
- **Renderer:** Forward+ is fine for a 2D prototype; can be switched to
  `gl_compatibility` later if a target machine needs it. Not a Phase 0
  decision.
- **Headless validation:** this sandbox has no display. A headless
  Godot binary is used for `--check-only` parses and short automated
  smoke runs. Full visual verification (art, camera feel, animation
  timing) requires opening the project in the Godot editor on a machine
  with a display — that step is **not** substitutable by headless runs
  and must happen before a milestone is called "done" for anything
  visual.

## 2. Top-Level Folder Map

```
project.godot
project_icon.svg

docs/                 Lead Agent: source-of-truth documentation
  GAME_DESIGN.md
  ARCHITECTURE.md
  AGENT_CONTRACTS.md
  PROGRESS.md
  QA/                 QA: checklists, bug reports

scripts/
  core/               Agent 1 (Core Systems): autoloads, state, save/load, events, data loading
  data/               Agent 1 / Agent 3: Resource *schema* definitions (class_name only, no content)
  rpg/                Agent 3 (RPG/Gear): player stats, inventory, equipment, leveling, currency
  combat/             Agent 2 (Combat): battle state machine, commands, damage resolution
  world/              Agent 4 (World/Gate): player movement, map transitions, map controllers
  gates/              Agent 4 (World/Gate): Gate combination resolution
  ui/                 Agent 5 (UI/UX): all Control-based UI scripts
  enemies/            Agent 6 (Enemy/Content): enemy behavior scripts, LootRoller
  audio/              Agent 8 (Audio): audio manager, playback hooks

scenes/
  main/               Boot scene, top-level Main scene
  world/              Town.tscn, map scenes
  combat/             Battle.tscn
  ui/                 UI scenes (HUD, menus, screens)

data/                 Content, as .tres Resource files (data-driven, no logic)
  items/              Agent 3
  characters/         Agent 3 (base player stat block)
  maps/               Agent 4 (map metadata: id, display name, exits, encounter table id)
  gates/              Agent 4 (keyword pool + combination table)
  skills/             Agent 2 (player + enemy SkillData rows)
  enemies/            Agent 6
  encounters/         Agent 6 (single-enemy EncounterData rows)
  loot/               Agent 6 (LootTableData rows, referenced by EnemyData.loot_table_id)

art/                  Agent 7: sprites, tiles, UI art (placeholders acceptable)
assets/               Agent 7: misc non-code assets
audio/                Agent 8: music/, sfx/
tests/                Agent 9 (QA): automated + scripted manual tests
```

Ownership mirrors CLAUDE.md Section 15. If a file needs to change
outside the areas above, follow the Section 17 procedure (explain why,
smallest possible interface change, notify Lead Agent, no redesign).

## 3. Autoload (Singleton) Layer

Registered in `project.godot` under `[autoload]`, load order matters:

1. **EventBus** (`scripts/core/EventBus.gd`) — global signal bus.
   Systems communicate through signals here instead of reaching into
   each other directly. No state, no logic beyond `signal` declarations
   and thin `emit_*` helpers.
2. **DataLoader** (`scripts/core/DataLoader.gd`) — loads and caches
   `.tres` Resources from `/data/**` by id. Every other system asks
   DataLoader for content; nothing does a raw `load()` on a data file
   outside this autoload.
3. **GameState** (`scripts/core/GameState.gd`) — holds the current
   `PlayerData` instance, current map id, and run-level flags (which
   Gate combinations are known/unlocked, which clues are found). This
   is the only autoload allowed to hold mutable game-session state.
4. **SceneManager** (`scripts/core/SceneManager.gd`) — owns switching
   the active scene (Town <-> Map <-> Battle) via `get_tree().change_scene_to_*`
   wrappers, plus a simple transition hook UI can fade against.
5. **SaveLoad** (`scripts/core/SaveLoad.gd`) — serializes `GameState`'s
   relevant fields to/from `user://save_slot_0.json`. Basic single-slot
   save is sufficient for the prototype.

Rule: UI and gameplay scripts read from `GameState` and call its methods
or emit `EventBus` signals. They must not hold their own copy of
authoritative state (e.g. a battle scene does not keep a second source
of truth for player HP — it reads/writes through `GameState.player`).

## 4. Data-Driven Content Model

Every content type is a `Resource` subclass (a schema) plus `.tres`
instances (the content) under `/data/`. This lets Agent 3/4/6 add
content without touching engine code, per CLAUDE.md Section 20.

Schema locations (Phase 0 deliverable — see AGENT_CONTRACTS.md for the
exact fields of each):

- `scripts/data/item_data.gd` — `ItemData` (base for all inventory items)
- `scripts/data/equipment_data.gd` — `EquipmentData extends ItemData`
- `scripts/data/skill_data.gd` — `SkillData`
- `scripts/data/enemy_data.gd` — `EnemyData`
- `scripts/data/gate_keyword_data.gd` — `GateKeywordData`
- `scripts/data/gate_combination_data.gd` — `GateCombinationData`
- `scripts/data/map_data.gd` — `MapData`

## 5. Scene / State Flow

```
Boot.tscn (autoloads already initialized by the engine)
   -> SceneManager.go_to_town()
Town.tscn (Waymark)
   <-> MapTransitionArea doorway -> SceneManager.go_to_map(map_id) -> CinderfallWoods.tscn
   -> (Phase 5) Gate interface replaces/supplements the raw doorway above
   -> (Phase 2) encounter trigger -> SceneManager.go_to_battle(encounter_id)
   -> Battle.tscn -> victory/defeat -> SceneManager.return_from_battle()
```

Phase 0 needed Boot -> Town to work end to end with no runtime errors.
Phase 1 (current) adds real movement/camera/tilemap/collision and a
working Town <-> Cinderfall Woods map transition. Battle scenes arrive
in Phase 2.

## 5a. World / Movement Layer (Phase 1)

`scripts/world/` (Agent 4) now contains, in addition to map controller
scripts (`town.gd`, `cinderfall_woods.gd`):

- **`player.gd`** (`scenes/world/Player.tscn`) — a `CharacterBody2D`
  with 4-directional movement (raw `Input.is_key_pressed` checks; a
  formal, rebindable `InputMap` is deferred to a later polish phase), a
  `CollisionShape2D`, and a child `Camera2D` exposing
  `set_camera_limits(pixel_rect: Rect2i)`. Every map instantiates its
  own `Player` at a `Marker2D` spawn point and calls
  `set_camera_limits()` with its own pixel bounds — the Player scene
  itself carries no per-map data.
- **`rect_map_builder.gd`** (`RectMapBuilder`, static utility) — paints
  a `TileMapLayer`'s ground and spawns `Obstacle` colliders from a map
  size plus a list of open-area `Rect2i`s (tile coordinates); anything
  not covered by an open rect becomes solid ground with an obstacle on
  top. Chosen over hand-authoring ASCII art or raw `TileMapLayer`
  binary `tile_map_data` because a list of rectangles is trivial to
  read, edit, and unit-test (`RectMapBuilder.is_open_at()` backs a
  simple BFS reachability check — see PROGRESS.md Phase 1 entry) with
  no risk of a silently-malformed binary blob.
- **`map_transition_area.gd`** — a generic `Area2D` doorway: walking a
  body in the `"player"` group into it calls
  `SceneManager.go_to_map(target_map_id)`. This is a **Phase 1 stand-in**
  for the real Gate-driven entry point; Phase 5 will make normal-map
  entry go through Gate combination resolution instead of a walk-up
  door (the doorway mechanism itself, and `SceneManager.go_to_map`,
  stay — only what triggers them changes).

### Collision layers (bits, not layer numbers)

| Layer | Used by |
|---|---|
| 1 | World geometry — `Obstacle` (`StaticBody2D`) |
| 2 | Player (`CharacterBody2D`) |
| 3 | Reserved for enemies (Phase 2) |

`Player.collision_mask = 1` (collides with world geometry).
`Obstacle.collision_mask = 0` (static, detects nothing).
`MapTransitionArea.collision_mask = 2` (detects the player only).

### Map layout contract

A map controller script (e.g. `town.gd`) defines `MAP_SIZE: Vector2i`
and `OPEN_RECTS: Array[Rect2i]`, calls
`RectMapBuilder.build(ground_layer, obstacle_container, obstacle_scene, MAP_SIZE, OPEN_RECTS, floor_source_id, wall_ground_source_id)`
in `_ready()`, then instantiates `Player` at its `PlayerSpawn` marker
and calls `set_camera_limits()`. Any new map (normal or special) should
follow this same shape.

## 6. Combat Interface Contract (Phase 2/3 — implemented)

Combat (`scripts/combat/battle_manager.gd`, `BattleManager`) consumes,
not owns:
- `PlayerData` (`GameState.player` directly — Combat does not copy it)
- `EnemyData` + its `SkillData` (loaded via `DataLoader` from
  `data/enemies/` and `data/skills/`, keyed by `EncounterData.enemy_id`)
- `EquipmentData` effects, via `StatsCalculator` (Phase 3 — see Section
  6a below). `BattleManager` never reads `player.attack`/`defense`/
  `magic_power`/`max_hp`/`max_mp` directly; it always goes through
  `StatsCalculator.effective_*()` so an equipped item's bonus is live
  the instant it's equipped, not just after the next battle starts.

One `BattleManager` instance lives at the root of `scenes/combat/Battle.tscn`
(not an autoload — a fresh instance per battle). It reads
`GameState.pending_encounter_id` (set by `SceneManager.go_to_battle()`)
in **`_enter_tree()`, not `_ready()`**: Godot runs a node's `_ready()`
after all of its children's `_ready()` calls, so if `BattleManager`
initialized `enemy`/`player` in its own `_ready()`, its child `BattleUI`
would read them as still-null during `BattleUI._ready()`. `_enter_tree()`
runs top-down (parent before children), so state is guaranteed set
before any child reads it. (Caught by the Phase 2 headless self-test —
see PROGRESS.md.)

Exposed API (UI calls these, never touches damage math directly):
- `start_battle(encounter_id: String)`
- `player_attack()`, `player_use_skill(skill: SkillData)`,
  `player_use_item()`, `player_defend()`, `player_run()`

Exposed signals (UI reads state only through these plus the public
`enemy` / `enemy_hp` / `player` fields):
- `turn_state_changed(state_name: String)` — `"player_input"`,
  `"resolving"`, `"enemy_turn"`, `"won"`, `"lost"`, `"fled"`
- `action_resolved(message: String)` — one line for the message log
- `hp_mp_changed` — a generic "redraw stat bars" ping
- `battle_won(xp: int, gold: int, leveled_up: bool, loot_item_name: String, clue_discovered: bool)` —
  `loot_item_name` is `""` when nothing dropped (see Section 6b);
  `battle_lost`, `battle_fled`

Damage formulas (deliberately simple — see GAME_DESIGN.md Section 27,
balance from playtesting, not a spreadsheet up front; `attacker.attack`
etc. below mean the `StatsCalculator` effective value, not the raw
`PlayerData` field, for the player's side):
- Basic attack: `max(1, attacker.attack - defender.defense)`
- Skill (non-self): `max(1, skill.power + attacker.magic_power - defender.defense)`
- Skill (`target_type == "self"`): heals `skill.power` HP, no defense involved
- Defending halves the next hit taken (integer division), one-shot flag
  cleared after it's used once
- Enemies always use `skill_ids[0]` if they have one, else basic attack
  — no enemy AI variety yet (Phase 2 scope); enemies have no equipment,
  so `EnemyData`'s raw fields are used as-is
- Item command (Phase 3): uses `Inventory.find_first_consumable()` —
  the first `ConsumableData` in `player.inventory` — and heals its
  `heal_hp`/`heal_mp`, capped at the effective max. No item-selection
  submenu yet since there is only one consumable type; revisit once a
  second one exists.

`Leveling` (`scripts/rpg/leveling.gd`, Agent 3) is a static, placeholder
XP curve (`xp_to_next_level(level) = level * 20`) called from
`BattleManager._win()`. Full balancing is Phase 3/4.

## 6a. Progression Layer (Phase 3)

`scripts/rpg/` (Agent 3) gained three static utilities alongside
`player_data.gd` and `leveling.gd`:

- **`StatsCalculator`** — `effective_attack/defense/magic_power/speed/
  max_hp/max_mp(player)`, each returning the matching `PlayerData` base
  field plus the sum of that stat's bonus across
  `equipped_weapon`/`equipped_armor`/`equipped_accessory` (any bonus
  field on any slot — a speed-boosting weapon is just as valid as an
  accessory one; the schema does not restrict bonuses by slot). This is
  the *only* place equipment math happens; nothing else computes a
  bonus by hand.
- **`EquipmentManager`** — `equip(player, item) -> EquipmentData`
  (returns whatever was previously in that slot, or null) and
  `unequip(player, slot) -> EquipmentData`. Both clamp `player.hp`/`mp`
  down if the new effective max is lower than the current value (an
  unequip can never leave hp/mp displaying above the new max). Neither
  method touches `player.inventory` — callers (currently only
  `InventoryUI`) are responsible for moving the returned item into the
  inventory array and removing the newly-equipped one from it.
- **`Inventory`** — `add_item`, `remove_item`, `find_first_consumable`.
  `player.inventory` is a flat `Array[ItemData]`; there is no
  stacking/count field, so buying the same potion twice just appends
  the same shared `ConsumableData` resource reference twice (items are
  treated as immutable templates, never mutated per-copy, so sharing a
  reference across multiple inventory slots is safe).

New schema: **`ConsumableData extends ItemData`** (`scripts/data/consumable_data.gd`)
— `heal_hp: int`, `heal_mp: int`.

UI built on this layer (Agent 5):
- **`InventoryUI`** (`scenes/ui/InventoryUI.tscn`, a child of
  `Player.tscn`, toggled by the `I` key) — lists equipped gear with
  Unequip buttons and inventory items with Equip buttons (for
  `EquipmentData`) or just a description (for `ConsumableData`), plus
  the player's current effective stats. Present in every map because
  it lives on `Player`, not on a per-map scene. Each equipment row also
  shows a Phase 4 comparison string (see Section 6b) vs. whatever
  currently occupies that slot.
- **`ShopUI`** (`scenes/ui/ShopUI.tscn`, instanced by `town.gd`, opened
  by walking into `ShopTrigger`) — a data-driven item list (the
  `item_ids` the shop sells is set on the instance by `town.gd`, not
  hardcoded in the script); Buy deducts `item.value` gold and calls
  `Inventory.add_item`. Both `InventoryUI` and `ShopUI` being open
  pauses `Player`'s `_physics_process` (`InventoryUI` checks its own
  `visible` state; `ShopUI`'s open/close is wired by `town.gd` since
  the shop is Town-only, not a `Player` child).

UI (`scripts/ui/battle_ui.gd` + `scenes/ui/BattleUI.tscn`, Agent 5)
reads battle state via the signals/fields above and drives the command
menu; it contains no combat math and never mutates `BattleManager`
fields directly.

## 6b. Loot Layer (Phase 4)

New schema: **`LootTableData`** (`scripts/data/loot_table_data.gd`) —
`drop_chance: float` (0..1) plus parallel `item_ids: Array[String]` /
`weights: Array[int]`. Deliberately flat (not an array of a nested
per-entry Resource) so a whole table is one easy-to-hand-author `.tres`
— see AGENT_CONTRACTS.md's Open Interface Decisions Log if that choice
needs revisiting later (e.g. once entries need their own per-entry drop
chance instead of one shared table-level chance).

**`LootRoller`** (`scripts/enemies/loot_roller.gd`, Agent 6, static) —
`roll(table: LootTableData) -> String` returns an item id or `""`.
First rolls `drop_chance`; if that passes, picks weight-proportionally
among `item_ids`. Content lives in `data/loot/`, referenced by
`EnemyData.loot_table_id`.

`BattleManager._win()` (Phase 4 addition) rolls the defeated enemy's
loot table (if `loot_table_id` is set), adds any resulting item via
`Inventory.add_item`, and — new `EnemyData.gate_clue_id` field — calls
`GameState.discover_clue()` if set. Both feed into the richer
`action_resolved` victory message and the extended `battle_won` signal
above, so `BattleUI` never has to ask `BattleManager` "what happened"
after the fact.

`InventoryUI`'s equipment comparison (Section 6a) reads
`EquipmentData`'s `@export` bonus fields directly via `Resource.get(field_name)`
rather than a per-stat match statement — see `_format_comparison()` in
`scripts/ui/inventory_ui.gd`. It duplicates none of `StatsCalculator`'s
logic; it only diffs one candidate item against whatever already
occupies that slot.

## 7. Gate Resolution Contract

`scripts/gates/gate_resolver.gd` exposes:
- `resolve(origin: String, tone: String, sign: String) -> GateResult`

Where `GateResult` (a small typed return, see AGENT_CONTRACTS.md) is one
of: `KNOWN` (has a destination map id), `SPECIAL` (unlocks the Red Gate),
`LOCKED` (known but not yet unlocked), `UNKNOWN` (well-formed but not in
the table), `INVALID` (malformed input — e.g. empty string or a keyword
outside the current pool). The resolver never throws; every input path
returns a `GateResult`.

## 8. Save Data Shape (Phase 0 minimum)

```json
{
  "player": { "level": 1, "xp": 0, "hp": 20, "mp": 10, "gold": 0, "equipment": {} },
  "known_gate_clues": [],
  "unlocked_maps": ["waymark"],
  "current_map": "waymark"
}
```

This will grow; treat it as additive only — do not remove keys without a
migration note in PROGRESS.md.

## 9. Testing Approach

Godot has no bundled test runner. For the prototype:
- Prefer small, pure-logic GDScript classes (gate resolver, stat
  calculator, loot table roller) that can be unit-tested by a plain
  script run via `godot4 --headless --script tests/xxx.gd`.
- QA (Agent 9) maintains `/tests/` and `/docs/QA/`.
- A headless smoke run (`godot4 --headless --path . --quit-after 5`) is
  run before every commit that touches `.gd`/`.tscn` files, to catch
  parse/runtime errors early (does not replace opening the project
  in-editor for anything visual). Note: the very first run against a
  fresh clone must be `godot4 --headless --editor --quit --path .`
  once, to build `.godot/global_script_class_cache.cfg` — without it,
  every `class_name` type (PlayerData, MapData, etc.) fails to resolve
  on the first headless boot.

## 10. Change Control

Any change to sections 3, 4, 6, 7, or 8 above is a cross-agent interface
change and must be reflected here by the Lead Agent in the same change
set that implements it, per CLAUDE.md Section 16.
