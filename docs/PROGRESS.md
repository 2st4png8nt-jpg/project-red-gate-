# PROGRESS.md — Project Red Gate

Owner: Lead / Architect

Log entries newest first. One entry per meaningful milestone (CLAUDE.md
Section 28).

---

## 2026-09-16 — Bug fix: Gate system was completely broken in exported builds

STATUS: COMPLETE

Found via the project owner's first real playtest of an actual exported
build (a standalone Windows .exe) — exactly the category of bug this
project's docs have repeatedly flagged as unverifiable in this sandbox
(headless runs and the editor both read the uncompiled `.tres` files
directly, so this was invisible to every self-test in every prior
phase). Reported symptom: the Gate word dropdowns showed nothing to
select.

ROOT CAUSE: `DataLoader.load_all_in_dir()` (used to enumerate an entire
content folder — Gate keywords and Gate combinations, both scanned by
`GateUI` and `GateResolver`) filtered directory entries with
`file_name.ends_with(".tres")`. Godot's export process converts `.tres`
resources to binary and leaves a `<name>.tres.remap` pointer file at
the original path; a raw `DirAccess` directory listing sees that
literal `.tres.remap` name, which never matches `.ends_with(".tres")`.
The result: `load_all_in_dir()` silently returned an empty array in
every exported build, for every directory it was asked to scan — not
just empty dropdowns, but `GateResolver._is_valid_word()` (which uses
the same call) always returning false, so even a hand-typed valid word
would have resolved as `INVALID`. Every other content type (enemies,
skills, items, loot tables, maps) loads via direct `load_resource()`
calls with a known constructed path, which Godot's loader resolves
correctly regardless of export — so this bug was scoped exactly to the
3 `load_all_in_dir()` call sites, all Gate-system directory scans.

FIX: `load_all_in_dir()` now strips a trailing `.remap` before checking
the `.tres` extension, then loads via the original (un-remapped) path —
`load()`/`ResourceLoader.load()` already follows the remap transparently
when given that canonical path. See ARCHITECTURE.md Section 3.

