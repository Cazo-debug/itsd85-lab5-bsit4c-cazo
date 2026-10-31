# Phase 1 progress — 2026-10-31

Phase 1 implemented and committed as `73840e8`. This section records Phase 1 evidence; the current Phase 2 status appears below.

## Delivered

- Godot 4.7.2 standard project, Compatibility, 720 × 1280 portrait, mouse-to-touch, 60 Hz physics, manual Android Back handling.
- ConfigFile progress, bounded level unlocks, best stars/times, avatar/settings/tutorial persistence, reset and star thresholds. Online completion cannot alter offline progress.
- Defensive avatar sanitization, seeded randomization API, six skin tones, eight outfits, four floats, five hats and four toot colors.
- Original low-poly primitive rider/float/hat model with shared materials and no shadows. Colored primitive puff previews show the toot selection.
- Rotating 3D avatar creator on a water disc; scrollable controls keep 120 px touch sizes, 28+ px text and the top 80 px clear. Name input, option wraparound, Randomize, Save and Back.
- Title, Main Menu, Avatar Creator, Mode Select, Settings and Credits navigation. Mode Select/Settings remain Phase 1 placeholders. Title Back exits; other screens return appropriately. Android Back and desktop Escape share navigation.
- Shared Fredoka theme and included OFL license; GUT 9.6.1 committed with upstream license.
- Bash setup/test runners and native PowerShell equivalents. Local editor downloads live in ignored `.bin/`.
- GDD, credits, README and rendered screenshots under `docs/screenshots/`.

## Validation

Run on Windows with Godot 4.7.2 standard and GUT 9.6.1:

```text
bash tools/run_tests.sh
Scripts               3
Tests                11
Passing Tests        11
Asserts             239
All tests passed!
```

The native PowerShell runner also passed the same 11 tests / 239 assertions. Coverage: progression bounds/replays, best results, save/reload/reset, star boundaries, offline protection, invalid avatar payloads, randomization, every model option, first-use/returning navigation, Back requests, creator controls/save, and recursive loading/instantiation/freeing of all seven Phase 1 scenes. Save tests use disposable paths and preserve the player's normal save.

Rendered Compatibility checks on Intel UHD Graphics: Title, Avatar Creator and Main Menu captured at 720 × 1280; every avatar option cycled without runtime errors. Screenshots visually inspected. This is desktop evidence, not Android/touch/device-performance acceptance. Automated navigation routes were checked; the manual F5 and close/reopen gate remains for the user.

## Decisions and limitations

- The plan defaults its bootstrap to 4.7-stable; the currently available 4.7.2-stable patch was pinned consistently instead. `GODOT_VERSION` remains configurable.
- Added PowerShell runners because Bash is not on this Windows PATH; the required `.sh` runner was run using Git Bash.
- Downloaded Fredoka from its official Google Fonts repository rather than leaving the project on a fallback font.
- Creator controls scroll to fit their required touch sizes beneath the preview. Its toot color is represented by primitive puff meshes; gameplay particles belong to Phase 2.
- The lab PDF/11-heading template is unavailable in the supplied materials. `GDD.md` has 11 explicitly provisional headings; exact heading alignment awaits that source.
- Audio and Net are intentional stubs. No racing, networking, APK, phone validation or publication was attempted in Phase 1.
- Reset clears campaign progress/tutorial state and preserves avatar/settings.

## Gate 1 — user checks

- [x] `tools/run_tests.sh` passes; result shown above.
- [ ] Press F5 in Godot: Title → Avatar Creator → Main Menu. Window is portrait.
- [ ] Change every avatar option and confirm the preview updates. Check Randomize. Save, close Godot and run again: the avatar persists.
- [x] Commit with `Phase 1: foundation, save system, avatar creator`.

The user subsequently requested “Continue”; Phase 2 was implemented on that instruction. No manual Gate 1 acceptance was reported in chat, so its user checkboxes remain open.

---

# Phase 2 progress — 2026-10-31

Phase 2 implemented. Stopped at Gate 2; Phase 3 has not started.

## Delivered

