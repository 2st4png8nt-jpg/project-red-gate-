# PROGRESS.md — Project Red Gate

Owner: Lead / Architect

Log entries newest first. One entry per meaningful milestone (CLAUDE.md
Section 28).

---

## 2026-09-15 — Phase 5: Gates established

STATUS: COMPLETE

Substantially larger than Phases 1-4: the project owner asked, mid-Phase-5,
for the word system to be *.hack*-inspired and genuinely generative —
words determine map type, level, dungeon design, and loot table,
rather than mostly resolving to "Unknown" unless specifically
catalogued. Two scope-defining questions were asked and answered before
building (see chat): formulaic parameters over full random layout
generation, and every valid combination generates something over
keeping most combinations inert. Both decisions and the reasoning are
also recorded in AGENT_CONTRACTS.md's Open Interface Decisions Log.

IMPLEMENTED:
- `GateResolver` (`scripts/gates/gate_resolver.gd`): `SPECIAL` (Red
  Gate) > `KNOWN` (Cinderfall Woods) > `GENERATED` (every other
  well-formed combination) > `INVALID`, in that priority order.
- `DungeonProfile` (`scripts/gates/dungeon_profile.gd`): pure
  word→number math. Origin picks a floor tile theme, Tone picks a
  level 1-4, Sign picks a branch tier 0-3 (which also picks the loot
  tier: low/mid/high by level).
- `GeneratedDungeon.tscn`/`generated_dungeon.gd`: builds a dungeon at
  runtime from a `DungeonProfile` — 4 fixed layout templates by branch
  tier (0-3 side branches), themed with `RectMapBuilder` same as every
  other map, populated with `GeneratedEncounterTrigger`s that build an
  `EncounterData` in memory (enemy picked from a shared pool, level and
  loot table from the profile) since pre-authoring a row per possible
  word combination isn't practical.
- `EnemyScaler` (`scripts/enemies/enemy_scaler.gd`): scales an
  `EnemyData`'s stats for a given level without mutating the shared
  cached resource. `BattleManager` now reads every enemy stat through
  it; `level` defaults to 1 (no change) so every Phase 2-4 hand-authored
  encounter is provably unaffected.
- `GateUI` (`scripts/ui/gate_ui.gd` + `scenes/ui/GateUI.tscn`): 3 word
  dropdowns populated from `data/gates/keywords/`, resolves via
  `GateResolver`, shows discovered clue hint text
  (`GateClueData`/`data/gates/clues/`). Replaces the old
  `MapTransitionArea` doorway to Cinderfall Woods in Town — reaching
  *any* dungeon now requires figuring out the right words.
- The Red Gate, finished properly rather than left as a dangling
  `MapData` reference: `RedGate.tscn`/`red_gate.gd` (hand-crafted, not
  generated — a deliberate design pillar from GAME_DESIGN.md Section
  7), the Ashen Warden boss (family `"ashen"`, 70 HP, can't be fled
  from), and **Cindermourn** — implemented exactly as GAME_DESIGN.md's
  own example specified it (+35 Attack, +15% damage vs. `"ashen"`,
  restores 5 MP on kill), via new structured `EquipmentData` fields
  rather than the vague `special_effect_id` string.
- Cleanup: removed the dead `data/gates/combinations/silent_marsh.tres`
  and `data/maps/silent_marsh.tres` rows — that combination was never
  built as a real scene through 4 prior phases, and now correctly just
  generates a Drowned-themed dungeon like any other combination.
  GAME_DESIGN.md documents this as a deliberate supersession, not a
  silent drop of established lore.
- Also fixed in passing: GAME_DESIGN.md's currency was named "Glimmer"
  but every line of actual code/UI since Phase 2 has said "Gold" —
  updated the doc to match reality rather than leave two names drifting.

FILES CHANGED: see this milestone's commit (large — ~9 new gameplay
scripts, 4 new scenes/prefabs, ~20 new data files, 4 new tile SVGs).

INTERFACES CHANGED:
- `GateCombinationData.result_type` enum dropped the unused `"locked"`
  value.
