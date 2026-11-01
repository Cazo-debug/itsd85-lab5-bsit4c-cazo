> HISTORICAL REFERENCE ONLY. Superseded on 2026-11-01 by the root IMPLEMENTATION_PLAN.md and ENVIRONMENT_SPEC.md. Do not execute instructions in this archived document.

# Toot Tubes: Implementation Plan (v2: sky course, shared rings)

ITSD 85 Lab: Mobile Game with Level Progression and Offline/Online Multiplayer
Section: BSIT-4C · Platform: Android (APK) · Orientation: portrait · Engine: Godot 4 (GDScript)

> **How to use this file with Codex**
> Put this file, `ENVIRONMENT_SPEC.md`, `AGENTS.md` and `docs/reference/` in the root of the Godot project repo. Then give Codex one phase at a time:
> `Do Phase 1 of IMPLEMENTATION_PLAN.md. Follow AGENTS.md. Stop at the Phase 1 gate and report.`
> Do not start the next phase until **you** have done that phase's "You check" list on your computer or phone.
>
> **The look and all gameplay numbers are fixed by `ENVIRONMENT_SPEC.md`** (sky course, cliffs, holes, spike rails, obstacles, the shared swim ring, riders, effects, camera, and the full Level 3 data). It matches the approved sample in `docs/reference/`. When this plan and the spec differ on a number or a look, the spec wins.

---

## 0. The game in one page (source of truth)

**Pitch:** Two friends share one swim ring on a water course floating in the sky. The only way to move is to toot, and each rider toots from their own side of the ring. Toot together to race to the finish; toot alone and you spin into the spikes.

**Look (all original assets):** a bright water channel on top of tall striped orange cliffs, high above the clouds. Grass rims, spike rails on some walls, holes in the water that drop you into the sky, spinning sweeper bars, sliding spike walls, bumpers, drain whirlpools, rolling spike logs. Clouds, floating islands and hot-air balloons around the course. Low-poly, flat colors. **Do not copy characters, logos, names, levels or music from Fart Together or any commercial game** (lab rule, page 21). Riders are our own simple cartoon people, not hippos.

**Core mechanic (one thumb per rider):**
- **Two riders share one ring.** Each rider has their own **3 toots**; one refills every **1.5 s**. A **bean** gives both riders +1.
- Tap the water. Your rider toots and pushes the ring from **their seat** toward that spot.
- Both riders toot the same way: the ring goes straight and fast. One rider alone: the ring moves **and spins**.
- The ring drifts and slows on its own (water drag) and bumps off walls, obstacles and the other ring.
- **Spikes** (spike rails, spike walls, spike logs) pop the ring. **Holes** drop it into the sky. Either way the ring comes back at the last checkpoint buoys after about 1 s. The timer keeps running.

**Players:** 2 riders per ring, at most 2 rings per race, so **up to 4 players**. Empty seats are filled by computer riders.

