# PROGRESS.md — Project Red Gate

Owner: Lead / Architect

Log entries newest first. One entry per meaningful milestone (CLAUDE.md
Section 28).

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
