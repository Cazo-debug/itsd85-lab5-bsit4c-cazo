> HISTORICAL REFERENCE ONLY. Superseded on 2026-11-01 by the root IMPLEMENTATION_PLAN.md and ENVIRONMENT_SPEC.md. Do not execute instructions in this archived document.

# Toot Tubes: Environment Spec v2 (sky course, shared rings)

This file tells Codex exactly how the 3D world looks and behaves. It matches the approved web sample in `docs/reference/course_sample.html` (three.js). When this file and the sample disagree, **the sample's numbers win**. Read its `<script>` for exact formulas.

Reference images: `docs/reference/ref_play_view.png` (play camera) and `docs/reference/ref_whole_course.png` (whole course from above).

**Originality rule:** this is our own course and our own riders. A sky course, shared rings, holes and spikes are common party-game ideas, but do not copy levels, characters (no hippos), names, logos, music or textures from Fart Together or any other commercial game.

---

## 1. World rules

- Units are meters. The water surface is y = 0. Up is +Y.
- The race goes **forward along −Z**. In data, `d` is the distance forward from the start, so a data point `[x, d]` is `Vector3(x, 0, -d)`.
- **The course floats in the sky.** It is a closed channel of water on top of tall striped cliffs that drop about 40 m into haze and clouds. There is no ocean. Around it: clouds below and to the sides, small floating islands, hot-air balloons.
- **Holes** in the water floor drop the whole ring into the sky. **Spike rails** line some walls.
- Renderer: Compatibility. No real-time shadows. Every color below is an sRGB hex value. Plain parts use `StandardMaterial3D` (roughness 1, metallic 0, specular 0.3).

## 2. Palette (shared materials, create each once and reuse)

| Token | Hex | Used for |
|---|---|---|
| sky_top / sky_mid / sky_low | `#6EC6F0` / `#BDEBFB` / `#EEF9FF` | Sky gradient (top, middle, bottom) |
| haze | `#E0F5FF` | Cliffs fade into this far below |
| water_deep / water_shallow | `#22A7D6` / `#4FD0EE` | Water shader |
| sand | `#FFA24C` | Bank tops, island tops |
| strata_a / strata_b | `#E9823A` / `#F69954` | Cliff side stripes |
| rim | `#7ACB3B` | Grass rims |
| foam | `#EAFBFF` | Hole rims |
| panel | `#1E2329` | Spike walls, spike rails |
| white | `#F6F6F2` | Spikes, stripes, poles, bumper tops |
| post | `#EF4B4B` | Sweeper post, end caps, barrels |
| bar | `#FFD23A` | Sweeper bar, finish arch |
| bumper | `#FF6B5A` | Bumper body |
| bean | `#B8682E` | Bean pickup |
| log | `#7A4A2C` | Spike log, balloon baskets |
| buoy | `#E94040` | Checkpoint buoys |
| sign | `#FF7A3D` | Finish sign |
| accents | `#FF6B5A`, `#2BB3A3`, `#FFD23A`, `#8F7CF6` | Umbrellas, balloons |

## 3. Sky, lighting, environment

- `WorldEnvironment` with a `Sky` using a small sky shader (gradient by view direction y):
  ```glsl
  shader_type sky;
  uniform vec3 top : source_color = vec3(0.431, 0.776, 0.941);
  uniform vec3 mid : source_color = vec3(0.741, 0.922, 0.984);
  uniform vec3 low : source_color = vec3(0.933, 0.976, 1.0);
  void sky() {
    float y = EYEDIR.y;
    COLOR = y > 0.0 ? mix(mid, top, smoothstep(0.0, 0.6, y)) : mix(mid, low, smoothstep(0.0, -0.5, y));
  }
  ```
  If the sky shader is a problem on a low-end phone, use background mode Color = sky_mid.
- Ambient light: source Color, white, energy about 0.6. Tonemap Linear. No glow, no SSAO, no fog.
- One `DirectionalLight3D`, white, energy about 0.6, shadows **off**, rotation about x = −60°, y = −30°.
- **Orange must stay orange.** If the sand looks pale yellow, lower the light energies.

## 4. Water (`shaders/water.gdshader`)

**One water plane per segment** (not one big ocean): `PlaneMesh` size (width + 0.02, length + 0.02), subdivisions about 1 per 1.5 m, centered on the segment at y = 0. All planes share one `ShaderMaterial`. Holes are cut out with `discard`.

