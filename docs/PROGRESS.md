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

---

# Revised Phase 1 implementation - 2026-11-01

Implemented the four-rider foundation after the user's execution instruction.
Stopped at revised Gate 1. Shared-ring movement, curved/elevated courses,
continuous gas, assistant steering and new hazards remain Phase 2 work; the old
solo course is explicitly labeled as a legacy prototype in the mode screen.

| Area | Implemented now | Still pending |
|---|---|---|
| Save schema | Version 2, four independent profiles, profile-0 `avatar` alias, validated four-seat assignments and leader style | Network ownership synchronization |
| Migration | Original-byte `.pre-v2.bak` before migration write, temporary-file replacement, known progress/settings preserved | User's physical-phone upgrade review |
| Crew preview | One ring/platform assembly, four spaced anchors, independent rider meshes, 1-4 occupants, all legacy appearance choices | Physical shared-ring simulation |
| Interface | Play opens Crew Setup; seat/profile/mode selection, assistant assignments, leader selection, selected-profile editor and cancel/save/Back | Gameplay input and LAN |

Files: `GameState.gd`, new `CrewData.gd`, `RiderModel.gd/.tscn`,
`SharedRingPreview.gd`, `Screen.gd`, `CrewSetup.tscn`, two new GUT suites,
`tools/verify_crew.gd`, Android export version and project documentation. Kept
legacy `AvatarModel`, `FloatPlayer`, level contracts, theme, Audio and Net intact.

Implementation choices: initialize three editable spare profiles alongside the
original profile, leaving their seats empty. UI mode cycles Empty / Assistant /
Local; assistants are visibly described as pending movement. Runtime peer seats
are supported by validation but become empty on disk; transient peer IDs and
unknown extra slot fields are never serialized. The creator previews the edited
profile's ring style; the crew preview uses its chosen occupied leader. A failed
creator save restores its prior in-memory profiles and shows an error.

Validation: `tools/run_tests.sh` passes **34 tests / 760 assertions in 9 suites**,
including all 26 prior tests. New checks cover two migration passes with exact
backup preservation, independent profile round trips and alias edits, malformed
field types, missing schema, fifth-seat rejection, duplicate profile/owner
rejection, peer-ID removal, 1-4 preview occupants, all appearance values,
selected-profile save/cancel, seat modes, profile selection and leader persistence.
Review found and fixed missing-key defaults and typed comparisons/membership
for malformed save data. No test acceptance was weakened.

`tools/verify_crew.gd` passed actual scene transitions and button signals through
first-use creator, main menu, one/four-rider crew, selected-profile editor,
save/reload, Android Back and legacy mode entry. Its 720 x 1280 layout assertions
pass (top 80 px safe region and 120 px touch targets; scrolled content is allowed
outside its clipping area). Inspected fresh screenshots:
`docs/screenshots/phase1_crew_one.png`, `phase1_crew_four.png`,
`phase1_crew_creator.png` and `phase1_crew_modes.png`.

Rendered desktop samples: four-rider crew 112 draw calls / 16,858 primitives;
four-rider creator with gas-color preview 125 draw calls / 16,522 primitives.
These are captured-frame counters on Intel UHD Graphics, not worst-case device
FPS measurements or proof of mid-range/low-end phone targets.

Legacy regression: `tools/verify_level_one.gd` passed 1,872 checks, completed in
16.73 seconds, collected eight beans and earned three stars. Test/verifier writes
use disposable paths; no real player save was modified. New screenshots retain
the prior sky/hole evidence under their original filenames.

Android build: `export/TootTubes-phase1-crew-debug.apk`, version
`0.3-crew-foundation` / code 5, **57,782,466 bytes**. Signature verification passed
with v2/v3. Package remains `com.itsd85.toottubes.prototype`, minimum API 24.
Archive checks confirm the new crew/rider resources and exclusion of references,
video, tests, tools, docs and credentials. No physical phone was available for
touch, upgrade or performance acceptance.

Known limits: existing pause/audio/settings placeholders remain; all runtime
co-op, physics and terrain changes belong to later gates. No rival gameplay was
added. User changes to `project.godot`, the reference video and untracked pack
HTML/images remain outside the phase commit.

## Revised Gate 1

- [x] Automated migration, crew, avatar and scene checks pass.
- [ ] User F5 review: create/edit/save profiles, switch seats, preview four occupants.
- [ ] User restart review: original avatar/progress and edited profiles persist; Back works.
- [ ] Actual phone: portrait readability, scrolling, touch targets and Back behavior.
- [x] Documentation and evidence updated; commit `Phase 1: four-rider shared-ring foundation`.

Manual steps and run commands: [PHASE1_CREW_TESTING.md](PHASE1_CREW_TESTING.md).
Revised Phase 2 has not begun.

---

# Phase 2 delivery-plan revision - 2026-11-01

The user asked why the environment was unchanged after Phase 1 and then asked
to revise Phase 2. This change updates documentation only. No gameplay code,
scenes, saves, APKs or phase-completion claims were changed.

Revised the canonical plan and its pack mirror around a visible replacement of
the playable environment. Phase 2 now explicitly starts from the completed
four-profile foundation and delivers seven connected Sky Garden sections:
launch pool, S-bends, narrow curved bridge, uphill/crest, hairpin/descent/dip,
obstacle garden and shared finish. The main course must contain the route
variety; a geometry fixture or updated preview alone cannot satisfy acceptance.
The hairpin must turn at least 150 degrees and the climb must gain at least one
physical ring diameter, with clearances/slopes kept within the existing spec.

Promoted the timed spiked crossbar from fixture-only to playable Level 1 alongside
bumper, current, sweeper, mallet and holes. Minimum counts are two bumpers, two
holes and one of each other type, with fair openings and two safe checkpoints.
Holes are actual unsupported openings and whole-crew falls, never orange caps
or blocking walls. Recoverable push/tip contacts remain distinct from falls.

Added explicit menu cutover: Play -> Crew Setup -> Start Sky Garden, plus an
accessible untimed Practice route, saved-crew integration, empty-crew feedback
and local-seat selection. Internal milestones do not create new approval gates;
future authorized execution must continue through playable integration. Main
Play may not remain routed to the legacy solo course at completion.

Added before/after portrait captures, uninterrupted gameplay recording, route
shape assertions against production data, menu-to-game verification and busy
four-rider performance evidence. Desktop versus phone checks stay separate.
The existing environment spec and GDD now agree with these requirements.

Validation: canonical/pack mirror equality, Phase 2 boundary/gate checks,
crossbar scope consistency and Git whitespace checks. No application tests
rerun: executable files are unchanged. The prior 34 tests / 760 assertions
remain Phase 1 evidence only. All Phase 2 gates remain unchecked.


---

# Revised Phase 2 implementation - 2026-11-02

Implemented the user's authorized Phase 2. Main Menu -> Play -> Crew Setup ->
Start Sky Garden now launches the new shared-ring environment, not the old solo
course. Practice is beside Start and uses the same connected geometry without
a time limit, with explicit section reset points. No Phase 3/4/5 execution.

## Delivered behavior

- One physical `SwimRing` with 1-4 saved riders, leader style, full vertical/yaw/
  pitch/roll motion, damped four-point water support, gravity, drift and per-seat
  off-centre forces. `RingPhysicsProfile` contains the tuning constants.
