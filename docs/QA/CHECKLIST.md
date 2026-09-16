# QA Checklist — Project Red Gate

Owner: Agent 9 (QA)

## Exit criteria for Phase 6 (Boss + Polish) — manual, needs a display

Not yet run against this build.

- [ ] Fighting any common enemy (Ember Wisp/Bramble Husk), its first
      turn is a basic attack, its second turn uses its skill, and it
      keeps alternating — it no longer uses the same skill every turn.
- [ ] Fighting the Ashen Warden down to roughly half HP triggers "The
      Ashen Warden's flames roar higher!" exactly once, and every one
      of its attacks afterward is Cinderquake (not Ashfall, not a
      basic attack) for the rest of the fight.
- [ ] Every hit (player's or the enemy's) produces a visible screen
      tint flash and a brief screen shake; the shake never leaves
      command buttons visibly misaligned or unclickable afterward.
- [ ] A hit, a victory, a defeat, and a fled battle each play a
      distinct short sound (even if simple/synthesized, not silence).
- [ ] Sound doesn't stutter or cut off oddly when two hits land in
      quick succession (e.g. a skill that also triggers a family-bonus
      recalculation).
- [ ] Walking through Cinderfall Woods, a generated dungeon, and the
      Red Gate all look visibly dimmer than Waymark, with a soft light
      following the player as they move; Waymark itself stays fully
      bright with no light attached to the player there.
- [ ] The lighting doesn't obscure obstacle tiles, encounter markers,
      or doorways to the point they're unreadable.
- [ ] No script errors appear in the console across a full loop:
      fight several common enemies (confirm attack/skill alternation),
      fight the Ashen Warden to its enrage point and past it, and walk
      through at least one generated dungeon and Cinderfall Woods to
      confirm the ambience renders in both.

## Exit criteria for the systems-depth pass (post-Phase-5) — manual, needs a display

Not yet run against this build.

- [ ] Fighting an enemy with 0 Defense hits noticeably harder than the
      same attack against a Defense-heavy enemy, but even the toughest
      current enemy always takes at least 1 damage from a hit (never a
      "0 damage" or "immune" result).
- [ ] Against the Ashen Warden (speed 6), an unequipped level-1 player
      sees the enemy act *first* with an opening message before any
      command menu is enabled; a fast-enough/high-Speed loadout instead
      lets the player act first.
- [ ] Fighting the Ashen Warden undefended (no armor equipped) as a
      fresh level-1 character is lethal from its opening attack — this
      is the intended, documented balance finding (GAME_DESIGN.md
      Section 9), not a bug; confirm the defeat flow (message, return
      to Waymark, HP/MP restored) still works correctly when it happens.
- [ ] Equipping the Cinderfall Cleaver adds **Cleave** to the Skill
      submenu; unequipping it removes Cleave from the menu again.
- [ ] Equipping Cindermourn adds **Ashbrand** to the Skill submenu (in
      addition to Cleave staying available only while the Cleaver is
      equipped — the two movesets don't stack or leak into each other).
- [ ] The 3 universal skills (Ember Slash, Guard Break, Second Wind)
      remain available regardless of which weapon is equipped, or none.
- [ ] In the Inventory screen, each item row shows "req. LvN"; the
      Equip button is visibly disabled for any item above the player's
      current level.
- [ ] Attempting to equip a level-gated item anyway (if reachable, e.g.
      via a stale button state) shows "Requires level N (you are M)."
      and does not change equipped gear or consume the item.
- [ ] Leveling up past an item's requirement makes its Equip button
      become enabled without needing to reopen the Inventory screen
      from scratch (or at minimum after a close/reopen).
- [ ] No script errors appear in the console across a full loop:
      open Inventory, attempt a blocked equip, level up, equip the
      Cleaver, fight (confirm Cleave is usable), switch to Cindermourn,
      fight the Ashen Warden (confirm Ashbrand is usable and initiative
      resolves correctly either direction).

## Exit criteria for Phase 5 (Gates) — manual, needs a display

Not yet run against this build.

- [ ] Walking into the Gate cluster in Waymark opens `GateUI` and
      pauses player movement; Close resumes movement without leaving Town.
- [ ] All 3 dropdowns list exactly the 4 words from their category
      (Origin/Tone/Sign), with a "— choose —" placeholder.
- [ ] Trying Open Gate with fewer than 3 words chosen shows "Choose all
      three words first" and does nothing else.
- [ ] `Hollow + Undying + Ember` shows the Red Gate flavor text and
      transitions to a distinctly red/black-tiled map.
- [ ] `Cinder + Broken + Ember` transitions to the existing Cinderfall
      Woods (unchanged from Phase 1-4).
- [ ] Any other well-formed combination (e.g. `Verdant + Forgotten + Tide`)
      transitions to a generated dungeon whose floor tiles match the
      Origin word's theme and whose title bar names the level correctly.
- [ ] Trying the same generated combination twice in a row (or leaving
      and re-entering via a fight) produces the *same* dungeon each
      time — not a different random layout.
- [ ] A higher-Tone-word dungeon (e.g. `Undying`) visibly has tougher
      enemies (more HP, hits harder) than a `Silent` one.
- [ ] A higher-Sign-word dungeon (`Umbra`) has visibly more branches
      than a lower one (`Ember`).
- [ ] Fighting in a generated dungeon and winning/losing/fleeing
      correctly returns to that same generated dungeon (not Town, not
      a blank/frozen screen) — this exercises the bug fixed in
      PROGRESS.md's Phase 5 entry.
- [ ] The Ashen Warden fight in the Red Gate: can't be fled, and
      defeating it drops Cindermourn every time.
- [ ] Equipping Cindermourn and re-fighting the Ashen Warden (if
      possible) or another `"ashen"`-family enemy shows visibly higher
      damage than an unequipped hit would.
- [ ] Discovered clues (from defeating the Cinder Wraith) show their
      hint text in the Gate UI, not just a raw id string.
- [ ] No script errors appear in the console across opening the Gate UI,
      trying an invalid word set, entering a generated dungeon, fighting
      there, and returning.

## Exit criteria for Phase 4 (Loot) — manual, needs a display

Not yet run against this build.

- [ ] Defeating Ember Wisp or Bramble Husk sometimes (not always) drops
      an item — either the Ember Draught or the Cinderfall Cleaver —
      and the victory message names it when it does.
- [ ] Defeating the Cinder Wraith always drops the Ashcinder Guard and
      always shows the "note falls from the wreckage" message.
- [ ] Dropped items actually appear in the Inventory screen afterward.
- [ ] In the Inventory screen, each equippable item shows a comparison
      string vs. whatever's currently equipped in that slot, and it
      updates correctly after equipping/unequipping (compare against a
      *different* item now, not the original baseline).
- [ ] The comparison string reads as "(no change)" when comparing an
      equipped item against itself.
- [ ] No script errors appear in the console across several dropped
      loot rolls and inventory screen visits.

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
