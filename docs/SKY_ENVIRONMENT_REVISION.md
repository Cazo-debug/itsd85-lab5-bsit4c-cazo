# Phase 1 and 2 review: sky environment

Approved scope, 2026-11-01: **Sky environment first**. Follow-up correction: the six circular orange areas are holes, with falling and checkpoint respawn now implemented. The supplied
`toot-tubes-codex-pack/` is reference material. Its shared-ring mechanics and
later-phase instructions are not authorization to replace the existing gameplay.

## Phase review

| Area | This revision | Still pending from the v2 pack |
|---|---|---|
| Phase 1 | Keep saves, navigation, avatar choices and tests; introduce the sky palette and a floating-pool avatar preview | Two-rider model, second avatar, team-assigned ring colors |
| Phase 2 environment | Segment-sized water, 40 m striped cliffs, green inner rims, closed turn joints, gradient sky, clouds, floating islands, balloons, umbrellas, checker strips, finish arch and six open holes | Shared-ring integration for holes |
| Phase 2 presentation | Two-second course overview, three-second countdown glide, reference follow camera and shared lighting | Two-seat HUD and buddy tutorial |
| Phase 2 gameplay | Existing solo float, eight beans, two checkpoints, finish/save and 75-second timer; holes now trigger a 0.9-second drop and checkpoint respawn | Shared-ring physics, computer buddy, duo input and revised 12-bean layout |

This completes the environment revision, **not the entire v2 Phase 2 gate**.
Phase 3 obstacles, rivals and additional courses have not started.

## Rendering choices

Use native low-poly Godot 3D with the Compatibility renderer. Repeated scenery
uses MultiMesh batches, materials are shared, and every mesh has real-time
shadows disabled. Clouds have 128 low-poly lobes in one draw batch. Nine floating
islands and their umbrellas share geometry batches. Three balloons bob gently.
Decorations have no collision and do not affect gameplay or race timing.

The sample's bank thickness (3.2 m), depth (40 m), top (0.9 m), rim dimensions,
water colors/formulas and camera framing are adopted. The existing Level 1 route
is retained; the supplied reference depicts Level 3. Water is tessellated roughly
every 1.5 m rather than drawing one oversized ocean. All segments share one
water material and use world coordinates to keep the waves continuous.

Shader adjustments: use ascending `smoothstep` edges with negated height for
the same downward haze/sky gradient. Reversed edges in the supplied examples
have undefined GLSL behavior. Each course shares its own water material with hole uniforms and discard; the avatar preview retains uncut water. Shafts have no caps or solid collision.

The reference HTML remains a reference, with no browser/CDN dependency in the
game. Its folder is excluded from Android exports. Existing screenshots are
preserved; revised captures use `phase1_sky_*` and `phase2_sky_*` names.

## Check it

Press **F5 → Tap to start → Play → Play Level 1**. Watch the overview and camera
glide, then tap ahead. Use **Main Menu → Avatar** to see the revised preview.
See [PHASE2_TESTING.md](PHASE2_TESTING.md) for commands and phone installation.

- [ ] Avatar preview rotates and all options/save/back work.
- [ ] Sky, cliffs and clouds make the course feel elevated.
- [ ] Camera glide and steering feel comfortable on desktop.
- [ ] Banks contain the float at every turn; holes drop/respawn it; beans and finish still work.
- [ ] Install the sky debug APK and check portrait/touch/FPS on a real phone.

Automated evidence and measured rendering costs are recorded in
[PROGRESS.md](PROGRESS.md). Desktop performance is not phone acceptance.