- `EncounterData` gained `level: int` and `loot_table_id_override: String`
  (additive).
- `EquipmentData` gained `bonus_damage_vs_family`, `bonus_damage_percent`,
  `mp_restore_on_kill` (additive).
- `EnemyData` unchanged this phase (already had `gate_clue_id` from
  Phase 4).
- New `SceneManager` methods: `go_to_generated_dungeon()`,
  `go_to_generated_battle()`, `go_to_current_map()` (the last one is
  what `BattleUI` now calls instead of `go_to_map(current_map_id)`
  directly — see KNOWN ISSUES below for why that mattered).
- New `GameState` fields: `pending_generated_encounter`,
  `pending_dungeon_profile` (both battle/session-scoped, not saved,
  same pattern as `pending_encounter_id`).

TESTS:
- `godot4 --headless --path . --quit-after 10`: Boot -> Town, no
  runtime errors.
- Explicitly re-verified Cinderfall Woods and the new RedGate.tscn each
  boot cleanly as real scene loads (not just through the resolver).
- Temporary self-test (removed before commit) covered, with real code
  paths rather than parse-only checks:
  - `GateResolver.resolve()` for all 4 result types with real word
    combinations, including the exact Red Gate and Cinderfall Woods
    rows and a deliberately invalid origin word.
  - `EnemyScaler` at all 4 levels — factors (1.00/1.35/1.70/2.05) and
    resulting stats matched the formula exactly.
  - **A full BFS reachability check (same technique as Phase 1) across
    all 4 generated-dungeon templates**: every doorway and every
    encounter tile reachable from spawn, for all 4 branch tiers — not
    just "does it parse," but "can a player actually get everywhere
    this dungeon puts something."
  - All 4 templates also instantiated for real (as child nodes, not a
    main-scene swap) to confirm `RectMapBuilder`/prop-spawning runs
    with no runtime errors for each theme/tier combination.
  - Cindermourn's family bonus, measured against a non-lethal hit so no
    `_win()`/level-up could confound the number: 70 HP -> 31 HP, exactly
    `round((40 atk - 6 def) * 1.15) = 39` damage.
  - `mp_restore_on_kill`, measured against a kill that stays under the
    XP-to-level-2 threshold so `Leveling`'s own full-heal-on-level-up
    couldn't mask it: 0 MP -> 5 MP exactly.
- **Real bugs found by this testing, not just clean passes:**
  1. `SceneManager.go_to_generated_dungeon()` set
     `GameState.current_map_id = "generated"`, but `BattleUI` returned
     from a battle by calling `go_to_map(GameState.current_map_id)` —
     which would have tried to load a nonexistent `data/maps/generated.tres`
     and silently stranded the player in the battle scene forever after
     winning or fleeing a fight in *any* generated dungeon. Caught by
     tracing the round-trip before ever running it, not by a failing
     test. Fixed by adding `SceneManager.go_to_current_map()`, which
     branches on `current_map_id == "generated"` and rebuilds the same
     dungeon from the still-held `pending_dungeon_profile` instead;
     `BattleUI` now calls this instead of `go_to_map()` directly.
  2. The enemy HP bar in `BattleUI` still read the enemy's *base*
     `max_hp` after `EnemyScaler` was introduced, so a level-4 enemy's
     HP bar denominator would have been wrong (e.g. showing `42/70`
     against an effective max of ~94). Fixed to compute
     `EnemyScaler.max_hp()` for display too.
  - Two test-harness mistakes, same recognizable patterns as prior
    phases: an invalid Origin word used in the tier-0 boot check (typo
    from copy-pasting a Sign word), and the MP-restore measurement
    initially picked a kill that also leveled up the player, so
    `Leveling`'s own full-heal masked the actual restored amount —
    both fixed by adjusting the test, not the production code.

KNOWN ISSUES:
- Generated dungeons all use the same 4 layout templates — the physical
  shape repeats across many word combinations sharing a branch tier,
  even though theme/level/loot still differ. See the Open Interface
  Decisions Log entry for why, and revisit after a human has actually
  played a few to judge if it feels repetitive.
