# Toot Tubes

**Updated 2026-11-05: Phase 4 LAN implemented and checked on the laptop.** Five curved, elevated courses share one physical ring and 1-4 cooperating riders. Two-to-four-peer LAN adds a ready lobby, host-owned simulation, interpolated guests, shared results/rematch and safe disconnect handling. Offline campaign/profiles stay separate. Physical two-phone/four-phone, human play and airplane-mode acceptance remain deferred. [Implementation plan](IMPLEMENTATION_PLAN.md) | [Environment specification](ENVIRONMENT_SPEC.md).

Godot 4.7.2 **standard** build, GDScript, Compatibility renderer. Courses, riders and scenery use original procedural artwork. Finished audio and release polish remain Phase 5.

## Run the updated game

Open `project.godot` in Godot and press **F5**. Choose **Tap to start -> Play -> Offline crew** to configure your crew, then **Start Sky Garden**. First-time players create/save a rider first. **Courses** on Main Menu or **Choose course** in the crew options opens Level Select; finish each course to unlock the next. **Practice** beside Start uses the first course without a timer; **Next area** moves between its seven sections.

For LAN, use **Play -> Host LAN crew** in one copy and **Join LAN crew** in the others. Enter `127.0.0.1` for another copy on this laptop, or the host's displayed Wi-Fi IP from another device. Guests mark Ready and the host starts. Everyone controls their assigned rider on the same ring. Any rider can pause; the host resumes/restarts/recovers. Switching laptop windows can pause the shared run through focus-loss handling. [LAN instructions and checks](docs/PHASE4_TESTING.md).

From PowerShell in this project folder:

```powershell
& .\.bin\Godot_v4.7.2-stable_win64.exe --path .
```

If the local engine is missing, run `.\tools\setup_godot.ps1` first.

## Crew and controls

In Crew Setup, select a seat and cycle **Seat** through Empty, Assistant and Local rider. Pick an unused profile with the arrows; **Edit rider** changes that profile and **Make leader** chooses the shared ring style. Keep at least one local rider. **Control this seat** selects the phone/primary keyboard seat. Assistants now steer with the same gas and physics rules.

- Desktop: **WASD** aims and moves the selected rider around the rim; hold **Space** to fart, release to coast. Aim is relative to the camera.
- Touch: aim/move your rider with the left pad and hold the right pad with another finger. Release or drag outside HOLD to stop. Centering AIM also stops thrust.
- Independent debug seats: seat 2 **IJKL + U**, seat 3 **TFGH + R**, seat 4 **arrows + Enter**. Primary WASD controls the selected seat; its duplicate binding is skipped. Keyboard rollover can limit simultaneous physical keys.
- **Pause** opens Resume, Restart, Sound and Quit. **Recover** and **Back/Escape** remain available. A fall clears input and returns the entire crew to its checkpoint while the clock continues. Release and press again after pause/recovery. Results offer Retry, Next when allowed, and Menu.

Sky Garden introduces bends, bridge, climb, hairpin, descent/dip and six hazard types. Canyon Switchbacks, Cloud Bridges, Spiral Springs and Festival Summit add paired mallets, sliding spiked gates, crushers, boulders, whirlpools and mixed timings. Each course has two ordered safe checkpoints and its own time budget. Each rider has independent gas; resting and beans replenish it.

Existing version-2 profiles/progress are preserved. Original save migration backups remain supported. The old solo course exists only under `scenes/legacy/` for regression checks.

## Android and verification

Updated build: `export/TootTubes-phase4-lan-debug.apk` (0.6.0-lan, code 10). Earlier APKs remain separate. The export folder is intentionally ignored by Git. [Phase 4 QA and phone checklist](docs/PHASE4_TESTING.md).

```powershell
.\tools\run_tests.ps1
& 'C:\Program Files\Git\bin\bash.exe' tools/net_smoke.sh
& .\.bin\Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 --path . --script tools/verify_sky_garden.gd -- --crew=4 --seed=1
.\tools\run_campaign_checks.ps1 -IncludeAssistants
```

Git Bash/Linux: `bash tools/run_tests.sh`. Tests and verification tools use disposable save files.

See [the Phase 3 testing guide](docs/PHASE3_TESTING.md) for campaign checks, fresh-process reload, captures, profiling and deferred phone steps. [UI/gameplay boundaries](docs/UI_LOGIC_BOUNDARIES.md) identifies where visual changes belong. [Progress](docs/PROGRESS.md) separates automated/rendered results from pending human/device gates. The earlier uninterrupted **scripted** Sky Garden recording remains `export/TootTubes-phase2-water-riders-demo.mp4`.

The [water/rider revision guide](docs/PHASE2_WATER_RIDERS.md) explains the shared profiles, new behavior and focused acceptance checks. Earlier APKs and captures remain historical.
