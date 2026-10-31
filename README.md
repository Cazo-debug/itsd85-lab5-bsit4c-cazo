# Toot Tubes

Godot 4.7.2 **standard** build, Compatibility renderer. Phases 1 and 2: persistent saves, avatar creator, navigation and a playable solo Level 1. The sky environment revision adds suspended cliffs, clouds, floating islands, balloons and a camera intro. Campaign expansion and networking are later phases.

## Open
Import `project.godot` into Godot 4.7.2 and press F5. On Windows, a local editor can be downloaded with:

```powershell
.\tools\setup_godot.ps1
& .\.bin\Godot_v4.7.2-stable_win64.exe --editor --path .
```

## Play Level 1

Press F5, choose **Tap to start**, create/save an avatar if needed, then **Play → Play Level 1**. Watch the two-second course overview, then wait for **3, 2, 1, TOOT!**. Click/tap ahead on the water to move, collect beans to refill the three gas charges, and reach the finish before 75 seconds. Back/Escape returns to the menu. The pause button is reserved for Phase 3; audio is silent until Phase 5.

See [the Phase 2 test guide](docs/PHASE2_TESTING.md) for the manual checklist and phone installation steps.

## Tests

```powershell
.\tools\run_tests.ps1
```

Git Bash / Linux:

```bash
bash tools/setup_godot.sh
bash tools/run_tests.sh
```

Set `GODOT` to a custom executable or `GODOT_VERSION` to a compatible release. Default: 4.7.2-stable. GUT 9.6.1 is vendored; Fredoka and its OFL license are included. Tests use an isolated save file, not the player's `user://save.cfg`.

Scripted race verification, using a disposable save:

```powershell
& .\.bin\Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 --path . --script tools/verify_level_one.gd
```

For rendered desktop evidence, omit `--headless --fixed-fps 60` and append `-- --capture --measure`. Screenshots go to `docs/screenshots/`; performance numbers describe that desktop only.

See `docs/PROGRESS.md` for validation and Gate 2. `IMPLEMENTATION_PLAN.md` and `AGENTS.md` define later scope. GDD headings await the original lab PDF template.

See [the Phase 1/2 sky revision](docs/SKY_ENVIRONMENT_REVISION.md) for the reference-pack review and remaining shared-ring scope. The current phone build is `export/TootTubes-phase2-sky-debug.apk`.