- No enemy variety per Origin theme — every generated dungeon reuses
  Ember Wisp/Bramble Husk regardless of theme. Also a documented,
  deliberate scope decision (CLAUDE.md's "3-5 enemy types" budget).
- The Gate UI's word dropdowns show all pool words with no indication
  of which combinations are "interesting" — matches the intended
  discovery/mystery design pillar, but is worth confirming feels right
  once played, not just read.
- As with every prior phase: validated headlessly and via targeted
  logic self-tests (including, this time, a full reachability sweep
  and exact-number combat math checks), never by clicking through a
  real window. UI layout (3 dropdowns + Open Gate button), pacing of
  the "the Gate hums..." flavor-text delay, and general dungeon *feel*
  across the 4 templates all need an editor playtest pass.

FOLLOW-UP (Phase 6 — Boss + Polish):
- Boss mechanics/AI variety for the Ashen Warden beyond "always use its
  one skill" (shared with every other enemy right now).
- Better map presentation: parallax/lighting/elevation cues per
  GAME_DESIGN.md Section 7 — every map is still flat placeholder tiles.
- Sound (currently nothing — `scripts/audio/`/`audio/` are still empty).
- Combat feedback polish (screen shake, hit flash, etc.).
- Basic balancing pass — actually play through several generated
  dungeons at different levels and see if the difficulty curve feels
  right, per GAME_DESIGN.md Section 27 (measure, then adjust).
- STOP AND TEST — this was the last CLAUDE.md-defined phase before
  "expand the game" territory (Section 23). Worth a deliberate check-in
  with the project owner on what comes after Phase 6.

---

## 2026-09-15 — Phase 4: Loot established

STATUS: COMPLETE

IMPLEMENTED:
- `LootTableData` schema (flat parallel `item_ids`/`weights` arrays, a
  `drop_chance`) and `LootRoller` (`scripts/enemies/loot_roller.gd`,
  static): drop-chance gate, then a weight-proportional pick.
- Two loot tables: `cinderfall_common_loot` (60% chance, 4:1 weighted
  between the Ember Draught and the new Cinderfall Cleaver — Ember Wisp
  and Bramble Husk both use it) and `cinder_wraith_loot` (100% chance,
  the new Ashcinder Guard).
- Two new items: Cinderfall Cleaver (uncommon weapon) and Ashcinder
  Guard (rare armor) — the prototype's first Uncommon/Rare gear
  actually reachable in the world, not just the Common-tier shop stock
  from Phase 3.
- New `EnemyData.gate_clue_id` field; set on the Cinder Wraith
  (`"cinder_wraith_note"`). `BattleManager._win()` now calls
  `GameState.discover_clue()` when it's set — the "boss drop confirms
  the final keyword" discovery source from GAME_DESIGN.md Section 8 is
  now real, even though the Gate UI that makes it *mean* something to
  the player is still Phase 5.
- `BattleManager._win()` rolls loot and folds both loot and the clue
  into the victory message and the (now 5-parameter) `battle_won`
  signal; `BattleUI` updated to match.
- `InventoryUI` equipment rows now show a comparison string against
  whatever's currently in that slot (`vs. equipped: ATK+8`, or
  `(no change)`), reading `EquipmentData`'s bonus fields directly via
  `Resource.get()` rather than duplicating `StatsCalculator`.

FILES CHANGED: see this milestone's commit.

INTERFACES CHANGED:
- `BattleManager.battle_won` signal grew two parameters
  (`loot_item_name: String`, `clue_discovered: bool`).
- `EnemyData` gained `gate_clue_id: String` (additive, defaults to `""`).
- New Section 6b in ARCHITECTURE.md for the loot layer; schema entries
  added to AGENT_CONTRACTS.md for `LootTableData` and the `EnemyData`
  field.

TESTS:
- `godot4 --headless --path . --quit-after 10`: Boot -> Town, no
  runtime errors. Re-verified Cinderfall Woods still boots cleanly.
