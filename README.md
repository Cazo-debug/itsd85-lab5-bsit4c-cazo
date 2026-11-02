# Toot Tubes

**Updated 2026-11-02: revised Phase 2 is implemented.** Play now opens the curved, elevated Sky Garden with one physical ring and 1-4 cooperating riders. Human play and real-phone acceptance remain pending. [Implementation plan](IMPLEMENTATION_PLAN.md) | [Environment specification](ENVIRONMENT_SPEC.md).

Godot 4.7.2 **standard** build, GDScript, Compatibility renderer. The route, riders and scenery use original procedural artwork. Campaign expansion, LAN and finished audio remain later phases.

## Run the updated game

Open `project.godot` in Godot and press **F5**. Choose **Tap to start -> Play -> Start Sky Garden**. First-time players create a rider before Play. **Practice** beside Start uses the same route without a timer; **Next area** moves between its seven sections.

From PowerShell in this project folder:

```powershell
& .\.bin\Godot_v4.7.2-stable_win64.exe --path .
```

If the local engine is missing, run `.\tools\setup_godot.ps1` first.

## Crew and controls

In Crew Setup, select a seat and cycle **Seat** through Empty, Assistant and Local rider. Pick an unused profile with the arrows; **Edit rider** changes that profile and **Make leader** chooses the shared ring style. Keep at least one local rider. **Control this seat** selects the phone/primary keyboard seat. Assistants now steer with the same gas and physics rules.

- Desktop: **WASD** aims the selected seat; hold **Space** to fart, release to coast. Aim is relative to the camera.
- Touch: aim with the left pad and hold the right pad with another finger. Release or drag outside HOLD to stop. Centering AIM also stops thrust.
- Independent debug seats: seat 2 **IJKL + U**, seat 3 **TFGH + R**, seat 4 **arrows + Enter**. Primary WASD controls the selected seat; its duplicate binding is skipped. Keyboard rollover can limit simultaneous physical keys.
- **Pause/Resume**, **Recover** and **Back/Escape** work. A fall clears input and returns the entire crew to its checkpoint while the clock continues. Release and press again after pause/recovery.

Sky Garden has S-bends, a narrow exposed bridge, a climb, a high hairpin, descent/dip, bumpers, current, sweeper, mallet, moving spiked crossbar and two open holes. Reach both checkpoints and cross the finish within 240 seconds. Each rider has independent gas; resting and beans replenish it.

Existing version-2 profiles/progress are preserved. Original save migration backups remain supported. The old solo course exists only under `scenes/legacy/` for regression checks.

## Android and verification

Updated build: `export/TootTubes-phase2-sky-garden-debug.apk` (0.4-sky-garden, code 6). Install this build instead of the Phase 1 preview APK. The export folder is intentionally ignored by Git.

```powershell
.\tools\run_tests.ps1
& .\.bin\Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 --path . --script tools/verify_sky_garden.gd -- --crew=4 --seed=1
```

Git Bash/Linux: `bash tools/run_tests.sh`. Tests and verification tools use disposable save files.

See [the current Phase 2 testing guide](docs/PHASE2_SKY_GARDEN_TESTING.md) for phone steps, four-controller checks, captures and performance limits. [Progress](docs/PROGRESS.md) separates automated/rendered results from pending human/device gates. The uninterrupted **scripted** gameplay recording is `export/TootTubes-phase2-sky-garden-demo.mp4`.
