# Toot Tubes: Implementation Plan v3

Revised 2026-11-01. Target: Android portrait, Godot 4.7.2 standard/GDScript, Compatibility renderer.

**Status (2026-11-05): Phases 1-4 implemented with laptop validation.** Five cooperative courses, offline progression and two-to-four-peer host-authoritative shared-ring LAN are available. Human/device and physical airplane-mode/LAN checks remain deferred under the user's laptop-first instruction; Phase 4's physical-phone gate stays open. See `docs/PROGRESS.md`, `docs/PHASE4_TESTING.md` and `docs/UI_LOGIC_BOUNDARIES.md`. Phase 5 has not started.

The user has replaced the earlier competitive design with **one shared swim ring carrying up to four cooperating riders**, varied curved/elevated courses, repeated directional thrust and many obstacles. This document is the authoritative implementation plan; [ENVIRONMENT_SPEC.md](ENVIRONMENT_SPEC.md) defines geometry, movement and hazard behavior. User instructions take precedence. The old HTML sample is a visual reference, not a source of mandatory gameplay numbers. Previous plans are preserved under `docs/archive/` as historical material only.

## 0. Product rules

- Exactly one physical swim ring/raft per active run; up to four occupied rider slots on that same ring. No competing ring, opposing team, rival bot or per-player finishing place.
- The cooperative objective is to get the whole crew through the course and across the finish. Falls reset the shared ring to its checkpoint; the clock continues.
- Each occupied rider slot supplies independently aimed, repeatable thrust. The ring responds to the combined forces, momentum, gravity, water support and obstacle contacts.
- Proposed controls for our adaptation: aim with a virtual stick/drag and **hold to fart**, release to stop; a short press gives a short burst. This is a design choice, not a verified button mapping from the reference video. Remove the fixed one-impulse-per-water-tap model as the primary control.
- Use per-rider continuous gas capacity, drain while thrusting and recovery while resting. Tune these values in Phase 2; the old three charges/1.5-second refill and 7/9-unit impulse are not authoritative for the new mechanics.
- Riders occupy identifiable positions around one inflatable rim with a central platform. Preserve individual names, outfits, hats and gas colors. All riders share the ring's physical motion; their meshes do not simulate independent vehicles.
- Routes must combine rounded bends, S-curves, hairpins, narrow ledges, wide pools, ascents, descents and dips. A sequence of sideways-offset straight boxes does not satisfy the requirement.
- Original course layouts, artwork, riders and audio. Preserve the colorful sky-waterpark feeling without copying commercial characters, branding or exact levels.
- Keep the existing five-level offline progression/save requirements. For compatibility, timed challenges and stars may retain the existing timer-based formula; times must be retuned after the new movement works. Timers are a cooperative challenge, never a race against another ring. A no-time-limit practice fixture is required for physics tuning.
- Full up-to-four-human LAN co-op is required in Phase 4, not an optional 2-versus-2 extension. Phase 2 proves four independent rider controllers locally; it must not claim four-phone acceptance.

### Course exploration and campaign direction

These are original design targets, not five levels to implement in Phase 2.

| Course | Environment and route | Obstacle combinations |
|---|---|---|
| 1: Sky Garden | Launch pool, S-bends, narrow curved bridge, climb/crest, broad hairpin, descent/dip and recovery pools | Bumpers, current, sweeper, swinging mallet, timed spiked crossbar and open holes |
| 2: Canyon Switchbacks | Coral cliffs, hairpins, alternating narrow/wide passages, descending curves | Paired mallets, sliding gates, boulders, exposed ledges |
| 3: Cloud Bridges | Suspended winding bridges, staggered elevation, steep but controllable crests and dips | Moving spiked crossbars, crushers, falling gaps, safe waiting bays |
| 4: Spiral Springs | Curved climbing route, downhill spiral, broad whirlpool pools, branch reconnects | Cross-currents, whirlpools, rotating sweepers, timed gates |
| 5: Festival Summit | Mixed climbs, sharp curves, fast descents and narrow finish approach | Combined hazards with fair openings and recovery areas |

Increase difficulty through route geometry, timing and combinations, not only shorter timers. Distinguish decorative floating islands, solid bumpers and dangerous holes visually.

## 1. Constraints and retained foundation

