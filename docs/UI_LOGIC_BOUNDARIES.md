# UI and gameplay boundaries

Phases 3-4, 2026-11-05. Visual changes should preserve these interfaces. A new gameplay feature may require a deliberate interface change and corresponding tests.

| Responsibility | Files | Change here for |
|---|---|---|
| Theme and existing menu layout | `assets/GameTheme.tres`, `scripts/Screen.gd`, `scenes/ui/` | Fonts, colors, spacing, creator/crew presentation |
| Course/settings presentation | `scripts/ui/CampaignScreen.gd` | Course cards, lock labels, settings layout |
| Gameplay HUD | `scripts/CrewHUD.gd` | Timer, crew labels, progress, countdown/banner presentation |
| Pause/result layout | `scripts/ui/RunPanels.gd` | Panel geometry, buttons, result formatting |
| AIM/HOLD visuals and hit rectangles | `scripts/ui/CrewPadView.gd` | Pad placement, colors, drawing; style is cached once |
| Contextual tutorial copy | `scripts/CourseHints.gd` | Short control, gas, bridge, hole and whirlpool hints |
| Campaign application rules | `scripts/CampaignFlow.gd` | Launch/crew validation, results, next course, sound persistence |
| Active-run controller | `scripts/Level.gd` | Shared clock, ordered checkpoints/finish, pause/restart, input cleanup |
| Input adapter | `scripts/CrewInput.gd` | Finger ownership, camera-relative aim, keyboard bindings, input release |
| Physical movement | `scripts/SwimRing.gd`, `RingPhysicsProfile.gd`, `RiderOrbit.gd` | Thrust, gas, support, drift, rider movement and recovery |
| Course content and geometry | `LevelDefs.gd`, `CampaignCourses.gd`, `SkyGardenData.gd`, `CoursePath.gd`, `CurvedCourse.gd`, `CourseHazard.gd` | Routes, obstacles, physical support and procedural meshes |
| Storage | `autoload/GameState.gd` | ConfigFile validation, migration backup, temporary write/rename, progression/settings/profile persistence |
| LAN mode/lobby presentation | `scripts/ui/NetworkScreen.gd`, `scenes/ui/ModeSelect.tscn`, `Lobby.tscn` | IP entry, ready/slot labels, shared preview, course and connection messages |
| LAN session and transport | `autoload/Net.gd` | ENet lifecycle, ready/load barrier, host actions, owned input routing, snapshots, timeout/disconnect cleanup |
| Incoming input rules | `scripts/NetInputGate.gd` | Ownership, sequence/round, type/range/rate/gas checks and expiry |
| Guest ring presentation | `scripts/RingReplication.gd` | Detached state snapshots and position/orientation interpolation; no guest force integration |

## HUD view contract

`Level.run_snapshot()` creates a detached Dictionary. `CrewHUD.present(view)` reads it; painting or changing that dictionary cannot modify the ring or saved progression. Fields include state, course/section, time left, progress, crew names/gas/firing, practice/fall state, hint, sound/save status, result and next availability.

HUD signals carry intent: `back_requested`, `pause_requested`, `reset_requested`, `action_requested(action)`. Panel actions are `resume`, `retry`, `sound`, `menu`, `next` and `save`. `Level.handle_action` coordinates them. Only the controller/campaign service commits results; UI labels do not award stars or unlock levels.

Online snapshots add `online`, `host` and `waiting`. Online panels emit the same resume/retry/menu intents plus `lobby`; the controller maps them to host-validated session actions. Every peer displays the host's single cooperative result. Guests cannot resume, rematch or recover the host ring. Any rider can request a shared pause or leave. Restyling these screens belongs in `NetworkScreen`, `CrewHUD`, `RunPanels` and the theme; it does not require changing ENet, persistence or physics.

The retained `Level.race_time`, `LevelDefs.LEVELS`, `GameState` save APIs, shared-ring seat APIs and existing crew/avatar routes remain available. Legacy avatar/crew edit callbacks remain in `Screen.gd`; this phase does not replace that working workflow with a new framework.

## Input and layout

`CrewInput.stick_rect()` and `gas_rect()` delegate to the pad view, so drawing and hit testing share geometry. The input adapter owns finger IDs, normalized aim, keyboard ownership and release semantics. Changing pad colors/layout belongs in the view. Changing gestures or adding a new action is a behavior change and needs input regression coverage.

Disabled gameplay pads leave new UI touches available. Pause, focus loss, falling, finishing and scene exit clear held state. Restyling panels must preserve those controller calls. Keep Fredoka, 28+ px body text, 120 px buttons and the top 80 px safe area at 720 x 1280.

## Storage behavior

UI calls application services; it does not open save files. Existing version-2 data and migration backups remain compatible. Writes use the existing `.tmp` then rename path. `last_save_error` is transient, not a schema change. A winning result with a failed write shows an in-game warning and Retry saving; settings errors are also visible. Tests use disposable paths and confirm that a failed write leaves the prior file intact.

Online members/avatars live in `Net`, separately from `GameState.local_profiles` and `crew_slots`. Level reads this temporary crew without assigning it to storage. Online mode blocks campaign writes; leaving restores the previous mode and offline result. Normal save APIs and the schema remain unchanged. Tests compare the disposable offline save byte for byte before and after connected runs, results and disconnects.

## Regression commands

Phase 5 keeps preference validation/persistence and quality application in `SettingsFlow.gd`; `SettingsScreen.gd` only presents controls and save status. `RunFeedback.gd` observes actual run/seat state to request sounds, vibration and presentation preferences. `Audio.gd` owns voice envelopes, mixer playback, focus and sound preferences. These modules do not integrate forces, move hazards or award progression. `TitleScreen.gd` presents the shared crew. `BuildCheck.gd` is an explicitly opted-in developer harness (`--build-check`), with isolated storage and no normal navigation action. Its packaged Windows run verifies the same UI/settings/audio contract as source.

`AndroidCheck.gd` is a separate opt-in debug probe with a private QA marker and isolated save. The native-input mode reports real controller/physics state without steering. A separately labeled solve mode uses the existing `CrewBrain` and a 3x clock. `tools/run_android_checks.py` owns native event injection, assertions, screenshots/log inspection and read-only emulator lifecycle; it rejects phone serials. These test modes have no ordinary player navigation action, and release Android builds ignore the private debug marker.

```powershell
& 'C:\Program Files\Git\bin\bash.exe' tools/run_tests.sh
& .\.bin\Godot_v4.7.2-stable_win64_console.exe --headless --path . --fixed-fps 60 --script tools/verify_campaign_flow.gd
& .\.bin\Godot_v4.7.2-stable_win64_console.exe --headless --path . --fixed-fps 60 --script tools/verify_campaign_flow.gd -- --reload --prefix=phase3_reload
```

The two flow commands intentionally run in separate processes. Complete mode leaves only its named test save; reload mode verifies it and removes it. They never write the normal player save. See [Phase 3 testing](PHASE3_TESTING.md) for the broader matrix and phone deferrals.