- Camera-relative held thrust, independent gas, release/rearm after depletion,
  pooled jets opposite the actual push, surface ripples and start/stop feedback
  signals for later attack/loop/release audio. Four keyboard bindings and
  cooperative assistants use the same validated `set_thrust_input` contract.
- Separate touch IDs, aim deadzone, outside release, focus/pause/Back/fall/finish
  cleanup. Fixed the centered-aim stale-thrust edge case during validation.
- Original 532.70 m Sky Garden: cloud launch, S-bends, curved narrow bridge,
  climb/crest, >=150-degree hairpin, descent/dip, obstacle garden and finish.
  The 4.8 m hull passes the 7.2 m minimum channel with 1.2 m clearance per side.
  Physical runs gain over 11 m between their low/high points; slopes stay below
  15 degrees. Path tangents, widths, projection and ribbon boundary crossings
  are tested against production geometry.
- Generated ribbon water, green rims, deep coral striped cliffs, clouds/islets
  and simplified matching bank collision use the same sampled route frames.
  Orange-rimmed openings have open shafts and no surface support. The right
  bridge edge is intentionally exposed.
- Six hazard types: two bumpers, local current, rotating sweeper, swinging
  mallet, timed spiked crossbar and two holes. Motion uses `Level.race_time`.
  Ordinary solids push/tip; holes and exposed edges cause whole-crew falls.
- Two ordered checkpoints, a whole-ring finish threshold, group beans, timed
  cooperative result, pause/retry/recover and existing best-time/star saving.
  Timeout disables pending recovery; practice never advances campaign saves.

## Decisions and scope

The time budget is 240 seconds, tuned against legal-input runs of 119.83-146.57
seconds rather than an assumed reference-video speed. Human feel/time fairness
still needs review. One cylindrical convex hull matches the platform-bearing
ring; four independent support points produce physical lean/tilt. The water is
query-based buoyancy, not a solid floor, so holes really remove support.

To retain regression coverage, the old `RaceLevel` is isolated in `LegacyLevel`
and `scenes/legacy/LegacyLevel01.tscn`, using `LevelDefs.LEGACY_LEVELS`. Existing
legacy tests keep their assertions. New `SkyLevel`, `CurvedCourse`, `RouteCamera`
and `CrewHUD` serve production `Level01.tscn`; replacing old builder internals
would have conflated two different geometry/control contracts. `FloatPlayer`
and its legacy API remain only for those fixtures. Normal menu play contains
one `SwimRing` and no opponent. New campaign data uses `LevelDefs.LEVELS`.

The single prototype route keeps a shared ribbon mesh rather than prematurely
splitting its small mesh into draw-call-heavy chunks. Baked rider geometry and
batched scenery keep measured geometry/draw counts under the desktop budgets.
Longer campaign routes can add spatial chunking in their own phase. No downloaded
models, textures, sounds or new dependencies were added. Sound playback remains
Phase 5; signals provide its lifecycle hooks.

## Automated and rendered evidence

`tools/run_tests.sh`: **49 tests / 2,249 assertions / 12 suites pass**, retaining
all 34 prior tests. New coverage includes input lifecycle/deadzone, four-seat gas,
short/held/repeated thrust, depletion, off-centre torque, real mallet collision,
actual gravity drops, current/downhill motion without thrust, assistant release,
route continuity/clearance/self-intersection, local support/holes, deterministic
hazards, ordered finish, practice isolation and pause/timeout during a fall.

Legal-input completion matrix, seed 1 (no transform movement after spawn):

| Occupied riders | Finish seconds | Contacts | Falls/recoveries | Beans |
|---|---:|---:|---:|---:|
| 1 | 146.57 | 1 | 0 | 10 |
| 2 | 132.18 | 3 | 0 | 10 |
| 3 | 123.60 | 2 | 0 | 10 |
| 4 | 119.85 | 2 | 0 | 10 |

All crossed both checkpoints and the cooperative finish. One-rider seed 1 at
30 and 120 render FPS produced identical 146.5667 s completion and 114.733339
force-seconds. Additional four-rider seed 2 completed in 119.83 s with two
contacts, no recovery and 9.70-degree peak tilt. These are deterministic
scripted drivers, not human playtests or proof of every possible input sequence.

The new hole/edge/recovery verifier passes headless and rendered: two whole-crew
recoveries, no stale input, continuing run clock and hidden water effects during
falls. A controlled mallet placement creates an actual body contact and
38.09-degree peak tilt. These placement fixtures are explicitly separate from
no-teleport solvability runs. Capture verification resumes itself if desktop
focus pauses the fixture; normal focus-loss pause is independently tested.

`verify_crew.gd` passed actual Play -> Crew -> Start Sky Garden -> Back -> Practice
navigation, four selected riders/one body, section reset and empty-crew launch
blocking, plus existing profile/back/layout checks. Portrait captures preserve
Phase 1 evidence under their original filenames. Existing baseline verifier also
passed before cutover (1,874 checks, 16.77 s, eight beans, three stars).

Fresh evidence is `docs/screenshots/phase2_v3_before_*` and `phase2_v3_*`:
overview, S-bend, bridge, climb, high hairpin, descent, obstacles, holes, finish,
result, hole fall, checkpoint recovery, edge fall and mallet contact.
`export/TootTubes-phase2-sky-garden-demo.mp4` is an uninterrupted scripted
four-seat run: 720 x 1280, H.264, 30 FPS, 3,743 frames / 124.77 seconds.
Decoded start/middle/end samples were checked. Raw capture frames and exports
stay ignored. Capture/encoding wall time is not representative FPS.

Earlier non-recording desktop full-run sample on Intel UHD Graphics,
Compatibility, 720 x 1280: median 16.671 ms / p95 17.638 ms, maximum 67 draw calls
and 50,110 visible primitives. Recording run maximum: 67 calls / 50,114 primitives;
its 25.026/47.881 ms timings include disk capture and are not performance claims.
Final non-recording seed 3 desktop run: **119.82 s**, two contacts, no recovery,
median **16.667 ms**, p95 **17.315 ms**, maximum **67 draw calls / 50,114 primitives**
on the same Intel UHD/Compatibility/720 x 1280 setup. This includes moving
camera, jets and ordinary contacts; fall/38-degree mallet fixtures are separately
verified, not included in that completion-run frame distribution.

## Android artifact and remaining acceptance

`export/TootTubes-phase2-sky-garden-debug.apk`: version **0.4-sky-garden / code 6**,
**57,842,511 bytes**, package `com.itsd85.toottubes.prototype`, minimum API 24.
Export succeeded and apksigner verified v2/v3 signatures. Archive checks confirm
SwimRing, CoursePath, CurvedCourse, Practice and route shader resources; reference
video/pack, tests, tools, documentation and credentials are excluded. Old APKs
remain separate. `adb devices` listed no connected phone.

Human completion, mobile touch/Back/upgrade behavior, sustained frame pacing and
heat on real phones remain pending. Desktop captures/counters do not satisfy
those gates. Full LAN, more campaign courses and finished audio remain later
phases. User edits to `project.godot`, the reference video and untracked pack
HTML/images are preserved outside this phase commit.

## Revised Gate 2

