# ARCHITECTURE.md — Project Red Gate

Owner: Lead / Architect
Status: Phase 5 (Gates)

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
  world/              Agent 4 (World/Gate): player movement, map transitions, map controllers, GeneratedDungeon
  gates/              Agent 4 (World/Gate): GateResolver, DungeonProfile
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
  gates/              Agent 4 (keyword pool + known/special combination rows + clues/)
  skills/             Agent 2 (player + enemy SkillData rows)
  enemies/            Agent 6
  encounters/         Agent 6 (single-enemy EncounterData rows)
  loot/               Agent 6 (LootTableData rows, referenced by EnemyData.loot_table_id or an EncounterData.loot_table_id_override)

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
(not an autoload — a fresh instance per battle). It reads either
`GameState.pending_generated_encounter` (Phase 5 — an in-memory
`EncounterData` built by a `GeneratedEncounterTrigger`, checked first
and cleared once consumed) or falls back to the file-based
`GameState.pending_encounter_id` (set by `SceneManager.go_to_battle()`)
in **`_enter_tree()`, not `_ready()`**: Godot runs a node's `_ready()`
after all of its children's `_ready()` calls, so if `BattleManager`
initialized `enemy`/`player` in its own `_ready()`, its child `BattleUI`
would read them as still-null during `BattleUI._ready()`. `_enter_tree()`
runs top-down (parent before children), so state is guaranteed set
before any child reads it. (Caught by the Phase 2 headless self-test —
see PROGRESS.md.) Both paths converge on the same private
`_start_with_encounter(encounter: EncounterData)`, which also stores
`current_encounter` (used by `_win()`'s loot lookup — see Section 6b)
and `enemy_level` (used by `EnemyScaler` — see below).

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

Damage formulas (`attacker.attack` etc. below mean the `StatsCalculator`
effective value for the player's side, and the `EnemyScaler` scaled
value — see Section 7a — for the enemy's side; `enemy_level` defaults
to 1, so hand-authored Phase 2-4 encounters are unaffected by that
addition. All damage now routes through `CombatMath.mitigate()` — see
Section 6c — rather than flat subtraction):
- Basic attack: `CombatMath.mitigate(attacker.attack, defender.defense)`,
  then the weapon family bonus below if it applies
- Skill (non-self): `CombatMath.mitigate(skill.power + power_stat, defender.defense)`,
  where `power_stat` is Attack or Magic Power depending on
  `skill.element` (`CombatMath.skill_power_stat()`, Section 6c), then
  the weapon family bonus below if it applies
- Skill (`target_type == "self"`): heals `skill.power` HP, no defense involved
- Defending halves the next hit taken (integer division), one-shot flag
  cleared after it's used once
- Enemies always use `skill_ids[0]` if they have one, else basic attack
  — no enemy AI variety yet (Phase 2 scope); enemies have no equipment,
  so `EnemyData`'s fields (scaled by `EnemyScaler` for level) are used
  as-is
- **Weapon family bonus (Phase 5 — Cindermourn's identity):** if
  `player.equipped_weapon.bonus_damage_vs_family` is non-empty and
  equals `enemy.family`, the computed damage is multiplied by
  `1.0 + bonus_damage_percent` (rounded, floor of 1). Applied in
  `_apply_weapon_family_bonus()`, called from both `player_attack()`
  and `player_use_skill()`'s non-self branch so it can't be
  accidentally skipped by one command and not the other.
- **MP restore on kill (Phase 5):** in `_win()`, if
  `player.equipped_weapon.mp_restore_on_kill > 0`, MP is restored by
  that amount (capped at `StatsCalculator.effective_max_mp`) *after*
  `Leveling.grant_xp()` has already run — a kill that also levels up
  gets its free full-MP heal from leveling first, so the restore may
  visibly do nothing on top of that; this is correct composition, not
  a bug (a self-test initially measured this wrong by picking a kill
  that also leveled up — see PROGRESS.md).
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
loot table — `current_encounter.loot_table_id_override` if set (Phase
5, used by generated dungeons whose loot tier depends on the dungeon's
level, not the enemy's own fixed `loot_table_id`), else
`enemy.loot_table_id` — adds any resulting item via `Inventory.add_item`,
and — `EnemyData.gate_clue_id` field — calls `GameState.discover_clue()`
if set. Both feed into the richer `action_resolved` victory message and
the extended `battle_won` signal above, so `BattleUI` never has to ask
`BattleManager` "what happened" after the fact.

`InventoryUI`'s equipment comparison (Section 6a) reads
`EquipmentData`'s `@export` bonus fields directly via `Resource.get(field_name)`
rather than a per-stat match statement — see `_format_comparison()` in
`scripts/ui/inventory_ui.gd`. It duplicates none of `StatsCalculator`'s
logic; it only diffs one candidate item against whatever already
occupies that slot.

## 6c. Combat Stat System Logic (systems-depth pass, post-Phase-5)

Requested directly by the project owner: gear should carry stats, stats
should drive abilities, and both should route through a logic-based
system rather than ad hoc arithmetic. Four changes, all in
`scripts/combat/`:

**`CombatMath`** (`scripts/combat/combat_math.gd`, static) replaces the
flat `power - defense` subtraction everywhere it was used:

- `mitigate(raw_power, defense) -> int` — a diminishing-returns curve,
  `damage = max(1, round(raw_power * (1 - defense/(defense + 40))))`.
  Flat subtraction has a cliff: once defense >= power every hit floors
  to 1 and stacking more defense past that point does nothing, while
  below it defense does nothing until it crosses the threshold. The
  percentage curve makes every point of defense worth something
  without ever fully negating an attack. `40` (`MITIGATION_K`) is the
  defense value that yields exactly 50% mitigation; tune this constant
  first if damage numbers feel off, per GAME_DESIGN.md Section 27
  (measure from play, don't pre-balance from a spreadsheet).
- `skill_power_stat(skill, attack_stat, magic_power_stat) -> int` —
  physical-element skills scale off Attack, everything else off Magic
  Power. Before this, `SkillData.element` was purely descriptive text;
  a skill flagged `"physical"` (Guard Break, Thorn Whip) was silently
  scaling off Magic Power like every other skill. `BattleManager` calls
  this for both the player's and the enemy's non-self skill damage.

**Initiative**: `_start_with_encounter()` now compares `enemy.speed`
(intentionally unscaled — see `EnemyScaler`'s doc comment) against
`StatsCalculator.effective_speed(player)` and lets the faster side act
first; turns alternate normally after that opening move. Previously the
player always acted first regardless of Speed, which made the stat (and
the Lucky Charm accessory that boosts it) purely decorative — Speed was
tracked and displayed everywhere but read nowhere in `BattleManager`.

**Weapon movesets**: new `EquipmentData.granted_skill_id: String` — a
weapon can grant one extra `SkillData` id, available in the Skill
submenu only while it's equipped, alongside the 3 universal skills
every player always has. `BattleUI._ready()` builds its skill button
list as `UNIVERSAL_SKILL_IDS + [equipped weapon's granted_skill_id, if
any]`. Cinderfall Cleaver grants Cleave (physical); Cindermourn grants
Ashbrand (ember — deliberately scales off Magic Power despite
Cindermourn itself only boosting Attack, giving a reason to invest in
Magic Power even on an Attack-focused unique-weapon build).

**Gear level-gating**: `EquipmentData.level_requirement` existed since
Phase 0 but nothing ever read it. `EquipmentManager.can_equip(player, item) -> bool`
now checks `player.level >= item.level_requirement`; `equip()` itself
still performs the swap unconditionally and does *not* self-check —
see the doc comment on why (a rejected equip can't be signaled through
the same "returns the previous item, or null" contract without a
caller that skipped the check misinterpreting a rejection as "nothing
was equipped before," and then wrongly discarding the item from
inventory). `InventoryUI` is the one caller today; it disables the
Equip button and shows a message when the check fails.

## 7. Gate Resolution Contract (Phase 5 — implemented)

`GateResolver.resolve(origin: String, tone: String, sign: String) -> Dictionary`
never throws; every input maps to exactly one of these, checked in this
priority order:

1. **`SPECIAL`** — the exact triple matches a `data/gates/combinations/*.tres`
   row with `result_type = "special"` (currently just the Red Gate).
   Returns `{"type": SPECIAL, "destination_map_id": String}`.
2. **`KNOWN`** — matches a row with `result_type = "known"` (currently
   just Cinderfall Woods). Same return shape as `SPECIAL`.
3. **`GENERATED`** — every other combination where all three words are
   real pool members (one from each category). Returns
   `{"type": GENERATED, "dungeon_profile": DungeonProfile}`.
4. **`INVALID`** — any word missing from the pool, or the wrong
   category. Returns `{"type": INVALID}`.

This is a deliberate change from the original "mostly Unknown until
catalogued" design (see AGENT_CONTRACTS.md's Open Interface Decisions
Log): there is no `UNKNOWN`/`LOCKED` result anymore. Every well-formed
combination produces a real destination — the mystery is in not knowing
which words to pick, not in the game refusing a combination it doesn't
recognize.

## 7a. Word-Driven Dungeon Generation (Phase 5)

**`DungeonProfile`** (`scripts/gates/dungeon_profile.gd`) is the pure
data output of `GateResolver`'s `GENERATED` case — computed by
`DungeonProfile.compute(origin, tone, sign)`, never authored as
content:

| Field | Driven by | Range / meaning |
|---|---|---|
| `level` | Tone | 1-4 (`1 + TONE_LEVEL_OFFSET[tone]`) — scales enemy stats and picks a loot tier |
| `floor_source_id` | Origin | which `world_tileset.tres` source is this dungeon's floor (visual theme) |
| `branch_tier` | Sign | 0-3 — how many side branches/how large the generated layout is |
| `loot_table_id` | derived from `level` | `generated_low_loot` (≤2) / `generated_mid_loot` (3) / `generated_high_loot` (4) |

**Why the layout itself is templated, not randomly generated per
combination:** this sandbox has no display, so a genuinely unique
random maze per word triple could produce an unreachable branch or a
sealed player spawn that only a human playing it would catch. Instead,
`GeneratedDungeon.tscn`/`generated_dungeon.gd` (Agent 4) picks one of 4
fixed layout *templates* by `branch_tier` (a doorway + straight
corridor, plus 0-3 side branches each guaranteed to touch or overlap
the corridor by construction — same additive-open-rect technique as
`RectMapBuilder`, just computed per-tier instead of hand-authored per
map) and paints it with `profile.floor_source_id`. The words still
determine map type, level, dungeon size, and loot table exactly as
asked; only the exact tile-by-tile geometry is one of 4 templates
rather than unique per combination. All 4 templates' reachability
(every doorway and encounter spot reachable from spawn) was verified
with the same BFS self-test technique used for Cinderfall Woods in
Phase 1 — see PROGRESS.md.

**How a generated encounter differs from a hand-authored one:**
`GeneratedEncounterTrigger` (`scripts/world/generated_encounter_trigger.gd`)
builds an `EncounterData` *in memory* at trigger time (picking randomly
from `enemy_ids`, an Ember Wisp/Bramble Husk pool) instead of loading
one from `data/encounters/*.tres` — there's no practical way to
pre-author a row per possible word combination. It sets the new
`EncounterData.level` and `loot_table_id_override` fields from the
dungeon's profile, then calls `SceneManager.go_to_generated_battle()`.
`BattleManager._enter_tree()` checks `GameState.pending_generated_encounter`
before falling back to the file-based `pending_encounter_id` path, so
both flows share the exact same combat code from that point on — see
Section 6's `EnemyScaler` note.

`SceneManager.go_to_generated_dungeon(profile)` sets
`GameState.current_map_id = "generated"` and
`GameState.pending_dungeon_profile = profile` (deliberately **not**
cleared after `GeneratedDungeon.tscn` reads it, unlike the
one-shot-consumed `pending_encounter_id`/`pending_generated_encounter`)
so that `SceneManager.go_to_current_map()` — what `BattleUI` calls to
return from a battle — can rebuild the identical dungeon by checking
for `current_map_id == "generated"` and re-calling
`go_to_generated_dungeon()` with the same profile, rather than trying
(and failing) to look up a `data/maps/generated.tres` row that doesn't
exist.

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
