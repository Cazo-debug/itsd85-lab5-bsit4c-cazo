# Toot Tubes - Game Design Document

Status: Phases 1-3 implemented, updated 2026-11-05; laptop checks pass, human play and real-phone acceptance deferred. Main Play configures one shared physical ring; Courses opens the five-course offline campaign. Practice remains untimed. These eleven headings remain provisional until the original lab PDF is supplied. The root IMPLEMENTATION_PLAN.md and ENVIRONMENT_SPEC.md are authoritative.

| Area | Implemented baseline | v3 target still pending |
|---|---|---|
| Riders and saves | Four profiles, validated seats/owners, profile-0 avatar alias, version-2 saves and original-file migration backup | Network-owned rider seats |
| Preview and navigation | One ring with four rider anchors, saved profiles/leader style, active assistants and four local controller bindings | Four-phone LAN in Phase 4 |
| Course and movement | Five original courses, one physical ring, sustained gas, curved/elevated terrain, gates/crushers/boulders/whirlpools, progression and complete offline flow | Four-phone LAN and Phase 5 presentation/audio polish |
| Validation | 70 tests, 45 campaign solvability cases, ordered UI campaign, fresh-process reload and rendered portrait checks | Human play, real-phone and airplane-mode acceptance |

## 1. Title and pitch

Toot Tubes: up to four friends cooperate on one inflatable swim ring through original curved, elevated waterpark obstacle courses, steering with coordinated fart thrust.

## 2. Audience and platform

Android portrait, Godot 4.7.2 standard/GDScript, Compatibility renderer. Desktop supports development and independent seat tests; actual four-human play is LAN co-op in Phase 4.

## 3. Core gameplay and controls

Implemented: aim, hold to thrust, release to stop, repeat as needed. Each rider has independent continuous gas and effects; their forces combine on one ring. Momentum, water resistance, gravity and collisions produce drift, yaw, pitch and roll. This control mapping is our design choice, not a verified mapping from the reference video. The old water-tap/three-charge mechanic is isolated in legacy regression fixtures.

## 4. Goals, win and loss

The entire crew completes the course together. Cooperative success/timeout uses the retained star thresholds and per-course budgets checked with 1-4 riders; human difficulty review is deferred. Practice has no time limit. Falling resets the shared ring at a safe checkpoint while the timer continues. There is no rival ring, opponent finish or individual finishing place. Ordinary solid hazards push/tip; holes and exposed edges remove support.

## 5. Level progression

Five implemented original courses: Sky Garden, Canyon Switchbacks, Cloud Bridges, Spiral Springs and Festival Summit. Routes mix bends, narrow passages, broad pools, climbs, descents and dips. Vary widths, flow and obstacle timing. Phase 3 adds course locks, cooperative results, Retry/Next/Menu, pause/restart/sound/quit and contextual hints. Existing unlocks/best times/stars and version-2 saves are preserved; online results remain isolated from offline progression.

Phase 2's revised delivery requires those core shapes in playable Sky Garden itself: launch pool, garden S-bends, narrow sky bridge, climb/crest, canyon hairpin and descent, obstacle garden and shared finish. Six playable hazard types include the spiked crossbar alongside bumpers, current, sweeper, mallet and holes. Start Sky Garden and untimed Practice must be reachable through the existing crew screen; a changed preview does not count as the new environment.

## 6. Modes and multiplayer

One ring in every mode. Offline offers a local rider and configurable cooperative seat assistants; the four-slot architecture also supports local development controllers. Phase 4 connects two to four phones to owned seats on the same host-simulated ring via ENet/LAN. Four-human co-op is required, not a separate competitive mode. Guest departure clears its held input; host loss returns guests safely to Mode Select. Networking remains unimplemented today.

## 7. Characters and customization

Four independently identifiable riders face outward and move around the shared rim when aiming, with spacing constraints. Their clothed rear panels turn red during actual thrust, then cool. Orbit positions drive the real force lever arms and supported weight shift. Preserve original procedural riders, skin/outfit/hat/toot choices and twelve-character names. Migrate existing avatar data into local profile 0 without deleting saved float styles. Ring appearance is shared. Empty slots have no rider or thrust. The creator previews up to four occupants while editing one selected profile.

## 8. Visual style and terrain

Colorful sky waterpark with turquoise water, orange/coral cliffs, green rims, clouds, foliage and floating scenery. Generate continuous 3D ribbon courses with matching collision; the water height and forward direction vary along the route. Use shared materials, primitive decorations, MultiMesh repeats and CPU particles. WaterStyle supplies shared wave parameters for rendering and buoyancy; wakes, foam and spray show interaction without full fluid simulation. Original layouts/characters/artwork; no commercial asset copying. No real-time shadows.

## 9. Audio

Original thrust attack/loop/release hooks, impact/fall/pickup/UI effects, optional credited CC0 music and saved audio controls. The existing Audio autoload remains a silent stub; production audio belongs to Phase 5.

## 10. Interface and accessibility

Retain Title, first-use Avatar Creator, Main Menu and Back navigation. Phase 1 adds four-slot crew preview/profile management. Phase 2 adds aim/hold controls, compact rider gas/status labels, one crew progress indicator, goal and timer. Keep minimum 28 px body text, 120 px touch targets and the top 80 px safe area at 720 x 1280. Do not place four full control panels on one phone. Touch release and focus loss clear held state. Reduced-motion settings remain polish work.

## 11. Technical plan and validation

Phase 1: four-rider foundation and safe save migration. Phase 2: one rigid-body ring, continuous thrust, curved/elevated terrain and working obstacle prototype. Phase 3: five cooperative courses and complete offline flow. Phase 4: four-human LAN co-op. Phase 5: polish and release. Tests separately prove save migration, multi-seat input, real torque/tilt/vertical motion, path projection, hazard response, group recovery and legal-input solvability. Desktop results are distinct from human/phone acceptance. Targets remain 60 FPS mid-range / 30 FPS low-end, under 150 draw calls and 60k visible triangles, APK under 60 MB; all require fresh measurement after migration.