- Godot standard build, typed GDScript with tabs, Compatibility renderer; no new engine, C#, GDExtension or heavy simulation dependency.
- Preserve Fredoka, theme, navigation, safe-area rules, avatar data, progress/unlocks, user settings, GUT and both test runners. Never overwrite the real save during tests.
- Mesh art stays procedural. Primitive meshes for riders/scenery; generated ribbon meshes and simplified matching collision for curved courses. Shared materials, MultiMesh repeats, CPU particles, no real-time shadows.
- Targets: 60 FPS on a mid-range phone, at least 30 FPS on a low-end phone, under 150 visible draw calls and 60k visible triangles, debug APK under 60 MB. Measure the four-rider/worst-obstacle case. Desktop/headless results do not establish phone performance.
- Every moving gameplay obstacle samples `Level.race_time`; deterministic motion parameters. Cosmetic cloud drift may use a separate visual clock.
- Keep secrets, keystores, `.bin/`, `.godot/`, exported APKs and device credentials out of Git. Credit assets.
- The lab PDF is still unavailable. Preserve the existing R1-R10 mapping as provisional; do not claim that a competitive winner requirement has been verified against the original rubric.

## 2. Contracts and migration boundary

### Retained and new files

Retain `GameState`, `Audio`, `Net`, `Level.race_time`, `LevelDefs.LEVELS`, save APIs and existing UI routes. Add `SwimRing.gd/.tscn`, `RiderModel.gd/.tscn`, `CrewInput.gd`, `CrewBrain.gd`, `CoursePath.gd`, `RingPhysicsProfile.gd`, `CourseHazard.gd`, and appropriate `scripts/obstacles/` scenes/scripts. `LevelBuilder`, camera, HUD, course data and water shader migrate to the new path/surface contract.

`FloatPlayer.toot_toward`, legacy `AvatarModel` and old course data remain available to existing fixtures until the replacement passes equivalent checks. The playable scene must switch to exactly one `SwimRing` at the Phase 2 cutover; do not run both architectures together. Retire legacy code only after references and replacement coverage have been checked.

### Crew and save data

- `GameState.save_version`: new schema version; load old saves without losing unlocks, best times/stars, settings or avatar. Back up the original before the first migration write; migration is idempotent.
- `GameState.local_profiles`: up to four sanitized avatar dictionaries. Existing `avatar` becomes profile 0 and remains a compatibility alias during migration.
- `GameState.crew_slots`: four entries describing `empty`, `local`, `assist` or `peer`, a profile reference and runtime owner. Never persist transient network peer IDs.
- Ring appearance is shared. Preserve legacy per-avatar `float_style` data; use the selected leader's style as the initial shared style instead of discarding saved choices.
- `last_result` represents cooperative success/failure, level, elapsed time, stars and recoveries. No first/second-place result; keep a deprecated legacy field only if required to read old data.
- Offline prototype defaults to one local rider with configurable cooperative assistants. Assistants occupy seats in the same ring, use the same gas/thrust rules and never become opponents. Human co-op capacity is up to four; four-person same-phone controls are not a requirement.

### Shared-ring API (target, not existing code)

```gdscript
const MAX_RIDERS: int = 4
var gas: Array[float]                 # one capacity value per slot
var seat_control: Array[String]       # empty, local, assist, peer
var simulate: bool                   # host/offline simulates; guests interpolate
func set_rider_avatar(seat: int, avatar: Dictionary) -> void
func set_thrust_input(seat: int, direction_world: Vector3, strength: float, held: bool) -> void
func release_all_inputs() -> void
func add_gas_all(amount: float) -> void
func enter_fall() -> void
func respawn_at_checkpoint() -> void
```

Validate slot bounds, occupancy, finite directions, strength and run state. Input sets desired state; force and gas drain run at the fixed physics step. Per-seat effects emit from the rider in the opposite direction to its push. All four seats may act in the same tick.

### Course and hazard contract

