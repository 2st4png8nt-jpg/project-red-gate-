# Architecture

Godot 4.3, GDScript, 2D top-down. 2D (not 3D) chosen as the simplest
practical technology for a real-time party-combat prototype — WASD
movement, mouse camera/targeting, and readable combat all work fine
top-down, and it keeps iteration fast with no 3D asset pipeline.

## Autoloads

- **EventBus** — signal bus. Current signals: `player_hp_changed`,
  `player_sp_changed`, `target_changed`, `skill_loadout_changed`,
  `item_identified`, `party_command_changed`.
- **DataLoader** — cached `.tres` loading. `load_all_in_dir()` strips a
  trailing `.remap` before checking the `.tres` extension, so exported
  builds (where Godot renames imported resources to `*.tres.remap`)
  scan directories identically to the editor. This bug cost real time
  in the previous project (Red Gate) and is fixed here from the start.
- **GameState** — session state owner. Currently holds
  `player_character` (loaded on `_ready()`), `current_map_id`,
  `player_hp`, `player_sp`, with `add_sp()`/`damage_player()` helpers
  that clamp and emit EventBus signals. Will grow in Phase 6 (party
  roster) and Phase 7 (equipped items).
- **SceneManager** — scene transitions via
  `get_tree().change_scene_to_file.call_deferred(...)`. Calling
  `change_scene_to_file` synchronously from a node's `_ready()` or an
  input handler throws "Parent node is busy adding/removing children";
  deferring avoids it. Only `go_to_test_arena()` exists so far.

No `SaveLoad` autoload this time — Red Gate's was never actually wired
to anything, so it's not being carried forward speculatively.

## Data schema pattern

`class_name` Resource scripts + matching `.tres` content files, same
pattern proven in Red Gate. `CharacterData`
(`scripts/data/character_data.gd`) is the first schema: shared by the
player's Adaptive character and AI Specialist companions alike — only
`specialization` differs between them. Fields: id, display_name,
position_name, specialization, max_hp, max_sp, sp_per_basic_attack,
attack, defense, move_speed, attack_range, is_player_controlled.

Further schemas (EquipmentData, SkillData, LootTableData) land in
their matching phases rather than being speculatively defined now, per
the "don't build ahead of the current phase" discipline.

## Combat architecture (fundamentally different from Red Gate)

Red Gate was turn-based with a dedicated `BattleManager` state machine
and a separate Battle scene. Tower RPG's combat is real-time and lives
directly in the dungeon/arena scene — there is no scene transition
into a "battle mode." `Player` (`scripts/world/player.gd`) is a
`CharacterBody2D` that moves every physics frame and resolves its own
basic attack by scanning the `"enemies"` group for the nearest target
in range.

## Scene set (Phases 1-3)

- `scenes/main/Boot.tscn` — `run/main_scene`. Prints autoload-ready
  status, then calls `SceneManager.go_to_test_arena()`.
- `scenes/world/Player.tscn` — `CharacterBody2D`, circle collider
  (layer 2), `ColorRect` placeholder visual, child `Camera2D` (smoothed
  follow), `AttackCooldownTimer` (0.5s, one-shot) gating basic-attack
  spam. Script: `scripts/world/player.gd`. Owns targeting state
  (`current_target`) — Tab cycles nearest-first through the
  `"enemies"` group; an `Enemy` can also set itself as the target
  directly via a click (see below). Basic attack prefers the current
  target when in range, else falls back to nearest-in-range, so the
  player can never be stuck unable to act just because nothing is
  targeted.
- `scenes/world/Enemy.tscn` — `CharacterBody2D` (layer 4, group
  `"enemies"`, `input_pickable = true` so clicks can be picked up),
  `ColorRect` visual, `Label` showing current HP, `AttackTimer`
  (one-shot, re-armed to `EnemyData.attack_cooldown`). Script:
  `scripts/world/enemy.gd` — a 3-state machine (IDLE/CHASE/ATTACK)
  driven entirely by `EnemyData` fields (aggro_range, attack_range,
  move_speed, attack, attack_cooldown), so new enemy types are new
  `.tres` instances, never new code. `_on_input_event` lets a player
  click select it as the target.
- `scenes/world/TestArena.tscn` — flat `ColorRect` floor, a
  `PlayerSpawn` marker, and a `DummySpawns` group of markers the arena
  script instances an `Enemy` at. Also instances `Hud.tscn`. Script:
  `scripts/world/test_arena.gd`.
- `scenes/ui/Hud.tscn` — `CanvasLayer` with HP/SP `ProgressBar`s driven
  by `EventBus.player_hp_changed`/`player_sp_changed`, plus a target
  panel (name + HP bar) shown on `EventBus.target_changed` and kept
  current each frame by reading the targeted `Enemy`'s `hp` directly
  (no per-enemy HP signal yet — simplest option until something else
  needs one). Script: `scripts/ui/hud.gd`.

## Data schemas (Phases 1-3)

- `CharacterData` (`scripts/data/character_data.gd`) — shared by the
  player's Adaptive character and AI Specialist companions; only
  `specialization` differs.
- `EnemyData` (`scripts/data/enemy_data.gd`) — id, display_name,
  max_hp, attack, move_speed, aggro_range, attack_range,
  attack_cooldown, is_elite.

## Collision layers

Reusing the convention proven in Red Gate: layer 1 = world/obstacles,
layer 2 = player, layer 4 (bit 3) = enemies. (`TestArena` has no
obstacles yet, so layer 1 is currently unused but reserved.)

## Known Godot quirk

A fresh checkout with no `.godot/` cache fails to resolve `class_name`
types (`Could not find type "CharacterData" in the current scope")
the very first time a script references one headlessly. Fix: run
`godot4 --headless --editor --quit` once to build the global script
class cache before `--headless --path . --quit-after N` validation
runs. This is a one-time cache-warm step, not a bug in the project
itself.