```glsl
shader_type spatial;
render_mode unshaded;
uniform vec3 deep : source_color = vec3(0.133, 0.655, 0.839);
uniform vec3 shallow : source_color = vec3(0.310, 0.816, 0.933);
uniform vec3 holes[8];   // x, z, radius (world). Unused: radius 0
varying vec3 wp;
void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.y += sin(w.x * 0.35 + TIME * 1.3) * 0.06 + sin(w.z * 0.27 + TIME * 1.1) * 0.06;
	wp = w;
}
void fragment() {
	for (int i = 0; i < 8; i++) {
		if (length(wp.xz - holes[i].xy) < holes[i].z) { discard; }
	}
	float band = sin(wp.x * 0.18 + wp.z * 0.12 + TIME * 0.6) * 0.5 + 0.5;
	vec3 col = mix(deep, shallow, band);
	float c = sin(wp.x * 1.3 + TIME) * sin(wp.z * 1.1 - TIME * 0.8) + sin((wp.x + wp.z) * 0.7 + TIME * 0.6);
	col = mix(col, vec3(1.0), smoothstep(1.15, 1.45, c) * 0.35);
	ALBEDO = col;
}
```
`LevelBuilder` fills `holes` from the level data (max 8 per level). Anything flat that lies on the water (ripples, shadows, strips, whirlpool) sits at **y = 0.13 to 0.15**.

## 5. Cliffs (`shaders/cliff.gdshader`)

Used on every bank box, hole shaft and floating-island underside. Sand on top, stripes on the sides, fading into haze far below.

```glsl
shader_type spatial;
render_mode unshaded, cull_disabled;
uniform vec3 sand : source_color = vec3(1.0, 0.635, 0.298);
uniform vec3 strata_a : source_color = vec3(0.914, 0.51, 0.227);
uniform vec3 strata_b : source_color = vec3(0.965, 0.6, 0.33);
uniform vec3 haze : source_color = vec3(0.88, 0.96, 1.0);
varying vec3 wp;
varying vec3 wn;
void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
void fragment() {
	vec3 col = wp.y > -0.4 ? sand : mix(strata_a, strata_b, step(0.5, fract(wp.y * 0.22)));
	float l = 0.62 + 0.38 * max(dot(normalize(wn), normalize(vec3(-0.4, 0.8, 0.35))), 0.0);
	col *= l;
	col = mix(col, haze, smoothstep(-3.0, -42.0, wp.y) * 0.9);
	ALBEDO = col;
}
```

## 6. Course pieces

### Banks (built by `LevelBuilder` from `segments`)
Constants: `BH = 0.9` (bank top), `BT = 3.2` (bank thickness), `DEPTH = 40` (cliff depth below water).

- **Bank box:** `BoxMesh` with the cliff shader, from y = −DEPTH to y = BH (height 40.9, center y = (BH − DEPTH) / 2). Collision: a `StaticBody3D` box only for the top 3 m (y −2 to 0.9) is enough.
- **Rim:** `BoxMesh` 0.7 wide, 0.32 tall, centered on the wall line at y = BH + 0.01, length = wall length + 0.7, material rim.
- For each segment `{d, length, width, x}`: `xl = x − width/2`, `xr = x + width/2`, from `d0 = d` to `d1 = d + length`.
  - Left bank box x [xl − BT, xl]; right bank box x [xr, xr + BT]; both d [d0, d1]. Rims on x = xl and x = xr.
  - Joint with the next segment (edges `nl`, `nr`) on the line d = d1:
    - Left: if `nl ≠ xl`, rim from xl to nl. If `nl > xl`, bank box x [xl, nl], d [d1, d1 + BT]; else x [nl, xl], d [d1 − BT, d1].
    - Right: if `nr ≠ xr`, rim from xr to nr. If `nr < xr`, bank box x [nr, xr], d [d1, d1 + BT]; else x [xr, nr], d [d1 − BT, d1].
  - First segment: rim across at d0, bank box x [xl − BT, xr + BT], d [d0 − BT, d0]. Last segment: rim across at d1, bank box x [xl − BT, xr + BT], d [d1, d1 + BT].
- Test: the channel is closed (a ring pushed sideways anywhere always hits a wall).