- `CoursePath` owns a 3D curve with position/tangents plus width and banked-surface samples. Route distance `s` is baked arc length, never `-position.z`.
- `sample(s)` yields position, tangent, lateral vector, surface normal and width. `project(point, previous_s)` searches the correct local route section to avoid jumps at nearby bends/overpasses. `surface_at(point, previous_s)` returns valid support, height, normal and local flow, excluding holes and outside edges.
- Place obstacles, beans, checkpoints, holes and finish by route distance plus lateral offset. Use the same sampled geometry for visible water, hazard placement and physics boundaries.
- Hazards declare `type`, `s`, `lateral`, parameters and an explicit response: `push`, `tip`, `fall` or `reset`. A spike-shaped mesh alone does not define its response.
- Ordered checkpoint/finish crossings prevent shortcuts, wrong-way completion and progress jumps across a hairpin. A checkpoint stores a full safe transform, route distance and local surface orientation.

## Phase 1: Four-rider foundation, avatar preview and safe migration

**Goal:** adapt the existing foundation to one ring with up to four occupants while preserving saves and working navigation. This phase does not implement the new moving-ring physics or LAN networking.

### Files expected to change

`autoload/GameState.gd`, `scripts/AvatarData.gd`, shared UI/creator scripts and scenes, new `RiderModel` and shared-ring preview, tests for save migration/crew/avatar/UI, `docs/GDD.md`, `docs/PROGRESS.md` and credits if assets change. Touch project settings/theme only where needed. Keep `Audio` and `Net` compatible.

### Tasks

1. Audit current Git state, saves, scenes and tests before editing. Retain the portrait viewport, 60 Hz physics, touch/mouse emulation, Android Back and existing setup/test tools. Do not reinstall working dependencies.
2. Add four-slot crew and local-profile data with schema migration, validation and safe defaults. Empty slots apply no force and render no rider. Assign each occupied slot exactly once.
3. Separate the rider mesh from the inflatable ring. Build one original ring with a central platform and four clear rim anchors. Preview 1, 2, 3 and 4 occupants; avatars must remain recognizable without overlap.
4. Extend the avatar creator to edit a selected local profile. Keep name length, all existing appearance options, Randomize, Save and Back. Preview the edited rider on the shared ring and label the selected slot. Preserve saved individual float-style choices as migration data.
5. Add a small crew setup/preview screen reachable from Play, with occupied/empty slot labels, profile selection and assistant toggles for offline development. The Phase 1 screen must clearly label shared-ring play as pending until Phase 2; keep the existing prototype accessible as such during migration.
6. Keep Title -> Avatar Creator on first use -> Main Menu -> crew/mode entry navigation. Every screen has usable Back behavior. Do not advertise rival racing, 2-versus-2 or separate player floats.
7. Keep touch targets at least 120 px, body text at least 28 px and the top 80 px safe area at 720 x 1280. Show four names/statuses without cramming four full control panels onto a phone.
8. Update the GDD and progress record with separate columns for implemented baseline versus v3 target. Existing 26-test results must not be relabeled as proof of this phase.

### Automated acceptance

- Old saves migrate twice without losing data or duplicating profiles; missing/corrupt/new fields are sanitized; use disposable save files and retain existing progression/star boundary coverage.
- Four profiles round-trip independently. Reject a fifth slot, duplicate ownership and invalid profile references. `avatar` and profile 0 remain consistent during compatibility.
- Preview 1/2/3/4 riders and all appearance options without overlapping anchors, invalid nodes or leaked resources. Exactly one ring mesh assembly.
- Creator edits affect only the selected profile; cancel/back does not overwrite another profile. First-launch and navigation smoke tests remain passing.
- Run `tools/run_tests.sh`; keep existing coverage and explain any intentional API migration rather than deleting tests to obtain a pass.

### Gate 1

- [x] Automated migration, crew, avatar and scene checks pass.
- [ ] F5: create/edit/save profiles, switch slots, preview four occupants on one ring.
- [ ] Restart: original avatar/progress and edited profiles persist; Back works.
- [ ] Mobile layout remains readable; no unsupported multiplayer claim.
- [x] Update progress with evidence; commit `Phase 1: four-rider shared-ring foundation`.

Stop at this gate. Do not begin Phase 2 without the user's execution instruction.

## Phase 2: Shared-ring physics, curved sky course and obstacle prototype

**Revision 2026-11-01: replace the playable environment. Implemented 2026-11-02; human play and phone acceptance remain pending.**

