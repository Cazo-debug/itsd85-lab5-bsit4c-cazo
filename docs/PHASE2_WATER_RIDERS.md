# Phase 2 feedback: moving riders and responsive water

Updated 2026-11-02. Latest APK: **0.4.1-water-riders / code 7**.

## What changed

| Observed problem | Implemented behavior |
|---|---|
| Riders face the center | Faces point outward in crew preview and gameplay |
| Riders stay in fixed places | Aiming moves each rider around the rim; spacing prevents overlap |
| No readable thrust effort | The clothed rear panel warms red during actual firing, cools after release, and the torso leans |
| Flat dotted water | Lit turquoise water, view-dependent highlights, moving caustics, bank/hole foam and small surface waves |
| Weak sense of interaction | Speed-dependent wake, pooled spray, physical wave buoyancy, longer coasting and supported rider weight shift |
| Risk of inconsistent later environments | Shared WaterStyle, RiderOrbit and RingPhysicsProfile; course data chooses a profile rather than duplicating behavior |

The shared ring remains one rigid body. Moving rider angles control both visible positions and force lever arms. Stable seat IDs still identify profiles/controllers. Aiming alone moves the rider without spending gas; hold supplies the actual force. Riders remain outward-facing when another rider blocks further movement; force direction still follows valid world aim, allowing non-radial steering torque.

This is responsive stylized water with bounded surface physics. The fine normal ripples, caustics and wake are visual; the two main wave components drive both rendered displacement and physical support. Holes and exposed edges remain unsupported. The shared Level.race_time clock freezes water and moving hazards during pause. Previously emitted particles dissipate naturally after release.

## Run and compare

Press **F5 -> Play -> Start Sky Garden**. Desktop: WASD aims/moves the selected rider and Space holds thrust. Touch: AIM moves the rider and HOLD supplies thrust. Independent seat bindings remain IJKL/U, TFGH/R and arrows/Enter.

Install `export/TootTubes-phase2-water-riders-debug.apk`, not the earlier sky-garden build. Same Android package; code 7 is newer than code 6, so a compatible signed upgrade can preserve saved profiles/progress. APK signature and packaged resources were verified; installation on a real phone is still pending.

Compare `docs/screenshots/phase2_v3_s_bend.png` with `phase2_feel_course_s_bend.png`. Focused captures are `phase2_feel_outward`, `orbit`, `thrust`, `wake` and `released`. The updated full-course captures use `phase2_feel_course_*`, and new fall/contact captures use `phase2_feel_hole_fall`, `hole_recovered`, `edge_fall` and `mallet_contact`.

Uninterrupted scripted four-seat demonstration: `export/TootTubes-phase2-water-riders-demo.mp4`. It uses ordinary per-seat input, gas and collisions after spawn. Focused pose/contact fixtures deliberately place the hull; they are not claimed as legal-input completion evidence.

## Reuse in later courses

- Keep `CoursePath`, `CurvedCourse`, `SwimRing` and `RiderOrbit` shared. Use new route/width/hazard data for new environments.
- Supply an optional WaterStyle Resource as `definition["water_style"]`; otherwise every course receives the same default. Palette, two analytic wave vectors and amplitude feed both shader parameters and buoyancy queries. Render-only small ripples must not become a separate support equation.
- Keep movement, orbit speed, gas, damping and weight-shift settings in RingPhysicsProfile. Do not reintroduce locked Y or different controls for each environment.
- Rider poses/colors and jets use actual firing state. Rebatch static hull/body geometry only when appearance changes; do not rebuild it during motion. Moving anchors update at physics steps for interpolation.
- Future LAN must replicate authoritative rider angles with the ring state and sanitize seat aim. No networking was added in this revision.

## Checks

The 55-test suite includes every previous assertion plus outward facing, no-overlap orbit, aiming without gas use, red tint/decay, analytic wave gradients, shader/profile agreement, paused water clock, hidden wake during falls and physical wave-driven hull movement without thrust.

Full legal-input seed 4 completion: one rider 132.88 s, two 120.85 s, three 114.17 s, four 110.88 s. All collected ten beans, crossed both checkpoints and finished without recovery. Contacts were 1/1/2/1. A separate seed 5 rendered recording completed in 110.90 s, one contact, zero recoveries and about 14.69 degrees peak physical tilt. A deliberate mallet fixture reached about 41.98 degrees and hole/edge fixtures recovered the whole crew twice.

Rendered budgets: the focused four-rider fixture reached 106 draw calls / 55,200 visible primitives; the full recorded course reached 80 / 56,402. Recording overhead is excluded from normal frame pacing claims. Fresh non-recorded timings and build verification are recorded in PROGRESS.md. Targets remain under 150 calls, 60k visible triangles and 60 MB APK. Phone FPS/heat acceptance is pending.

Run the focused fixture:

```powershell
& .\.bin\Godot_v4.7.2-stable_win64_console.exe --path . --fixed-fps 60 --script tools/verify_water_riders.gd
```

Run a full recording into a fresh directory:

```powershell
& .\.bin\Godot_v4.7.2-stable_win64_console.exe --path . --fixed-fps 60 --script tools/verify_sky_garden.gd -- --crew=4 --seed=5 --capture --capture-prefix=phase2_feel_course --record --record-dir=.bin/water-riders-record
ffmpeg -framerate 30 -i .bin/water-riders-record/%05d.jpg -c:v libx264 -crf 20 -pix_fmt yuv420p -movflags +faststart export/TootTubes-phase2-water-riders-demo.mp4
```

Use a fresh recording directory; stale frames from an earlier attempt must not be encoded. The full-run capture window must stay focused; focused collision/pose fixtures explicitly resume themselves after desktop focus loss. Ordinary focus-loss pause is separately tested.

## Human acceptance still open

- [ ] Confirm outward facing, aim-driven movement and spacing feel right on the phone.
- [ ] Check red tint appears during actual firing and clears after release, pause, depletion and recovery.
- [ ] Check water/wake readability, bends, slopes, impacts, camera and hole recovery in a human-played completion.
- [ ] Install code 7 and test two-finger touch, Back, save upgrade, sustained frame pacing and heat.

Gate 2 remains open for these human/device checks. This revision does not start Phase 3.