### Holes (`holes`: `{pos: [x, d], radius}`)
- Cut out of the water by the water shader.
- **Foam rim:** flat `TorusMesh` at y 0.12, ring radius = hole radius, tube 0.17, material foam.
- **Shaft:** open `CylinderMesh` (no caps) radius = hole radius, height 7, center y = −3.5, cliff shader. Below it you see haze and clouds.
- **Fall rule:** when the ring's center is closer than `radius − 0.2` to the hole center, the ring falls: speed × 0.2, 0.9 s drop animation (`y = −10 × t²`, scale shrinks to 0.3), small foam puff, then respawn at the last checkpoint. Holes ignore the safe time after a respawn (respawn points are never near holes).

### Spike rails (`spike_rails`: `{side: "left"|"right", from, to}`)
- Along that side's wall line, from d = from to d = to.
- Dark strip: `BoxMesh` 0.35 wide, 0.55 tall, inside the wall by 0.18 m, y 0.3, material panel.
- White cones (r 0.14, height 0.45, 6 sides) every 0.9 m pointing into the channel, at y 0.35, 0.55 m inside the wall. Use **one `MultiMeshInstance3D`** for all rail cones in the level.
- **Pop rule:** a ring whose center is within `ring_radius + 0.25` of the wall line inside the rail's d range pops.

### Sky decor (no collision)
- **Clouds:** 32 clusters of 4 squashed spheres (r 1, 10 × 8 segments), white with a little emissive so they stay bright. 22 under the course (y −14 to −34, x ±65, d −20 to 210), 10 to the sides (x ±45 to ±105, y 2 to 24). Drift side to side slowly. Use a `MultiMeshInstance3D`.
- **Floating islands:** 9, alternating sides at x ±24 to ±64, y −6 to +8, spread along the course. Top: sand cylinder (r 2.5 to 5.5, height 1.2) with rim torus; underside: cone pointing down (radius = r, height = 2.2 r) with the cliff shader or strata_a; a small umbrella on top.
- **Hot-air balloons:** 3 (accent colors) with a white band and a log-colored basket 5.4 m below, bobbing ±1.2 m. Positions (x, y, d): (−42, 16, 60), (48, 22, 120), (−55, 10, 175).
- **Beach umbrellas on banks:** pole white r 0.06 height 2.2 at y BH + 1.0; canopy cone r 1.3 height 0.55 at y BH + 2.1, tilted 0.12 rad outward; 1.7 m outside the wall line.

### Start, checkpoints, finish
- **Checker strips** (1.4 m deep, 8 × 2 black and white squares, nearest filter) at d = 1.2 and at `finish_d`, y 0.14.
- **Checkpoint buoys:** red sphere r 0.5 at y 0.25 with a white band (r 0.51, height 0.18, y 0.3), 0.6 m inside each wall. A thin `Area3D` across the channel records the checkpoint.
- **Finish arch:** upright `TorusMesh` across the channel (inner `width/2 − 0.45`, outer `width/2 + 0.45`), material bar; the bottom half hides under the water. Orange sign quad 5 × 1.25 m on top (y = width/2 + 1.1) with white "FINISH" (`Label3D`, Fredoka). Finish `Area3D` from `finish_d` forward 4 m.

### Beans
`SphereMesh` r 0.4 scaled (1.25, 0.75, 0.8), material bean, plus a cream highlight sphere r 0.12 (`#FFE2B8`) at (0.18, 0.18, 0.12). Base y 0.6, bobs ±0.12, spins 1.6 rad/s. **Pickup radius 2.0 m** from the ring center. Gives **+1 gas to each rider** in that ring (max 3). Hidden for 8 s, then returns.

## 7. Obstacles

All motion uses only `Level.race_time` (`t`). Moving solids are `AnimatableBody3D` with `sync_to_physics` on. "Pops" means call `SwimRing.pop()`. `R` is the ring radius (1.45).

