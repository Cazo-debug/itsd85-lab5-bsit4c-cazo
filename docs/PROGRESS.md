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

---

# Phase 1/2 sky environment revision — 2026-11-01

The user requested review of `toot-tubes-codex-pack/` and an environment like
the supplied sky-course screenshot, then explicitly selected **Sky environment
first**. Reviewed both reference images, the HTML sample/formulas, and the v2
Phase 1/2/spec sections. The pack remains source material; it has not replaced
the active gameplay contract. See [the scoped review](SKY_ENVIRONMENT_REVISION.md).

Implemented a sky gradient and shared lighting; six finite water segments;
40 m striped cliffs fading into haze; green inner rims and closed bank joints;
128 cloud lobes in one MultiMesh; nine floating islands; three balloons;
bank/island umbrellas; red/white checkpoint buoys; checker strips and a full-width
yellow finish arch. Added a two-second whole-course intro and a smooth camera
glide during the three-second countdown. Phase 1 now uses the sky palette and
a floating-pool avatar preview. Existing avatar/save and solo-race behavior remain.

Validation on Godot 4.7.2 / GUT 9.6.1:

```text
Scripts                6
Tests                 23
Passing Tests         23
Asserts              468
All tests passed!
```

New checks cover confined water/shared materials, cliff depth, shallow collision
shapes, deterministic scenery, side-wall coverage near every turn, closed end
caps and camera framing. Existing impulse/bounce, avatar/save, UI, pickup and race
checks pass. Countdown assertions were extended with the new blocked-input intro;
none of the prior test coverage was removed.

Rendered verification at 720 x 1280 on Intel UHD Graphics completed the course
in 16.73–16.75 seconds, all eight pickups, both checkpoints, three saved stars,
and no boundary/speed violations. A measurement-only run reported approximately
60 FPS, peak 122 draw calls and 47,384 primitives. This uses Godot frame-delta
monitors on this desktop, not a real-phone or wall-clock benchmark. A separate
screenshot-capture run showed an 85 ms maximum frame while capture tooling was
active; the measurement-only run reported 16.666 ms. Screenshots preserve the
earlier baseline and use `phase1_sky_*` / `phase2_sky_*`; avatar options were cycled
and the preview/overview/play/finish images visually inspected.

Signed debug export: `export/TootTubes-phase2-sky-debug.apk`, 57,756,615 bytes
(57.8 MB decimal), version `0.2-sky` / code 3, existing prototype package,
ARMv7 + ARM64. APK signature verification passed (v2/v3). Archive check confirms
Level 1 is included and reference-pack/docs/tests/tools/addons/keystores are not.
The export and signing identity remain outside Git. No physical-phone install
or FPS test was performed.

Decisions: adopt the reference environment while retaining the existing Level 1
route. Use ascending shader smoothstep edges to avoid undefined reversed-edge
behavior. Hole cut-outs are deferred with hole physics, rather than drawing
holes that the float cannot fall through. Shared-ring physics, buddy, duo, second
avatar and the v2 gameplay migration remain pending. Phase 3 has not started.

## Revision gate

- [x] 23 automated tests / 468 assertions pass using `tools/run_tests.sh`.
- [x] Rendered race and avatar-preview checks pass; debug APK exported/verified.
- [ ] User checks avatar options, save and Back in the revised preview.
- [ ] User plays Level 1: sky height, camera glide, collision and steering feel.
- [ ] User installs the new APK and checks portrait, touch and smoothness on phone.
- [x] Commit: `Phase 2: sky environment revision for Phases 1 and 2`.

Environment revision complete. Full v2 Phase 2 and human/device gates remain pending.

---

# Circular-hole correction — 2026-11-01

User clarified that the circular orange areas are holes where the float falls,
not solid islands. Replaced all six existing Level 1 island positions with holes;
the surrounding orange banks remain solid. This clarification authorizes the
hole behavior previously deferred by the environment-only scope. It does not
start shared rings, duo, rivals or Phase 3.

