# Progress

## Status: Phase 1 complete (movement + camera + basic combat)

Validated headlessly — project boots, all 4 autoloads initialize, the
test arena loads, and the attack path (player -> nearest enemy in
range -> damage -> SP gain) runs with no script errors.

## What exists right now

- Project skeleton: `project.godot`, folder structure, `.gitignore`,
  placeholder icon.
- Autoloads: EventBus, DataLoader, GameState, SceneManager.
- Data schema: `CharacterData`. Content: `player_fisherman.tres`
  (the Phase 1 "Adaptive Fisherman" player character).
- Scenes: `Boot.tscn`, `Player.tscn`, `TestDummy.tscn`,
  `TestArena.tscn`.
- Player: WASD movement (raw key polling, no InputMap actions defined
  yet — simplest option for Phase 1, revisit once a real control
  scheme / rebinding screen is needed), camera follow, LMB basic
  attack that damages the nearest in-range enemy and grants SP via
  `GameState.add_sp()`.
- TestDummy: static HP pool with a live label, dies at 0 HP. No AI —
  that's Phase 2.

## Validated

```
godot4 --headless --editor --quit        # one-time: build global script class cache
godot4 --headless --path . --quit-after 2
```

Output:
```
[Boot] Tower RPG booting...
[Boot] Autoloads ready -> EventBus=true DataLoader=true GameState=true SceneManager=true
[TestArena] loaded.
```

No SCRIPT ERROR / parse / compile errors.

## Spec Section 41 "STOP AND TEST" — not yet answerable

The 8 playtest questions need an actual play session (feel of
movement, attack timing, whether combat reads as "deliberate" rather
than twitchy, etc.), not just a headless boot check. This prototype
isn't playable by a human yet — no exported build exists, and basic
attack / movement alone isn't enough content to judge combat feel
against. Revisit this checkpoint once Phase 2 (targeting + enemy AI)
and Phase 3 (HP/SP UI) land, since right now there's no way to see
your own HP/SP or a real fight back from an enemy.

## Next up (task #62 — Phase 2)

Targeting (explicit target selection/switching, not just "nearest in
range") + giving TestDummy (or a successor) actual enemy AI so there's
something to fight back against.