| Type | Looks | Motion | Collision |
|---|---|---|---|
| **bumper** | Cylinder r 1.1 / 1.2, height 1.1, y 0.4, bumper color; white cylinder r 0.75, height 1.12 on top. | Still. Squash tween on hit (1.25, 0.7, 1.25) → 1 over 0.25 s. | Solid r 1.15. Bounce 0.9 plus 6 m/s outward push and a small random spin (±1.5 rad/s). |
| **sweeper** | Post cylinder r 0.75 to 0.85, height 1.8, y 0.5, post color, white sphere r 0.55 on top. Arm at y 0.9: bar r 0.35, length 2 × `length`, bar color, red sphere caps r 0.45. | `arm.rotation.y = deg_to_rad(speed_deg) * t` | Post solid r 0.8. Bar capsule r 0.35. On hit push the ring away by `max(2, abs(ω) × distance_from_center × 0.8)` m/s and add spin `ω × 0.5`. Never pops. |
| **spike_wall** | Box `width` × 1.7 × 0.7 at y 0.55, panel with white dots (dot r 0.18 on a 0.4 m grid, shader on local x/y), 6 white cones (r 0.16, h 0.55) on each long side pointing ±Z, red barrels r 0.3, h 0.9 at both ends. | `x = pos.x + travel * sin(TAU * (t / period + phase))` | Box half sizes (width/2 + 0.3, 0.9). Touch pops. |
| **whirlpool** | Disc r `radius` at y 0.15, transparent: dark blue center fading out, 3 white spiral arms, clear in the middle so a drain hole shows through. Spins 2.2 rad/s. | Visual spin only. | Pull within `radius + R/2`: toward center `strength × (1 − 0.5 × min(1, d / radius))` plus 3 m/s² swirl, plus spin 1.5 rad/s². Put a small **hole** (r 1.0) at its center: getting sucked in drops you. |
| **spike_log** | Cylinder r 0.5, length 3.4 along Z, y 0.45, log color, 12 white cones (r 0.13, h 0.45) around it. | `x = pos.x + travel * sin(TAU * t / period)`, roll `rotation.z = −(x − pos.x) / 0.5` | Capsule along Z, half length 1.7, r 0.75. Touch pops. |
| **current** (Levels 1 and 5) | Lighter strip at y 0.14 with scrolling white arrows. | Visual only. | Area pushes `force` in `dir`. |

Whirlpool shader sketch:
```glsl
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float a = atan(p.y, p.x);
	float arms = smoothstep(0.75, 0.95, sin(a * 3.0 + r * 11.0 - TIME * 2.2)) * step(0.26, r);
	float fade = (1.0 - smoothstep(0.0, 1.0, r)) * step(0.26, r);
	ALBEDO = mix(vec3(0.03, 0.24, 0.39), vec3(1.0), arms);
	ALPHA = clamp(fade * 0.8 + arms * fade * 0.75, 0.0, 1.0) * step(r, 1.0);
}
```

## 8. The shared swim ring (`SwimRing.tscn`)

**Two riders share one ring.** Each rider (seat) has their own 3 toots. Max 2 rings per race = **max 4 players**.

| Part | Value |
|---|---|
| Body | `RigidBody3D`, mass 1, `gravity_scale` 0, lock linear Y and angular X/Z (it can spin around Y), sphere collider r **1.45**, bounce 0.5 |
| Ring mesh | 8 `TorusMesh` arcs (or one torus with an 8-stripe shader), ring radius 1.03, tube 0.42, lying flat at y 0.2, alternating team color and white |
| Seats | Seat 0 at local (−0.62, 0, 0), seat 1 at (+0.62, 0, 0). A rider model sits in each seat, facing −Z |
| Blob shadow | Quad 3.8 × 3.8, radial dark gradient (`#08283C` at 45% to 0), y 0.13, not part of the visual |
| Team colors | Orange ring `#FF7A59`, purple ring `#8F7CF6` |

**Rider model** (all inside the seat node, front is −Z): body cylinder top r 0.27, bottom 0.36, height 0.68 at y 0.5 (outfit); head sphere r 0.31 at y 1.02 (skin); eyes spheres r 0.055 at x ±0.11, y 1.07, z −0.27 (`#111111`); cap half sphere r 0.28 scaled (1.08, 0.8, 1.08) at y 1.2 plus brim box 0.38 × 0.05 × 0.28 at z −0.27 (hat color). Other hats from AvatarData use the same scale.

