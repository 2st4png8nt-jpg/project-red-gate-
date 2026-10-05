# Progress

## Status: Phases 1-3 complete (movement/combat, targeting/AI, HP+SP)

Validated headlessly — project boots, all 4 autoloads initialize, the
test arena loads, and a 200-frame simulated run (enemy chases from
aggro range into attack range and starts hitting the player) produces
no script errors.

## What exists right now

- Project skeleton: `project.godot`, folder structure, `.gitignore`,
  placeholder icon.
- Autoloads: EventBus, DataLoader, GameState, SceneManager.
- Data schemas: `CharacterData`, `EnemyData`. Content:
  `player_fisherman.tres` (Phase 1 "Adaptive Fisherman" player),
  `dummy_brute.tres` (Phase 2 test enemy).
- Scenes: `Boot.tscn`, `Player.tscn`, `Enemy.tscn`, `TestArena.tscn`,
  `Hud.tscn`.
- **Player**: WASD movement (raw key polling, no InputMap actions
  defined yet — simplest option for now, revisit once a real control
  scheme / rebinding screen is needed), camera follow, explicit
  targeting (Tab cycles nearest-first through all enemies; clicking an
  enemy selects it directly), LMB basic attack that hits the current
  target if in range, else falls back to the nearest enemy in range
  (so the player is never left unable to act), and grants SP via
  `GameState.add_sp()`.
- **Enemy**: data-driven (`EnemyData`) state machine — IDLE (player
  outside aggro range) -> CHASE (move toward player) -> ATTACK (player
  in attack range, hits on a cooldown via `GameState.damage_player()`).
  Clickable (`input_pickable`) to set itself as the player's target.
  Dies at 0 HP.
- **Hud**: player HP/SP bars driven by `EventBus.player_hp_changed` /
  `player_sp_changed`; a target panel (name + HP bar) that appears
  when a target is selected, polling the targeted Enemy's `hp`
  directly each frame (simplest option — no per-enemy HP-changed
  signal needed yet).

## Validated

```
godot4 --headless --editor --quit         # one-time per session: build global script class cache
godot4 --headless --path . --quit-after 200
```

Output:
```
[Boot] Tower RPG booting...
[Boot] Autoloads ready -> EventBus=true DataLoader=true GameState=true SceneManager=true
[TestArena] loaded.
```

No SCRIPT ERROR / parse / compile errors across the run, including the
enemy's full IDLE -> CHASE -> ATTACK transition and player damage.

## Spec Section 41 "STOP AND TEST" — still not answerable from headless runs

The 8 playtest questions need an actual human play session (feel of
movement, attack timing, whether combat reads as "deliberate" rather
than twitchy, whether targeting via Tab/click feels natural, etc.).
Headless validation only proves the systems don't crash — it says
nothing about feel. An exported/playable build is the next thing
needed before that checkpoint can be answered honestly.

## Next up (task #64 — Phase 4)

Skills: ACTIVE/PASSIVE/TRIGGER skill data schema, SP-cost consumption,
and at least one usable active skill bound to a number key, building
on the SP pool this phase already wired up.
