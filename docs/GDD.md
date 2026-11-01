# Toot Tubes - Game Design Document

Status: revised Phase 1 implemented 2026-11-01; manual phone acceptance pending. The app now has four saved profiles and a shared-ring crew preview. The playable course remains the labeled solo prototype with sky scenery and six holes. Revised Phase 2 is not implemented. These eleven headings remain provisional until the original lab PDF is supplied. The root IMPLEMENTATION_PLAN.md and ENVIRONMENT_SPEC.md are authoritative.

| Area | Implemented baseline | v3 target still pending |
|---|---|---|
| Riders and saves | Four profiles, validated seats/owners, profile-0 avatar alias, version-2 saves and original-file migration backup | Network-owned rider seats |
| Preview and navigation | One ring/platform with four separate rider anchors; profile editor, local/assistant/empty selection and leader style | Active assistant steering and four local controllers |
| Course and movement | Legacy solo Level 1 remains runnable | Shared rigid body, held gas, curves, climbs/descents and new obstacles in Phase 2 |
| Validation | Migration/crew/UI tests, rendered portrait checks, legacy regression | Real-phone review and revised gameplay acceptance |

## 1. Title and pitch

Toot Tubes: up to four friends cooperate on one inflatable swim ring through original curved, elevated waterpark obstacle courses, steering with coordinated fart thrust.

## 2. Audience and platform

Android portrait, Godot 4.7.2 standard/GDScript, Compatibility renderer. Desktop supports development and independent seat tests; actual four-human play is LAN co-op in Phase 4.

## 3. Core gameplay and controls

Target: aim, hold to thrust, release to stop, repeat as needed. Each rider has independent continuous gas and effects; their forces combine on one ring. Momentum, water resistance, gravity and collisions produce drift, yaw, pitch and roll. This control mapping is our design choice, not a verified mapping from the reference video. The current app's water taps and three discrete gas charges are legacy mechanics to migrate.

## 4. Goals, win and loss

The entire crew completes the course together. Timed challenges retain cooperative success/timeout and existing stars pending time-budget tuning; practice has no time limit. Falling resets the shared ring at a safe checkpoint while the timer continues. There is no rival ring, opponent finish or individual finishing place. Specific hazards explicitly declare push, tip, fall or reset behavior; not every spike means instant death.

## 5. Level progression

Five planned original courses: Sky Garden, Canyon Switchbacks, Cloud Bridges, Spiral Springs and Festival Summit. Mix S-bends, hairpins, narrow passages, broad pools, climbs, descents and dips. Vary scenery, flow and obstacle timing instead of repeating a straight lane with more hazards. Phase 2 builds the first course plus a geometry/physics fixture; Phase 3 completes the campaign, locks and results. Preserve saved unlocks/best times/stars and keep online results isolated from offline progression.

## 6. Modes and multiplayer

One ring in every mode. Offline offers a local rider and configurable cooperative seat assistants; the four-slot architecture also supports local development controllers. Phase 4 connects two to four phones to owned seats on the same host-simulated ring via ENet/LAN. Four-human co-op is required, not a separate competitive mode. Guest departure clears its held input; host loss returns guests safely to Mode Select. Networking remains unimplemented today.

## 7. Characters and customization

Four independently identifiable riders sit around a single rim and central platform. Preserve original procedural riders, skin/outfit/hat/toot choices and twelve-character names. Migrate existing avatar data into local profile 0 without deleting saved float styles. Ring appearance is shared. Empty slots have no rider or thrust. The creator previews up to four occupants while editing one selected profile.

## 8. Visual style and terrain

Colorful sky waterpark with turquoise water, orange/coral cliffs, green rims, clouds, foliage and floating scenery. Generate continuous 3D ribbon courses with matching collision; the water height and forward direction vary along the route. Use shared materials, primitive decorations, MultiMesh repeats and CPU particles. Original layouts/characters/artwork; no commercial asset copying. No real-time shadows.

## 9. Audio

Original thrust attack/loop/release hooks, impact/fall/pickup/UI effects, optional credited CC0 music and saved audio controls. The existing Audio autoload remains a silent stub; production audio belongs to Phase 5.

## 10. Interface and accessibility

Retain Title, first-use Avatar Creator, Main Menu and Back navigation. Phase 1 adds four-slot crew preview/profile management. Phase 2 adds aim/hold controls, compact rider gas/status labels, one crew progress indicator, goal and timer. Keep minimum 28 px body text, 120 px touch targets and the top 80 px safe area at 720 x 1280. Do not place four full control panels on one phone. Handle touch release, focus loss and reduced-motion camera settings.

## 11. Technical plan and validation

Phase 1: four-rider foundation and safe save migration. Phase 2: one rigid-body ring, continuous thrust, curved/elevated terrain and working obstacle prototype. Phase 3: five cooperative courses and complete offline flow. Phase 4: four-human LAN co-op. Phase 5: polish and release. Tests separately prove save migration, multi-seat input, real torque/tilt/vertical motion, path projection, hazard response, group recovery and legal-input solvability. Desktop results are distinct from human/phone acceptance. Targets remain 60 FPS mid-range / 30 FPS low-end, under 150 draw calls and 60k visible triangles, APK under 60 MB; all require fresh measurement after migration.