**Toot physics (the core of the game):**
```
seat_world = ring.global_transform * seat_local         # where this rider sits now
dir = flat_normalize(tap_point - seat_world)            # ignore if the tap is closer than 0.3 m
impulse = dir * 7.0
ring.apply_impulse(impulse, seat_world - ring.global_position)   # pushes AND spins
seat.gas -= 1
```
- Set `inertia = Vector3(0, 2.9, 0)` so one toot from one seat spins the ring about as much as the sample (`ANG_K = 0.35`). Angular damp about 2.0 (sample: spin × `exp(−2.0 × delta)`). Max spin 4 rad/s.
- Two riders tooting the same way: torques cancel, the ring goes straight and fast (2 × 7 = 14 m/s, the max speed).
- One rider alone: the ring moves and turns. **This is the teamwork challenge.**
- Water drag: velocity × `exp(−1.1 × delta)` (linear damp ≈ 1.1, damp mode Replace, then tune to match). Max speed 14 m/s.
- Gas per seat: 3 max, +1 every 1.5 s.
- Ring vs ring: equal push apart, bounce 0.6, small random spin.

**Animation:** visual bob `sin(t × 3 + offset) × 0.07`, tiny roll `sin(t × 2.1 + offset) × 0.03`. On any toot: ring squash (1 + 0.12q, 1 − 0.15q, 1 + 0.12q), and that rider squashes (1 + 0.2s, 1 − 0.25s, 1 + 0.2s). After a respawn, blink 12 times per second for 1.5 s.

**Pop / fall / respawn:** pop = white puff of 16, hidden 1 s. Fall = hole drop (section 6). Both respawn 3 m past the last checkpoint at `segment.x + team_side` (orange −2.5, purple +2.5), speed and spin 0, facing forward, 1.5 s safe from spikes.

## 9. Who controls each seat

| Mode | Orange ring seat 0 | Orange ring seat 1 | Purple ring |
|---|---|---|---|
| Offline solo | You (any tap) | Computer buddy | Computer, both seats (Levels 2 to 5; none in Level 1) |
| Offline duo (2 people, 1 phone) | Player 1: taps on the **left half** | Player 2: taps on the **right half** | Computer, both seats |
| Online, 2 phones | Host | Guest | Computer, both seats |
| Online, 3 phones | Host | Guest 1 | Guest 2 + computer buddy |
| Online, 4 phones | Host | Guest 1 | Guests 2 and 3 |

In duo mode, draw a faint dashed line down the middle of the screen and show "Left half: Player 1 · Right half: Player 2" until the first toot.

**Computer buddy (your teammate):** when you toot, it copies your toot direction after 0.18 s (85% of the time) if it has gas. If you have not tooted for 1.4 s, it steers by itself toward the next waypoint every 1.2 s (aim error ±11°).

**Computer ring (rivals):** each seat toots toward the next waypoint (advance when within 4.5 m) every 1.6 to 2.1 s with up to ±14° aim error. Later levels shorten the delay. After a fall or pop, skip to the first waypoint past the respawn point.

## 10. Effects

- **Toot puff:** `CPUParticles3D`, one-shot, 10 spheres (r 0.3), from 0.9 m behind the rider's seat, moving away at 1.5 to 4 m/s with spread, rising 0.6 to 1.8 m/s, growing to 1.6× and fading over 0.7 s. Color = that rider's toot color.
- **Ripple rings:** flat white rings (inner 1.25, outer 1.5) at y 0.15, one every 0.13 s while ring speed > 1.5 m/s, scale 0.7 to 2.1, alpha 0.6 to 0.
- **Pop:** 16 white puffs in all directions. **Fall:** 10 foam puffs.
- Pre-warm particle materials during the countdown.

## 11. Camera

- **Play view:** follows **your** ring. Position `(ring.x × 0.85, 14, ring.z + 12)`, look at `(ring.x × 0.9, 0, ring.z − 7)`, FOV 55°, near 0.5, far 800. Smooth with `1 − exp(−delta × 4.5)`. The camera does **not** spin with the ring.
- **Shake:** bumper 0.25, sweeper 0.2, ring bump 0.15, fall 0.35, pop 0.5; decays 1.6/s; off with reduce motion.
- **Whole-course view** for the level intro (2 s before the countdown): position `(0, 192, −55)`, look at `(0, 0, −93)`, smooth `1 − exp(−delta × 3)`.

## 12. Level 3 data (copy into `LevelDefs.gd`)