- [x] All new/migrated tests pass; one physical ring in the playable scene.
- [x] Actual menu actions launch new Sky Garden and Practice with saved crew.
- [x] Four independent inputs, short/held/repeated thrust and per-seat gas verified.
- [x] Production curves, S-bends, hairpin, narrow route, climb, descent and dip verified.
- [x] Seven connected sections, six hazard types, two bumpers/holes/checkpoints.
- [x] Physical contact/tilt and whole-crew hole/edge recovery verified.
- [ ] Human camera/control readability and actual mobile release acceptance.
- [ ] Human-played completion; desktop profiling portion is recorded above.
- [ ] Real-phone install, touch, portrait, frame pacing and heat.
- [x] Before/after captures, uninterrupted scripted recording, guide and phase commit.

Commit message: `Phase 2: four-rider ring, curved terrain and cooperative obstacles`.
Run/manual steps: [PHASE2_SKY_GARDEN_TESTING.md](PHASE2_SKY_GARDEN_TESTING.md).


---

# Phase 2 feedback revision: moving riders and water - 2026-11-02

The user reported weak water/physics presentation and fixed inward-facing riders,
then explicitly chose **aim also moves the rider around the rim**. Implemented
this as a Phase 2 correction before expanding the environment set.

## Shared behavior and presentation

Riders now face outward in both preview and gameplay. `RiderOrbit` moves their
positions at fixed physics steps with bounded speed and 0.76-radian minimum
angular separation. Controller/seat identity stays stable. Movement alone costs
no gas. Forces use those same moving lever arms; a small bounded supported load
shift adds real torque. `RingPhysicsProfile` owns orbit speed, load shift,
angular damping and water drag. Drift remains after release; axes stay free.

The static hull and each rider's body are batched separately, preserving movable
anchors and a separate clothed rear panel. Actual firing drives red rear tint,
lean and the existing jets; release cools the tint. Jets follow the moving rear
positions with an interpolated hull pose. No meshes/materials/particle nodes
are rebuilt during sustained movement or thrust.

`WaterStyle` is the shared Resource for palette, two wave components and amplitude.
`CoursePath` uses the same analytic waves and derivatives for buoyant height/
normal that `CurvedCourse` supplies to the water shader. `Level.race_time` drives
both and pause freezes both. Waves never restore support over holes/edges.
Generated water has six strips across its width for bounded displacement cost.
Lit shading, view-dependent highlights, caustics, bank/hole foam, speed-dependent
wake and pooled spray replace the old unlit dotted surface. Fine ripples/caustics/
wake remain cosmetic; the two main waves affect the real hull. This is a bounded
surface model, not full fluid simulation. Real collision, gravity, slope motion
and cooperative fall/finish behavior remain in the shared rigid body.

Future courses must reuse WaterStyle, RiderOrbit, RingPhysicsProfile and the
same path/mesh/physics code. They can change route data/palette without inventing
another movement model. The canonical environment spec, plan and both pack
mirrors now reflect this user-authorized change. LAN replication of authoritative
orbit angles remains a future Phase 4 requirement; no network work was started.

## Validation and evidence

Final `tools/run_tests.sh`: **55 tests / 2,298 assertions / 13 suites pass**,
including every prior test. New checks cover outward faces, orbit spacing,
movement without gas, real moving force anchors, red tint/decay, analytic wave
gradients, CPU/shader parameter agreement, physical hull movement without
thrust, paused water time and suppression of wake/support during falls. The
existing mean-height query assertion now includes the shared wave displacement;
its tolerance is unchanged. No assertions were removed or weakened.

Full legal-input driver, seed 4, with no transform changes after spawn:

| Riders | Finish seconds | Contacts | Recoveries | Beans |
|---|---:|---:|---:|---:|
| 1 | 132.88 | 1 | 0 | 10 |
| 2 | 120.85 | 1 | 0 | 10 |
| 3 | 114.17 | 2 | 0 | 10 |
| 4 | 110.88 | 1 | 0 | 10 |

All crossed both checkpoints and the cooperative finish. A rendered recorded
four-seat seed 5 run also passed: 110.90 s, one contact, no recoveries, 10 beans,
14.69-degree peak physical tilt, maximum 80 draw calls / 56,402 visible primitives.
Its frame times include disk capture and are not normal gameplay performance.

The focused pose/thrust/wake fixture passed at portrait 720 x 1280: up to 106 draw
calls / 55,200 visible primitives, 11.13 m/s before release and 4.99 m/s after its
coasting interval. New hole/edge fixtures pass headless and rendered, with two
whole-crew recoveries and no stale input. The controlled live mallet fixture
reaches 41.98 degrees of physical tilt with an actual contact. Those deliberate
placement fixtures are distinct from legal-input completion evidence.

Actual menu/profile/practice navigation and portrait layout checks pass again.
Updated preview samples: one rider 71 calls / 9,666 primitives; four riders
118 / 17,926; creator 129 / 17,194. These are desktop counters, not phone FPS.
New `phase2_feel_*` captures show outward/orbit/thrust/release/wake and recovery;
`phase2_feel_course_*` shows the updated full course. The earlier captures remain
historical. The new uninterrupted scripted recording is
`export/TootTubes-phase2-water-riders-demo.mp4`: H.264, 720 x 1280, 30 FPS,
3,474 frames / 115.80 seconds. Encoded start/middle/end frames were decoded
and inspected. Recording/capture inputs are scripted, not human playtests.

Non-recording four-seat seed 6 run on Intel UHD Graphics, Compatibility,
720 x 1280: median **16.656 ms**, p95 **18.488 ms**, maximum **80 draw calls /
56,402 visible primitives**. Completion 110.92 s, one contact, no recoveries,
ten beans, 14.76-degree peak tilt. No capture/encoding process ran during this
measurement. Desktop timing does not establish phone FPS or heat acceptance.

## APK and acceptance

New artifact: `export/TootTubes-phase2-water-riders-debug.apk`, version
**0.4.1-water-riders / code 7**, **57,855,109 bytes**. Android export succeeded;
apksigner verifies v2/v3 signatures. Package/minimum API stay
`com.itsd85.toottubes.prototype` / 24. Archive checks confirm WaterStyle,
RiderOrbit and route shader resources and exclude reference video/pack, tests,
tools, documentation and credentials. Old APKs remain separate.

Gate 2 automated/code portions pass. Human assessment of the new orbit, spacing,
red feedback, water/camera readability and a completed run remains open. Real
phone install/upgrade, two-finger input, Back, sustained frame pacing and heat
remain unverified. Nothing in Phase 3 has started. User edits to project.godot
and untracked reference media/pack documents remain outside the commit.

Guide: [PHASE2_WATER_RIDERS.md](PHASE2_WATER_RIDERS.md).

---

# Gate 2 verification and recovery-camera fix - 2026-11-05

User requested finishing Gate 2, then confirmed **no phone is available; finish all other checks**. Completed the available automated/rendered checks and the pending QA tooling. Human feel/completion and physical-phone gates remain open. Phase 3 has not started.

## Fix and tools

- Rendered recovery review exposed a real defect: after a distant checkpoint reset, the camera continued smoothing from the fall location and could leave the crew outside the view. Connected the existing `SwimRing.recovered` signal to `RouteCamera.snap` in `Level`. Recovery now moves the camera with the checkpoint teleport; normal follow remains damped. The shared signal also covers manual recovery and Practice area changes.
- Added a regression for immediate rider visibility after a checkpoint more than 50 m away. Added safe-view checks to both hole and edge recovery fixtures. No tests or assertions were removed or weakened.
- Finished `verify_gate2_inputs.gd`: actual menu mouse events, keyboard and two-finger event lifecycle, one Local plus three production Assistants, real countdown, repeated holds/releases, pause/focus cleanup, ordered finish and Back. Added configurable capture prefixes, a no-capture timing mode and full-run camera assertions. Disposable saves remain isolated from the player's save.
- Finished the Android test-only helper and builder. Fixed Windows PowerShell compression assembly loading and keytool stderr handling; delete the disposable signing key afterward. The helper checks game focus during gestures and only cancels pointers it started. These QA files are excluded from game exports.
- Updated README and the current testing guides to the new APK. Preserved the old APKs, recordings, screenshots, existing `project.godot` edit and reference media/pack files.