**Goal:** pressing Play must lead to a visibly new, playable 3D sky waterpark with one shared ring carrying the selected 1-4 riders. The course must visibly wind, narrow, climb and descend, with repeated directional fart thrust and physical obstacles. Ship one complete original course plus an accessible practice route. A crew preview, background recolor, isolated geometry demo or unchanged legacy Level 1 does not complete this phase.

### Authorized Phase 2 feedback revision - 2026-11-02

Aim also moves each rider around the rim while faces remain outward. Preserve stable seat IDs, prevent overlap, apply forces at the moving anchors and show red clothed-rear feedback during actual thrust. Keep hull batching separate from moving rider parts. Improve the shared water with lit shading, small physical waves, shore/hole foam, wakes and spray; shader displacement and buoyancy use the same `WaterStyle` and paused run clock. Reuse the same profiles/systems for later environments. Validate crew-size solvability and performance again, rebuild a versioned APK, and leave human/phone gates pending until actually reviewed.

### Starting point and delivery boundary

- Reuse completed Phase 1 (`0961604`): `CrewData`, four saved profiles, validated seats, `RiderModel`, leader style, save-version-2 migration and crew navigation. Do not rebuild those systems or discard existing saves.
- `SharedRingPreview` is presentation only. Build a moving `SwimRing` using the same rider appearances/seat layout, with a shared visual component where practical; do not treat preview rotation as gameplay physics.
- Use real 3D in the existing Godot Compatibility renderer. The target is the reference's elevated waterpark composition and cooperative movement, with original layouts and art. Exact commercial levels and unknown physics constants are not requirements.
- Internal steps below belong to this single phase. Once Phase 2 execution is authorized, continue through playable integration and validation; a geometry milestone is not a separate approval gate or a reason to stop.
- Deliver a visibly changed main Play route, a new versioned APK, fresh captures and a test report distinguishing automated, rendered and real-phone evidence. Four-phone networking and the remaining four campaign courses stay in later phases.

### What the player must see

| View / action | Required visible result |
|---|---|
| Main Menu -> Play -> Crew Setup | Saved crew is shown; **Start Sky Garden** launches the new course and **Practice** launches the geometry/physics route |
| Opening overview | A winding suspended turquoise channel, coral/orange cliff sides, green rims, clouds below, a high section and a lower section visible together |
| Normal play camera | All occupied riders share one rim/platform; the upcoming bend or obstacle is readable; camera follows route height and heading smoothly |
| Steering and farting | Aimed short bursts and held jets, independent gas per rider, drift after release, countersteering and recoverable tilting |
| Orange-rimmed opening | An actual open hole with depth and no water/support across its center; entering causes a whole-crew fall and checkpoint recovery |
| Finishing | One cooperative success/timeout result; no opponent ring or first/second place |

### Playable Sky Garden route

These are required connected sections of Level 1, not just separate test scenes. Build an original layout with the same route data driving visible geometry, collision, hazards and progress. Let `D` be the final physical ring diameter; tune clearances after matching the visible hull and riders.

| Sequence | Geometry and environment | Gameplay and readability |
|---|---|---|
| 1. Cloud launch pool | Wide basin above clouds with room to rotate the complete ring | Safe aim/hold/release tutorial and crew gas display |
| 2. Garden S-bends | Two rounded bends in opposite directions; changing heading clearly visible | At least two bumpers and a current zone; room to countersteer |
| 3. Narrow sky bridge | One continuous curved narrowing with a clearly marked exposed-edge section | Precise steering; safe approach and checkpoint before the higher-risk route |
| 4. Climb and crest | Sustained uphill, a rounded crest and an elevated pool | Body gains at least one `D` of height over the climb; readable sweeper and waiting space on the pool |
| 5. Canyon return | A broad hairpin turning at least 150 degrees, then downhill into a dip | Distinct upper/lower banks; no progress jump to the adjacent arm; checkpoint outside hazard sweeps |
| 6. Obstacle garden | Wider recovery pools separated by curved passages | Swinging mallet, timed spiked crossbar and at least two open holes, spaced so a safe line or waiting window exists |
| 7. Shared finish | Clear straightening into a finish basin | Entire ring crosses the ordered finish; save the cooperative result once |