- Temporary self-test (removed before commit) exercised real code
  paths rather than just checking they parse:
  - `LootRoller` edge cases: a 100%-chance single-item table always
    returns that item, a 0%-chance table always returns `""`, an empty
    table returns `""`.
  - `LootRoller` weighted distribution: 400 rolls of a 3:1-weighted
    two-item table landed at 75%/25% almost exactly (299/101), a
    strong statistical confirmation the weighting math is right, not
    just "it returns something."
  - A real `_win()` call against the Cinder Wraith encounter: the
    `battle_won` signal carried `loot_item_name="Ashcinder Guard"` and
    `clue_discovered=true` exactly as expected (100% drop chance, one
    item), the player's inventory grew by exactly one, and
    `GameState.known_gate_clues` gained `"cinder_wraith_note"`.
  - `InventoryUI._format_comparison()`: with nothing equipped, the
    Rusted Shortsword showed `ATK+6`; equipped against itself, `(no
    change)`; the Cinderfall Cleaver against the equipped shortsword,
    `ATK+8` (14 - 6) — confirms the diff is against the *equipped*
    item, not the base stat.
- **One test-harness bug, same pattern as Phase 3**: the comparison
  test function used `await` internally but was called without
  `await` from the outer self-test, so `SceneManager.go_to_town()` ran
  and freed the calling scene before the comparison test's awaited
  frames resumed — its output silently never printed rather than
  erroring loudly. No production bug this round once that was fixed;
  every real code path checked out on the first correct test run.

KNOWN ISSUES:
- Loot only exists in Cinderfall Woods; Silent Marsh has no map, no
  enemies, and no loot yet (still waiting on that map being built).
- No "rewards" beyond loot/XP/gold/clues — no quest rewards, no
  discrete "treasure chest" pickups outside combat. Not called for by
  the vertical-slice definition yet either.
- Equipment comparison is text-only (no color-coding of positive vs.
  negative deltas) — fine for a prototype, worth revisiting once real
  UI art exists.
- As with every prior phase: validated headlessly and via targeted
  logic self-tests, not by clicking through a real window. Loot text
  legibility, comparison-string readability, and drop-rate "feel" all
  need an editor playtest pass.

FOLLOW-UP (Phase 5 — Gates):
- The Gate interface in Waymark (currently the doorway to Cinderfall
  Woods is a plain walk-up trigger — Phase 5 replaces its *trigger*
  with real Gate combination entry per ARCHITECTURE.md Section 5a).
- Gate keyword combination UI, wired to the already-seeded
  `data/gates/` content and the `known_gate_clues`/`cinder_wraith_note`
  the player can now actually earn.
- The Red Gate special destination and Cindermourn, the unique weapon.
- STOP AND TEST before Phase 6.

---

## 2026-09-15 — Phase 3: Progression established

STATUS: COMPLETE

IMPLEMENTED:
- `StatsCalculator`, `EquipmentManager`, `Inventory` (`scripts/rpg/`):
  effective-stat computation from base stats + equipped gear, equip/
  unequip with hp/mp clamping, and thin inventory add/remove/find
  helpers. See ARCHITECTURE.md Section 6a for the full interface.
- `ConsumableData extends ItemData` schema.
- 4 real items in `data/items/`: Rusted Shortsword, Traveler's Vest,
  Lucky Charm (equipment — matching GAME_DESIGN.md Section 11's example
  table exactly), and the Ember Draught consumable.
- `BattleManager` now reads all player combat stats through
  `StatsCalculator` instead of `PlayerData`'s raw fields, so equipping
  something changes combat immediately, not just after the next battle
  loads. `player_use_item()` actually works now (was a Phase 2 stub).
- `InventoryUI`: equip/unequip screen, a child of `Player.tscn` so it's
  available in every map, toggled with `I`. Shows current effective
  stats live.
- `ShopUI` + `ShopTrigger`: a Waymark shop selling the 4 items above,
  a real currency sink for the gold Phase 2's battles produce.

FILES CHANGED: see this milestone's commit.