## Validation

Required `tools/run_tests.sh`, Godot 4.7.2 standard / GUT 9.6.1:

```text
Scripts              13
Tests                56
Passing Tests        56
Asserts            2302
All tests passed!
```

Focused camera/run suite: **5 tests / 30 assertions pass**. Corrected rendered recovery fixture: **two safe whole-crew recoveries**, one real mallet contact, **41.98-degree** peak physical tilt; rider safe-view checks pass. The before/after `gate2_final_hole_recovered.png` and `gate2_corrected_hole_recovered.png` show the defect and correction explicitly. Fixtures deliberately place the hull and are separate from legal-input completion evidence.

Final post-fix rendered event-driver run with screenshots disabled: **36 checks pass**, **110.32 s** completion, **56** hold presses, **6,691** touch events, **one contact**, **zero recoveries**, both ordered checkpoints, no extra focus-loss resumes. All four rider head points stayed inside the defined safe area for **100% of sampled frames**. This does not establish occlusion-free visibility under every possible impact or human camera comfort. Earlier capture run: 37 checks including one extra desktop focus resume; its images use `gate2_final_*`.

Final desktop performance sample on Intel UHD Graphics, Compatibility, 720 x 1280: **16.661 ms median / 18.572 ms p95**, sampled maxima **80 draw calls / 56,402 visible primitives**. The emulator, other game checks, screenshot writes and recording/encoding were stopped for this run. These are desktop results, not phone frame pacing or heat evidence. Earlier focused four-rider and preview measurements remain in their dated sections.

New phone artifact: `export/TootTubes-phase2-gate2-debug.apk`, **0.4.2-gate2 / code 8**, **57,855,109 bytes**. Export succeeded; apksigner verifies v2/v3. Package/minimum API remain `com.itsd85.toottubes.prototype` / 24, ARMv7 + ARM64. Archive checks confirm Level01, WaterStyle and RiderOrbit and exclude tests/tools/docs/addons/reference materials and credentials. SHA-256: `FAD1C70BB8361E0899DA1428421F9377F5A3E369671F347ED1006E41EFF999AC`.

## Android and remaining acceptance

The isolated read-only Android 11 emulator now exposes GLES 3.1. The delivered ARM APK installs and initializes the engine, but stalls before a usable game screen under translation; ARM runtime acceptance remains unsuccessful here. A separate ignored x86_64 export of the same code 8 source rendered Title, creator/save, menu, Crew Setup and Practice. The helper accepted **39 OS touchscreen events** across three two-pointer sequences in Practice, with inactive HOLD feedback after release. Android navigation returned to the menu. This supplemental native-emulator smoke is not an ARM phone run, a gas/force assertion, or a human completion. Short ADB menu taps were inconsistent; longer stationary swipes were used. Rejected helper attempts reported zero events; they do not verify its separate foreground-guard path.

The production export preset is restored to ARMv7 + ARM64. The QA helper was uninstalled and the owned emulator processes stopped. Existing emulator profile/data were preserved. APKs, temporary exports, logs, SDK/editor files and signing material remain outside Git.

## Gate 2 checklist

- [x] New/migrated tests; exactly one physical ring.
- [x] Main Play opens saved-crew Sky Garden; Practice is reachable; legacy solo is isolated.
- [x] Four independent occupants; short/held/simultaneous thrust coverage.
- [x] Curves, S-bends, hairpin, narrow route, climb/descent/dip geometry.
- [x] Seven connected sections, six hazards, two bumpers/two holes and two safe checkpoints.
- [x] Physical push/tilt, whole-crew falls/recovery; corrected camera follows checkpoint reset.
- [ ] Human camera/control review and reliable physical mobile release; automated/rendered coverage passes.
- [ ] Human-played completion; desktop frame times and four-rider counters are recorded above.
- [ ] Real-phone install/upgrade, sustained touch, portrait, frame pacing and heat; deferred because no phone is available.
- [x] Before/after captures, existing uninterrupted scripted recording, updated progress/testing guides; commit `Phase 2: four-rider ring, curved terrain and cooperative obstacles`.

All available automated work is complete. Gate 2 is not relabeled as fully accepted: the plan explicitly requires human play and physical-phone checks. Stop here; no campaign or networking implementation.

Report and reproduction commands: [PHASE2_GATE2_QA.md](PHASE2_GATE2_QA.md).

---

# Phase 3: five cooperative courses and offline progression - 2026-11-05

The user authorized Phase 3 after accepting **laptop-first validation with phone checks deferred**, and requested UI/gameplay separation so visual refactors mainly change UI files. This authorization advances implementation; it does not mark previous human/device checks as performed. Phase 4 has not started.

## Delivered

- Five playable original courses: retained Sky Garden plus Canyon Switchbacks, Cloud Bridges, Spiral Springs and Festival Summit. Each has a distinct connected spline, widths/elevation, palette and hazard mix; two safe ordered checkpoints; holes and an ordered cooperative finish. All use the same SwimRing/RiderOrbit/RingPhysicsProfile/WaterStyle pipeline.
- Added real moving spiked gates, rising/falling crushers, marked moving boulders and bounded whirlpool swirl/pull. Existing bumper/current/sweeper/mallet/crossbar and open holes remain. Motion is sampled only from `Level.race_time`; no hazard timers or RNG. Repeated current/whirlpool markings and gate spikes use MultiMesh. Whirlpools do not silently become lethal/reset zones.
- Level Select displays locks, saved stars and best times. Completing each actual course unlocks only the next. Shared result shows Retry, Next when allowed, Menu and final-campaign completion. Failure offers no Next and awards no stars. Retry/Restart create fresh scenes with the original course budget; saves/settings/crew remain intact.
- Complete Pause/Resume/Restart/Sound/Quit, focus/input cleanup, clear in-game save errors and Retry saving. Sound preference persists; actual SFX/music remain Phase 5. Contextual hints cover aiming/coasting, gas, exposed bridge edges, holes and whirlpools. Practice stays untimed and does not save campaign wins.
- Removed Level 1 hardcoding from course loading and result saving. `CampaignFlow` owns launch/crew checks, campaign results, next-course validation, cards and settings persistence. `Level` coordinates the run and supplies detached HUD snapshots, without setting label text or styling.
- Presentation lives in CrewHUD and `scripts/ui/`: course/settings views, pause/result panels and AIM/HOLD pad drawing/layout. `CrewInput` keeps input ownership and normalized requests; it delegates hit rectangles to the pad view. Styles are cached instead of recreated during every draw. Disabled pads no longer consume touches intended for panel buttons.
- Preserved version-2 profiles, avatar alias, crew/leader, safe migration backup/temp-write handling, progress/star formula and online progression isolation. Transient `last_save_error` does not change the save schema. Failed-write coverage confirms the prior file survives and a subsequent retry persists the in-memory result.
- Updated README, GDD, plan, credits and testing/architecture guides; retained historical captures and reference material.

