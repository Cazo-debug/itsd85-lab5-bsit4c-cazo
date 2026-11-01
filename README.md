# Toot Tubes

**Updated 2026-11-01:** revised Phase 1 is implemented: four saved rider profiles, crew setup and one shared-ring preview. Shared-ring movement, held thrust, curved/elevated courses and new hazards are still Phase 2 work. [Implementation plan](IMPLEMENTATION_PLAN.md) · [Environment specification](ENVIRONMENT_SPEC.md).

Godot 4.7.2 **standard** build, Compatibility renderer. The old solo Level 1 remains accessible as a labeled legacy prototype. Campaign expansion and networking are later phases.

## Open
Import `project.godot` into Godot 4.7.2 and press F5. On Windows, a local editor can be downloaded with:

```powershell
.\tools\setup_godot.ps1
& .\.bin\Godot_v4.7.2-stable_win64.exe --editor --path .
```

## Preview your crew

Press F5, choose **Tap to start**, create/save your first rider, then **Play**. Select a seat and scroll its options. Tap **Seat** to cycle Empty → Assistant → Local rider → Empty; use the arrows to select an unused profile. **Edit rider** customizes that profile; **Make leader** chooses whose ring style the crew uses. Up to four riders appear on the same ring. Assistants are preview assignments until Phase 2 adds movement.

Existing saves migrate automatically on the next save. The original is preserved beside it as `save.cfg.pre-v2.bak`; unlocks, best times/stars, settings and the original avatar remain. See [the Phase 1 test guide](docs/PHASE1_CREW_TESTING.md).

Run directly from PowerShell in this folder:

```powershell
& .\.bin\Godot_v4.7.2-stable_win64.exe --path .
```

## Play the legacy Level 1

Choose **Play → Modes / legacy prototype → Play legacy Level 1**. Watch the two-second course overview, then wait for **3, 2, 1, TOOT!**. Click/tap ahead on the water to move, collect beans to refill the three gas charges, and reach the finish before 75 seconds. This older course uses profile 1 and the original solo controls. Back/Escape returns to the menu. The pause button is reserved for Phase 3; audio is silent until Phase 5.

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

See `docs/PROGRESS.md` for validation and the revised Gate 1. `IMPLEMENTATION_PLAN.md` and `AGENTS.md` define later scope. GDD headings await the original lab PDF template.

See [the historical sky revision](docs/SKY_ENVIRONMENT_REVISION.md) for the reference-pack review. The crew preview phone build is `export/TootTubes-phase1-crew-debug.apk`; physical-phone acceptance remains pending.

The six circular orange areas are open holes: falling blocks steering for 0.9 seconds, then respawns you three metres past your last checkpoint. The timer continues.