- Main Menu → Play → Play Level 1 opens the solo tutorial. Countdown blocks input; GO starts the shared `race_time`. Finish/time-out writes `last_result` and returns to Mode Select after a brief message; wins use the existing progress/star contract. Full Result UI remains Phase 3.
- `LevelDefs.LEVELS` contains only Level 1: 140 m, 75 seconds, offset channel segments, six islands, eight beans, two checkpoints and a finish ring. Side-bank connectors and end caps enclose the course.
- `LevelBuilder` builds the course from data; reusable water/bank/island/bean/checkpoint/finish scenes use primitive meshes, shared StandardMaterial3D resources and MultiMesh checkered tiles.
- Simple texture-free water waves, ambient lighting, no real-time shadows, blob shadow, colored one-shot CPU puffs and expanding white CPU ripple trails.
- RigidBody3D floats locked to the water plane, water drag, bounce, three charges, one refill per 1.5 seconds, pickup refill and 14 m/s solver speed cap. Visual bob/turn/tilt and impulse squash. SFX calls use the silent Phase 1 Audio stub; an optional pitch argument preserves existing calls.
- Unhandled ScreenTouch → camera ray → water plane. Mouse-to-touch emulation handles desktop clicks once; HUD controls consume taps. Smooth render-frame camera follows interpolated body motion with small collision shake.
- HUD: goal appears centrally for the first three racing seconds, then course name at top; timer turns red below 10 seconds; three bean-shaped charge icons; racer progress dot; disabled Phase 3 pause control; working Back/Android Back/Escape. First-toot hint is saved as seen.
- Signed debug APK and export preset for ARMv7/ARM64. SDK/JDK 17 paths configured locally; keystore remains outside Git. No new assets beyond original procedural artwork.

## Validation

`tools/run_tests.sh` on Godot 4.7.2 / GUT 9.6.1:

```text
Scripts               5
Tests                19
Passing Tests        19
Asserts             335
All tests passed!
```

Includes all Phase 1 tests, real solver impulse/speed/height/bank-bounce checks, refill timing, invalid/countdown taps, course construction, pickup cooldown, race countdown/timeout rules and recursive smoke checks for all 16 scenes. No tests were weakened or removed.

`tools/verify_level_one.gd` runs the complete real course with a scripted waypoint driver, using a disposable save. Headless and rendered runs passed: actual countdown touch rejected, disabled HUD touch consumed, one mouse click spends exactly one charge, all eight bean sensors collect, both checkpoints register, no bank escape or speed-cap violation, and a 3-star finish is saved. Typical finish time ~16.7 racing seconds. This proves a scripted route works; human game feel is still a manual gate.

Rendered desktop run at 720 × 1280 on Intel UHD Graphics: approximately 60 FPS average after warm-up, peak 67 draw calls and 15,776 primitives. These are desktop sample measurements, not phone performance guarantees. Countdown/race/finish screenshots were visually reviewed under `docs/screenshots/phase2_*.png`; the initial gas-row wrapping issue was corrected.

Android debug export succeeded: `export/TootTubes-phase2-debug.apk`, 57,743,865 bytes (~57.7 MB decimal), ARMv7 + ARM64, Android 7/API 24 minimum. APK signature verification passed; package `com.itsd85.toottubes.prototype`, version `0.2-phase2`. Archive check found Level 1 and no bundled test/addon/tool/docs directories or keystore files. APKs, signatures, templates and editor downloads remain ignored. No physical phone install or playtest was performed.

## Decisions and remaining limitations

- Preserved Godot's existing editor formatting in `project.godot`; added named collision layers, physics interpolation and Android texture-import support.
- Fixed an impulse integration issue found by physics tests: do not overwrite cached velocity immediately after applying a pending impulse; cap it in `_integrate_forces` instead.
- SFX generation/music, full pause/results, additional courses, bots, spike respawn and moving obstacles are later work. The slow current strip is explicitly deferrable in Phase 2 and remains Phase 3.
- Added minimal Level 1 entry in Mode Select so the new race can be played through F5. Offline/Online selection and Level Select remain Phase 3/4.
- Debug template comes from the official Godot 4.7.2 export-template archive. The preset uses local `.bin/templates/android_debug.apk`; other machines can install the matching templates in Godot and clear the custom-template field.
- The debug APK uses Godot's generated development signing identity, never a release key. Final package/team identity, icon and signed release belong to Phase 5.
- The original lab PDF is still unavailable; exact GDD heading alignment remains open.

## Gate 2 — user checks

- [x] Automated tests pass; results shown above.
- [ ] Play Level 1 on the computer (click = tap). Check punchy movement, water drag, smooth camera and goal text.
- [ ] Bump banks and islands; confirm bouncing and no escape from the course.
- [ ] Check puffs, ripple rings and bean pickup; observe 60 FPS in Godot's profiler.
- [ ] Install the debug APK on a real phone; confirm portrait orientation, touch and smoothness.
- [x] Commit with `Phase 2: 3D race core and Level 1`.

Stop here until the user checks Gate 2 and requests Phase 3.
