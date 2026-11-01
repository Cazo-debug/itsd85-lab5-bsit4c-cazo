> Pack mirror of ../ENVIRONMENT_SPEC.md. Root specification wins if copies diverge.

# Toot Tubes: Environment and Movement Spec v3

Revised 2026-11-01. **Target specification, not a statement of implemented features.** Read with [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md). Exactly one shared swim ring, up to four riders, cooperative completion. The video informs movement and composition; the earlier HTML sample no longer fixes the rules or numbers.

## 1. Evidence and deliberate adaptation

The supplied 40.4-second video shows four riders on one raft, rounded elevated channels, narrow exposed edges, swinging mallets, repeated rider jets, strong tilting, sweeping fast-water sections and ramps. It does not reveal exact input bindings, force constants, gas refill, buoyancy equations or death/checkpoint rules. Hold-to-thrust, continuous gas, assistants and recovery safeguards below are design choices for our original adaptation. Do not describe them as reverse-engineered facts.

## 2. Course geometry

Use metres and +Y up. Forward is the **local path tangent**, not a global -Z direction. The water surface is a curved ribbon at varying height, not one plane at y=0.

`CoursePath` contains a 3D curve with smooth handles, baked arc-length lookup, width keys and optional bank-angle keys. At each sample derive a stable tangent/lateral/normal frame; avoid frame flips at inflections. Generate water, rim, bank top, cliff sides and simplified collision from those same frames. Chunk long courses for culling and keep neighboring vertices/normals continuous. Do not fake an S-bend by overlapping rectangular planes.

Example target data shape (illustrative, not a finished level):

```gdscript
{
    "number": 1, "name": "Sky Garden",
    "goal_text": "Work together to reach the finish",
    "path": [
        {"position": Vector3(0, 0, 0), "in": Vector3.ZERO, "out": Vector3(0, 0, -8), "width": 16.0},
        {"position": Vector3(18, 0, -24), "in": Vector3(-8, 0, 4), "out": Vector3(8, 0, -4), "width": 12.0},
        {"position": Vector3(12, 6, -58), "in": Vector3(8, -2, 8), "out": Vector3(-8, 2, -8), "width": 8.0}
    ],
    "hazards": [{"type": "mallet", "s": 30.0, "lateral": 0.0, "response": "tip", "period": 4.0}],
    "holes": [{"s": 18.0, "lateral": -3.0, "radius": 1.8}],
    "checkpoints": [{"s": 10.0, "lateral": 0.0}],
    "finish_s": 60.0
}
```

The example is not solvable course data and its distances must be validated against the built curve. Production definitions require two or more checkpoints, safe starts, an ordered finish and an explicit time budget after tuning.

Mandatory route vocabulary:

| Shape | Purpose | Acceptance |
|---|---|---|
| Wide basin | Learn aim/hold, regroup and refill | Space to turn the complete ring |
| Broad bend / S-bend | Cooperative steering and countersteering | Continuous tangent and no angular wall joints |
| Hairpin / switchback | Brake, rotate and accelerate | Projection/progress cannot jump to the neighboring arm |
| Narrow curved bridge | Precise coordinated movement | Ring diameter plus documented lateral clearance |
| Uphill | Sustained thrust against gravity | Physical center of mass gains height |
| Downhill | Momentum and controlled braking | Physical descent and landing, not camera-only motion |
| Crest / dip | Pitch, unloading and recovery | Stable surface queries and no collision seam launch |
| Branch/reconnect or elevated overlap | Later original route variety | Explicit route/checkpoint identity; no XZ-only shortcuts |

Initial geometry limits are tuning constraints, not copied measurements: tutorial clear width at least ring collision diameter plus 1.6 m; later narrow fixtures at least diameter plus 0.8 m. Gentle tutorial slopes start at 6-15 degrees with smooth transitions. Bend inner radii must exceed the ring radius plus safety clearance; reject ribbon self-intersections. Steeper slopes/banking belong in the fixture until they are controllable.