Level 1 therefore includes an S-bend, hairpin, curved narrow passage, climb, descent and dip in the actual playable route. Keep short straights as recovery spaces, not as the dominant layout. Use the existing width/slope limits in `ENVIRONMENT_SPEC.md`; do not meet these requirements by shrinking the ring, scaling only the scenery or faking elevation with camera motion. Practice repeats each shape with reset points and no time limit, and remains reachable from the menu.

### Files expected to change

New `SwimRing`, `CrewInput`, `CrewBrain`, `CoursePath`, `RingPhysicsProfile`, `CourseHazard`, obstacle scripts/scenes and practice fixture; migrate `Level`, `LevelBuilder`, `LevelDefs`, camera, HUD, water/hole support, checkpoint/finish and pickup integration. Update `Screen.gd`/Crew Setup and mode routes to launch the new level and practice mode. Reuse Phase 1 rider/profile contracts. Extend meaningful physics/input/course/solvability tests and verification tools; update testing guide, screenshots, export version and progress. Keep the old course explicitly isolated for regression if needed; preserve unrelated user changes.

### Implementation order

1. **Visible environment first:** generate the connected Sky Garden route above and a practice fixture from the same path/mesh pipeline. Build water, rims, deep cliff sides and matching collision from sampled 3D frames. Inspect an overview and play-camera captures before tuning gameplay. Confirm the S-bend, hairpin and upper/lower route sections are unmistakable. Weld seams and reject self-intersections. This milestone must flow into playable integration within Phase 2.
2. **One physical ring:** one `RigidBody3D` with a stable compound/convex collision shape and four rider anchors. Enable vertical movement, yaw, pitch and roll. Replace the globally locked water plane with gravity plus bounded, damped water support at several points. Support must disappear outside the channel and over holes. No teleporting or visual-only tilt to fake slope traversal.
3. **Repeatable rider thrust:** implement held input with per-step force and continuous per-seat gas consumption. Short tap, long hold and repeated presses must produce distinct, measurable durations of thrust. Release stops thrust immediately; momentum continues. Apply forces at appropriate rider attachment points, allowing steering/torque rather than forcing every push through the center.
4. **Direction and strength:** camera-relative aiming converted into world/surface directions; normalize/clamp valid input. Riders can aim beyond a purely radial-to-center vector so turning is physically possible. Transform anchors with the ring's orientation. Sum all seats in the same fixed step; tune 1/2/3/4-occupant behavior without multiplying maximum speed unfairly.
5. **Input lifecycle:** drag-to-aim plus hold-to-thrust on mobile; mouse/keyboard equivalents on desktop. Track finger IDs and handle touch release, drag outside the control, app focus loss, Back, pause, countdown, fall and finish. These must clear held state; UI interaction never starts or leaves thrust running.
6. **Four-controller proof:** desktop test bindings and a deterministic scripted driver can control all four seats independently and simultaneously. Offline assistants are configurable, use the same gas/force rules and release inputs when disabled. A one-human setup must remain steerable without silently spawning another ring. No LAN implementation in this phase.
7. **Movement tuning:** retain drift and sideways motion, natural yaw, visible roll/pitch and recovery after moderate impacts. Use configurable damping, maximum speed/spin and support strength in one profile. Tune crest departure and landing, gravity on slopes and recovery from a tipped ring. Do not flatten the route to make tests pass.
8. **Playable Level 1:** integrate all seven connected sections in the route table, including the hairpin and height changes in the normal Play route. At least two safe checkpoints and a safe line or timed opening through each mandatory hazard. Place recovery/waiting areas before difficult transitions; no unavoidable collision immediately after spawning. Demonstrate solo and four-occupant completion.
9. **Minimum hazards now:** six working types in the playable course: bumper, rotating sweeper, swinging mallet, directional current, open hole and timed spiked crossbar. Include at least two bumpers, two holes and one of each other type. Exposed bridge edges additionally allow falls. Repeat hazards in practice for isolated response tests. Drive motion from `Level.race_time`. Crossbars and ordinary solid contacts push/tip; only explicitly marked reset zones reset immediately. Keep decorative spikes separate from functional hazards. This moves the crossbar into Level 1 instead of deferring its playable use to Phase 3.
10. **Fall and recovery:** the entire ring and crew drop together after losing support over a hole/edge. Clear every held input and hide water-only effects while unsupported. Restore a safe checkpoint transform with zero velocity and fresh input required; avoid a reset loop. Disable timed recovery after the run has already ended. A prolonged overturned/out-of-bounds state has a recovery route.
11. **Presentation:** use the retained bright palette, cliff depth, cloud batches and scenery, adapted to each path's height. A route-aware camera looks ahead around bends and changes height smoothly; it must not spin with every raft rotation or clip through a hammer/cliff. Two-second overview then countdown. Ripples sit on the local surface, jets stay attached to active riders, and gas/effects reflect actual held input.
12. **HUD and flow:** one crew progress indicator, up to four compact name/gas/active-seat indicators, cooperative goal, timer and Back. Explain aim/hold/release and shared recovery. Keep existing star/progress saving behind cooperative completion; no finishing-place UI. Tune the Level 1 time budget from playtests, not an assumed video speed.
13. **Cutover:** Main Menu -> Play -> Crew Setup -> **Start Sky Garden** must launch the new shared-ring scene using the saved crew and leader style. Provide **Practice** beside that entry, a clear message for an all-empty crew, and a choice of the locally controlled seat if several local seats are configured. Remove the Phase 1 pending-play message from completed entry points. Old solo scenes may remain development/regression fixtures but must not be the default or only playable option. Preserve existing saves and historical evidence; retire old assumptions only after equivalent replacement checks. Rebuild a clearly versioned debug APK and keep old exports separate.

