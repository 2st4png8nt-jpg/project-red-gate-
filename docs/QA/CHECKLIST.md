# QA Checklist — Project Red Gate

Owner: Agent 9 (QA)

## Exit criteria for Phase 3 (Progression) — manual, needs a display

Not yet run against this build.

- [ ] Pressing `I` in Waymark or Cinderfall Woods opens the Inventory
      screen and pauses player movement; pressing it again (or Close)
      resumes movement.
- [ ] Walking into the shop marker in Waymark opens the shop and pauses
      movement; Leave closes it and resumes movement.
- [ ] Buying an item deducts the correct gold and adds it to inventory;
      trying to buy with insufficient gold is refused with a message
      and nothing is deducted.
- [ ] Equipping the Rusted Shortsword/Traveler's Vest/Lucky Charm from
      the Inventory screen updates the displayed stats immediately and
      moves the item from the item list to the equipped list.
- [ ] Unequipping moves the item back to the inventory list and stats
      drop back down.
- [ ] Equipping a weapon actually increases attack damage dealt in the
      very next battle (no need to leave and re-enter the map).
- [ ] Using the Ember Draught in battle heals the expected amount and
      is removed from inventory; using Item with no consumables left
      reports "No items to use" without ending the turn.
- [ ] No script errors appear in the console through a full buy ->
      equip -> fight -> use-item -> unequip loop.

## Exit criteria for Phase 2 (Combat) — manual, needs a display

Not yet run against this build (see the limitation note at the bottom).

- [ ] Walking into each of the 3 encounter markers in Cinderfall Woods
      starts a battle against the expected enemy (Ember Wisp / Bramble
      Husk in the corridor, Cinder Wraith in the branch alcove).
- [ ] Attack, Skill, Defend, and Run all do something visible and
      correct; Item reports "No items to use" without ending the turn.
- [ ] The Skill submenu shows all 3 player skills with correct MP
      costs, and Back returns to the main command menu without
      spending a turn.
- [ ] Trying a skill with insufficient MP is rejected with a message
      and doesn't consume MP or end the turn.
- [ ] HP/MP bars (text) update immediately after every action, for
      both the player and the enemy.
- [ ] Winning shows the correct XP/gold and returns to Cinderfall
      Woods after a short pause.
- [ ] Losing shows a defeat message and returns to Waymark with HP/MP
      restored.
- [ ] Running succeeds against Ember Wisp/Bramble Husk and is refused
      (with a message) against the Cinder Wraith.
- [ ] Command buttons are disabled (not clickable) during the enemy's
      turn and re-enable once control returns to the player.
- [ ] No script errors appear in the debug console during a full
      battle from start to victory or defeat.

## Exit criteria for Phase 1 (Movement + World) — manual, needs a display

These require actually opening the project in the Godot 4.3 editor and
playing — headless runs cannot verify feel, camera framing, or whether
movement gets stuck on geometry. Not yet run against this build.

- [ ] Player moves smoothly in all 4 directions with WASD and arrow keys.
- [ ] Player cannot walk through any obstacle/wall tile in Town or
      Cinderfall Woods.
- [ ] Player does not get stuck/snagged on doorway corners or on the
      seam between adjacent obstacle tiles.
- [ ] Camera follows the player smoothly and never shows area outside
      the map bounds.
- [ ] Walking into the Town doorway transitions to Cinderfall Woods;
      walking into the Cinderfall Woods doorway transitions back to
      Town, each time placing the player at the correct spawn point.
- [ ] The Cinderfall Woods branch alcove is visibly reachable and reads
      as a distinct side path, not part of the main corridor.
- [ ] No visible tile seams, gaps, or z-fighting in the placeholder
      tilemap.

## Exit criteria for Phase 0 (Foundation)

- [ ] Project opens in Godot 4.3 editor with no import errors.
- [ ] `godot4 --headless --check-only` reports no script parse errors.
- [ ] Launching the project boots directly to Waymark (Town placeholder)
      with no runtime errors in the output/log.
- [ ] All five autoloads (EventBus, DataLoader, GameState, SceneManager,
      SaveLoad) are present under Project Settings -> Autoload and
      initialize without error.
- [ ] `DataLoader` can load at least one `.tres` file from each of
      `data/gates/` without error.
- [ ] No system outside `scripts/core/` performs a raw `load()` on a
      file under `data/` (spot-check via grep).
- [ ] Save/Load autoload can write and read back a placeholder save
      file under `user://` without error.

## How to run the headless checks

```
godot4 --headless --editor --quit --path .        # first run only: builds the class cache
godot4 --headless --path . --quit-after 5          # smoke run, boots to Town and exits
```

(`godot4` is a symlink to the Godot 4.3 binary set up for this sandbox;
on a real dev machine substitute the local Godot 4.x executable.)

## Known limitation

This sandbox has no display, so headless checks catch script/scene
parse errors and startup crashes only. They do **not** verify visuals,
camera framing, animation timing, or input feel. A pass here is not a
substitute for opening the project in the editor before signing off on
any visual milestone.