INTERFACES CHANGED:
- `BattleManager`'s internal stat reads changed from `player.attack`
  etc. to `StatsCalculator.effective_attack(player)` etc. — no change
  to `BattleManager`'s public API/signals, so `BattleUI` needed only a
  display-value fix (HP/MP bars now show effective max, not base max).
- New Section 6a in ARCHITECTURE.md for the progression layer; new
  Open Interface Decision recorded in AGENT_CONTRACTS.md for why
  equipment bonuses are computed on read rather than mutated on equip.

TESTS:
- `godot4 --headless --path . --quit-after 10`: Boot -> Town, no
  runtime errors. Re-verified Cinderfall Woods still boots cleanly
  (its `Player` instance now also carries `InventoryUI`).
- Temporary self-test (removed before commit) drove the real Phase 3
  code paths end to end, not just checked that they parse:
  1. Bought all 4 shop items via `ShopUI._on_buy_pressed()` directly —
     gold and inventory size matched exactly (100 -> 50 gold, 4 items).
  2. Equipped weapon+armor+accessory via `EquipmentManager.equip()` —
     `StatsCalculator` reported exactly base+bonus for attack, defense,
     speed, and max HP, and the previously-empty slots correctly held
     nothing to return to inventory (inventory dropped from 4 to 1,
     just the consumable).
  3. Started a real `Battle.tscn` and called `player_attack()` — damage
     matched `effective_attack - enemy.defense` exactly (8, not the
     base-stat value of 2), proving the equipment bonus is live in
     actual combat, not just in isolated stat queries.
  4. Used the Ember Draught via `player_use_item()` — healed the exact
     `heal_hp` amount and removed the item from inventory.
  5. Unequipped the weapon — attack dropped back to base and the sword
     returned to inventory.
- **Two bugs found while writing this test, both in the test harness,
  not production code** (noted here so the pattern is recognizable
  next time): (a) assigning an untyped array literal to a property
  declared `Array[String]` through a generically-`Node`-typed variable
  fails at runtime — Godot's dynamic property setter enforces the
  declared array type strictly, so the literal needs its own
  `Array[String]`-typed intermediate variable first; (b) calling an
  `await`-using test function without `await`ing it from `_ready()`
  lets the very next line (`SceneManager.go_to_town()`) run — and free
  the calling scene — before the test coroutine resumes, producing a
  confusing "null tree" error far from the real mistake. A third
  apparent failure (item use silently doing nothing) turned out to be
  `BattleManager` correctly refusing the action because the battle was
  still mid-turn — the test needed to wait out the enemy-turn delay
  first, same lesson as Phase 2 about `--quit-after` counting frames.

KNOWN ISSUES:
- No equipment *comparison* UI (showing before/after stats before
  committing to an equip) — explicitly Phase 4 scope.
- No loot drops from combat yet — the only way to get equipment is the
  Waymark shop. Phase 4 adds drop tables.
- Inventory has no scrolling; if it grows large it will overflow the
  screen. Fine for the prototype's current ~5 items, revisit if that
  changes.
- Buying/equipping/using items has not been clicked through in a real
  window — same caveat as every prior phase, headless + logic
  self-tests aren't a substitute for an editor playtest pass.

FOLLOW-UP (Phase 4 — Loot):
- Loot tables and equipment drops from Cinderfall Woods encounters
  (the Cinder Wraith should drop something worth the fight).