Do not require every edge to be a tall wall. Mark low curbs, guarded banks and exposed ledges explicitly. Only designated exposed edges permit falling off. At bank joints and guarded edges, visual continuity and collision continuity must agree.

## 3. Sky and water treatment

Retain the bright palette: sky #6EC6F0/#BDEBFB/#EEF9FF, turquoise water #22A7D6/#4FD0EE, orange sand #FFA24C, coral cliff accents, green rim #7ACB3B, foam #EAFBFF and dark hazard panels #1E2329. Color variations distinguish gardens, canyon switchbacks, cloud bridges, spiral pools and summit scenery.

Cliffs extend downward relative to each local bank top; use visible strata and depth haze. Clouds sit beneath and beside the route, not as an ocean substitute. Keep floating islands, foliage, umbrellas and balloons outside the playable collision corridor. Do not block upcoming hazards with decorations.

Water flow animation uses route coordinates so streaks follow curves/downhill sections. Small cosmetic ripples do not alter the authoritative support surface. Render ordinary ripples and blob shadows just above the queried local surface, orient them to its normal, and suppress them while airborne or falling.

Holes remove both visible water and physical support. Use a local surface frame for rim and open shaft. Scope shader cut-outs to relevant chunks/heights so a hole on one elevated section cannot erase an unrelated section below it. No orange cap or solid collider across the opening. Foam rings identify holes; green/orange solid islands remain distinct decorations/obstacles only when intentionally authored.

Use shared materials per needed course/chunk parameter set, MultiMesh for repeated small parts, low-poly meshes, CPU particles, simple shaders and no real-time shadows. Maintain the plan's measured phone budgets; no expensive full fluid simulation is required.

## 4. One ring, four rider anchors

One `SwimRing` owns the physical body, rim/platform, crew, gas state and recovery state. Four well-spaced anchors around the perimeter support 1-4 occupied slots. Ring dimensions/collision match the visible hull and rider clearance; starting prototype radius around 1.8 m is tunable. Rider meshes stay attached during ordinary movement and lean with the hull. No independently moving player floats.

Each slot has a unique owner/controller, sanitized avatar, aim direction, held state, requested strength and gas value. Empty seats exert no force. Teammate assistants use this same API and never teleport or steer a second body. Ring appearance belongs to the shared craft rather than to competing teams.

## 5. Thrust and gas

Proposed mobile interaction: drag a direction control to aim; hold the thrust control to emit; release to stop. Desktop exposes equivalent aim/hold controls. Four independent debug bindings/test controllers prove concurrency without placing four sets of phone controls on one small screen. Actual four-person play is provided over LAN in Phase 4.

At each fixed physics step, accept valid occupied-seat requests, project aim into the appropriate water/surface frame, compute force from requested strength and the tunable physics profile, consume that seat's gas proportionally to duration, then apply force at the transformed attachment offset. Do not call one central impulse only on button-down. Never make forces depend on render-frame count.

Short presses give short thrust; held presses sustain thrust until release or depletion; repeated presses remain possible. Gas recovers while resting after a short configurable delay. Depletion requires a defined recovery/re-arm threshold to prevent endless tiny automatic pulses. A release must be recorded even if gas is empty or the game state changes.

Combined linear force is the sum of active seats. Torque follows force direction and lever arm; a radial force aimed exactly through the center has no steering torque. Therefore allow aim directions that generate controlled torque. A symmetric left/right pair pushing forward should mostly cancel yaw; inconsistent direction or timing can turn the craft. Do not assert that every single-seat push must spin it regardless of geometry.

Keep thrust, gas rates, damping, support spring/damping, speed and spin limits together in `RingPhysicsProfile`. Tune with 1/2/3/4 occupied slots so fewer players can complete the course and four cannot trivially bypass every obstacle. Initial tuning is a prototype decision; no exact constants were measured from the clip. Pickups replenish the occupied crew with capacity clamps and a visible explanation.