## Automated validation

Required `tools/run_tests.sh`, Godot 4.7.2 standard / GUT 9.6.1:

```text
Scripts              16
Tests                70
Passing Tests        70
Asserts            7425
All tests passed!
```

New coverage: campaign/crew/lock validation, all five ordered results and fresh state load, final-course Next boundary, failure/practice/online/invalid-result isolation, save-error reporting/prior-file preservation, settings persistence, all-route slope/clearance/height/checkpoint/hole safety, exact ribbon-edge self-intersection rejection, deterministic new hazards, real solver contact and real open/closed collision windows, detached UI snapshots, UI lock cards, paused panel input over the hidden gas pad, one-time result commit and tutorial handling. No existing test/assertion was removed or weakened. Missing-storage warnings in the deliberate write-failure test are expected.

All **45/45** headless legal-input cases passed: five courses x four crew sizes x seeds 1 and 3, plus one Local driver/three production Assistants at seed 7 for every course. Each case uses normal per-seat force/gas after spawn, actual rigid-body motion, both checkpoints and cooperative finish; no transform movement. Zero recoveries across the matrix. Contacts reached 18 in the hardest solo sample, so this is not collision-free teleport evidence.

Seed 1 simulated racing seconds:

| Course | One rider | Four riders | Matrix cases |
|---|---:|---:|---:|
| Sky Garden | 131.72 | 111.00 | 9 |
| Canyon Switchbacks | 152.55 | 126.32 | 9 |
| Cloud Bridges | 142.20 | 116.13 | 9 |
| Spiral Springs | 161.30 | 132.23 | 9 |
| Festival Summit | 155.22 | 125.67 | 9 |

`verify_campaign_flow.gd`: **102 checks pass** through real menu mouse events, locked selection, pause clock/input cleanup, sound toggle/save, real Restart, a separately labeled 0.1-second timeout fixture/Retry, legal-input completion of all five courses in order, actual Next transitions and final Menu. One local-seat driver plus three production Assistants completed in 110.20 / 125.87 / 115.25 / 131.82 / 125.38 s with zero recoveries. This does not substitute for human input/feel assessment.

A **second Godot process** passes **12 reload checks**: all five stars/times/unlocks, crew ownership, saved sound preference and final-course launch through UI. Complete mode leaves only its named disposable save; reload removes it. Preview fixtures now use a separate disposable save name. The player's normal save is untouched.

The existing Gate 2 mouse/key/two-finger verifier passes **34 headless checks**: 110.32 s, 56 holds, 6,691 touch events, one contact and no recoveries. Its headless timing/camera counters do not establish rendered performance.

## Rendered laptop evidence and performance

All five course overview/play/pause/failure-result fixtures pass **36 rendered checks**. Captures use `phase3_preview_*` and were visually inspected. They deliberately place the hull; they are not course-completion evidence. Midcourse placed samples before the final cloud reduction reached 59-65 calls / 49,208-53,416 visible primitives. Successful full-run results are separately captured as `phase3_spiral_final_result.png` and `phase3_festival_final_result.png`, including Next and final-campaign boundary.

Clean full rendered runs on Intel UHD Graphics, Compatibility, 720 x 1280, four riders, seed 4, no screenshot writes during racing or concurrent tests/exports:

| Course | Finish s | Median ms | p95 ms | Max calls | Max primitives | Contacts / recoveries |
|---|---:|---:|---:|---:|---:|---|
| Spiral Springs | 131.83 | 16.661 | 18.346 | 71 | 58,128 | 2 / 0 |
| Festival Summit | 125.73 | 16.673 | 17.763 | 74 | 57,225 | 8 / 0 |

Both had zero focus-loss resumes. The driver can explicitly resume after focus loss when requested; ordinary application focus loss still pauses/clears input. Full-run timing excludes intro/countdown, pause and finished-state image writes. The verifier now fails rendered runs without frame samples or over 150 calls / 60k primitives. Desktop counters do not establish phone FPS or heat.

Initial Spiral Springs profiling reached 60,144 primitives, just over budget. Reduced only distant cloud sphere rings from four to three: same cloud instances/positions and batching, with no route, collision, water-strip, crew, input or physics changes. Final Spiral peak is 58,128. Festival's peak also dropped from 59,241 to 57,225. No course variety or fourth rider was cut.

## Build and decisions

Phone handoff: `export/TootTubes-phase3-campaign-debug.apk`, **0.5.0-campaign / code 9**, **57,885,832 bytes**. Export succeeds and apksigner verifies v2/v3. Same package `com.itsd85.toottubes.prototype`, minimum API 24, ARMv7 + ARM64. Archive confirms Levels 01-05 and the three new UI modules; tests, tooling, addons, docs, reference pack/video, keystores and credentials are excluded. SHA-256: `7FF90EBC44E3D8D584A84EF77B30F02EDB1D2FF1F1F83422175EBD7EC4D4603E`.

This phase keeps the established single-route CoursePath/ordered-checkpoint model. Spiral Springs uses connected spiral turns rather than branch choices; optional branch/reconnect exploration would need explicit route identity before adding shortcuts. UI work is a focused separation, not a framework rewrite: existing avatar/crew editing callbacks remain compatible. The original lab PDF is still absent, so eleven GDD headings/rubric alignment remain provisional.

Laptop campaign execution has no service dependency: Net stays idle and Android internet/network-state permissions remain disabled. This is source/build and local execution evidence, not physical airplane-mode acceptance. No phone or emulator testing was attempted in Phase 3, per the laptop-first direction. Actual audio, LAN, release signing and publication were not started.

## Gate 3 checklist

- [x] Five original cooperative courses; one physical ring and shared movement/water.
- [x] Locks, best stars/times, Result/Retry/Next/Menu and final-course boundary.
- [x] Pause/Resume/Restart/Sound/Quit, contextual hints and documented UI/logic interfaces.
- [x] Actual menu-driven lose/retry and ordered full campaign.
- [x] Save/relaunch in a fresh process; crew/settings/progression preserved.
- [x] Required tests, all-course 1-4 rider/assistant solvability, checkpoint/collision/recovery and rendered laptop checks.
- [ ] Human feel/difficulty and physical-phone touch/Back/performance; deferred by user.
- [ ] Physical airplane-mode completion/retry/relaunch; deferred by user.
- [x] Progress/testing/architecture guides and commit `Phase 3: five cooperative courses and progression`.

Stop here. Phase 3 logic/laptop work is complete; manual/device gates remain open. Phase 4 needs a separate execution instruction.

Guides: [PHASE3_TESTING.md](PHASE3_TESTING.md), [UI_LOGIC_BOUNDARIES.md](UI_LOGIC_BOUNDARIES.md).

---

# Phase 4: shared-ring LAN implementation (2026-11-05)

Authorized by the user's `next` instruction after Phase 3, retaining laptop-first validation and deferring physical phones. Phase 4's implementation/laptop checks are complete; its required real two-phone/four-phone acceptance remains open. Phase 5 has not started.

## Implemented behavior and separation

`Net` now uses ENet port 7777 with `MAX_CLIENTS = 3`. Mode Select offers Offline/Host/Join. The lobby shows one ring, four identifiable slots, host IP, course selection, readiness and start/leave. A load barrier starts one common round after every current member has loaded. The host chooses from its unlocked courses; online play cannot unlock the guest's campaign.