- Rarity beyond "common" actually appearing in the world (Uncommon/Rare
  gear per GAME_DESIGN.md Section 11's progression table).
- Equipment comparison UI in `InventoryUI`.
- STOP AND TEST before Phase 5.

---

## 2026-09-15 — Phase 2: Combat established

STATUS: COMPLETE

IMPLEMENTED:
- `BattleManager` (`scripts/combat/battle_manager.gd`): full state
  machine — `start_battle()`, `player_attack()`, `player_use_skill()`,
  `player_use_item()`, `player_defend()`, `player_run()`, enemy turn
  resolution, victory/defeat/flee. One instance per `Battle.tscn`, not
  an autoload.
- `EncounterData` schema + 3 single-enemy encounters (Ember Wisp,
  Bramble Husk, Cinder Wraith mini-boss — the last with `can_flee = false`).
- `EnemyData` rows for all three, each with one `SkillData` (enemies
  always use their first skill; no AI variety yet, by design for Phase 2).
- 3 player skills (Ember Slash, Guard Break, Second Wind) as `SkillData`
  rows in the new `data/skills/` content folder.
- `Leveling` (`scripts/rpg/leveling.gd`): minimal placeholder XP curve,
  applies stat increases and a full heal on level-up.
- `BattleUI` (`scripts/ui/battle_ui.gd` + `scenes/ui/BattleUI.tscn`):
  command menu, skill submenu, HP/MP display, message log, and the
  post-battle transition back to the world.
- `EncounterTrigger` + three placements in Cinderfall Woods (two common
  enemies in the corridor, the mini-boss in the branch alcove), each
  with a small colored marker for visibility during playtesting.
- `SceneManager.go_to_battle()` implemented for real (was a stub).

FILES CHANGED: see this milestone's commit.

INTERFACES CHANGED:
- New Combat Interface Contract finalized in ARCHITECTURE.md Section 6
  (signals, `player_*()` methods, damage formulas).
- `GameState.pending_encounter_id` added (battle-only, not saved).
- `EncounterData` schema added to the fixed schema list.

TESTS:
- `godot4 --headless --path . --quit-after 10`: Boot -> Town, no
  runtime errors. Also re-verified Cinderfall Woods (now with 3
  encounter triggers) still boots cleanly.
- Temporary self-test (removed before commit, same pattern as prior
  phases) drove a real `Battle.tscn` instance through:
  - a full attack round: `player_attack()` dealt the expected
    `attack - defense` damage, then after the enemy-turn delay the
    enemy's skill dealt its expected damage back and state correctly
    returned to `PLAYER_INPUT`;
  - a direct win: `battle_won` fired with the exact enemy's
    `xp_reward`/`gold_reward`, and `GameState.player`'s gold/xp updated
    accordingly;
  - a direct loss: `battle_lost` fired and the player was restored to
    full HP/MP (the documented placeholder defeat behavior);
  - the Cinder Wraith's flee block: `player_run()` correctly refused
    and left state at `PLAYER_INPUT`.
- **Real bug found and fixed by this testing, not just a clean pass:**
  `BattleManager` originally called `start_battle()` in `_ready()`.
  Godot calls a node's `_ready()` only after all of its children's
  `_ready()` calls have already run, so `BattleUI` (a child of
  `BattleManager` in `Battle.tscn`) was reading `battle_manager.enemy`
  as still-null inside its own `_ready()` — every real battle would
  have logged a script error and shown a blank enemy name/HP on the
  very first frame. Fixed by moving the read of
  `GameState.pending_encounter_id` into `_enter_tree()`, which Godot
  runs top-down (parent before children) rather than bottom-up. See
  ARCHITECTURE.md Section 6 for the explanation kept in the code comment.
- Learned mid-testing that `--quit-after N` counts **frames, not
  seconds** — an early run of this same self-test with `--quit-after 15`
  exited before a 0.8s in-battle timer could fire, and looked like a
  false pass/fail rather than "test didn't run long enough." Noted here
  so the next phase's self-test doesn't repeat the mistake.

KNOWN ISSUES:
- Equipment bonuses are not yet applied to combat stats (Phase 3/4 —
  there is no equipment to grant yet either).
- Item command is present in the menu but always reports "No items to
  use" since the inventory system doesn't exist yet (Phase 3/4).
- No enemy AI variety — every enemy always uses its one skill, never a
  basic attack or a defensive action.
- No animation/feedback beyond text messages and HP number changes —
  "combat feedback" polish (screen shake, hit flash, etc.) is later.
- Defeat has no real penalty (full heal, return to Waymark) — a
  deliberate placeholder so a solo playtester never gets soft-locked;
  revisit once there's something worth losing.
- As with Phase 1, this was validated headlessly and via targeted
  logic self-tests, not by clicking through a real window — button
  layout, readability, and pacing (are the 0.6s/1.2s delays too slow
  or too fast?) need a real playtest pass in the Godot editor.

FOLLOW-UP (Phase 3 — Progression):
- Real inventory: pick up/use items, item command actually works.
- Equipment comparison and stat application (weapon/armor/accessory
  bonuses flowing into `BattleManager`'s damage formulas).
- Currency sinks (Waymark shop).
- STOP AND TEST before Phase 4.

---

## 2026-09-15 — Phase 1: Movement + World established

STATUS: COMPLETE

IMPLEMENTED:
- `Player.gd`/`Player.tscn`: `CharacterBody2D` with 4-directional
  movement (raw key checks), a `CollisionShape2D`, and a child
  `Camera2D` with `set_camera_limits(pixel_rect)`.
- `RectMapBuilder` (`scripts/world/rect_map_builder.gd`): paints a
  `TileMapLayer`'s ground and spawns `Obstacle` (`StaticBody2D`)
  colliders from a map size plus a list of open-area `Rect2i`s.
  Chosen deliberately over hand-authored ASCII layouts or raw
  `TileMapLayer` binary `tile_map_data`, both of which are error-prone
  to author correctly without a visual editor — see KNOWN ISSUES.
- `MapTransitionArea` (`scripts/world/map_transition_area.gd`): generic
  walk-in doorway trigger calling `SceneManager.go_to_map(id)`.
- Placeholder tile art (`art/tiles/tile_grass.svg`, `tile_dirt.svg`,
  `tile_forest_floor.svg`) and a shared `world_tileset.tres`, plus a
  generic `Obstacle.tscn` prop (one visual reused as walls/trees/rocks,
  per the "small coherent visual vocabulary" design pillar).
- `Town.tscn` rebuilt: real tilemap ground, border collision, player
  spawn, and a doorway to Cinderfall Woods.
- `CinderfallWoods.tscn` (new): the prototype's first real dungeon — a
  main corridor plus a branching north alcove (the exploration/bonus
  area called for in GAME_DESIGN.md Section 7), and a doorway back to
  Waymark.
- Collision layer convention documented (ARCHITECTURE.md Section 5a):
  layer 1 = world geometry, layer 2 = player, layer 3 reserved for
  enemies (Phase 2).

FILES CHANGED: see this milestone's commit.

INTERFACES CHANGED:
- New `scripts/world/` contracts: `RectMapBuilder.build()`/`is_open_at()`,
  `Player.set_camera_limits()`, `MapTransitionArea.target_map_id`.
  Documented in ARCHITECTURE.md Section 5a and AGENT_CONTRACTS.md.
- `SceneManager` unchanged in signature but its `call_deferred` fix
  from Phase 0 is what makes `go_to_map()` safe to call from a
  transition area's physics callback.

TESTS:
- `godot4 --headless --path . --quit-after 10`: Boot -> Town, no
  runtime errors.
- Temporary self-test (removed before commit, same pattern as Phase 0):
  a pure-logic BFS over `RectMapBuilder.is_open_at()` confirmed, for
  both maps, that every doorway and the branch alcove are actually
  reachable from that map's spawn point — this is what makes the
  open-rect layout approach trustworthy without a visual editor:
  a bad rect shows up as an unreachable target, not a silent dead end.
  - Town: `(17,5)` doorway reachable from spawn `(3,5)` -> true
  - Cinderfall Woods: `(0,5)` return doorway and `(9,2)` branch alcove
    both reachable from spawn `(2,5)` -> true
- Temporarily pointed Boot at `SceneManager.go_to_map("cinderfall_woods")`
  to confirm that scene also boots with no runtime errors (tilemap
  paint, obstacle spawn, player instantiation, camera limits all ran
  cleanly), then reverted Boot to its normal `go_to_town()` call.

KNOWN ISSUES:
- No player sprite/animation, still a solid-color placeholder
  (Agent 7, later phase).
- Movement uses raw key checks, not a formal `InputMap` — fine for one
  developer testing, but rebinding won't work until that's added.
- Collision and reachability were verified logically and via a clean
  headless boot; actual moment-to-moment movement feel (does the
  player get caught on a doorway corner, does the camera lag feel
  right) has **not** been verified, since this sandbox has no display
  and no way to simulate key input into a running window. Opening the
  project in the Godot 4.3 editor and walking around both maps by hand
  is a required follow-up before Phase 1 is called done in the fullest
  sense.
- No encounters, no combat trigger yet in Cinderfall Woods (Phase 2).
- Cinderfall Woods only has a west entrance/exit; no second exit toward
  a future area yet (not needed until later phases).

FOLLOW-UP (Phase 2 — Combat):
- Encounter trigger in Cinderfall Woods.
- Battle scene/state machine, command menu (Attack/Skill/Item/Defend/Run).
- Enemy turns, victory/defeat, hookup to `PlayerData`.
- STOP AND TEST before Phase 3.

---

## 2026-09-15 — Phase 0: Foundation established

STATUS: COMPLETE

IMPLEMENTED:
- Full folder structure per ARCHITECTURE.md (docs/, scripts/, scenes/,
  data/, art/, assets/, audio/, tests/).
- Documentation source of truth: GAME_DESIGN.md, ARCHITECTURE.md,
  AGENT_CONTRACTS.md, this file.
- Godot 4.3 project (`project.godot`) with autoload chain: EventBus,
  DataLoader, GameState, SceneManager, SaveLoad.
- Data schemas (Resource `class_name` definitions, no content logic):
  ItemData, EquipmentData, SkillData, EnemyData, GateKeywordData,
  GateCombinationData, MapData.
- PlayerData resource (Agent 3 domain) with the Section 10 stat block.
- Seed content: keyword pool (12 words) and the 3 prototype Gate
  combinations from GAME_DESIGN.md, as `.tres` resources under
  `data/gates/`.
- Smallest bootable prototype: `Boot.tscn` -> `SceneManager` ->
  `Town.tscn` (Waymark placeholder — ColorRect ground + label, no
  movement yet, that is Phase 1). Confirms the autoload chain and
  scene-transition architecture work end to end.
- QA checklist stub for Phase 0 exit criteria.

FILES CHANGED: see initial commit.

INTERFACES CHANGED: N/A (first commit — all interfaces are new).

TESTS:
- `godot4 --headless --path . --quit-after 5` run repeatedly while
  building the foundation; caught and fixed one real bug (see below).
- Temporary self-test code (later removed) exercised `DataLoader`
  against all 12 seeded keywords and all 3 seeded Gate combinations
  (confirmed the Red Gate row resolves to `result_type="special"`,
  `destination_map_id="red_gate"`), plus a `SaveLoad` round trip
  (set gold/level/a clue, save, reset state, load, verify it matches).
  All passed.
- Bug found and fixed: `SceneManager` called `change_scene_to_file()`
  synchronously, which throws "Parent node is busy adding/removing
  children" when called from `Boot`'s own `_ready()`. Fixed by
  deferring the call (`change_scene_to_file.call_deferred(...)`) in
  both `go_to_town()` and `go_to_map()`.
- No visual/editor verification was possible in this sandbox (no
  display). Opening the project in the Godot 4.3 editor on a machine
  with a display is a required follow-up before any visual milestone
  is called done.

KNOWN ISSUES:
- No player movement, camera, tilemap, or collision yet (Phase 1).
- No combat, no UI beyond nothing, no Gate resolver logic yet (Phases
  2/5) — schemas and seed data exist, logic does not.
- Save/load has not been exercised against real gameplay state yet
  (only structurally present).
- Art is placeholder-only (solid ColorRects), per design.

FOLLOW-UP (Phase 1 — Movement + World):
- Player movement (CharacterBody2D + input), camera, tilemap, collision.
- Build Cinderfall Woods as the first real dungeon map with a branching
  path.
- Wire actual map transitions through SceneManager.
- STOP AND TEST before Phase 2.
