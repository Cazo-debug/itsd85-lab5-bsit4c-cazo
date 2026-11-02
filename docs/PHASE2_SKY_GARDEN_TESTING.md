# Revised Phase 2: Sky Garden testing

Updated 2026-11-02. This is the current shared-ring game; the earlier PHASE2_TESTING.md describes a retired solo prototype.

## Open the right version

From the repository folder in PowerShell:

```powershell
& .\.bin\Godot_v4.7.2-stable_win64.exe --editor --path .
```

Press **F5 -> Tap to start -> Play -> Start Sky Garden**. Create/save a rider first if prompted. The opening view must show the winding turquoise channel, deep coral cliffs and a high hairpin. The run has one shared ring, a 240-second timer, four gas slots and AIM/HOLD pads. If you see the old straight solo course or three gas charges, stop that old running game and launch the current project.

Use **Practice** in Crew Setup for untimed exploration. **Next area** advances through launch, S-bends, bridge, climb, hairpin, obstacle garden and finish. These explicit practice teleports are separate from normal runs and never save campaign results.

## Manual desktop checklist

- [ ] Configure 1, 2, 3 and 4 occupied seats; try one Local rider with three Assistants. Verify one ring, distinct profiles and the chosen leader's style.
- [ ] Try all-empty seats: Start should show a message rather than launching. Choose the active local seat with **Control this seat**.
- [ ] Aim with **WASD**, hold **Space**, release, then press again. Brief bursts and longer holds should differ; drift continues after release. Rest to refill gas; depleted gas needs release before firing again.
- [ ] Four-controller debug: seat 2 **IJKL/U**, seat 3 **TFGH/R**, seat 4 **arrows/Enter**. WASD/Space controls the selected seat; the duplicate binding for that seat is skipped. Check independent gas and opposing pushes. Hardware keyboard rollover may limit simultaneous keys.
- [ ] Follow both S-bends, the exposed narrow bridge, climb, crest, high hairpin, downhill and dip. The body must change height and tilt; the camera must show upcoming turns without following every hull spin.
- [ ] Touch bumpers, sweeper, mallet and moving spiked crossbar. They push/tip instead of instantly killing the crew. Release thrust in the current and on the descent to see drift.
- [ ] Enter an orange-rimmed hole and leave the exposed bridge edge. Watch the whole craft drop, lose water ripples, then recover together. The clock continues and old held input must be cleared. Recover also resets a stranded craft.
- [ ] Pause with thrust held, release, Resume, then press again. Try Back/Escape and switching app focus. Check no stuck jet on return.
- [ ] Cross both checkpoints in order and the finish. Check one cooperative success/timeout result, Again, saved stars/time, and no finishing-place UI.
- [ ] Complete a human-played run and record whether steering, gas pacing, clearances and the 240-second budget feel fair. Automated completion does not establish this.

## Automated checks

```powershell
.\tools\run_tests.ps1
& .\.bin\Godot_v4.7.2-stable_win64_console.exe --headless --path . --fixed-fps 60 --script tools/verify_sky_garden.gd -- --crew=1 --seed=1
& .\.bin\Godot_v4.7.2-stable_win64_console.exe --headless --path . --fixed-fps 60 --script tools/verify_sky_garden.gd -- --crew=4 --seed=2
& .\.bin\Godot_v4.7.2-stable_win64_console.exe --headless --path . --fixed-fps 60 --script tools/verify_sky_recovery.gd
& .\.bin\Godot_v4.7.2-stable_win64_console.exe --path . --script tools/verify_crew.gd
```

Git Bash: `bash tools/run_tests.sh`. The engine comes from `tools/setup_godot.ps1` or `tools/setup_godot.sh` if missing. GUT/save verification uses disposable paths. Existing migration, beans, avatar and legacy assertions are retained.

The Sky Garden driver uses only the public per-seat thrust API after spawn, real gas, rigid-body movement and normal checkpoint/finish logic. Change `--crew=1..4` and `--seed=N` (deterministic input pulse phase, not randomized obstacle motion). JSON reports go to `.bin/sky_result_CREW_SEED.json`. Compare `--fixed-fps 30` and `120` for the same seed to check render-rate independence.

`verify_sky_recovery.gd` deliberately places the ring over a hole/edge and in the mallet sweep. It is a collision/recovery fixture, not a no-teleport completion test. It explicitly resumes its simulation if the capture window loses desktop focus; ordinary focus-loss pause is covered separately by GUT and the manual checklist.

## Captures and recording

Omit `--headless`, add `-- --crew=4 --seed=2 --capture` to the Sky Garden command to write overview, S-bend, bridge, climb, hairpin, descent, obstacles, holes, finish and result PNGs to `docs/screenshots/phase2_v3_*.png`. Run recovery with `-- --capture` for hole/edge fall, checkpoint recovery and mallet contact. Keep the old `phase2_v3_before_*` baseline captures.

The delivered `export/TootTubes-phase2-sky-garden-demo.mp4` is an uninterrupted **scripted four-seat run**, not a human playtest. To recreate:

```powershell
New-Item -ItemType Directory -Force .bin/sky-record-jpg | Out-Null
& .\.bin\Godot_v4.7.2-stable_win64_console.exe --path . --fixed-fps 60 --script tools/verify_sky_garden.gd -- --crew=4 --seed=2 --record
ffmpeg -framerate 30 -i .bin/sky-record-jpg/%05d.jpg -c:v libx264 -crf 20 -pix_fmt yuv420p -movflags +faststart export/TootTubes-phase2-sky-garden-demo.mp4
```

Use an empty recording directory for a new run; stale tail frames from an earlier recording must not be included. Keep the capture window focused. Disk capture/encoding overhead is not representative gameplay performance. Ordinary rendered verifier runs report median/p95 frame time and maximum visible draw/primitive counters; headless timings are not GPU performance.

## Install and check on Android

Build: **0.4-sky-garden / code 6**, `export/TootTubes-phase2-sky-garden-debug.apk`, same package `com.itsd85.toottubes.prototype`. Install this APK over the previous compatible debug-signed build to preserve saves. Do not uninstall to work around a signature mismatch if you need those saves.

With USB debugging enabled and the phone authorized:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" install -r .\export\TootTubes-phase2-sky-garden-debug.apk
```

Alternatively copy the APK to the phone and open it. Android may request permission to install from that source.

- [ ] Verify saved profiles/progress survive the upgrade and Play opens the new course.
- [ ] At portrait 720 x 1280 reference scale, check text, safe top region, scrolling, 120 px buttons, Back button and Android Back gesture.
- [ ] Use two fingers for AIM/HOLD, change aim while holding, release outside, center aim, change apps, pause, fall and finish. No old finger may continue thrust after recovery.
- [ ] Complete a human run, retry and relaunch; check saves and camera readability.
- [ ] Profile the busiest four-rider sections, all jets, collisions and fall/recovery on real phones. Record device, resolution/quality, median/p95 frame time, draw calls/triangles and sustained heat/battery behavior.

Targets: 60 FPS on mid-range / 30 FPS low-end; under 150 visible draw calls, 60k visible triangles and 60 MB APK. Desktop counters and a signed APK do **not** satisfy phone frame pacing, touch or heat acceptance. No phone was connected during this implementation. Audio and LAN are not included in Phase 2.