The host alone simulates the shared ring, gas, water, hazards, ordered checkpoints and finish. `NetInputGate` validates owned seats, current round, increasing sequence, types, finite direction/strength, strength bounds, rate, gas and run state. Explicit release is reliable; input expires after 350 ms without refresh. `RingReplication` sends/interpolates full 3D pose/orientation, velocities, gas, aim/held/firing/depletion, rider orbit and run state, including clock, pickups and the single cooperative result. Guest bodies stay frozen with collision/engine interpolation disabled. All moving hazards still evaluate only `Level.race_time`.

Any rider may pause/leave; the host resumes, recovers, restarts or returns the crew to lobby. Rematch clears clock, checkpoints, gas/input and replication state; round IDs reject old input/snapshots. The selected guest-loss policy is **vacant seat**, without automatic assistants: immediately release the old seat and remove its rider from the shared preview/body presentation. Host loss, silence or unreachable IP shows an in-game explanation and returns to Mode Select. Connect/load/host-silence limits are 10/15/8 seconds. Normal ENet disconnect detection may finish sooner.

Session profiles/owners remain separate from `GameState.local_profiles` and `crew_slots`; the existing save schema and write/migration logic are unchanged. Online results do not save/unlock progress. Leaving restores the previous offline mode and result. UI sends intents through `Net` or HUD signals; fonts/layout/labels remain in `NetworkScreen`, `CrewHUD`, `RunPanels`, `CrewPadView` and theme files. Network validation and ring physics have no layout responsibilities. See [UI_LOGIC_BOUNDARIES.md](UI_LOGIC_BOUNDARIES.md).

## Validation evidence

- Required `tools/run_tests.sh`: **78 tests / 7,642 assertions / 19 suites, all passing**; `.bin/phase4-final-tests.log`. Existing tests remain intact. New coverage includes hostile/stale/rate/gas input, isolated storage/session lifecycle, actual owned-input adapter release, snapshot interpolation and visible portrait lobby slots/buttons.
- Required `tools/net_smoke.sh`: **128 checks pass**, separate real processes, first host + 1 guest then host + 3 guests. Final reports: `.bin/phase4-validation/20261105-110145/`, aggregate log `.bin/phase4-final-net-smoke.log`. The runner also rejects engine runtime errors even if process exit is zero.
- Two-peer Sky Garden: **126.30 s**, two stars, zero recoveries, both ordered checkpoints and identical result on both peers. Four-peer: **119.20 s**, three stars, zero recoveries, both checkpoints, identical result on all four peers and real force contribution from all four seats. Scripted seat drivers use normal sustained input/gas with a 3x clock; they never teleport or refill the body. This is transport/logic evidence, not four-human or wireless acceptance.
- Network checks also pass forged-seat rejection, explicit release before expiry, dropped release/refresh expiry after observed held input, fresh rematch, shared pause/resume, guest departure/vacancy, host departure, wrong/unreachable connection, and **abrupt host-process kill** returning the guest to Mode Select. Disposable offline save files remain byte-identical across connected play/results/disconnects, and offline mode/prior result are restored.
- `verify_lan_ui.gd`: **six rendered fixture checks**, visually inspected Mode Select, four-slot lobby and actual online result HUD. `docs/screenshots/phase4_*.png` are presentation fixtures, not network-run proof or performance profiling. Visual inspection caught zero-height lobby slot labels; explicit label dimensions and regression coverage now keep all four visible within the 720 x 1280 layout.
- Debug export **0.6.0-lan / code 10**, `export/TootTubes-phase4-lan-debug.apk`, **57,915,202 bytes**, ARMv7 + ARM64, minimum API 24 / target 36, v2/v3 signature verified. INTERNET and ACCESS_NETWORK_STATE enabled for LAN; VIBRATE retained. New runtime resources are present; tooling/docs/addons/reference media/signing material excluded. SHA-256 `0039B10532A0487F27BED7E7A3B4461F82390756938D381A60603B1E270676D7`. No physical installation claim.

## Decisions and remaining acceptance

No backend is needed for local ENet co-op. Guests can request a shared pause; only the host resumes/restarts/recovers, avoiding contradictory local clocks or body resets. Guest seats become vacant rather than silently assigning an assistant. These are the simplest policies consistent with one host-owned physical ring and are explained in the lobby/testing guide.

The network fixture identifies riders by their assigned sanitized profile, because process-launch order does not guarantee connection/seat order. Its release-loss deadline uses the actual host receive timestamp plus a physics margin; it does not assume synchronized process frames. Both observed held state and eventual release are required. Initial failing runs are retained in `.bin`; only the final passing evidence above supports acceptance.

No router/firewall settings were changed, no external service was used, and no release/push was performed. The preexisting `project.godot` change, reference video and reference-pack docs remain untouched. New screenshots contain only original procedural game assets. Audio/production release work remains Phase 5. Original lab PDF/rubric alignment is still provisional.

## Gate 4 checklist

- [x] Host-authoritative one-ring LAN, two to four owned rider slots and ready/load barriers.
- [x] Input ownership/rate/sequence/strength/gas validation, explicit release/expiry and guest interpolation.
- [x] Shared result, pause/rematch/leave, vacancy policy and clear timeout/host-loss recovery.
- [x] Existing/new tests, two-process then four-process completion and required net smoke pass.
- [x] Offline profile/progression/file isolation, portrait presentation and signed debug package verified.
- [ ] Two physical phones and four physical phones: cooperative controls, wireless interruption, shared finish/rematch, Android Back/touch/performance; deferred by user.
- [x] Update docs and commit `Phase 4: four-player shared-ring LAN co-op`.

Stop after Phase 4. [PHASE4_TESTING.md](PHASE4_TESTING.md) contains laptop instructions and the remaining device checklist. Physical gates remain open; Phase 5 needs a separate execution instruction.

---

# Phase 5: laptop acceptance of current polish (2026-11-05)

The user asked to establish everything that can be tested here before device acceptance. The worktree already contained Phase 5 audio/settings/title/build changes. This pass inspected and tested those changes, repaired verification/build issues, and documented the current candidates. It does not close the physical-phone/human gates or claim release publication. Existing unrelated work, reference video/pack docs and the preexisting `project.godot` edit were preserved.

## Available polish and boundaries

Original synthesized sustained thrust loops have per-seat attack/release envelopes, with impacts, falls, pickups, checkpoint/result/UI effects and original looping music. Saved controls cover master sound, music volume, high/low quality, vibration, reduced motion and FPS. The four-rider title and original SVG icon use the established primitive models. Full Fredoka OFL and Godot/third-party license notices are accessible in Credits and bundled with the builds.

`SettingsFlow` owns preference validation/save and decorative quality application; settings UI only presents controls/status. `RunFeedback` observes actual run/seat state for audio/haptics and quality/motion. `Audio` owns playback/envelopes/focus. Physics, gas, route/hazards, seat ownership and campaign progression remain in their existing modules. Replication includes contact/pickup counters for guest feedback. Low quality preserves all four riders, physical geometry/collision, hazards, mass and gas; it reduces clouds and particles only. See [UI_LOGIC_BOUNDARIES.md](UI_LOGIC_BOUNDARIES.md).

## Fresh local evidence

