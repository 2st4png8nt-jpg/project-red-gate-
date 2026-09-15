# PROGRESS.md — Project Red Gate

Owner: Lead / Architect

Log entries newest first. One entry per meaningful milestone (CLAUDE.md
Section 28).

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