Jets emit opposite the applied push, at the corresponding rider, while that rider is actually thrusting. Use pooled/limited effects and attack/loop/release audio hooks. Releasing must stop emission promptly while previously emitted particles dissipate naturally. Cosmetic particle lifetime is not proof of continued force.

## 6. Physics and recovery

Keep yaw, pitch, roll and vertical motion available. Use a stable rigid body with gravity, modest water drag and bounded damped support forces at multiple hull sample points. Sample the correct nearby route section and local surface; absent water/holes provide no buoyant support. Do not snap Y every tick or directly align the body to the route tangent. A hull can drift laterally, climb, descend, tip, leave the surface at a crest and land.

Use stable simplified collision and continuous collision where needed. Walls, banks, rocks and moving solids must impart real contact responses. Prevent tunneling at narrow seams and excessive angular energy without locking all rotation. A bounded righting assist while supported is acceptable if documented and demonstrated; it must not cancel all impacts or prevent falling.

Checkpoint data stores a full route-relative transform. A group fall clears all held requests, shows the whole craft descending, then resets everyone to the latest safe transform with zero velocity and input requiring a fresh press. Keep the run clock going. Respawn clearance must exclude holes, edges and the complete swept volume of moving obstacles. Timeout/finish cancels pending recovery. Add a deterministic recovery rule for a craft stranded upside down or far outside the course.

The previous 0.9-second visual drop is a legacy behavior, not the new gravity/support implementation. Preserve its safety expectations in migrated tests without pretending a mesh-only drop demonstrates full 3D falling physics.

## 7. Obstacle library and response rules

| Hazard | Behavior | Phase |
|---|---|---|
| Bumper | Solid contact, bounded outward push, readable squash feedback | 2 playable |
| Sweeper | Rotating solid bar, pushes and can tip the ring | 2 playable |
| Swinging mallet | Pendulum head crossing the route; wait/steer around it | 2 playable |
| Current | Force in local route direction or a declared cross-current | 2 playable |
| Hole / exposed edge | Removes support; whole-crew fall and checkpoint recovery | 2 playable |
| Spiked crossbar | Timed moving bar; declared push/tip or reset response | 2 fixture, 3 campaign |
| Crusher | Timed descending hazard with visible warning and escape space | 3 |
| Moving gate / spiked panel | Opens a passage on a repeatable cycle | 3 |
| Boulder / rolling obstacle | Blocks or sweeps a defined portion of the lane | 3 |
| Whirlpool | Inward/swirl force with a separately declared drain/fall area | 3 |

All gameplay motion is evaluated from shared `race_time`, phase, period, pivot and local route frame. Use moving collision bodies appropriately. Do not award instant death to all spiked meshes: the clip shows recoverable contacts. Clearly identify authored lethal/reset zones and retain push/tip behavior for ordinary hazards. Many obstacles means varied mechanics and fair combinations, not filling every metre with unavoidable hazards.

Measure the ring's swept clearance, provide waiting bays at timed narrow passages and keep checkpoints outside hazard sweeps. Tutorial timing is forgiving; later combinations increase difficulty. Hazard tuning cannot silently change behavior on guests in Phase 4.

## 8. Camera and visual acceptance

Follow the shared ring position with damped height and route look-ahead. Blend heading toward the forward route/velocity as appropriate; never rotate the view with every raft yaw impulse. Handle low speed, reverse travel, hairpins, slopes, falls and respawns without instant flips. Check camera obstruction near cliffs/large hazards and respect reduced-motion settings.

Overview must reveal the original winding layout and meaningful elevations. Play view must show enough of the next bend/hazard to react. Capture a wide curve, narrow bridge, uphill/downhill, tilted collision and four riders emitting independently. The earlier reference sample's fixed (x,14,z+12) world-axis camera is superseded where it fails on these routes.

Acceptance requires both legal-input automated runs and human play. Record frame pacing with four active riders and the busiest hazard grouping on actual phones. Keep geometry collision/progress tests separate from screenshots and keep local four-controller tests separate from four-phone network proof.