### Smoothness and evidence requirements

- Keep a fixed physics step and interpolate visible movement. Avoid rebuilding meshes/materials or allocating new particle nodes during sustained thrust. Pool jets and use shared materials/MultiMesh repeats; reduce distant decorative cost before reducing route variety or required crew capacity.
- Profile the busiest visible obstacle section with all four riders thrusting, including camera movement, contact/tilt and fall/recovery. Report frame-time distribution, visible draw calls and triangles, device/build and quality setting. Existing Phase 1 preview counters do not establish gameplay performance.
- Capture the old course baseline before cutover, then the new overview, S-bend, narrow bridge, uphill/crest, hairpin/descent, obstacle contact and hole fall/recovery at the same portrait resolution. Include one uninterrupted gameplay recording showing repeated thrust, a real bend, height change and a physical hazard response. Label scripted versus human input.
- Validate route shape from both overview and normal camera. Screenshots establish visual change; logged physical height/orientation, collision tests and legal-input runs establish behavior. Neither substitutes for the other. Compare against the supplied video observations without claiming exact copied physics.

### Automated acceptance

- **Thrust:** only the selected seat drains; all four can act in one tick; invalid/empty slots, non-finite vectors and disabled states are rejected. Release stops force, not momentum. Gas cannot become negative or create endless depleted sputtering. Equal simulated hold durations give comparable results at different render rates.
- **Torque/physics:** an off-centre non-radial push changes yaw; a symmetric forward pair reduces net yaw while accelerating. Real collision contacts produce tilt/push. The ring climbs, descends and crosses a crest with meaningful vertical motion; physics constraints do not lock these axes.
- **Input:** press/drag/release, simultaneous touch IDs, UI touches, focus loss and race-state transitions. No duplicate mouse/touch emission or stuck held thrust.
- **Geometry:** continuous path tangents and collision seams; both curvature signs in the S-bend; at least 150-degree hairpin; climb gains at least one ring diameter; descent and dip change the physical body's height. Assert these in the production Level 1 definition, not only in practice. Narrow sections still pass a ring with documented clearance. Correct local surface support and hole cut-outs on slopes. Progress stays on the correct branch at hairpins and nearby elevated sections.
- **Hazards:** deterministic transforms at the same shared time; mallet/sweeper contact response; current force in local flow direction; crossbar response matches its declared behavior; holes remove support. Checkpoint transform is outside every hazard's swept volume.
- **Recovery and finish:** all seats reset together; no gas drain/input during fall/countdown; no resume after timeout; ordered checkpoint/finish crossing; no shortcut completion across a nearby bend; save only one cooperative result.
- **Solvability:** fixed-step cooperative driver completes the real curved Level 1 in time for configured 1/2/3/4 occupied slots. It uses normal thrust/gas and contacts, never direct transform movement. Run several recorded deterministic seeds; log falls and contacts. Also exercise cooperative assistants. A scripted finish is not human feel acceptance.
- **Regression:** retain save/progression/avatar/navigation/bean coverage, adapting semantic assertions where contracts intentionally changed. Run `tools/run_tests.sh`, a complete rendered run, and the hole/edge/recovery verification against the new geometry.
- **Playable cutover:** drive actual menu actions from Play through Crew Setup to Start Sky Garden and Practice. Check the production scene contains one `SwimRing`, the selected 1-4 profiles/leader style, all required route sections and the six required hazard types. Empty-crew launch is blocked with a usable message. A passing legacy race or preview test is not Phase 2 acceptance.