- Required `tools/run_tests.sh`: **85 tests / 7,807 assertions / 21 suites pass**, `.bin/phase5-local-tests-final.log`. The deliberate invalid-save test emits its expected warning. Final run has no resource-leak/runtime errors; assertions were not removed or weakened.
- Required `tools/net_smoke.sh`: **128 checks pass**, `.bin/phase5-local-net-fixed.log` and `.bin/phase4-validation/20261105-145503/`. Host + 1 guest then host + 3 guests finish with identical shared results, both checkpoints, real force from every seat and no recoveries. Results also cover spoof rejection, explicit release, dropped refresh expiry, pause/rematch, guest vacancy, deliberate host exit, unreachable IP, abrupt host kill and byte-identical disposable offline saves.
- `verify_campaign_flow.gd`: **102 checks** through actual menu events, pause/restart, timeout/retry fixture and all five normal-input course completions; **12 checks** in a separate reload process. Course times: **110.20 / 125.87 / 115.25 / 131.82 / 125.38 s**, all with zero recoveries. `.bin/phase5-campaign.log`, `phase5-campaign-flow.json`, `phase5-reload.log`, `phase5-reload-flow.json`.
- `verify_gate2_inputs.gd`: **36 checks**, **6,691 synthetic touch events plus mouse/key checks**, **56 held thrust presses**, Sky Garden **110.32 s**, one contact and zero recoveries. `.bin/phase5-input-final.log`, `.bin/gate2-input-result.json`. This headless run does not establish Android touch, rendering FPS or camera framing acceptance.
- `BuildCheck.gd`: **39 checks** for navigation, four title riders, scrollable settings, persistence reload, bundled notices, four low-quality riders with real fourth-seat force, FPS display, pause audio cleanup and actual non-silent mixed PCM. The mixer stress check explicitly verifies four voices sustaining at full gain while music plays; its isolated observer cannot silently cancel the voices.
- `verify_portable.py`: the **same 39 checks pass headless and rendered in the release EXE**, copied into a fresh temporary folder containing only that executable. Reports `.bin/phase5-portable-headless.json`, `.bin/phase5-portable-rendered.json`; logs of the same names. Rendered audio uses WASAPI; headless uses Dummy, both exercising the engine mixer. No microphone recording is involved. Captures `.bin/phase5_title.png`, `phase5_settings.png`, `phase5_pause_low_quality.png` were visually inspected. Listening quality remains a human check.

## Four-rider rendered performance

Festival Summit full normal-input runs, seed 4, Compatibility, Intel UHD Graphics, 720 x 1280, 60 FPS cap. No concurrent tests/exports or screenshot writes during racing. Both crossed the ordered checkpoints, completed in **125.73 s**, produced real force from all four seats, had eight contacts and **zero recoveries/focus resumes**.

| Quality | Median ms | p95 ms | Peak draw calls | Peak visible primitives | Frames with four firing |
|---|---:|---:|---:|---:|---:|
| High | 16.665 | 17.079 | 74 | 57,225 | 4,814 |
| Low | 16.666 | 17.188 | 73 | 47,305 | 4,815 |

Reports `.bin/course_result_5_4_4.json` and `_low.json`; logs `.bin/phase5-profile-high.log` and `phase5-profile-low.log`. Both pass the 150-call / 60k-primitive budgets. Low quality reduces peak visible primitives by about **17%**, retaining identical simulated physics/force/gas results. Both already sit near the laptop's 60 FPS cap; no claim about phone FPS, heat or low-quality speedup follows.

## Verification/build fixes and local candidates

The first LAN run caught an explicit-release fixture tied to narrow race-clock windows. The fixture now waits for a host-observed held packet, sends a real reliable guest release and requires the host to observe fresh release before expiry, with a finite timeout. The lost-refresh fixture still requires observed held state and actual host expiry. No network/physics rules were relaxed.

The old input-event verifier skipped the Phase 4 Mode Select screen; it now clicks Offline crew and asserts both navigation stages. GUT's new post-run hook and UI/network verifiers stop audio and wait for queued mixer cleanup before exit. These changes address shutdown resource errors without filtering errors or changing test results.

The release EXE ignored the editor-style `--script` check and simply opened Title. `BuildCheck` now runs as a Node behind an explicit `--build-check` user argument in Title startup. The portable runner deletes old reports before launch and validates real standalone output; normal player navigation has no test action. The signing builder now trims a trailing newline in the encrypted credential file so an existing protected local signing identity can be reused.

Current candidates are **0.7.0-rc1 / code 11**: `export/TootTubes-phase5-debug.apk`, `export/TootTubes-0.7.0-rc1-release.apk`, `export/TootTubes-0.7.0-rc1.exe`. The release APK uses the separate `com.itsd85.toottubes` package; debug retains `com.itsd85.toottubes.prototype`. Both APKs are ARMv7 + ARM64, minimum API 24 / target 36, with v2/v3 signatures verified. Archive inspection confirms runtime modules, all 11 audio assets, icon and full notices; tooling/tests/docs/reference media/signing material are excluded. `export/phase5-builds.json` records final sizes/hashes. Exports and signing material are ignored; private credentials stay outside the repository. The portable Windows EXE is not publisher-code-signed. No publication, phone control, emulator installation, router or firewall changes were performed.

## Gate 5 status

- [x] Local audio/settings/title/icon/notices polish available and validated.
- [x] Required tests, campaign/reload, controls, multi-process LAN and standalone UI/mixer checks pass.
- [x] High/low four-rider laptop rendering budgets pass; local candidates/signatures/resources verified.
- [ ] Two physical phone classes: four riders firing amid hazards, sustained FPS/frame pacing and heat.
- [ ] Android install/upgrade, touch/Back/Home/resume/vibration and offline airplane-mode campaign/save acceptance.
- [ ] Physical two-phone/four-phone Wi-Fi play, shared finish/rematch and interruptions.
- [ ] Human camera/steering/visual/audio/difficulty review, final phase handoff/commit and release publication decision.

**Phase 5 remains open.** This is a local validation checkpoint; current Phase 5 work and these verification fixes remain uncommitted pending phase handoff. The original lab rubric PDF is still unavailable. [PHASE5_TESTING.md](PHASE5_TESTING.md) contains reproducible commands and the remaining device checklist.

## Phase 5 continuation: Android behavior checks and implementation handoff

The user's `continue` instruction retained laptop-first validation. Added `AndroidCheck.gd`, an opt-in debug probe with an isolated save and a private QA marker; the public launcher's security policy ignores arbitrary command-line extras. Added a separate x86-64 `Android Emulator QA` preset, an explicit-emulator-only runner, native HOLD drag-out support in the existing instrumentation helper, blank-capture/runtime-error rejection, bounded startup retries and read-only emulator configuration restoration. Ordinary player navigation and phone ARM presets retain their existing behavior. No environment, physics, rider-count or thrust rules changed.

**Android result is partial, not an accepted rendered game.** A software-rendered x86-64 fixture passed **55 behavior checks**: Android menu taps/Back, saved settings across same-version reinstall/relaunch, four riders, native two-pointer ownership with actual force/gas drain, release and HOLD drag-out, Home/resume input/audio cleanup, separate 3x scripted airplane-mode completion, both checkpoints, force from all four seats, cooperative save and reloaded stars/time/unlock. However, all captures were flat blue and Godot logged shader errors. `.bin/phase5-android-logic-only.json` explicitly records `logic_passed: true`, `passed: false` and failed rendering. This is not physical-touch, phone-performance or four-human evidence.

