# Phase 3: offline campaign testing

2026-11-05. Laptop validation is authorized; physical-phone and airplane-mode acceptance are deferred. Phase 4 networking is not implemented. Current debug APK: `export/TootTubes-phase3-campaign-debug.apk`, **0.5.0-campaign / code 9**.

## Play on the laptop

Open `project.godot` and press F5, or:

```powershell
& .\.bin\Godot_v4.7.2-stable_win64.exe --path .
```

Create/save a rider if prompted. **Play** opens crew setup; configure one Local rider plus optional Assistants. **Start Sky Garden** keeps the familiar first-course entry. **Choose course** is in the crew options scroll area; **Courses** on Main Menu opens the same Level Select directly. Start with at least one local rider. Locked cards explain the previous-course requirement.

| Course | Time budget | Route and hazard focus |
|---|---:|---|
| Sky Garden | 240 s | S-bends, bridge, crest, hairpin, six introductory hazard types |
| Canyon Switchbacks | 260 s | Alternating widths, coral switchbacks, paired mallets, sliding spiked gate and moving boulders |
| Cloud Bridges | 270 s | Narrow exposed crossings, staggered heights, crossbars, crushers and waiting pools |
| Spiral Springs | 290 s | Climbing/descending turns, cross-currents, two whirlpools, sweepers and a gate |
| Festival Summit | 300 s | Mixed climbs, narrow final bridge and combined hazard timings |

Movement, rider orbit, gas and water waves use the same profiles in all five. Whirlpools apply bounded swirl/pull; only separately authored holes/exposed edges remove support. Ordinary spiked bars, gates, crushers and boulders contact/push/tip rather than resetting on mesh appearance. Every moving hazard samples the shared run clock.

Desktop: WASD aims, Space holds thrust. Touch-compatible AIM/HOLD controls remain. Release to coast/refill. Pause opens Resume, Restart, Sound and Quit; results offer Retry, Next when allowed, and Menu. The final result reports campaign completion without creating a sixth course. Back/Escape returns to crew setup. Practice is untimed and does not save campaign wins.

## Repeat automated acceptance

```powershell
& 'C:\Program Files\Git\bin\bash.exe' tools/run_tests.sh
.\tools\run_campaign_checks.ps1 -IncludeAssistants
& .\.bin\Godot_v4.7.2-stable_win64_console.exe --headless --path . --fixed-fps 60 --script tools/verify_campaign_flow.gd
& .\.bin\Godot_v4.7.2-stable_win64_console.exe --headless --path . --fixed-fps 60 --script tools/verify_campaign_flow.gd -- --reload --prefix=phase3_reload
```

Matrix defaults: all five courses, 1/2/3/4 riders, seeds 1 and 3, plus four occupied seats with one driver and three production Assistants at seed 7 when `-IncludeAssistants` is supplied. The same legal-input driver uses normal gas/thrust and actual contacts after spawn, without moving transforms. Seed varies the input pulse phase; obstacle motion is deterministic. Results and per-case logs remain under ignored `.bin/phase3-validation/`.

Completed laptop acceptance: **70 GUT tests / 7,425 assertions / 16 suites**, **45/45 matrix runs**, **102 UI-campaign checks** and **12 fresh-process reload checks**. Every matrix case finished without recovery. Expected missing-storage warnings in the failed-write test are intentional and checked. No existing test/assertion was removed or weakened.

Seed 1 timing examples, simulated race seconds:

| Course | One rider | Four riders |
|---|---:|---:|
| Sky Garden | 131.72 | 111.00 |
| Canyon Switchbacks | 152.55 | 126.32 |
| Cloud Bridges | 142.20 | 116.13 |
| Spiral Springs | 161.30 | 132.23 |
| Festival Summit | 155.22 | 125.67 |

The campaign verifier uses real menu input, a local-seat driver plus production Assistants and ordered finishes through all five courses. It separately shortens one run's limit to 0.1 s to test timeout/Retry; that fixture is not a normal completion. It tests locks, pause clock/input cleanup, sound save, actual scene restart, cooperative results, Next, final-course boundary and Menu. The second command starts a fresh engine process and reloads crew, sound, best times/stars and unlocked courses from its disposable save.

## Rendered evidence and profiling

```powershell
& .\.bin\Godot_v4.7.2-stable_win64_console.exe --path . --fixed-fps 60 --script tools/verify_campaign_flow.gd -- --previews --capture --prefix=phase3_review
& .\.bin\Godot_v4.7.2-stable_win64_console.exe --path . --fixed-fps 60 --script tools/verify_sky_garden.gd -- --level=4 --crew=4 --seed=4 --resume-on-focus --result-capture --capture-prefix=phase3_spiral_review
```

Preview mode deliberately places the hull for course overview, play, pause and failure-result captures. It is **not** legal-input completion evidence. Delivered captures use `phase3_preview_*`; current placed samples are below 150 calls / 60k primitives. Full-run desktop timing and draw counters are recorded in [PROGRESS.md](PROGRESS.md). Timing excludes intro/countdown, pause and finished-state screenshot writes. `--resume-on-focus` is an explicit automation override, not ordinary focus behavior; ordinary focus-loss pause remains tested.

The `--result-capture` option captures only after the run ends, preserving normal race timing. `--capture` adds course screenshots and should be excluded from normal pacing measurements. Run timings with other game checks/exports stopped. Headless frame times are not graphics performance; desktop counters do not establish phone FPS or heat.

Final four-rider desktop samples: Spiral Springs **16.661 ms median / 18.346 ms p95**, **71 calls / 58,128 primitives**; Festival Summit **16.673 / 17.763 ms**, **74 / 57,225**. Both completed without recovery. Distant cloud detail was reduced to meet budget; route geometry/collision/physics stayed unchanged. Rendered verification now fails if real frame samples are absent or budgets are exceeded.

## Phone handoff and deferred acceptance

The APK is signed for development, same package as earlier debug builds, ARMv7 + ARM64, minimum API 24, internet/network-state permissions disabled. Test tooling, documentation, reference video/pack, credentials and exports are excluded from the game package. Do not use the old Phase 2 APK to check Phase 3.

Size **57,885,832 bytes**; v2/v3 signatures verified. SHA-256: `7FF90EBC44E3D8D584A84EF77B30F02EDB1D2FF1F1F83422175EBD7EC4D4603E`.

```powershell
adb devices -l
adb -s DEVICE_SERIAL install -r export/TootTubes-phase3-campaign-debug.apk
```

Do not uninstall/clear game data to bypass a signature mismatch when saved profiles/progress matter. Keep keys and APKs outside Git.

- [ ] Human play: steering, gas, timing, camera and course difficulty across the campaign.
- [ ] Physical device install/upgrade, saved crew, portrait layout, two-finger release, Android Back and Home/resume.
- [ ] Airplane-mode complete/retry/relaunch with preserved stars, times, settings and profiles.
- [ ] Sustained four-rider performance and heat on real phones.

Offline code has no service dependency: Net remains idle, no HTTP client or connection is started by these flows, and export network permissions remain disabled. This is source/build evidence and local execution, not a physical airplane-mode test. Sound preferences work; actual sound assets/music remain Phase 5. Human/device checks are deferred per the user's laptop-first direction.

For visual refactors, use [UI and gameplay boundaries](UI_LOGIC_BOUNDARIES.md); keep the controller/view interfaces and input lifecycle intact.