### Gate 2

- [x] All new and migrated tests pass; exactly one physical ring in the playable scene.
- [x] F5 -> Play -> Start Sky Garden opens the visibly new environment with the saved crew; Practice is reachable; the old solo course is not the default.
- [x] Four occupants can contribute independently; short bursts, long holds and simultaneous pushes are visibly distinct.
- [x] Geometry fixture proves curves, S-bends, hairpins, narrow route, uphill, downhill and dip.
- [x] Playable Level 1 includes the seven connected sections, six working hazard types, at least two bumpers/two holes and two safe checkpoints.
- [x] Collisions can tilt and displace the ring; the crew can recover; falls reset everyone safely.
- [ ] Camera stays readable through curves, slopes and impacts; mobile controls release reliably.
- [ ] Complete a human-played run; record desktop frame times and worst four-rider scene draw/triangle counts.
- [ ] Install debug APK on a real phone; check sustained touch, portrait, frame pacing and heat. Do not substitute desktop measurements for this gate.
- [x] Before/after captures and uninterrupted gameplay recording demonstrate the environment and movement change; update progress/testing guide and commit `Phase 2: four-rider ring, curved terrain and cooperative obstacles`.

Automated/rendered checks support the checked items. Human control/camera feel and real-device acceptance remain open; desktop counters do not establish phone performance.

Gate 2 human/device checks remain recorded as open. The user subsequently authorized Phase 3 using laptop validation, with phone checks deferred; this does not relabel those earlier manual checks as passed.

## Phase 3: Five cooperative courses and complete offline flow

Execution authorized 2026-11-05 after the user accepted laptop-first checking and required UI/gameplay separation. Preserve the Section 0/2 rules, existing saves and shared physics; no Phase 4 networking or Phase 5 audio/release work.

Expand the five environment directions above with crushers, moving gates, boulders, whirlpools, spiked barriers and combined timing puzzles. Keep fair openings and safe respawns. Add Level Select/locks, cooperative Result/Retry/Next/Menu, Pause/Restart/Sound/Quit and contextual tutorials. Preserve offline saves, best times/stars, settings and airplane-mode play. Cooperative seat assistants replace opponent bots. Test all five courses with the same legal-input driver, ordered progression, checkpoint safety, different crew sizes and difficulty variety. No rival finish, rankings or separate opponent ring. Gate: all five courses, lose/retry, save/relaunch, airplane mode and manual phone tests. Commit `Phase 3: five cooperative courses and progression`.

### Delivered boundaries and files

`CampaignFlow` owns campaign application rules. `Level` coordinates simulation and supplies detached snapshots. `CrewHUD`, `scripts/ui/CampaignScreen.gd`, `RunPanels.gd` and `CrewPadView.gd` own presentation/layout. Keep stable input commands and signals when restyling UI. `CampaignCourses`, `LevelDefs`, Levels 02-05, shared path/hazard/rendering changes and the existing Sky Garden use the same movement/water profiles. `GameState` retains version-2 storage/migration contracts and reports write errors. Tests and verification scripts remain outside exports. Details: `docs/UI_LOGIC_BOUNDARIES.md`.

### Gate 3

- [x] All five original cooperative courses are playable; shared geometry/physics and no opponent ring.
- [x] Course locks, stars/times, cooperative Result/Retry/Next/Menu and final-course boundary.
- [x] Pause/Resume/Restart/Sound/Quit and contextual hints; UI changes use the documented presentation interfaces.
- [x] Lose/retry and complete ordered campaign through actual menu actions.
- [x] Save/relaunch verified in a fresh Godot process; profiles/settings and progression preserved.
- [x] Required `tools/run_tests.sh`, all-course 1-4 rider/assistant solvability, safe checkpoints, collision/recovery and rendered laptop checks.
- [ ] Human feel/difficulty review and physical-phone touch/Back/performance acceptance; deferred by the user.
- [ ] Physical airplane-mode completion/retry/relaunch; source/build/offline laptop evidence is recorded separately.
- [x] Update progress/testing/architecture guides and commit `Phase 3: five cooperative courses and progression`.