FILES CHANGED: `scripts/core/data_loader.gd` (the fix),
`docs/ARCHITECTURE.md` (documented the gotcha so a future
directory-scanning helper doesn't reintroduce it).

TESTS:
- Reproduced first, not just fixed blind: exported a temporary Linux
  build (this sandbox can run Linux binaries directly, unlike Windows)
  with a debug script printing the raw `DirAccess` listing of
  `data/gates/keywords/` — confirmed every entry showed as
  `<word>.tres.remap`, and `load_all_in_dir()` returned 0 resources
  against that same exported binary, before writing any fix.
- Applied the fix, re-exported the same Linux debug build, and
  confirmed `load_all_in_dir()` now returns all 16 keywords.
- Extended the check to `GateResolver.resolve()` directly against the
  exported binary: a known combo (`Cinder+Broken+Ember`) resolves
  `KNOWN`, the special combo (`Hollow+Undying+Ember`) resolves
  `SPECIAL`, a well-formed unlisted combo (`Verdant+Silent+Gale`)
  resolves `GENERATED` with the correct level, and a nonsense word
  resolves `INVALID` — all four paths verified against the actual
  exported artifact, not just headless logic.
- Re-ran the standard headless smoke test against the uncompiled
  project (unaffected either way, since the editor/headless path never
  saw `.remap` files) to confirm nothing else regressed.
- Re-exported the real Windows build with the fix and re-delivered it.

KNOWN ISSUES:
- This was the first bug in the whole project caught by an actual
  exported build rather than headless validation or the editor — a
  strong signal that other exported-build-only issues could exist
  undetected. Nothing else is currently suspected, but nothing else has
  been exported-and-clicked through by a human yet either.
- Still unverified: how the Gate UI dropdowns actually *feel* to use
  (click responsiveness, popup positioning at different window sizes) —
  this fix makes them populate correctly, not necessarily pleasant to
  use; that needs the project owner's next playtest pass.

FOLLOW-UP:
- If more directory-scanning gotchas turn up, consider replacing
  `load_all_in_dir()`'s raw `DirAccess` scan with an explicit manifest
  resource per content folder (a small `Array[String]` of ids) rather
  than trusting filesystem listing to behave identically in the editor,
  headless, and every export target. Not done now since the `.remap`
  strip fixes the actually-observed failure with a 1-line change;
  revisit only if a second, different export-only bug surfaces.

---

## 2026-09-16 — Content-expansion pass: more enemies, gear, Gate words (post-Phase-6)

STATUS: COMPLETE

Phase 6 was the last CLAUDE.md-defined phase; asked which direction
"expand the game" (Section 23) should take, the project owner chose
more content within existing systems over new systems — more enemies,
gear, and Gate words, no new mechanics.

IMPLEMENTED:
- **4 new Gate words** (12 -> 16): **Frost**/**Storm** (Origin, each
  with its own new floor tile theme — `tile_frost.svg`/`tile_storm.svg`,
  2 new `world_tileset.tres` sources), **Ancient** (Tone, level 5 — the
  first word past the original 1-4 range), **Fracture** (Sign, reuses
  tier 3 rather than a new unverified layout template). `GateUI` and
  `GateResolver` needed zero code changes — both already scan
  `data/gates/keywords/` rather than using a hardcoded list.
- **2 new common enemies**: **Thornling** (`verdant` family, tanky
  physical) and **Brinewisp** (`drowned` family, the first common enemy
  built around Magic Power). `GeneratedDungeon` gained an
  `ORIGIN_ENEMY_POOL` so Verdant/Drowned dungeons spawn a themed enemy
  instead of the same duo every origin used to share; every other
  origin (including the new Frost/Storm) still falls back to the
  original pool.
- **5 new gear items**: Windward Ring (Speed/MP accessory), Verdant
  Fang (weapon with a new moveset, Piercing Thorn), Iron Buckler and
  Brinewoven Robe (two new armor options — Brinewoven Robe is the
  *first item in the game to raise Magic Power at all*), and
  Stormcaller Pendant (a Rare accessory exclusive to level-4+ dungeon
  loot, so the high tier isn't just earlier items at better odds). All
  wired into `generated_low/mid/high_loot` at modest weights alongside
  the existing entries.

FILES CHANGED:
- New: `art/tiles/tile_frost.svg`, `art/tiles/tile_storm.svg`,
  `data/gates/keywords/{frost,storm,ancient,fracture}.tres`,
  `data/enemies/{thornling,brinewisp}.tres`,
  `data/skills/{thornling_bramble_lash,brinewisp_undertow,verdant_fang_piercing_thorn}.tres`,
  `data/items/{verdant_fang,iron_buckler,brinewoven_robe,windward_ring,stormcaller_pendant}.tres`.
- Modified: `art/tiles/world_tileset.tres` (2 new sources),
  `scripts/gates/dungeon_profile.gd` (3 dict extensions),
  `scripts/world/generated_dungeon.gd` (`ORIGIN_ENEMY_POOL`),
  `data/loot/generated_{low,mid,high}_loot.tres` (new items added).

INTERFACES CHANGED: none — this pass is pure content on top of Phase
0-6 schemas. No new `EnemyData`/`EquipmentData`/`SkillData` fields were
needed.

TESTS:
- Headless self-tests (temporary code in `boot.gd`, reverted after,
  confirmed via `git diff --stat` showing no changes):
  - Verified `DungeonProfile.compute("Frost", "Ancient", "Fracture")`
    resolves to exactly `level=5, floor_source_id=7, branch_tier=3,
    loot_table_id="generated_high_loot"`, and `Storm` resolves to
    `floor_source_id=8`.
  - Verified every new enemy, its skill(s), every new item, and every
    new item's moveset skill (where set) load without error via
    `DataLoader`.
  - Verified every item id referenced in the 3 generated loot tables
    resolves to a real `ItemData` (catches a typo'd id that would
    otherwise silently show up as "Found: " with no item at runtime).
  - Extended the Phase 6 balance-sweep style check to levels 1-5 and to
    all 4 common enemies (including the 2 new ones), this time using
    each enemy's *worst case* (as if it used its skill every turn,
    which the Phase 6 AI-variety change prevents from actually
    happening) rather than only its basic attack. Even under that
    pessimistic assumption, no enemy ever kills the player in fewer
    than 3 hits at any level 1-5, and the numbers scale proportionally
    with no anomaly at the new level 5 — Ancient was safe to ship
    without adjusting `EnemyScaler` or `CombatMath.MITIGATION_K`.
  - Loaded a `Frost + Silent + Gale` generated dungeon headlessly (no
    script errors) and captured an Xvfb + Mesa llvmpipe screenshot
    confirming the new icy floor theme renders correctly (shown to the
    project owner).
- A full headless smoke run (`godot4 --headless --path . --quit-after 10`)
  passed cleanly after all changes (required the usual class-cache
  rebuild pass first, since new `class_name`-less content doesn't need
  it but this run followed script changes from the same session).

KNOWN ISSUES:
- Thornling/Brinewisp are reachable only through generated dungeons
  (`GeneratedDungeon.ORIGIN_ENEMY_POOL`), never through Cinderfall
  Woods — their own `EnemyData.loot_table_id` field is consequently
  inert today (generated encounters always use
  `EncounterData.loot_table_id_override`); both point at
  `generated_mid_loot` as a safe default rather than being left empty.
- Cinder, Hollow, Frost, and Storm dungeons still reuse Ember Wisp/
  Bramble Husk rather than getting their own themed enemy — a
  deliberate, incremental widening of the original "3-5 enemy types"
  scope cap (now 6), not a full per-Origin monster roster. Recorded as
  a decision, not an oversight — see AGENT_CONTRACTS.md.
- As with every content-only pass in this project, only headless logic
  validation, self-tests, and one screenshot were possible — no
  interactive playtest of how the new gear/enemies/words actually feel
  in a real session.

FOLLOW-UP:
- If a future pass wants full per-Origin monster variety, Cinder/
  Hollow/Frost/Storm are the remaining gaps in `ORIGIN_ENEMY_POOL`.
- A genuine 5th `branch_tier` (rather than Fracture reusing tier 3)
  would need a new hand-verified layout template in
  `GeneratedDungeon`'s `TIER_*` arrays, following the same BFS-
  reachability process used for the original 4.
- No further content is planned unless requested — this was a
  deliberate, bounded expansion of existing systems, not the start of
  an open-ended content backlog.

---

## 2026-09-16 — Phase 6: Boss + Polish established

STATUS: COMPLETE

The last CLAUDE.md-defined phase before "expand the game" territory
(Section 23). Worked the exact follow-up list the Phase 5 entry below
left behind: boss AI variety, better map presentation, sound, combat
feedback polish, and a balancing pass.

IMPLEMENTED:
- **Boss AI variety**: every enemy now alternates basic attack/skill by
  turn count instead of always using its one skill (fixes the issue for
  the whole roster, not just the boss). `EnemyData` gained
  `enrage_threshold`/`enrage_skill_id`; the Ashen Warden enrages at 50%
  HP, permanently switching to a new, stronger skill (**Cinderquake**,
  power 24 vs. Ashfall's 14) with a one-time flavor message. See
  ARCHITECTURE.md Section 6d.
- **Combat feedback polish**: `BattleManager` gained `enemy_hit`/
  `player_hit` signals; `BattleUI` reacts with a screen-tint flash and a
  short screen-shake tween, purely presentational (no new damage math).
- **Procedural audio**: `ToneSynth` synthesizes short `AudioStreamWAV`
  jingles at runtime; a new `Sfx` autoload (6th autoload) plays `hit`/
  `victory`/`defeat`/`flee` cues from `BattleUI`'s existing signal
  handlers. No external audio assets exist or are needed — this
  sandbox has no way to source or license them. See ARCHITECTURE.md
  Section 8a.
- **Dungeon ambience**: `DungeonAmbience` adds a dim `CanvasModulate`
  plus a player-following `PointLight2D` (texture generated at runtime
  via `GradientTexture2D`, no art asset) to Cinderfall Woods, every
  generated dungeon, and the Red Gate — not Town, which stays the
  bright safe hub. See ARCHITECTURE.md Section 7b.
- **Balancing pass**: measured (not guessed) — a headless sweep
  computed player-vs-common-enemy damage exchange at generated-dungeon
  levels 1-4 with starter gear. Result: common enemies consistently
  take 2-3 hits to kill and never come close to one-shotting the player
  (worst case at level 4 is 4 hits to kill the player) — the curve
  needed no adjustment. See TESTS below for the actual numbers.

FILES CHANGED:
- New: `scripts/combat/combat_math.gd` unaffected; new this phase:
  `scripts/audio/tone_synth.gd`, `scripts/audio/sfx.gd`,
  `scripts/world/dungeon_ambience.gd`,
  `data/skills/ashen_warden_cinderquake.tres`.
- Modified: `scripts/data/enemy_data.gd` (enrage fields),
  `scripts/combat/battle_manager.gd` (AI variety, enrage, hit signals),
  `scripts/ui/battle_ui.gd` + `scenes/ui/BattleUI.tscn` (HitFlash,
  shake, Sfx calls), `scripts/world/cinderfall_woods.gd`,
  `scripts/world/generated_dungeon.gd`, `scripts/world/red_gate.gd`
  (DungeonAmbience.apply calls), `data/enemies/ashen_warden.tres`
  (enrage values), `project.godot` (new `Sfx` autoload).

INTERFACES CHANGED:
- `EnemyData` gained `enrage_threshold: float` and
  `enrage_skill_id: String` (both default to "off").
- `BattleManager` gained `enemy_hit(damage: int)` and
  `player_hit(damage: int)` signals.
- New autoload `Sfx` (`scripts/audio/sfx.gd`), exposing
  `Sfx.play(clip_name: String)`.
- New static utility `DungeonAmbience.apply(map_root, player)`.

TESTS:
- Headless self-tests (temporary code in `boot.gd`/`cinderfall_woods.gd`,
  reverted after, confirmed via `git diff --stat` showing no changes):
  - `ToneSynth`/`Sfx`: verified all 4 clips build to non-empty
    `AudioStreamWAV` data and `Sfx.play("hit")` does not error.
  - Enrage logic: unit-tested `_choose_enemy_skill_id()` directly
    against a standalone `BattleManager` instance — confirmed turn 1
    (odd) picks no skill, turn 2 (even) picks Ashfall, and once HP is
    dropped to 40% the very next call (an odd turn, which would
    normally mean no skill) instead returns Cinderquake with
    `_just_enraged == true`, and a subsequent even turn stays on
    Cinderquake with `_just_enraged` correctly cleared.
  - Ambience: loaded Cinderfall Woods, a generated dungeon (tier 3,
    level 4), and the Red Gate headlessly with no script errors, then
    captured an Xvfb + Mesa llvmpipe screenshot of Cinderfall Woods
    confirming the dim tint and the player's light glow render
    correctly (shown to the project owner).
  - Balance sweep numbers (starter gear: Rusted Shortsword + Traveler's
    Vest):

    | Level | Enemy | Player deals/hit | Hits to kill enemy | Enemy deals/hit | Hits to kill player |
    |---|---|---|---|---|---|
    | 1 | Ember Wisp | 11 | 2 | 3 | 9 |
    | 1 | Bramble Husk | 10 | 2 | 5 | 5 |
    | 2 | Ember Wisp | 13 | 2 | 4 | 8 |
    | 2 | Bramble Husk | 12 | 3 | 7 | 5 |
    | 3 | Ember Wisp | 14 | 2 | 6 | 6 |
    | 3 | Bramble Husk | 13 | 3 | 8 | 5 |
    | 4 | Ember Wisp | 16 | 2 | 7 | 6 |
    | 4 | Bramble Husk | 15 | 3 | 10 | 4 |

- A full headless smoke run (`godot4 --headless --path . --quit-after 10`)
  passed cleanly after all changes, including the new `Sfx` autoload
  (required a class-cache rebuild pass first — the same
  `godot4 --headless --editor --quit --path .` step every prior phase
  needed after adding new `class_name` scripts).

KNOWN ISSUES:
- Headless runs have no audio output device (fall back to Godot's dummy
  audio driver) and this sandbox cannot play sound for a human either —
  `Sfx.play()` is verified to build valid streams and not error, but
  what it actually sounds like is unverified. A human should listen in
  the editor before calling audio "done."
- The enrage mechanic and hit-flash/shake are logic- and
  screenshot-verified, but their *feel* (does the shake read as
  impactful without being annoying, is 50% the right enrage threshold)
  needs an actual playtest, per every prior phase's same caveat about
  this sandbox having no way to simulate real input/timing feel.
- Presentation is still solid-color placeholder tiles underneath the
  new lighting — the lighting makes them read better, but this is not
  the parallax/depth-layering art pass GAME_DESIGN.md Section 2
  ultimately calls for.
- As requested by the project owner in a much earlier turn, art is
  still explicitly a later concern; Phase 6 deliberately spent its
  "polish" budget on lighting/audio/feedback systems that generalize
  across every current and future map, rather than on one-off sprite
  work.

FOLLOW-UP:
- This was CLAUDE.md's last explicitly-defined phase. Per the Phase 5
  entry's own note, this is a natural point for a deliberate check-in
  with the project owner on what "expand the game" (CLAUDE.md Section
  23) should mean next — more content within existing systems (more
  enemies/gear/gate words) vs. new systems (a second Reach, a proper
  class/build system, a real art pass), rather than continuing to
  assume the next phase's shape.
- If a human playtest disagrees with the 50% enrage threshold or the
  shake/flash intensity, both are single tunable values
  (`EnemyData.enrage_threshold`, the `strength` args in
  `battle_ui.gd`'s `_shake()` calls).

---

## 2026-09-15 — Systems-depth pass: stats, abilities, movesets (post-Phase-5)

STATUS: COMPLETE

The project owner asked, after seeing Phase 5's screenshot, to deepen
combat/progression beyond the vertical slice: gear should meaningfully
grant stats, abilities should be driven by the right stats, weapons
should have their own movesets, and the whole thing should run on a
"logic based" stat system rather than ad hoc numbers — tied together
with leveling. Not a new phase per CLAUDE.md's roadmap; a depth pass
across systems already built in Phases 2-5.

IMPLEMENTED:
- `CombatMath` (`scripts/combat/combat_math.gd`, new): centralizes
  damage math for `BattleManager`. `mitigate(raw_power, defense)` uses
  a diminishing-returns curve (`defense/(defense+40)`) instead of flat
  `power - defense` subtraction — defense is always worth something,
  never makes a unit unhittable (floor of 1 damage).
  `skill_power_stat()` picks Attack for `element == "physical"` skills,
  Magic Power for everything else, so elemental skills finally scale
  off the stat their fiction implies.
- Speed-based initiative in `BattleManager._start_with_encounter()`:
  whichever side has higher effective Speed opens the battle; ties
  default to the player. Speed existed since Phase 0 but was purely
  decorative until now. Only the opening turn is speed-checked; turns
  alternate normally afterward.
- Weapon movesets: `EquipmentData.granted_skill_id` (new field) names
  an extra `SkillData` only offered in `BattleUI`'s Skill submenu while
  that weapon is equipped. Authored two: Cinderfall Cleaver grants
  **Cleave** (`data/skills/cleaver_cleave.tres`), Cindermourn grants
  **Ashbrand** (`data/skills/cindermourn_ashbrand.tres`).
- `EquipmentManager.can_equip()` (new): enforces the
  `level_requirement` field every item has had since Phase 0 but which
  was never checked. `InventoryUI` disables the Equip button and shows
  a rejection message for gear above the player's level. Assigned real
  `level_requirement` values across the item set (starter gear at 1,
  Cinderfall Woods drops at 2, Red Gate drops at 3) — every item had
  shipped with the Phase 0 placeholder of `0`.

FILES CHANGED:
- New: `scripts/combat/combat_math.gd`,
  `data/skills/cleaver_cleave.tres`, `data/skills/cindermourn_ashbrand.tres`.
- Modified: `scripts/combat/battle_manager.gd` (mitigation, initiative,
  element-aware skill scaling), `scripts/data/equipment_data.gd`
  (`granted_skill_id`), `scripts/rpg/equipment_manager.gd`
  (`can_equip`), `scripts/ui/battle_ui.gd` (moveset consumption),
  `scripts/ui/inventory_ui.gd` + `scenes/ui/InventoryUI.tscn`
  (level-gating UI + message label), `data/items/*.tres` (level
  requirements, `granted_skill_id` on the two weapons above).

INTERFACES CHANGED:
- `EquipmentData` gained `granted_skill_id: String` (empty = grants
  nothing).
- `EquipmentManager` gained `can_equip(player, item) -> bool`. `equip()`
  itself is unchanged and still does not self-check — see
  AGENT_CONTRACTS.md's Open Interface Decisions Log for why.
- `BattleManager` damage paths (`player_attack`, `player_use_skill`,
  `_enemy_turn`) now route through `CombatMath` instead of inline flat
  subtraction. No public signature changed, only internal math.

TESTS:
- Headless self-tests (temporary code in `boot.gd`, reverted after,
  confirmed via `git diff --stat` showing no changes) with exact-number
  verification, not just "does it run":
  - `CombatMath.mitigate(40, 6)` hand-checked against the live
    Cindermourn-vs-Ashen-Warden basic attack: expected
    `round(40*(1-6/46))=35`, then the existing weapon-family bonus
    `round(35*1.15)=40`; battle showed `enemy_hp 70 -> 30`, exact match.
  - Initiative: confirmed the Ashen Warden (speed 6) correctly acts
    first against a level-1 player (effective speed 5, even with
    Cindermourn equipped, since it grants no speed bonus) — the test
    had to wait out the enemy's opening turn before attempting a player
    action, which was the correct new behavior, not a bug.
  - Level-gating: confirmed `can_equip()` rejects a level-3 item for a
    level-1 player and `InventoryUI` shows the rejection message.
- One real bug found and fixed during this pass: `battle_ui.gd`'s
  `var weapon := battle_manager.player.equipped_weapon` failed to
  parse ("Cannot infer the type of 'weapon' variable") because
  `battle_manager` is `Node`-typed via `get_parent()`, making the
  access chain dynamically typed. Fixed with an explicit
  `var weapon: EquipmentData = ...` annotation — same class of error
  hit in earlier phases with untyped access through generically-typed
  nodes.

KNOWN ISSUES:
- **Balance finding, not a bug**: an undefended level-1 player cannot
  survive the Ashen Warden's opening Ashfall under the new mitigation
  formula — its raw power exceeds the player's base 20 HP once
  mitigated. Confirmed intentional/working-as-designed via a follow-up
  test with a Traveler's Vest equipped (survives with 1 HP). Documented
  in GAME_DESIGN.md Section 9 rather than silently tuned away, per
  CLAUDE.md Section 27's "measure then adjust" philosophy — the Red
  Gate is meant to require gearing up first.
- Only the opening turn is speed-checked; there is no full ATB/speed
  queue across a multi-turn battle. Acceptable for this prototype's
  scope.
- As with every prior phase, only headless logic validation and
  self-tests were possible in this sandbox — no interactive play.
  Opening the project in the Godot 4.3 editor to feel the new combat
  pacing (does mitigation feel too spongy/too swingy, does initiative
  read clearly in the UI) is a required follow-up before calling combat
  feel "done" in the fullest sense.

FOLLOW-UP:
- If a human playtest finds the mitigation curve too spongy or too
  swingy, `CombatMath.MITIGATION_K` is the single tuning knob.
- Consider a small UI cue for who won initiative (currently only
  inferable from the message log).
- No further systems work is planned unless requested — this was an
  explicit scope-widening ask, not part of the phased roadmap.

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