Each hole has a white foam rim, an orange open shaft (no top/bottom cap), a water
shader cut-out, and no solid collider. One shader material is shared within each
course; its hole uniforms cannot contaminate the avatar preview or another level.
Center distance under radius minus 0.2 triggers a 0.9-second shrinking drop.
Steering, pickups and finish are blocked during the fall. Respawn is three metres
past the saved checkpoint, with zero velocity and restored controls. The clock
continues; timeout cancels the fall and cannot restore input after the race ends.
Before reaching a checkpoint, respawn uses the starting position plus three metres.

Validation: `tools/run_tests.sh` passed **26 tests / 523 assertions** across seven
scripts, including the new hole tests and all previous checks. Tests cover all
six cut-outs/open shafts, safe edge versus falling center, repeated-trigger guard,
blocked steering, actual visual descent, checkpoint respawn and timeout during a
fall. The full headless race still finishes in 16.73 seconds with all eight beans,
both checkpoints and three stars.

`tools/verify_holes.gd` passed with the real rendered race: teleport into the first
opening, detect the fall through the normal race loop, reject input, observe the
drop, respawn and verify that the timer continued. Visually reviewed screenshots
are `docs/screenshots/phase2_holes_course.png`, `phase2_holes_fall.png` and
`phase2_holes_respawn.png`; earlier sky screenshots remain as historical evidence.

Updated debug build: `export/TootTubes-phase2-holes-debug.apk`, version `0.2-holes`
/ code 4, 57,761,075 bytes. Signature verification passed (v2/v3); archive checks
confirmed the remapped Hole scene and reference/test/tool/secret exclusions.
Physical phone behavior remains a manual check. Existing user changes
to `project.godot` and the untracked reference pack are preserved outside this commit.

## Correction gate

- [x] Tests, full scripted race and rendered hole/respawn check pass.
- [ ] Drift into an opening; confirm a fall instead of a bounce.
- [ ] Reach a checkpoint, fall again, and confirm the new respawn location.
- [ ] Install the updated APK and check the same behavior on the phone.


---

# Phase 1/2 plan revision v3 - 2026-11-01

User requested edits to Phase 1 and Phase 2 after confirming a new direction:
one shared ring with up to four cooperating riders, repeated directional thrust,
curves, narrow passages, uphill/downhill/dips and varied physical obstacles.
This turn edits documentation only. No gameplay scripts, scenes, export settings,
APKs or saves were changed; no implementation phase gate is newly completed.

Updated root IMPLEMENTATION_PLAN.md, new root ENVIRONMENT_SPEC.md, both pack
mirrors, root/pack AGENTS guidance, GDD and README status. Historical plans/spec
are preserved under docs/archive/ with explicit non-executable status. The old
sky revision record is marked historical. Later-phase carry-forward requirements
now use cooperative campaign results and two-to-four-phone ownership of one ring;
no competitor ring, opponent bot or 2-versus-2 extension remains an active task.

Phase 1 now specifies safe legacy-save migration, four independent profiles/slots,
separate rider and shared-ring models, crew preview and compatibility/navigation
checks. Phase 2 specifies continuous aim/hold/release, per-seat gas and forces,
unlocked rotation/vertical motion, real 3D path geometry, route-based progress,
local surface support, camera adaptation and shared checkpoint recovery. It must
prove all four local controllers before Phase 4 proves four real phones.

Mandatory Phase 2 geometry fixture: broad curve, S-bend, hairpin, narrowing,
climb, descent and dip. Playable tutorial: bumper, current, sweeper, swinging
mallet and holes; timed spiked crossbar additionally tested in the fixture.
Phase 3 expands the original course environments and the remaining obstacle
library. Held input/gas tuning are proposed adaptation rules, not claimed as
exact mechanics measured from the reference video.

Validation for this documentation change: checked canonical/pack mirror equality,
required phase/gate sections, Markdown file links, historical archive retention,
absence of active legacy racing requirements and Git whitespace. No application
tests rerun because no executable files changed; the previous 26 tests/523
assertions remain historical prototype evidence, not v3 acceptance.

Revised Phase 1 and Phase 2 status: PLANNED / NOT EXECUTED. Existing user change
to project.godot, the supplied MP4 and reference HTML/images remain preserved.