```gdscript
{
	"number": 3, "name": "Sweeper Spin",
	"goal_text": "Beat the purple ring past the sweepers in 60 seconds",
	"time_limit": 60.0,
	"rival_ring": true, "rival_toot_delay": 1.6, "rival_aim_error_deg": 14.0,
	"segments": [
		{"d": 0, "length": 30, "width": 14, "x": 0},
		{"d": 30, "length": 30, "width": 12, "x": 3},
		{"d": 60, "length": 35, "width": 16, "x": 0},
		{"d": 95, "length": 25, "width": 10, "x": -3},
		{"d": 120, "length": 30, "width": 16, "x": 0},
		{"d": 150, "length": 30, "width": 14, "x": 2},
	],
	"islands": [],
	"holes": [
		{"pos": [-3, 22], "radius": 2.0},
		{"pos": [5.5, 44], "radius": 2.2},
		{"pos": [-5.5, 78], "radius": 1.6},
		{"pos": [-3, 134], "radius": 1.0},
		{"pos": [-2.5, 168], "radius": 1.8},
	],
	"spike_rails": [
		{"side": "right", "from": 34, "to": 56},
		{"side": "left", "from": 96, "to": 119},
		{"side": "right", "from": 152, "to": 178},
	],
	"obstacles": [
		{"type": "bumper", "pos": [3, 14]},
		{"type": "sweeper", "pos": [0, 70], "length": 6.5, "speed_deg": 70},
		{"type": "sweeper", "pos": [0, 86], "length": 6.5, "speed_deg": -95},
		{"type": "spike_wall", "pos": [-3, 103], "width": 4, "travel": 3, "period": 3.2, "phase": 0.0},
		{"type": "spike_wall", "pos": [-3, 113], "width": 4, "travel": 3, "period": 3.2, "phase": 0.5},
		{"type": "bumper", "pos": [5, 127]},
		{"type": "whirlpool", "pos": [-3, 134], "radius": 4, "strength": 7},
		{"type": "bumper", "pos": [2, 145]},
		{"type": "spike_log", "pos": [2, 161], "travel": 5, "period": 4},
	],
	"beans": [ [0, 10], [-3, 27], [3, 36], [0, 52], [-5, 64], [5, 80], [-3, 98], [-1, 118], [4, 140], [6, 160] ],
	"checkpoints": [ 60, 120 ],
	"waypoints": [ [0, 6], [1, 20], [3, 32], [1, 44], [1, 58], [0, 78], [0, 92], [-3, 100], [-3, 118], [2, 124], [3.5, 136], [0, 150], [1, 158], [3, 168], [2, 178] ],
	"start": [0, 4], "finish_d": 172,
	"umbrellas": [ [0, -1, 12], [1, 1, 40], [2, -1, 75], [3, 1, 108], [0, -1, 140], [2, 1, 165] ],
}
```
Rings start side by side at `start.x − 2.5` (orange) and `start.x + 2.5` (purple).

## 13. Other levels

Same pieces, palette, camera and numbers. Follow the level table in `IMPLEMENTATION_PLAN.md`:

- **Level 1 Lazy River:** wide (14 to 16 m), gentle S-turns, a `current` strip helping you forward, 12 beans, **1 large hole** with a hint ("Don't drift into holes!"), no spikes, **no rival ring** (learn to toot together with your buddy).
- **Level 2 Bumper Bay:** bumpers and small islands in a wide lagoon, 2 holes, slow rival ring (delay 2.2 s, error 20°).
- **Level 3 Sweeper Spin:** exactly the data above.
- **Level 4 Whirl Pool:** 2 to 3 drain whirlpools, 2 spike walls in a 9 m corridor with spike rails, fewer beans (6), rival delay 1.4 s, error 10°.
- **Level 5 Grand Toot:** about 220 m, every obstacle type, 2 spike logs, 6 holes, rival delay 1.2 s, error 8°, 70 s.

Every level must pass the bot solvability test from the plan (a perfect 2-seat computer ring finishes in time).

## 14. Visual acceptance (you check)

Put the Godot Level 3 next to `docs/reference/ref_play_view.png`:
- [ ] The track floats in the sky: striped orange cliffs dropping into haze, clouds below, floating islands and balloons around.
- [ ] Holes show a white foam ring and a drop. Drifting over one makes the ring fall and respawn at the buoys.
- [ ] Dark spike rails with white spikes on some walls pop you.
- [ ] Two riders sit in one striped ring. Tooting from one seat spins the ring; both tooting the same way goes straight.
- [ ] Sweepers spin, spike walls slide, the drain whirlpool spins, the spike log rolls.
- [ ] The camera sits behind and above your ring like the reference image and moves smoothly.
- [ ] The whole course from above matches `ref_whole_course.png`.