**Win / lose (offline):** Win = your ring crosses the finish arch before the timer hits 0 **and** before the rival ring. Lose = timer hits 0, or the rival ring finishes first.
**Stars:** win with more than 50% time left = 3, more than 25% = 2, otherwise 1 (same formula as the lab's `Level.gd`).

**Modes:**
- **Offline solo:** you + a computer buddy in your ring. Level 1 has no rival; Levels 2 to 5 add a computer rival ring that gets faster. Works in airplane mode.
- **Offline duo (2 people, 1 phone):** player 1 taps the left half of the screen, player 2 the right half. Same levels and progression. This is the lab's "two players on one device" option.
- **Online (same Wi-Fi, lab Option A):** 2 to 4 phones. 2 phones = co-op in one ring vs a computer ring. 4 phones = 2 vs 2. The host runs the physics and decides the winner. Online results do not change offline unlocks.

**Avatar creator:** name (max 12 chars), skin tone, outfit color, hat, toot color. Saved on the phone. Other players see your rider and name online.

### Level plan (R1, R2)

| Lvl | Name | Goal text on screen | New or harder | Time | Rival ring |
|---|---|---|---|---|---|
| 1 | Lazy River | Reach the finish arch in 75 seconds | Learn to toot together, beans, a helping current, first hole | 75 s | None |
| 2 | Bumper Bay | Beat the purple ring in 60 seconds | Bumpers, small islands, 2 holes, first rival ring (slow) | 60 s | Slow |
| 3 | Sweeper Spin | Beat the purple ring past the sweepers in 60 seconds | Sweepers, spike walls, spike rails, drain whirlpool, 5 holes | 60 s | Medium |
| 4 | Whirl Pool | Beat the purple ring through the whirlpools in 55 seconds | Several drain whirlpools, narrow spiked corridor, fewer beans | 55 s | Faster |
| 5 | Grand Toot | Beat the purple ring in 70 seconds | Everything plus spike logs, 6 holes, longer course | 70 s | Fastest |

### Lab requirement map (acceptance checklist)

| Req | Where it is built | Where it is tested |
|---|---|---|
| R1 5 levels, each harder | Phase 3 (`LevelDefs.gd`) | `test_level_defs.gd`, ring solvability test |
| R2 Goal text on level start | Phase 2 HUD | You check, Phase 2 |
| R3 Result screen, stars, Retry/Next/Menu | Phase 3 | `test_stars.gd`, You check |
| R4 Locked levels show a lock | Phase 3 | `test_game_state.gd`, You check |
| R5 Progress survives app close | Phase 1 | `test_game_state.gd` save/load, You check on phone |
| R6 Offline in airplane mode | Phase 3 (solo and duo) | You check, Phase 3 and 5 |
| R7 Two phones, one match | Phase 4 (2-phone co-op first) | `net_smoke` headless test, You check with 2 phones |
| R8 Offline/Online on menu, error not crash | Phase 3 menu, Phase 4 errors | `net_smoke` unreachable test, You check Wi-Fi off |
| R9 Real phone, fixed portrait, touch | Phase 1 settings, Phase 5 export | You check, Phase 5 test matrix |
| R10 Title, pause, sound on/off, readable text | Phases 3 and 5 | You check, Phase 5 |
| Bonus | Stars, player names, settings, tutorial hints, color-blind toot colors, duo mode, 4-player online | Phases 3, 4, 5 |

---

## 1. Tech stack (all free, matches the lab PDF)

| Part | Choice | Why |
|---|---|---|
| Engine | **Godot 4** (the lab says 4.7; any 4.x stable from 4.3 up works), standard build, not .NET | Lab default, exports to Android |
| Renderer | **Compatibility** | Lab requirement for low-cost phones; supports simple 3D |
| Language | GDScript, static typing on | Lab default |
| Physics | Godot 3D physics. Each swim ring is one `RigidBody3D` locked to the water plane that can spin around Y; toots use `apply_impulse` at the seat position | Pushing and spinning come for free |
| 3D art | Built from Godot primitive meshes in code | No downloads, tiny APK, Codex can build it all |
| Shaders | 4 small ones: water (with hole cut-outs), cliff stripes, sky gradient, whirlpool | Looks good, very cheap |
| Effects | `CPUParticles3D`, `MultiMeshInstance3D` for repeated parts | Safest and fastest on low-end Android |
| Save | `ConfigFile` at `user://save.cfg` | Lab default, works offline |
| Online | High-level Multiplayer + `ENetMultiplayerPeer`, port 7777, host-authoritative | Lab Option A, no server |
| Optional backend | Nakama in Docker (Option B, bonus only) | See Phase 4C |
| Tests | **GUT** (Godot Unit Test, MIT) run headless | Codex can run them without a screen |
| Audio | Toot and UI sounds generated by a Python script into `.wav`; one CC0 music loop added by you (`.ogg`) | Lab: `.ogg` music, `.wav` effects |
| Font | Fredoka (Google Fonts, OFL) | Round, readable, fits the look |
| Version control | Git + GitHub | Lab requirement |

**Performance budget (lightweight):** 60 fps on a mid-range phone, at least 30 fps on a low-end phone. Under 150 draw calls and under 60k triangles on screen. No real-time shadows (blob-shadow quad under each ring). APK under 60 MB.

---

## 2. Project structure

```
res://
├── AGENTS.md
├── IMPLEMENTATION_PLAN.md
├── ENVIRONMENT_SPEC.md
├── autoload/
│   ├── GameState.gd        # progress, stars, avatar, settings, save/load
│   ├── Net.gd              # host/join, errors, players and seats
│   └── Audio.gd            # music + sfx players, respects sound on/off
├── scenes/
│   ├── ui/                 # Title, MainMenu, ModeSelect, LevelSelect, AvatarCreator,
│   │                       # Lobby, Result, OnlineResult, Settings, Credits, PauseMenu, HUD
│   ├── levels/             # Level01.tscn ... Level05.tscn (thin: Level.gd + level_number)
│   ├── actors/             # SwimRing.tscn, RiderModel.tscn
│   └── course/             # WaterSegment, BankBox, Rim, Hole, SpikeRail, Island, FinishArch,
│                           # Checkpoint, Bean, Bumper, Sweeper, SpikeWall, Whirlpool,
│                           # SpikeLog, Current, SkyDecor (clouds, floating islands, balloons)
├── scripts/
│   ├── Level.gd            # race clock, win/lose, stars, countdown
│   ├── LevelBuilder.gd     # builds the course from LevelDefs data
│   ├── LevelDefs.gd        # const data for all 5 levels
│   ├── SwimRing.gd         # shared ring physics, seats, gas, pop/fall/respawn
│   ├── RingBrain.gd        # computer riders: buddy and rival
│   ├── TapInput.gd         # screen tap -> seat + point on water
│   ├── AvatarData.gd       # avatar options, defaults, sanitize, to/from dict
│   └── obstacles/          # one script per obstacle type
├── shaders/                # water, cliff, sky, whirlpool (.gdshader)
├── assets/{fonts,audio,icons}/
├── tools/                  # gen_sfx.py, run_tests.sh, setup_godot.sh, net_smoke.sh
├── tests/                  # GUT tests + net_smoke.gd
├── addons/gut/
└── docs/                   # GDD.md, CREDITS.md, PROGRESS.md, TEST_MATRIX.md,
                            # reference/ (approved sample + screenshots), screenshots/
```

### Key contracts (keep these names so phases fit together)

**GameState (autoload)** extends the lab's version:
```gdscript
const SAVE_PATH := "user://save.cfg"
const TOTAL_LEVELS := 5
var unlocked_level: int = 1
var best_stars: Dictionary = {}        # int level -> int 1..3
var best_times: Dictionary = {}        # int level -> float seconds
var current_level: int = 1
var mode: String = "offline"           # "offline" | "online"
var offline_style: String = "solo"     # "solo" (you + computer buddy) | "duo" (2 people, 1 phone)
var last_result: Dictionary = {}       # {won, stars, level, time, place}
var avatar: Dictionary = {}            # AvatarData dict
var avatar_p2: Dictionary = {}         # second person in duo mode
var settings: Dictionary = {"sound": true, "music_volume": 0.7, "vibration": true, "quality": "high", "show_fps": false}
var seen_tutorial: bool = false
func is_unlocked(level: int) -> bool
func complete_level(level: int, stars: int, time_used: float) -> void   # saves
func save_progress(path: String = SAVE_PATH) -> void
func load_progress(path: String = SAVE_PATH) -> void
func reset_progress() -> void
func has_avatar() -> bool
func level_scene_path(level: int) -> String
static func calc_stars(time_left: float, time_limit: float) -> int     # 0 when lost
```
Offline duo progress uses the same save (one campaign per phone).

**AvatarData**
```gdscript
const SKIN_TONES := [6 Color values]
const OUTFIT_COLORS := [8 Color values]
const HATS := ["none", "cap", "crown", "propeller", "bucket"]
const TOOT_COLORS := ["green", "mint", "purple", "pink", "yellow"]   # differ in brightness too (color-blind friendly)
static func default_avatar() -> Dictionary   # {name:"Player", skin:0, outfit:0, hat:1, toot:0}
static func random_avatar(rng: RandomNumberGenerator) -> Dictionary
static func sanitize(d: Variant) -> Dictionary  # clamps indexes, strips name to 12 printable chars, fills missing keys
```
Ring colors come from the team (orange or purple), not the avatar.

**SwimRing** (numbers in `ENVIRONMENT_SPEC.md` section 8)
```gdscript
signal tooted(seat: int, direction: Vector3)
signal popped
signal fell
signal finished
const SEATS := 2
const RADIUS := 1.45
const SEAT_LOCAL := [Vector3(-0.62, 0, 0), Vector3(0.62, 0, 0)]
const MAX_GAS := 3
const REFILL_TIME := 1.5
const TOOT_IMPULSE := 7.0
const MAX_SPEED := 14.0
var team: int                       # 0 = orange, 1 = purple
var gas: Array[int] = [3, 3]
var seat_control: Array[String] = ["local", "buddy_ai"]
	# "local" (this phone, any tap) | "local_left" | "local_right" (duo halves)
	# | "buddy_ai" | "rival_ai" | "peer:<id>" (online human)
var simulate: bool = true           # false on online guests: the host's synced state drives it
func toot_from_seat(seat: int, world_point: Vector3) -> bool   # false if no gas, popped, falling, or finished
func add_gas_all(amount: int) -> void
func pop() -> void
func fall_into_hole() -> void
func respawn_at(d: float) -> void
func set_rider_avatar(seat: int, avatar: Dictionary) -> void
```

**Level data shape (`LevelDefs.LEVELS`, an Array of Dictionary).** Distances are in meters. `d` is distance forward from the start; the builder maps `[x, d]` to `Vector3(x, 0, -d)`. Full example: Level 3 in `ENVIRONMENT_SPEC.md` section 12.
```gdscript
{
  "number": 1, "name": "Lazy River",
  "goal_text": "Reach the finish arch in 75 seconds",
  "time_limit": 75.0,
  "rival_ring": false, "rival_toot_delay": 2.2, "rival_aim_error_deg": 20.0,
  "segments":    [ {"d": 0, "length": 40, "width": 14, "x": 0}, ... ],
  "islands":     [ {"pos": [x, d], "radius": 3.0} ],
  "holes":       [ {"pos": [x, d], "radius": 2.0} ],               # max 8
  "spike_rails": [ {"side": "left", "from": 96, "to": 119} ],
  "obstacles":   [ {"type": "sweeper", "pos": [x, d], "length": 6.5, "speed_deg": 70}, ... ],
  "beans":       [ [x, d], ... ],
  "checkpoints": [ d1, d2 ],
  "waypoints":   [ [x, d], ... ],     # computer racing line, start to finish
  "start": [0, 4], "finish_d": 172,
  "umbrellas":   [ [color_index, side, d], ... ]
}
```
Obstacle types: `bumper`, `sweeper`, `spike_wall`, `whirlpool`, `spike_log`, `current`.

**Every moving obstacle is driven only by the shared race clock** (`Level.race_time`). Never its own timer or random numbers. This keeps obstacles identical on every phone online with no extra network data.

---

## Phase 1: Foundation, avatar creator and test harness

**Goal:** the project opens, the settings match the lab, the save system and avatar creator work, and tests run headless.

### Tasks
1. **Project settings** (lab Phase 2): Renderer Compatibility; viewport 720 × 1280; stretch mode `canvas_items`, aspect `expand`; orientation Portrait; Emulate Touch From Mouse on; physics ticks 60; `application/config/quit_on_go_back = false`. App name "Toot Tubes". Enable multi-touch (needed for duo mode).
2. **Folders and Git**: create the structure above. `.gitignore` = the lab's version (`.godot/`, `/android/`, `*.apk`, `*.aab`, `*.ipa`, `export/`) plus `*.keystore`, `*.jks`, `export_credentials.cfg`, `.bin/`. Do **not** ignore `addons/gut/`; it is committed so tests run anywhere.
3. **Test setup**: add GUT to `addons/gut/` (the GUT release for Godot 4 from github.com/bitwes/Gut). Add `tools/run_tests.sh`:
   ```bash
   #!/usr/bin/env bash
   set -e
   GODOT=${GODOT:-godot}
   $GODOT --headless --path . --import
   $GODOT --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
   ```
   Add `tools/setup_godot.sh` that downloads the Godot Linux binary matching `GODOT_VERSION` (default `4.7-stable`) from `github.com/godotengine/godot-builds/releases` into `./.bin/` if `godot` is not on PATH.
4. **Autoloads**: `GameState.gd` (contract above), `Audio.gd` (stub: `play_sfx(name)`, `play_music()`, respects `settings.sound`), `Net.gd` (empty stub for now).
5. **AvatarData.gd** (contract above).
6. **RiderModel.tscn**: the rider from `ENVIRONMENT_SPEC.md` section 8 (body, head, eyes, hat options). One method: `apply(avatar: Dictionary)`. Low poly (12 to 16 radial segments).
7. **AvatarCreator.tscn**: top half is a `SubViewportContainer` showing your rider sitting in an orange ring, slowly spinning, on a small water disc with sky behind. Bottom half: name `LineEdit` (max 12), and for each option a row with ◀ value ▶ buttons (at least 120 px). Buttons: Randomize, Save. Save writes to `GameState.avatar` and saves. The same screen with a "Player 2" title edits `avatar_p2` (opened from duo mode).
8. **Placeholder screens** with working navigation: Title (tap to start) → if no avatar saved, AvatarCreator first → MainMenu (Play, Avatar, Settings, Credits). Play goes to an empty ModeSelect for now. Android back gesture (`NOTIFICATION_WM_GO_BACK_REQUEST`) goes back one screen; on Title it quits.
9. **Font and theme**: one `Theme` resource with Fredoka, body text at least 28 px, buttons at least 120 px high, rounded flat button styles (sky `#6EC6F0`, deep `#1A8FB8`, sand `#FFA24C`, rim green `#7ACB3B`, orange accent `#FF7A3D`, text white with dark outline). If the font file is missing, ask the user to put `Fredoka-*.ttf` in `assets/fonts/` and continue with the default font.
10. **Docs**: write `docs/GDD.md` from Section 0 using the lab's 11-heading template. Create `docs/PROGRESS.md` and `docs/CREDITS.md`.

### Automated tests (Codex runs these)
- `tests/test_game_state.gd`: level 1 unlocked at start; completing 1 unlocks 2; completing 1 again does not unlock 3; best stars keep the max; level 5 does not unlock 6; save then load at a test path gives the same values (simulates app restart); `reset_progress` works; `calc_stars` gives 3 / 2 / 1 / 0 at the boundaries.
- `tests/test_avatar.gd`: default is valid; `sanitize` clamps bad indexes, cuts long names to 12, fills missing keys, handles `null` and non-dictionary input; avatar and avatar_p2 survive save and load.
- `tests/test_scenes_smoke.gd`: every `.tscn` under `scenes/` loads, instantiates and frees without errors.

### Gate 1 (you check)
- [ ] `tools/run_tests.sh` passes (Codex shows the output).
- [ ] Press F5 in Godot: Title → Avatar creator → Main menu. Window is portrait.
- [ ] Change every avatar option; the 3D preview updates. Randomize works. Close Godot, run again: your rider is still there.
- [ ] Commit: `Phase 1: foundation, save system, avatar creator`.

---

## Phase 2: The sky course and the shared ring (Level 1 playable)

**Goal:** Level 1 is fun to play on the computer: the sky course, smooth shared ring, tooting from both seats, holes, beans, finish arch, timer and goal text.

**Build every visual and number in this phase from `ENVIRONMENT_SPEC.md` sections 1 to 6 and 8 to 11.** Where this phase and the spec differ, the spec wins.

### Tasks
1. **Shaders** (`shaders/`): `water.gdshader` (with the `holes` array), `cliff.gdshader`, `sky.gdshader`, exactly as in the spec.
2. **Course pieces** (`scenes/course/`): `WaterSegment`, `BankBox` (cliff shader, from y −40 to 0.9), `Rim`, `Hole` (foam rim + shaft + `Area3D`), `Island`, `FinishArch` (+ sign + `Area3D`), `Checkpoint` (buoys + `Area3D`), `Bean`, `SkyDecor` (clouds as `MultiMeshInstance3D`, floating islands, balloons, umbrellas). Use shared materials; one material per color.
3. **LevelBuilder.gd**: reads one `LevelDefs` dictionary and builds water segments, banks (joint rules from spec section 6), rims, holes (and fills the water shader's `holes` uniform), islands, beans, checkpoints, finish, umbrellas, sky decor and the start position. Phase 3 adds obstacles, spike rails and the rival ring.
4. **SwimRing.tscn + SwimRing.gd** (contract above, numbers in spec section 8):
   - `RigidBody3D`, mass 1, `gravity_scale = 0`, lock linear Y and angular X/Z, `inertia = Vector3(0, 2.9, 0)`, linear damp ≈ 1.1, angular damp ≈ 2.0, sphere collider r 1.45, bounce 0.5. Clamp speed to 14 and spin to 4 rad/s.
   - Ring mesh (8 striped arcs in team color and white), two `RiderModel` seats, blob shadow.
   - `toot_from_seat`: seat world position → flat direction to the tap point (ignore if under 0.3 m) → `apply_impulse(dir * 7.0, seat_world - global_position)`; that seat's gas −1; emit `tooted`; puff in that rider's toot color from behind the seat; ring and rider squash; toot sfx at random pitch 0.9 to 1.15; light vibration if enabled.
   - Gas refills per seat. Ripple trail while speed > 1.5. Bob and roll animation.
   - `pop()`, `fall_into_hole()`, `respawn_at()` as in the spec. Blink for 1.5 s after respawn.
5. **TapInput.gd**: in `_unhandled_input`, on `InputEventScreenTouch` pressed (every finger, so two people can tap at once): ray from the camera through the tap, intersect the plane y = 0. Pick the seat: in solo, seat 0; in duo, left half of the screen = seat 0, right half = seat 1. Call `ring.toot_from_seat(seat, point)`. Taps on UI buttons must not toot.
6. **Computer buddy (basic)** in `RingBrain.gd`: for solo mode, copies your toot direction after 0.18 s (85%), and steers alone toward the next waypoint every 1.2 s if you have not tooted for 1.4 s (spec section 9).
7. **Camera**: follows your ring from behind and above (spec section 11), smooth, does not spin with the ring. Shake on bumps, falls and pops. Level intro: 2 s whole-course view, then glide into the play view during the countdown.
8. **Lighting and sky**: `WorldEnvironment` with the sky shader, ambient light, one `DirectionalLight3D` with shadows off (spec section 3).
9. **Level.gd** (extends `Node3D`, adapted from the lab's `Level.gd`): states `INTRO → COUNTDOWN → RACING → FINISHED`. Countdown "3, 2, 1, TOOT!" (taps blocked). `race_time` counts up from GO. `time_left = time_limit − race_time`. When your ring crosses the finish: `end_level(true)`. Time out: `end_level(false)`. Uses `GameState.calc_stars` and `complete_level`. For now the result can print and go back to the menu (Phase 3 adds the Result screen).
10. **HUD** (`CanvasLayer`): goal text big for the first 3 s, then small at the top (R2); timer (red under 10 s); distance "34 / 172 m"; **two gas meters** ("You" and "Buddy" or "P1" and "P2", 3 bean icons each); progress bar with a dot per ring; pause button top right (wired in Phase 3). In duo mode, a faint dashed line down the middle and "Left half: Player 1 · Right half: Player 2" until the first toot. Keep the top 80 px clear (notch).
11. **Level01.tscn** using `LevelDefs` level 1 (spec section 13): wide channel with gentle S-turns, one large hole, 12 beans, 2 checkpoints. First-time hints: "Tap the water to toot!", then "Toot together to go straight!", then near the hole "Holes drop you into the sky!".

### Automated tests
- `tests/test_swim_ring.gd`: a toot spends only that seat's gas and fails at 0; each seat refills 1 per 1.5 s; a toot forward from seat 0 alone gives forward velocity **and** non-zero spin; toots the same way from both seats give forward velocity and spin near 0; speed never exceeds 14; a tap closer than 0.3 m does nothing; `add_gas_all(1)` raises both seats, capped at 3.
- `tests/test_holes.gd`: a ring placed over a hole (center within radius − 0.2) falls, emits `fell`, and respawns 3 m past the last checkpoint after about 1.2 s; a ring at the hole's edge (center outside radius − 0.2) does not fall.
- `tests/test_level_builder.gd`: building level 1 creates water for every segment, a start, a finish area, at least 2 checkpoints, all beans and holes; the water shader's `holes` uniform matches the level data; the channel is closed (a ring pushed sideways at many d values always hits a wall).
- Add the new scenes to the smoke test.

### Gate 2 (you check)
- [ ] Tests pass.
- [ ] Play Level 1 on the computer (click = tap). It looks like `docs/reference/ref_play_view.png`: sky, clouds, striped cliffs, your two riders in one ring.
- [ ] Tooting feels punchy. Your buddy follows your toots and the ring goes fairly straight. Without the buddy (stop and let it steer), the ring spins when only one side toots.
- [ ] Drift into the hole: the ring drops and comes back at the buoys.
- [ ] Turn on duo mode (temporary debug toggle is fine): left and right halves control different riders. Two fingers at once both work.
- [ ] FPS stays at 60 on the computer.
- [ ] **Install a debug APK on your phone now** (lab says install early). Taps work, portrait, smooth.
- [ ] Commit: `Phase 2: sky course, shared ring, Level 1`.

---

## Phase 3: Obstacles, 5 levels, rival ring, progression and offline modes

**Goal:** the full offline game: 5 levels with obstacles, the rival computer ring, level select with locks, result screen, pause menu, solo and duo. Works in airplane mode.

### Tasks
1. **Obstacles** (`scenes/course/` + `scripts/obstacles/`), all from spec section 7, all moving ones `AnimatableBody3D` driven only by `Level.race_time`: `Bumper`, `Sweeper`, `SpikeWall`, `Whirlpool` (with its center drain hole), `SpikeLog`, `Current`. Plus **`SpikeRail`** from spec section 6 (one `MultiMeshInstance3D` for all rail spikes in a level). Use MultiMesh for every repeated small part.
2. **LevelDefs.gd**: Level 3 is copied exactly from `ENVIRONMENT_SPEC.md` section 12. Write Levels 1, 2, 4, 5 following spec section 13 and the Level plan table. Each later level must be harder or different. Leave a fair line through every obstacle for a ring 2.9 m wide. Never put a checkpoint respawn point near a hole.
3. **Rival ring** in `RingBrain.gd`: a purple `SwimRing` whose two seats are `rival_ai` (spec section 9): each seat toots toward the next waypoint every `rival_toot_delay` to `+0.5` s with up to `rival_aim_error_deg` error. Same physics as you, so obstacles, holes and spikes affect it fairly. Rival riders get random avatars and the names "Bubbles" and "Fizz".
4. **Screens**:
   - `ModeSelect`: **Play Offline**, **Play Online**, Back (lab code). Play Offline asks **Solo** (you + computer buddy) or **Duo** (2 people, 1 phone). Duo opens the Player 2 avatar creator the first time.
   - `LevelSelect`: 5 big level cards (number, name, best stars, best time). Locked cards show a lock icon, are greyed out and do nothing when tapped (R4).
   - `Result`: "Level Cleared!" or "Try Again", stars pop in one by one, time, place (1st/2nd), Retry, Next (disabled if lost or on level 5), Menu (R3). Confetti and a fanfare on a win; on an unlock, "Level N unlocked!" with a sparkle.
   - `PauseMenu`: Resume, Restart, Sound On/Off, Quit to menu. `get_tree().paused = true`, menu `process_mode = WHEN_PAUSED` (R10). Android back during a race opens pause.
5. **Offline flow**: ModeSelect → Solo/Duo → LevelSelect → Level → Result, like the lab's game flow diagram. Clearing a level saves before the Result screen. No network code runs offline (`Net` stays idle).
6. **Tutorial hints**: Level 1 (toot, toot together, beans, hole), Level 3 first time ("Spikes pop you!"). Store `seen_tutorial`.

### Automated tests
- `tests/test_level_defs.gd`: exactly 5 levels numbered 1..5; each has non-empty `goal_text`, `time_limit > 0`, start, finish, at least 2 checkpoints, at least 4 waypoints ending past `finish_d`, at most 8 holes; all obstacle types are known; holes and islands are inside their segment and do not touch walls; no checkpoint respawn point is within 4 m of a hole; Levels 3, 4, 5 each add an obstacle type or have less time than the level before; no rival in Level 1, a rival ring in 2 to 5.
- `tests/test_ring_solvable.gd` (important): for each level, run it headless with a **perfect computer ring** (both seats, no aim error, delay 0.5 s, always tooting the same way) at a fixed physics step for up to `time_limit` seconds. Assert it finishes in time. Then run the level's real rival ring and assert it also finishes in time but slower than the perfect ring (so players can win).
- `tests/test_obstacles.gd`: a `Sweeper` at `race_time = 1.0` has the same rotation every run; `SpikeWall` position matches the formula; the whirlpool pulls toward its center; a ring touching a spike rail pops, a ring 1 m away does not.
- `tests/test_progression_flow.gd`: `complete_level(2, 2, 40.0)`, reload from file, level 3 unlocked and level 4 locked.
- `tests/test_duo_input.gd`: a simulated tap on the left half tooted seat 0, the right half seat 1; two taps in the same frame both toot.

### Gate 3 (you check)
- [ ] Tests pass, including ring solvability for all 5 levels.
- [ ] Level 3 matches `docs/reference/ref_play_view.png` and `ref_whole_course.png`.
- [ ] Play all 5 levels solo. Each feels harder or new. Obstacles move smoothly. The rival ring is beatable but not easy.
- [ ] Play 2 levels in **duo** with a classmate on one phone.
- [ ] Lose a level on purpose: Try Again, Retry works. Clear it: stars, Next unlocks (R3).
- [ ] Level select shows locks; locked levels cannot be opened (R4).
- [ ] On the phone: clear Level 2, force-close, reopen: Level 3 still unlocked (R5).
- [ ] On the phone in **airplane mode**: Play Offline, clear Level 1, close and reopen. No freeze, no error (R6). Screen-record this (lab Checkpoint 4).
- [ ] Commit: `Phase 3: obstacles, 5 levels, rival ring, offline solo and duo`.

---

## Phase 4: Online multiplayer (2 to 4 phones, same Wi-Fi)

**Goal:** phones on the same Wi-Fi join one race. **Do 4A first** (2 phones, needed for R7), then 4B (up to 4 phones). The host runs the physics and decides the winner. Every failure ends on a clear message, never a crash.

### Phase 4A: 2 phones share one ring (required)
1. **Net.gd** (start from the lab's code, page 17): `PORT = 7777`, `MAX_CLIENTS = 3` (ready for 4B). Signals `match_ready`, `net_error(message)`, `players_changed`. Add:
   - `players: Dictionary` (peer_id → `{name, avatar, seat_index}`), where seat_index 0..3 means orange seat 0, orange seat 1, purple seat 0, purple seat 1.
   - `@rpc("any_peer", "reliable") func register_player(data: Dictionary)`: the host runs `AvatarData.sanitize` on it, assigns the first free seat (host = 0, first guest = 1, then 2, then 3), and sends the full `players` list to everyone.
   - `func seat_plan() -> Array`: for each of the 4 seats, either a peer id or `"buddy_ai"` / `"rival_ai"`. Rule: if the purple ring has no humans, both its seats are `rival_ai`; if a ring has one human, the empty seat is `buddy_ai`.
   - `my_ip()` from the lab code; show all LAN addresses if more than one. `leave()` resets `players` and sets `OfflineMultiplayerPeer`.
2. **Lobby.tscn** (lab A.2): your rider and name. **Host** → "Waiting… your IP is 192.168.x.x". IP `LineEdit` (numeric keyboard, remembers last IP) + **Join**. Status label. A 5-second `Timer` after Join: if not connected, `Net.leave()` and show "Cannot reach host. Check that you are on the same Wi-Fi." (R8). Show the 4 seats as two rings with the riders or "Computer" in each seat. Host picks a course (any of the 5 levels; online ignores offline locks) and taps Start. Guests see "Waiting for host to start…". Back leaves cleanly.
3. **Starting the match**: host calls `start_match.rpc(level, seed, seat_plan)`. Every phone loads the level and builds both rings from the seat plan. Each phone reports "loaded"; when all have, the host sends `begin_countdown.rpc()`. `race_time` starts at GO on each phone.
4. **Host-authoritative rings** (simple and fair for shared rings):
   - Only the **host** simulates physics for both rings (`simulate = true`). On guests, rings are `freeze = true`, `freeze_mode = KINEMATIC`, and follow the host.
   - A guest's tap sends `@rpc("any_peer", "reliable") func request_toot(seat_index, dir: Vector3)` to the host. The host checks that the sender owns that seat, the race is running, and the seat has gas, then calls `toot_from_seat`. The guest plays the puff and sound **right away** for feel; the host's result follows within a few milliseconds on LAN.
   - The host also runs the computer seats (`buddy_ai`, `rival_ai`).
   - A `MultiplayerSynchronizer` on each ring syncs `position`, `rotation.y`, `linear_velocity`, `angular_velocity.y`, `gas`, and a state byte (alive / popped / falling / finished) from the host at about 30 Hz. Guests interpolate between the last two snapshots with a small velocity prediction; snap only if the error is over 3 m.
   - Host broadcasts effects: `@rpc("authority", "unreliable") fx_toot(ring, seat, dir)` (for toots from other phones), `@rpc("authority", "reliable") fx_pop(ring)`, `fx_fall(ring)`.
   - Rider avatars and name labels (`Label3D`, billboard) from `Net.players`.
5. **Winner (host decides)**: the host sees the finish crossing in its own simulation and calls `announce_winner.rpc(team, race_time)` (lab pattern). Time out with no finisher: `announce_draw.rpc()`.
6. **OnlineResult screen**: "Your team wins!" / "Your team lost!" / "Time's up! Draw", both rings with riders, finishing time. **Rematch** (host only, same course) and **Leave**. Online results do **not** change offline progress.
7. **Disconnects**: if any player leaves or the connection drops at any point, the host replaces that seat with a computer rider and the race continues; if the **host** leaves, every guest stops, calls `Net.leave()`, goes to ModeSelect and sees "The host left the game." in an in-game popup (not an OS dialog). Pause online shows the menu but does not pause the race ("The race keeps going online").
8. **Android export**: tick **Internet** and **Access Network State** in the Android preset (lab A.4).

### Phase 4B: up to 4 phones, 2 vs 2 (stretch, do after 4A works on real phones)
- Guests 2 and 3 take the purple seats. The lobby shows "2 vs 2" when 4 are in. Nothing else changes: the host already simulates both rings and fills empty seats with computer riders.
- Check the network load: 2 rings × 30 Hz is small; keep toot requests tiny (seat + 2 floats).

### Automated tests
- `tests/test_net_seats.gd`: seat assignment for 1, 2, 3 and 4 players; `seat_plan()` fills empty seats with `buddy_ai` / `rival_ai` correctly; a player leaving frees their seat and it becomes a computer seat.
- `tests/test_net_validation.gd`: `register_player` with bad data ends up sanitized; `request_toot` is rejected for a seat the sender does not own, when the race is not running, or when the seat has no gas.
- `tests/net_smoke.gd` + `tools/net_smoke.sh`: start a headless host (`--net-test-host`) and a headless client (`--net-test-client 127.0.0.1`). Assert: client connects; both `players` lists have 2 entries in seats 0 and 1; the host starts level 1; both load it; a client `request_toot` changes the orange ring's velocity on the host and the synced position reaches the client within 1 s; then the client quits and the host replaces seat 1 with `buddy_ai` without crashing. Exit code 0 on success.
- `tools/net_smoke.sh` second case: client joins `10.255.255.1` (unreachable); after 5 s the "Cannot reach host" error is set; exit code 0, no crash.
- Optional third case (4B): host + 3 headless clients fill all 4 seats.

### Gate 4 (you check, needs 2 Android phones; 4 for 4B)
- [ ] Tests and net smoke pass.
- [ ] Both phones on the same Wi-Fi or one phone's hotspot. Phone A hosts, Phone B joins by IP. The lobby shows both of you in the orange ring and "Computer" in the purple ring.
- [ ] Race: both of you control the same ring from your own seats. Tooting together goes straight. Movement is smooth on both phones, obstacles match.
- [ ] The result is right on both phones (R7).
- [ ] Turn Wi-Fi off on Phone B, choose Online, Join: error message, no crash (R8).
- [ ] Close the app on Phone B mid-race: Phone A keeps racing with a computer buddy. Close the host app: Phone B shows "The host left the game." and returns to the menu.
- [ ] Record this video (lab Checkpoint 5).
- [ ] (4B) With 4 phones: 2 vs 2 works.
- [ ] Commit: `Phase 4: online shared rings`.

### Phase 4C (optional bonus, only if Phases 1 to 5 are done): Nakama backend
Internet play and an online leaderboard. Server: `docker compose up -d` with the official Nakama compose file on a laptop or school server (ports 7350 API, 7351 console). Client: the `nakama-godot` addon. Add "Play over internet" in the Lobby: `authenticate_device_async`, `add_matchmaker_async("*", 2, 4)`, then the same messages as Option A as match state (op codes: 1 ring state from the host, 2 toot request, 3 fx, 4 result). Leaderboard `best_times_level_N`. Change `defaultkey` and the console password, never commit them. Keep Option A working; the lab requires it.

---

## Phase 5: Polish, performance and release build

**Goal:** it looks and feels finished, runs smoothly on two different phones, every asset is credited, and a release APK is on GitHub (v1.0).

### Tasks
1. **Audio**: `tools/gen_sfx.py` (Python standard library only: `wave`, `math`, `random`) generates original `.wav` files into `assets/audio/`: `toot_1..4` (low noisy buzz with pitch bend, 0.25 to 0.5 s), `bean`, `boing`, `pop`, `fall` (falling whistle), `tap`, `countdown`, `go`, `win`, `lose`, `unlock`, `wind` (soft sky ambience loop). Music: one CC0 `.ogg` loop the user adds to `assets/audio/music.ogg`; if it is missing, the game runs silently. Music plays from the `Audio` autoload. Sound On/Off is saved (R10).
2. **Settings screen** (bonus): sound on/off, music volume, vibration, graphics Low/High, show FPS. Low = no ripple trail, fewer clouds and particles, fewer water subdivisions, sky shader replaced by a flat color.
3. **Juice**: button press scale tween, screen shake, stars pop in, confetti on wins, unlock sparkle, rider cheer (jump tween) when crossing the finish.
4. **Title screen**: "Toot Tubes" in Fredoka with an outline over a live 3D background (your two riders in a ring bobbing on a cloud-high pool, a puff now and then), "Tap to start".
5. **Credits screen** + `docs/CREDITS.md`: every asset with author and license (Fredoka OFL, music CC0 source, GUT MIT, Godot MIT, generated sounds "original").
6. **App icon**: 1024 × 1024 PNG (a striped ring with two riders and a green puff, sky background), set in Project Settings and the Android preset (main, adaptive foreground and background).
7. **Performance pass**: hidden FPS and draw-call label (Settings → Show FPS). Check the budget in Section 1. Reuse materials, MultiMesh for repeats (spikes, clouds, rail cones), no shadows, small particle counts, pre-warm particles during the countdown. Default to Low quality on first launch if FPS stays under 40 for 3 s.
8. **Android release export**: package `com.itsd85.<team>.toottubes`, name "Toot Tubes", portrait, permissions Internet + Access Network State, version 1.0 (code 1). Create a release keystore with `keytool` **on your computer**, never commit it. Export `export/TootTubes-v1.0.apk` with "Export With Debug" off.
9. **README.md** with the lab's headings (page 30): About the game (pitch + 2 screenshots), How to play (shared ring, solo/duo), Offline and online modes (host/join, seats), How to build (Godot version, export steps, run tests), Download (v1.0 release link), Playtest results, Credits, Paper.
10. **CI (optional)**: `.github/workflows/tests.yml` that runs `tools/setup_godot.sh` and `tools/run_tests.sh` on every push.
11. **Test matrix**: `docs/TEST_MATRIX.md` with the lab's table (page 23) for 2 phones.

### Automated tests
- Full test run plus net smoke pass.
- `tests/test_settings.gd`: sound off is saved and loaded; Audio plays nothing when sound is off; a missing `music.ogg` causes no error; Low quality hides ripples and reduces clouds.
- `tests/test_scenes_smoke.gd` still passes for every screen.

### Gate 5 (you check: final acceptance)
Go through the lab's R1 to R10 with the release APK on **two different phones**:
- [ ] R1 to R5: all 5 levels, goal text, results, locks, progress survives force-close.
- [ ] R6: airplane mode offline play (solo and duo).
- [ ] R7, R8: online match on two phones; Wi-Fi-off error.
- [ ] R9: installs from the APK, portrait only, touch works (two fingers in duo).
- [ ] R10: title, pause menu, sound toggle, text readable on the smallest phone.
- [ ] Smooth (no visible stutter), not too hot after 10 minutes. Fill in `docs/TEST_MATRIX.md`.
- [ ] Screenshots of every screen in `docs/screenshots/` (lab Checkpoint 6).
- [ ] Repo name `itsd85-lab<no>-bsit4c-<team>`. Tag and release:
  ```bash
  git switch main && git pull
  git tag -a v1.0 -m "ITSD 85 Lab final submission"
  git push origin v1.0
  ```
  GitHub → Releases → v1.0 → attach the APK (not in the repo) → Publish.

**After the game (not Codex work, plan time for it):** playtest with 5+ testers using the lab forms (Phase 8 of the PDF; play solo Levels 1 to 3, then one online match sharing a ring with a team member), fix at least 3 issues and retest, demo video (2 to 3 min), the IEEE paper, the contribution log, then submit on Google Classroom. If you fix playtest issues, release v1.1.

---

## Time estimate (with Codex doing the coding)

| Phase | Work | Rough time |
|---|---|---|
| 1 | Foundation, save, avatar creator, tests | 2 to 3 h |
| 2 | Sky course, shared ring, Level 1 | 5 to 7 h |
| 3 | Obstacles, 5 levels, rival ring, solo and duo, menus | 5 to 7 h |
| 4A | Online, 2 phones in one ring | 5 to 7 h |
| 4B | Up to 4 phones (2 vs 2) | 1 to 2 h |
| 5 | Polish, release APK | 3 to 4 h |

About **3 full days** now, up from 2: the shared ring, sky course and 4 players add work. Phase 2 (ring feel) and Phase 4A (online) are the riskiest. If time runs out, cut in this order: Phase 4C, Phase 4B (stay at 2 phones), Settings extras, spike logs, balloons and floating islands (keep clouds), avatar hats. **Never cut** anything in the R1 to R10 table.

## Known risks and fallbacks

| Risk | Fallback |
|---|---|
| The shared ring feels hard to control | Raise the buddy's copy chance to 95%, lower `inertia` spin effect (raise inertia to 3.5), add a small auto-straighten (extra angular damp) on Level 1 |
| 3D runs slowly on a cheap phone | Low quality by default if FPS stays under 40 for 3 s; flat sky color; fewer clouds and particles |
| Online movement looks jumpy | Raise sync to 30 Hz (already), increase interpolation delay to 100 ms |
| Online toot feels late on a guest | Keep the instant local puff and sound; on LAN the push arrives within a few ms |
| Godot version in Codex differs from yours | Set `GODOT_VERSION` in `tools/setup_godot.sh` to your exact version; open the project in your editor before each gate |
| Codex cannot see the game | It relies on the automated tests and the reference images; the "You check" lists catch the rest. Send Codex screenshots of what looks wrong |
| Online fails only on phones | Check Android permissions (Phase 4A task 8), same Wi-Fi, use a phone hotspot (school Wi-Fi often blocks device-to-device traffic) |
