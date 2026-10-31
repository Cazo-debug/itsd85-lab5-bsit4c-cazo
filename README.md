# Toot Tubes

Godot 4.7.2 **standard** build, Compatibility renderer. Phase 1 only: persistent saves, primitive-mesh avatar creator, theme and navigation. No racing or networking yet.

## Open
Import `project.godot` into Godot 4.7.2 and press F5. On Windows, a local editor can be downloaded with:

```powershell
.\tools\setup_godot.ps1
& .\.bin\Godot_v4.7.2-stable_win64.exe --editor --path .
```

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

See `docs/PROGRESS.md` for validation and the Phase 1 gate. `IMPLEMENTATION_PLAN.md` and `AGENTS.md` define later scope. GDD headings await the original lab PDF template.
