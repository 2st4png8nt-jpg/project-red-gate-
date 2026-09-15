# PROGRESS.md — Project Red Gate

Owner: Lead / Architect

Log entries newest first. One entry per meaningful milestone (CLAUDE.md
Section 28).

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
