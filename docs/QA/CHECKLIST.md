# QA Checklist — Phase 0 (Foundation)

Owner: Agent 9 (QA)

## Exit criteria for Phase 0

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