ARM execution on the installed Android 11 emulator failed in its old translation layer with an unsupported instruction. Software rendering produced a shader failure matching [Godot issue 109550](https://github.com/godotengine/godot/issues/109550). A lower light-capacity experiment did not fix it and was reverted. Host GPU mode with dynamic GLES detection reached GLES 3.1 without the earlier shader error but did not reach Title within 120 seconds. ANGLE fell back to SwiftShader on this SDK and also failed final startup acceptance. Final reports remain failed. Do not use the earlier 55 positive checks to claim that Android graphics work.

The runner now requires nonblank central screenshot content and rejects Godot/runtime fatal errors. It captures failure evidence and removes its debug marker before closing its managed emulator session. `tools/test_android_checks.py` has **four passing device-free regression tests**: physical serial refusal before any ADB command, flat-frame rejection, nonblank-frame acceptance and byte-identical configuration restoration after startup failure. The negative render fixture intentionally emits a rejected-frame message; the unittest result is `OK`.

All original AVD userdata/encryption images retain their original lengths/SHA-256 hashes, and the original configuration is restored byte for byte: `.bin/phase5-emulator-preservation.json`. No emulator processes remain. Three verified disposable overlays created by this run were removed after shutdown (about 1.8 GB); an older unrelated overlay was preserved. No phone, router, firewall, SDK installation or publication was changed. [ANDROID_EMULATOR_TESTING.md](ANDROID_EMULATOR_TESTING.md) documents commands, setup constraints and evidence limits.

Fresh handoff checks: required `tools/run_tests.sh` **85 tests / 7,807 assertions / 21 suites pass** (`.bin/phase5-handoff-tests.log`); required `tools/net_smoke.sh` **128 checks pass** (`.bin/phase5-handoff-net.log`, `.bin/phase4-validation/20261105-193532/`). The final standalone Windows EXE passes **39 checks each** headless and rendered, from fresh folders containing only the EXE. Actual rendered mixer peak is **0.1253**, with all four voices sustained at full gain and music, without clipping in the sample. `.bin/phase5-handoff-portable-*.log` and `phase5-portable-*.json` hold the evidence.

Final local candidates were rebuilt and APK signatures verified after the QA additions: `export/TootTubes-phase5-debug.apk`, `export/TootTubes-0.7.0-rc1-release.apk`, `export/TootTubes-0.7.0-rc1.exe`. All remain **0.7.0-rc1 / code 11**; the phone APKs remain ARMv7 + ARM64 and the emulator fixture stays in ignored `.bin/`. Final sizes/hashes are in `export/phase5-builds.json`. Signing material remains outside Git. Windows rendering is accepted locally; Android rendering/ARM execution remain pending a working compatible runtime or physical phones.

### Gate 5 implementation checkpoint

- [x] Audio/settings/title/icon/notices and local campaign/input/save/LAN checks.
- [x] Required GUT/net smoke, four QA-runner safeguard tests and standalone Windows checks.
- [x] Local signed Android candidates, embedded Windows candidate and reproducible test guides.
- [x] Preserve existing AVD data/configuration, unrelated work and private signing material.
- [ ] Android rendering acceptance: current emulator stack fails; physical ARM builds are not execution-validated here.
- [ ] Two phone classes: install/upgrade, touch/Back/Home/vibration, sustained four-rider FPS/frame pacing and heat.
- [ ] Physical airplane-mode campaign/save, two-phone/four-phone Wi-Fi finish/rematch/interruption and human review.
- [x] Commit the implementation checkpoint as `Phase 5: cooperative polish and release`; full Phase 5 acceptance remains open and nothing is published.

The commit excludes the preexisting `project.godot` physics-tick edit and unrelated reference video/pack documents. The earlier uncommitted-checkpoint note above is historical. This handoff does not start another phase or close the outstanding hardware/human gates.

## Phase 5 continuation: Android startup diagnostics and smoke-fixture reliability

The user's `Next` instruction continues the outstanding Phase 5 validation. Added
`--startup-only` to `tools/run_android_checks.py`: it checks Android Title telemetry
and visible rendering without installing the touch helper or entering gameplay.
`--output` puts an attempt's logs, captures, results and configuration-restoration
record in its own directory. A boot failure now records its exception and a
failed result even when the emulator never enters the test body; an older pass
cannot survive as the current outcome. Reports label startup-only scope explicitly.

Seven device-free QA-runner tests pass, including three new cases for evidence
isolation, excluding touch/gameplay from startup-only mode, and replacing a stale
pass with the real failed-boot reason. The existing physical-serial, blank-frame
and configuration-restoration checks remain intact. Required GUT rerun passes
**85 tests / 7,807 assertions / 21 suites**: `.bin/phase5-next-tests.log`.

A bounded read-only host-GPU diagnostic was stopped under heavy laptop memory
pressure (248,676 KiB available in one sample). Boot-ready appeared during
shutdown and APK installation could not complete, so it supplies **no new app
rendering or gameplay acceptance evidence**. The prior failed-render results
remain separate. The emulator's process tree was stopped and its configuration
restored. All four original AVD userdata/encryption image hashes and lengths,
plus configuration bytes, remain unchanged: `.bin/phase5-next-preservation.json`.
Only six positively identified disposable overlays from our previous 19:29 and
current 20:21 sessions were removed after shutdown, with path/time/backing-image
records in `.bin/phase5-next-*-cleanup.json`. Older unrelated overlays and user
applications were preserved. No phone, SDK, router or firewall was changed.

The required LAN rerun exposed two smoke-fixture problems. First, incoming
snapshots restore the normal control adapter's `enabled` flag, so its idle
physics callback could overwrite the fixture's sustained seat input. The fixture
now disables that adapter's physics processing while retaining the normal
`Net.submit_input` path. Second, a one-shot spoof sent over `unreliable_ordered`
could be superseded before host validation. The original forged-thrust probe is
retained, with an additional reliable forged-release probe to exercise the same
host ownership validation deterministically. Existing gas/movement/height,
ownership, sustained-force, release/expiry and save assertions are unchanged;
reports now include the three observed gas/movement/height flags. These changes
are confined to `tools/net_smoke_peer.gd`; game networking and physics are unchanged.

Required LAN validation after both fixture fixes passes **128 checks**:
two-peer crew 41, four-peer crew 75, unreachable host 6 and abrupt host loss 6.
Final evidence: `.bin/phase5-next-net-final.log` and
`.bin/phase4-validation/20261105-203340/`. The earlier failed runs remain under
`.bin/phase4-validation/20261105-202651/` and
`.bin/phase4-validation/20261105-202951/`.

No runtime game files or export presets changed in this continuation, so the
previous signed APKs and embedded Windows candidate were retained. The testing
guide now correctly separates the committed implementation checkpoint from
pending publication. Android rendering, physical ARM execution, two phone
performance classes, wireless co-op and human playtests remain open.

### Gate 5 follow-up status

- [x] Required GUT: 85 tests and 7,807 assertions pass.
- [x] Required LAN smoke: all 128 checks pass after fixture repairs, with original assertions retained.
- [x] Seven QA-runner regression tests; separate startup-only reports and preserved prior evidence.
- [x] Original AVD images/configuration, unrelated work and signing material preserved.
- [ ] Accepted Android rendering and ARM execution; this emulator diagnostic does not close either gate.
- [ ] Two physical phone classes, touch/Back/Home/haptics/heat, airplane-mode campaign/save, two/four-phone Wi-Fi and human playtests.
- [ ] Publication decision; full Phase 5 acceptance remains open.