Stop after Phase 3. Human/device checks remain open; Phase 4 needs a separate execution instruction.

## Networking and release requirements

These replace the old competitive tasks so future phases cannot restore the discarded racing design.

### Phase 4: Two to four phones on one shared ring

First validate host plus one guest, then host plus three guests; four-human co-op is required before Phase 4 is complete. Keep ENet port 7777 with `MAX_CLIENTS = 3`. Host simulates the one ring, hazards and cooperative finish. Guests submit owned-seat aim/thrust state; validate ownership, rate, strength, sequence and gas. Sync full position/orientation, linear/angular velocity, per-seat gas and run state; interpolate guests. Use input expiry plus explicit release so packet loss/disconnect cannot leave thrust stuck on. All seats see the same result; no per-peer winner. The lobby displays one ring with four slots. On guest loss, stop that seat's input and mark it vacant/assist according to the selected policy; host loss returns guests to Mode Select with a clear message. Retain timeout/unreachable-IP handling, rematch/leave, Android network permissions and online progress isolation. Net smoke covers 2 and 4 peers, unauthorized inputs, release loss and disconnects. Real 2-phone and 4-phone tests remain mandatory. Internet backend is optional only after working LAN co-op. Commit `Phase 4: four-player shared-ring LAN co-op`.

Implemented 2026-11-05 following the user's `next` instruction. UI lives in `scripts/ui/NetworkScreen.gd`; session transport/application rules in `Net`, validation in `NetInputGate`, interpolation in `RingReplication`. The selected guest-loss policy is vacant seat, without automatic assistants. See [Phase 4 testing](docs/PHASE4_TESTING.md).

### Gate 4

- [x] One host-authoritative ring, four owned seats, lobby readiness/load barrier and shared result.
- [x] Two-process then four-process full cooperative course completion; explicit/lost release, spoofed input, pause/rematch, guest/host departure and abrupt host loss.
- [x] Existing/new tests and `tools/net_smoke.sh` pass; offline files/profiles/progression remain isolated.
- [x] Rendered laptop lobby/result inspection and Android debug export/signature/permissions verified.
- [ ] Real two-phone and four-phone co-op, wireless interruption and touch/Back/performance acceptance; deferred by user.
- [x] Update progress and commit `Phase 4: four-player shared-ring LAN co-op`.

Stop after Phase 4. Its laptop implementation is complete; physical-phone acceptance is still pending. Do not start Phase 5 without a separate execution instruction.

### Phase 5: Polish and release

Original sustained fart loops with attack/release, impacts/falls/pickups/UI/music, saved audio/quality settings, reduced camera shake, four-rider title/icon, attribution, device profiling, release signing, README, test matrix and human playtests. Retain tests plus net smoke, offline/online error cases, portrait/back/accessibility, private signing keys and explicit release publication checks. Check performance with all four riders firing amid moving hazards on at least two phone classes. Do not cut the required fourth rider, route variety or cooperative physics to meet an old schedule; reduce decorative cost first. Commit `Phase 5: cooperative polish and release`.

## Lab traceability and validation status

| Existing requirement | Revised owner |
|---|---|
| R1 five distinct levels / R2 goal | Phase 3 campaign / Phase 2 cooperative goal |
| R3 results / R4 locked progression | Phase 3 cooperative results and level select |
| R5 persistent saves | Phase 1 migration, regression through all phases |
| R6 offline | Phase 2 local prototype, Phase 3 airplane-mode acceptance |
| R7 multiplayer / R8 errors | Phase 4 one-ring LAN co-op and error/disconnect tests |
| R9 APK/touch / R10 menus/audio | Early Phase 2 phone build, Phases 3-5 completion |

Exact rubric alignment awaits the original lab PDF. No unsupported claim that the video shows our gas formula, reset policy, hold controls or timer rules. Budget/schedule must be re-estimated after the Phase 2 movement prototype; previous two-day/three-day estimates are superseded.
