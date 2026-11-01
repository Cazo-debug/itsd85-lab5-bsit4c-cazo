> HISTORICAL REFERENCE ONLY. Superseded on 2026-11-01 by the root IMPLEMENTATION_PLAN.md and ENVIRONMENT_SPEC.md. Do not execute instructions in this archived document.

# Toot Tubes: Implementation Plan

> 2026-11-01 scope update: Phases 1 and 2 now include the approved
> [sky environment revision](docs/SKY_ENVIRONMENT_REVISION.md), using the supplied
> `toot-tubes-codex-pack/` visuals. The user selected environment first; the pack's
> shared-ring gameplay migration remains pending. The original plan below is
> retained as the baseline and does not mark the full v2 phases complete.

ITSD 85 Lab: Mobile Game with Level Progression and Offline/Online Multiplayer
Section: BSIT-4C · Platform: Android (APK) · Orientation: portrait · Engine: Godot 4 (GDScript)

> **How to use this file with Codex**
> Put this file and `AGENTS.md` in the root of the Godot project repo. Then give Codex one phase at a time:
> `Do Phase 1 of IMPLEMENTATION_PLAN.md. Follow AGENTS.md. Stop at the Phase 1 gate and report.`
> Do not start the next phase until **you** have done that phase's "You check" list on your computer or phone.

---

## 0. The game in one page (source of truth)

**Pitch:** Players sit on pool floats in a 3D water park and race to the finish. The only way to move is to toot.

**Look (inspired by the reference clip, all original assets):** bright 3D water park seen from a tilted camera above and behind the player. Turquoise water, orange sand islands with green rims, black spike walls, spinning sweeper bars, round bumper islands, white ripple rings behind each float, green fart puffs. Low-poly, flat colors, no textures except tiny generated ones. **Do not copy characters, logos, names or music from the reference game or any commercial game** (lab rule, page 21).

**Core mechanic (one thumb):**
- Tap anywhere on the water. Your float toots and gets pushed toward that spot.
- You hold up to **3 toots** (gas meter). One toot refills every **1.5 s**. A **bean** pickup refills one instantly.
- Floats drift and slow down on their own (water drag). Floats bump into each other and into obstacles.
- Hitting **spikes** pops you: you respawn at the last checkpoint after 1 s (time keeps running).

**Win / lose (offline):** Win = cross the finish ring before the timer hits 0 **and** before every bot. Lose = timer hits 0, or a bot finishes first.
**Stars:** win with more than 50% time left = 3, more than 25% = 2, otherwise 1 (same formula as the lab's `Level.gd`).

**Modes:**
- **Offline:** 5-level campaign. Level 1 solo tutorial, Levels 2 to 5 vs computer floats that get faster each level. Works in airplane mode.
- **Online:** 2 phones on the same Wi-Fi (host and join by IP, lab Option A). Same course, live race, host decides the winner. Online results do not change offline unlocks.

**Avatar creator:** name (max 12 chars), skin tone, outfit color, float style, hat, toot color. Saved on the phone. Your opponent sees your avatar and name online.

### Level plan (R1, R2)

| Lvl | Name | Goal text on screen | New or harder | Time | Bots |
|---|---|---|---|---|---|
| 1 | Lazy River | Toot to the finish ring in 75 seconds | Learn to toot, beans, gentle current, hint arrows | 75 s | 0 |
| 2 | Bumper Bay | Beat Bubbles to the finish in 60 seconds | Round bumper islands, first bot (slow) | 60 s | 1 |
| 3 | Sweeper Spin | Beat Bubbles past the sweepers in 60 seconds | Spinning sweeper bars, spike walls that pop you | 60 s | 1 |
| 4 | Whirl Pool | Beat Bubbles through the whirlpools in 55 seconds | Whirlpools that pull you, moving spike walls, fewer beans | 55 s | 1 |
| 5 | Grand Toot | Beat Bubbles and Fizz in 70 seconds | Everything plus rolling spike logs, longer course, 2 bots | 70 s | 2 |

### Lab requirement map (acceptance checklist)

| Req | Where it is built | Where it is tested |
|---|---|---|
| R1 5 levels, each harder | Phase 3 (`LevelDefs.gd`) | `test_level_defs.gd`, bot solvability test |
| R2 Goal text on level start | Phase 2 HUD | You check, Phase 2 |
| R3 Result screen, stars, Retry/Next/Menu | Phase 3 | `test_stars.gd`, You check |
| R4 Locked levels show a lock | Phase 3 | `test_game_state.gd`, You check |
| R5 Progress survives app close | Phase 1 | `test_game_state.gd` save/load, You check on phone |
| R6 Offline in airplane mode | Phase 3 | You check, Phase 3 and 5 |
| R7 Two phones, one match | Phase 4 | `net_smoke` headless test, You check with 2 phones |
| R8 Offline/Online on menu, error not crash | Phase 3 menu, Phase 4 errors | `net_smoke` unreachable test, You check Wi-Fi off |
| R9 Real phone, fixed portrait, touch | Phase 1 settings, Phase 5 export | You check, Phase 5 test matrix |
| R10 Title, pause, sound on/off, readable text | Phases 3 and 5 | You check, Phase 5 |
| Bonus | Stars, player names, settings, tutorial hints, color-blind toot colors | Phase 5 |

---

## 1. Tech stack (all free, matches the lab PDF)

| Part | Choice | Why |
|---|---|---|
| Engine | **Godot 4** (the lab says 4.7; any 4.x stable from 4.3 up works), standard build, not .NET | Lab default, exports to Android |
| Renderer | **Compatibility** | Lab requirement for low-cost phones; supports simple 3D |
| Language | GDScript, static typing on | Lab default |
| Physics | Godot 3D physics, `RigidBody3D` floats locked to the water plane | Natural bumping and pushing with no extra code |
| 3D art | Built from Godot primitive meshes in code (capsules, spheres, tori, cylinders, boxes) | No downloads, tiny APK, Codex can build it all |
| Water | One small custom shader (vertex wave + scrolling color bands) | Looks good, very cheap |
| Effects | `CPUParticles3D` | Safest on low-end Android |
| Save | `ConfigFile` at `user://save.cfg` | Lab default, works offline |
| Online | High-level Multiplayer + `ENetMultiplayerPeer`, port 7777 | Lab Option A, no server |
| Optional backend | Nakama in Docker (Option B, bonus only) | See Phase 4B |
| Tests | **GUT** (Godot Unit Test, MIT) run headless | Codex can run them without a screen |
| Audio | Toot and UI sounds generated by a Python script into `.wav` (original, no license issue); one CC0 music loop added by you (`.ogg`) | Lab: `.ogg` music, `.wav` effects |
| Font | Fredoka (Google Fonts, OFL) | Round, readable, fits the look |
| Version control | Git + GitHub | Lab requirement |

**Performance budget (lightweight):** 60 fps on a mid-range phone, at least 30 fps on a low-end phone. Under 150 draw calls and under 60k triangles on screen. No real-time shadows on Low quality (use a soft blob-shadow quad under each float). APK under 60 MB.

---

## 2. Project structure

```
res://
├── AGENTS.md
├── IMPLEMENTATION_PLAN.md
├── autoload/
│   ├── GameState.gd        # progress, stars, avatar, settings, save/load
│   ├── Net.gd              # host/join, errors, player registry
│   └── Audio.gd            # music + sfx players, respects sound on/off
├── scenes/
│   ├── ui/                 # Title, MainMenu, ModeSelect, LevelSelect, AvatarCreator,
│   │                       # Lobby, Result, OnlineResult, Settings, Credits, PauseMenu, HUD
│   ├── levels/             # Level01.tscn ... Level05.tscn (thin: Level.gd + level_number)
│   ├── actors/             # FloatPlayer.tscn, AvatarModel.tscn, Bot (script on FloatPlayer)
│   └── course/             # Water, Bank, Island, FinishRing, Checkpoint, Bean,
│                           # Bumper, Sweeper, SpikeWall, Whirlpool, SpikeLog, Current
├── scripts/
│   ├── Level.gd            # race clock, win/lose, stars, countdown
│   ├── LevelBuilder.gd     # builds the course from LevelDefs data
│   ├── LevelDefs.gd        # const data for all 5 levels
│   ├── FloatPlayer.gd      # toot physics, gas, pop/respawn
│   ├── BotBrain.gd         # computer opponent
│   ├── TapInput.gd         # screen tap -> point on water
│   ├── AvatarData.gd       # avatar options, defaults, sanitize, to/from dict
│   └── obstacles/          # one script per obstacle type
├── shaders/water.gdshader
├── assets/{fonts,audio,icons}/
├── tools/gen_sfx.py        # generates original .wav effects
├── tests/                  # GUT tests + net_smoke.gd
├── addons/gut/
└── docs/                   # GDD.md, CREDITS.md, PROGRESS.md, TEST_MATRIX.md, screenshots/
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
var last_result: Dictionary = {}       # {won, stars, level, time, place}
var avatar: Dictionary = {}            # AvatarData dict
var settings: Dictionary = {"sound": true, "music_volume": 0.7, "vibration": true, "quality": "high", "show_fps": false}
var seen_tutorial: bool = false
func is_unlocked(level: int) -> bool
func complete_level(level: int, stars: int, time_used: float) -> void   # saves
func save_progress() -> void
func load_progress() -> void
func reset_progress() -> void
func has_avatar() -> bool
func level_scene_path(level: int) -> String
static func calc_stars(time_left: float, time_limit: float) -> int     # 0 when lost
```
`save_progress` and `load_progress` must accept an optional path argument so tests can use `user://test_save.cfg`.

**AvatarData**
```gdscript
const SKIN_TONES := [6 Color values]
const OUTFIT_COLORS := [8 Color values]
const FLOAT_STYLES := ["donut", "striped", "duck", "lifebuoy"]
const HATS := ["none", "cap", "crown", "propeller", "bucket"]
const TOOT_COLORS := ["green", "purple", "pink", "yellow"]   # all distinguishable for color-blind players (also differ in brightness)
static func default_avatar() -> Dictionary   # {name:"Player", skin:0, outfit:0, float_style:0, hat:0, toot:0}
static func random_avatar(rng: RandomNumberGenerator) -> Dictionary
static func sanitize(d: Variant) -> Dictionary  # clamps indexes, strips name to 12 printable chars, fills missing keys
```

**FloatPlayer**
```gdscript
signal tooted(direction: Vector3)
signal popped
signal finished
const MAX_GAS := 3
const REFILL_TIME := 1.5
const TOOT_IMPULSE := 9.0
const MAX_SPEED := 14.0
var gas: int
var is_local_controlled: bool       # false for bots and for remote online players
func toot_toward(world_point: Vector3) -> bool   # false if no gas
func add_gas(amount: int) -> void
func pop() -> void                  # spikes: hide, particles, respawn at checkpoint after 1 s
func apply_avatar(avatar: Dictionary) -> void
```

**Level data shape (`LevelDefs.LEVELS`, an Array of Dictionary).** Distances are in meters. `d` is distance forward from the start; the builder maps `[x, d]` to `Vector3(x, 0, -d)`.
```gdscript
{
  "number": 1, "name": "Lazy River",
  "goal_text": "Toot to the finish ring in 75 seconds",
  "time_limit": 75.0,
  "bots": 0, "bot_toot_delay": 1.6, "bot_aim_error_deg": 20.0,
  "segments":   [ {"d": 0, "length": 40, "width": 14, "x": 0}, ... ],   # channel pieces with banks on both sides
  "islands":    [ {"pos": [x, d], "radius": 3.0} ],                     # solid round islands
  "obstacles":  [ {"type": "sweeper", "pos": [x, d], "length": 8, "speed_deg": 70}, ... ],
  "beans":      [ [x, d], ... ],
  "checkpoints":[ d1, d2 ],
  "waypoints":  [ [x, d], ... ],      # bot racing line, start to finish
  "start": [0, 2], "finish_d": 140
}
```
Obstacle types: `bumper` (bouncy pillar), `sweeper` (spinning bar, pushes), `spike_wall` (slides side to side, pops on touch, `travel`, `period`), `whirlpool` (`radius`, `strength`, pulls toward center), `spike_log` (rolls across, pops), `current` (`size`, `dir`, `force`, pushes).

**Every moving obstacle is driven only by the shared race clock** (`Level.race_time`), for example `rotation_degrees.y = speed_deg * race_time`. Never use its own timer or random numbers. This keeps obstacles identical on both phones online with no extra network data.

---

## Phase 1: Foundation, avatar creator and test harness

**Goal:** the project opens, the settings match the lab, the save system and avatar creator work, and tests run headless.

### Tasks
1. **Project settings** (lab Phase 2): Renderer Compatibility; viewport 720 × 1280; stretch mode `canvas_items`, aspect `expand`; orientation Portrait; Emulate Touch From Mouse on; physics ticks 60; `application/config/quit_on_go_back = false`. App name "Toot Tubes".
2. **Folders and Git**: create the structure above. `.gitignore` = the lab's version (`.godot/`, `/android/`, `*.apk`, `*.aab`, `*.ipa`, `export/`) plus `*.keystore`, `*.jks`, `export_credentials.cfg`, `.bin/`. Do **not** ignore `addons/gut/`; it is committed so tests run anywhere.
3. **Test setup**: add GUT to `addons/gut/` (download the GUT release for Godot 4 from github.com/bitwes/Gut). Add `tools/run_tests.sh`:
   ```bash
   #!/usr/bin/env bash
   set -e
   GODOT=${GODOT:-godot}
   $GODOT --headless --path . --import
   $GODOT --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
   ```
   Add `tools/setup_godot.sh` that downloads the Godot Linux binary matching `GODOT_VERSION` (default `4.7-stable`) from `github.com/godotengine/godot-builds/releases` into `./.bin/` if `godot` is not on PATH. Add `.bin/` to `.gitignore`.
4. **Autoloads**: `GameState.gd` (contract above), `Audio.gd` (stub: `play_sfx(name)`, `play_music()`, respects `settings.sound`), `Net.gd` (empty stub for now).
5. **AvatarData.gd** (contract above).
6. **AvatarModel.tscn**: a `Node3D` that builds a chunky cartoon rider from primitives: capsule body (outfit color), sphere head (skin tone), two small black sphere eyes, simple hat meshes per hat option; sits in a float (TorusMesh; "striped" uses alternating ring segments; "duck" adds a sphere head and cone beak on the front; "lifebuoy" is red and white). One method: `apply(avatar: Dictionary)`. Low poly: set radial segments to 12 to 16.
7. **AvatarCreator.tscn**: top half is a `SubViewportContainer` showing the AvatarModel slowly spinning on a small water disc. Bottom half: name `LineEdit` (max 12), and for each option a row with ◀ value ▶ buttons (at least 120 px wide). Buttons: Randomize, Save. Save writes to `GameState.avatar` and saves.
8. **Placeholder screens** with working navigation: Title (tap to start) → if no avatar saved, AvatarCreator first → MainMenu (Play, Avatar, Settings, Credits). Play goes to an empty ModeSelect for now. Android back gesture (`NOTIFICATION_WM_GO_BACK_REQUEST`) goes back one screen; on Title it quits.
9. **Font and theme**: one `Theme` resource with Fredoka, body text at least 28 px, buttons at least 120 px high, rounded flat button styles in the game palette (water `#3CC3E6`, deep `#1A8FB8`, sand `#FF9F45`, rim green `#7ACB3B`, spike black `#1E2329`, text white with dark outline). If the font file is missing, ask the user to put `Fredoka-*.ttf` in `assets/fonts/` and continue with the default font.
10. **Docs**: write `docs/GDD.md` from Section 0 using the lab's 11-heading template. Create `docs/PROGRESS.md` and `docs/CREDITS.md`.

### Automated tests (Codex runs these)
- `tests/test_game_state.gd`: starts at level 1 unlocked; completing level 1 unlocks 2; completing level 1 again does not unlock 3; best stars keep the max; level 5 does not unlock 6; save then load at a test path gives the same values (simulates app restart); `reset_progress` works; `calc_stars` gives 3 / 2 / 1 / 0 at the boundaries.
- `tests/test_avatar.gd`: default is valid; `sanitize` clamps out-of-range indexes, cuts long names to 12, fills missing keys, handles `null` and non-dictionary input; avatar survives save and load.
- `tests/test_scenes_smoke.gd`: every `.tscn` under `scenes/` loads and instantiates and frees without errors.

### Gate 1 (you check)
- [ ] `tools/run_tests.sh` passes (Codex shows the output).
- [ ] Press F5 in Godot: Title → Avatar creator → Main menu. Window is portrait.
- [ ] Change every avatar option; the 3D preview updates. Randomize works. Close Godot, run again: your avatar is still there.
- [ ] Commit: `Phase 1: foundation, save system, avatar creator`.

---

## Phase 2: The 3D race (core gameplay in Level 1)

**Goal:** Level 1 is fun to play on the computer: smooth float, nice water, camera, tooting, beans, finish ring, timer and goal text.

### Tasks
1. **Water** (`shaders/water.gdshader`, `unshaded` or very simple lighting): big `PlaneMesh` (subdivided about 40 × 80) under the whole course. Vertex: small sine waves (amplitude 0.05 to 0.1). Fragment: turquoise base, lighter bands that scroll slowly, white foam where `fract` of a wave noise is near 1. No textures, no screen reading.
2. **Course pieces** (`scenes/course/`): `Bank` (orange `BoxMesh` walls with a green top strip, `StaticBody3D`), `Island` (orange `CylinderMesh` with green rim torus, `StaticBody3D`), `FinishRing` (yellow torus on posts + `Area3D` across the channel, checkered flag strip), `Checkpoint` (thin `Area3D`, small buoy markers), `Bean` (small brown capsule that bobs and spins, `Area3D`, gives +1 gas, respawns after 8 s).
3. **LevelBuilder.gd**: reads one `LevelDefs` dictionary and spawns banks along each segment, islands, beans, checkpoints, finish, start position, and (Phase 3) obstacles and bots. Only primitives and the scenes above. Use shared `StandardMaterial3D` resources (one per color), not one material per mesh.
4. **FloatPlayer.tscn**: `RigidBody3D`, `gravity_scale = 0`, lock linear Y and angular X/Z, `linear_damp ≈ 1.1`, `angular_damp` high, sphere collider radius 0.9, `PhysicsMaterial` bounce 0.5, layer "floats". Child `AvatarModel`. The visual child bobs (sine on Y, small tilt in the move direction) and smoothly turns to face the velocity. Clamp speed to `MAX_SPEED`.
   - `toot_toward`: direction = flat vector from float to target (ignore if shorter than 0.3 m); `apply_central_impulse(dir * TOOT_IMPULSE)`; gas −1; emit `tooted`; spawn a green puff (`CPUParticles3D`, 12 to 16 spheres, one-shot, behind the float, in the avatar's toot color); short squash-and-stretch tween on the visual; sfx `toot_1..4` at random pitch 0.9 to 1.15; light vibration if enabled.
   - Gas refills one every `REFILL_TIME`.
   - **Ripple trail**: a `CPUParticles3D` emitting flat white ring quads at the float's position while speed > 1.5, growing and fading over 0.8 s (like the reference clip).
   - **Blob shadow**: a dark transparent circle quad just above the water under the float.
5. **TapInput.gd**: in `_unhandled_input`, on `InputEventScreenTouch` pressed: ray from the camera through the tap, intersect plane y = 0, call `player.toot_toward(point)`. Taps on UI buttons must not toot (UI controls stop the event).
6. **Camera**: `Camera3D` that follows the local player from behind and above (pitch about −50°, distance about 14 m, FOV about 55), looks a little ahead in the race direction, moves with `lerp` (smooth, no jitter: update in `_physics_process` or use physics interpolation if available). Small shake on bumps and pops.
7. **Lighting**: one `DirectionalLight3D` (shadows off), a `WorldEnvironment` with a flat sky color and ambient light so the flat colors look bright. Optional light fog in the distance for depth.
8. **Level.gd** (extends `Node3D`, adapted from the lab's `Level.gd`): states `COUNTDOWN → RACING → FINISHED`. Countdown "3, 2, 1, TOOT!" (input blocked during it). `race_time` counts up from GO. `time_left = time_limit − race_time`. When the player crosses the finish: `end_level(true)`. When time runs out: `end_level(false)`. Uses `GameState.calc_stars` and `complete_level`. For now the result can just print and go back to the menu (Phase 3 adds the Result screen).
9. **HUD** (`CanvasLayer`): goal text big in the center for the first 3 s, then small at the top (R2); timer (turns red under 10 s); gas meter with 3 bean icons; progress bar from start to finish with dots for each racer; pause button top right (wired in Phase 3). Keep everything clear of the top 80 px (notch).
10. **Level01.tscn** using `LevelDefs` level 1: wide straight channel with two gentle S-turns built from offset segments, a few islands, 6+ beans, 2 checkpoints, a slow `current` strip (Phase 3 obstacle, may be added then). First-time hint: a bouncing arrow and the text "Tap the water to toot that way!" until the first toot.

### Automated tests
- `tests/test_float_player.gd`: `toot_toward` spends gas and returns false at 0 gas; refill adds 1 per 1.5 s (simulate with `_process` calls or a fake time); after a toot toward +X the velocity has a positive X part; speed never exceeds `MAX_SPEED`; a tap point too close does nothing.
- `tests/test_level_builder.gd`: building level 1 creates a start, a finish area, at least 2 checkpoints, banks for every segment, all beans.
- Add the new scenes to the smoke test.

### Gate 2 (you check)
- [ ] Tests pass.
- [ ] Play Level 1 on the computer (click = tap). Tooting feels punchy, drifting feels like water, the camera is smooth, the goal text shows at the start.
- [ ] Bumping a bank or island bounces you; you cannot leave the course.
- [ ] Puffs, ripple rings and the bean pickup all show. FPS (Settings will add an FPS toggle; for now use the Godot profiler) stays at 60.
- [ ] **Install a debug APK on your phone now** (lab says install early): Project → Export → Android → Export Project (debug). Taps work, it is portrait, it runs smoothly.
- [ ] Commit: `Phase 2: 3D race core and Level 1`.

---

## Phase 3: Obstacles, 5 levels, progression and offline mode

**Goal:** the full offline game: 5 levels with obstacles, bots, level select with locks, result screen, pause menu. Works in airplane mode.

### Tasks
1. **Obstacles** (`scenes/course/` + `scripts/obstacles/`). All moving ones are `AnimatableBody3D` (`sync_to_physics` on) or `Area3D`, all driven only by `Level.race_time`:
   - `Bumper`: short fat cylinder with a striped top; on hit, extra outward impulse (6) and a squash tween + "boing" sfx.
   - `Sweeper`: center post + long bar (cylinder) rotating at `speed_deg` degrees per second; pushes floats.
   - `SpikeWall`: dark box panel with white dots (dots drawn in a tiny shader or as small spheres in one `MultiMesh`), cone spikes on the front; slides `travel` meters along X with `sin(TAU * race_time / period)`. A thin `Area3D` on the spike side calls `pop()`.
   - `Whirlpool`: animated spiral on the water (rotating flat disc with a swirl shader or a ring of particles) + `Area3D` that each physics frame adds a force toward its center (stronger near the middle) and a little sideways spin.
   - `SpikeLog`: rotating spiked cylinder rolling across the channel and back; pops on touch.
   - `Current`: water strip with scrolling arrows; constant force in `dir`.
   - Use `MultiMeshInstance3D` for repeated small parts (spikes, dots, buoys) to keep draw calls low.
2. **Pop and respawn**: on `pop()`: puff of white particles, "pop" sfx, hide float, disable collision, after 1 s place it at the last checkpoint it passed, 1.5 s of blinking where spikes cannot pop it again.
3. **LevelDefs.gd**: write all 5 levels following the Level plan table. Each later level must be harder or different (more obstacles, less time, narrower channel, fewer beans, new obstacle type). Courses about 140 m (L1) to 220 m (L5). Leave a fair line through every obstacle.
4. **BotBrain.gd** (offline opponent, based on the lab's `SimpleAI` pattern): attached to a `FloatPlayer` with `is_local_controlled = false`. Steers to the next waypoint (advance when within 4 m). Toots toward the waypoint when it has gas and `bot_toot_delay` has passed, with a random aim error up to `bot_aim_error_deg`. Uses the same physics as the player, so obstacles affect it fairly. Later levels: shorter delay, smaller error. Bots get random avatars and fixed names ("Bubbles", "Fizz").
   If a bot finishes first, the player loses (show "Bubbles won!").
5. **Screens**:
   - `ModeSelect`: two big buttons, Play Offline and Play Online, plus Back (lab code).
   - `LevelSelect`: 5 big level cards in a grid (lab code, made prettier): number, name, best stars (★ icons), best time. Locked cards show a lock icon, are greyed out and do nothing when tapped (R4).
   - `Result`: "Level Cleared!" or "Try Again", stars animate in one by one, time, place (1st/2nd/3rd), buttons Retry, Next (disabled if lost or on level 5), Menu (R3). Confetti particles and a fanfare on a win; on a level unlock, show "Level N unlocked!" with a sparkle.
   - `PauseMenu`: Resume, Restart, Sound On/Off, Quit to menu. `get_tree().paused = true`, menu `process_mode = WHEN_PAUSED` (R10). Android back during a race opens pause.
6. **Offline flow**: ModeSelect → LevelSelect → Level → Result, exactly like the lab's game flow diagram. Clearing a level saves before the Result screen. No network code may run in offline mode (`Net` stays idle).
7. **Tutorial**: Level 1 hints (first toot, first bean "Beans refill your toots!", first checkpoint). Level 3 shows "Spikes pop you! Avoid them" the first time. Store `seen_tutorial` in GameState.

### Automated tests
- `tests/test_level_defs.gd`: exactly 5 levels; numbers 1..5; each has non-empty `goal_text`, `time_limit > 0`, start, finish, at least 2 checkpoints, at least 4 waypoints ending past `finish_d`; every obstacle type is known; level 3, 4, 5 each have at least one obstacle type not used in the level before or less time; bots: 0 in L1, at least 1 after.
- `tests/test_bot_solvable.gd` (important): for each level, run the level headless with a **perfect bot** (no aim error, delay 0.4 s) as the "player" at a fixed physics step for up to `time_limit` seconds. Assert it reaches the finish in time. This proves every level can be cleared. Then run the real Level-N bot and assert it finishes in the time limit too, but slower than the perfect bot (so the player can win).
- `tests/test_obstacles.gd`: a `Sweeper` at `race_time = 1.0` has the same rotation every run (deterministic); `SpikeWall` position for a given `race_time` matches the formula; whirlpool force points toward the center.
- `tests/test_progression_flow.gd`: simulate `complete_level(2, 2, 40.0)`, reload from file, assert level 3 unlocked and level 4 locked.

### Gate 3 (you check)
- [ ] Tests pass, including bot solvability for all 5 levels.
- [ ] Play all 5 levels on the computer. Each feels harder or new. Obstacles move smoothly.
- [ ] Lose a level on purpose: Result shows Try Again, Retry works. Clear it: stars, Next unlocks (R3).
- [ ] Level select shows locks; locked levels cannot be opened (R4).
- [ ] On the phone: clear Level 2, force-close the app, reopen: Level 3 is still unlocked (R5).
- [ ] On the phone in **airplane mode**: Play Offline, clear Level 1, close and reopen. No freeze, no error (R6). Screen-record this (lab Checkpoint 4).
- [ ] Commit: `Phase 3: obstacles, 5 levels, bots, progression`.

---

## Phase 4: Online multiplayer (2 phones, same Wi-Fi)

**Goal:** two phones join one race, see each other's avatars and names moving smoothly, and the host decides the winner. Every failure ends on a clear message, never a crash.

### Tasks
1. **Net.gd** (start from the lab's code, page 17): `PORT = 7777`, `MAX_CLIENTS = 1`, signals `match_ready`, `net_error(message)`, `players_changed`. Add:
   - `players: Dictionary` (peer_id → `{name, avatar}`).
   - `@rpc("any_peer", "reliable") func register_player(data: Dictionary)`: the host runs `AvatarData.sanitize` on it (never trust the other phone), stores it, then sends the full `players` list to everyone.
   - `my_ip()` from the lab code; also show all LAN addresses if more than one.
   - `leave()` resets `players` and sets `OfflineMultiplayerPeer`.
2. **Lobby.tscn** (lab A.2): shows your avatar and name. **Host** button → "Waiting… your IP is 192.168.x.x". IP `LineEdit` (numeric keyboard, remembers last IP) + **Join** button. Status label. A 5-second `Timer` after Join: if not connected, `Net.leave()` and show "Cannot reach host. Check that you are on the same Wi-Fi." (R8). When both are in: both avatars shown side by side. Host picks a course (any of the 5 levels; online ignores offline locks) and taps Start. Guest sees "Waiting for host to start…". Back button leaves cleanly.
3. **Starting the match**: host calls `start_match.rpc(level, seed)` (lab code). Both phones load the level in online mode. Each phone tells the host "loaded"; when both have loaded, the host sends `begin_countdown.rpc()`. Both run the 3-2-1 countdown locally; `race_time` starts at GO on each phone (LAN delay is a few ms, so obstacles stay in sync because they use `race_time`).
4. **Spawning and syncing floats**:
   - Use a `MultiplayerSpawner` under the level for floats. The host spawns one float per peer and names it after the peer id. Each float calls `set_multiplayer_authority(peer_id)`.
   - Your own float: normal physics, controlled by your taps.
   - The other float: `freeze = true`, `freeze_mode = KINEMATIC`, no local forces.
   - `MultiplayerSynchronizer` on each float syncs `position`, `linear_velocity` and the visual yaw from the authority at about 20 Hz. On the receiving phone, smooth it: keep the last two snapshots and interpolate, plus a small velocity-based prediction. Snap only if the error is over 3 m. Result: the other player moves smoothly, no teleporting.
   - Toots: `@rpc("any_peer", "unreliable") func remote_toot(dir)` only for the puff and sound on the other phone.
   - Pops: `@rpc("any_peer", "reliable") func remote_pop()` for the effect; the position sync handles the respawn.
   - Bumping: your float collides with the other (kinematic) float and bounces; both phones do this for their own float, so bumps feel fair on both sides.
   - Apply each float's avatar from `Net.players`; show the name on a small label above each float (`Label3D`, billboard).
   - No bots online.
5. **Winner (host decides)**: when your float enters the finish area, send `report_finish.rpc_id(1)`. The host checks: race is running, no winner yet, and that peer's synced position is near the finish (within 6 m). Then `announce_winner.rpc(peer_id, race_time)` (lab pattern). If time runs out with no finisher, the host sends `announce_draw.rpc()`.
6. **OnlineResult screen**: "You win!" / "You lose!" / "Time's up! Draw", both avatars, finishing time. Buttons: **Rematch** (host only, same course; guest waits) and **Leave**. Online results do **not** change offline progress.
7. **Disconnects**: if the other player leaves or the connection drops at any point (lobby, countdown, race, result), stop the race, call `Net.leave()`, go to ModeSelect, and show the error message in a popup panel built into the UI (not an OS dialog). Pause in online mode shows the menu but does not pause the game (say "The race keeps going online").
8. **Android export**: in the Android export preset, tick **Internet** and **Access Network State** (lab A.4). Without these, online fails silently on the phone.

### Automated tests
- `tests/test_net_sanitize.gd`: `register_player` with bad data (huge name, negative indexes, missing keys, wrong types) ends up sanitized; finish validation function rejects a peer whose position is far from the finish and a second finisher after a winner exists.
- `tests/net_smoke.gd` + `tools/net_smoke.sh`: start a headless host instance (`--net-test-host`) and a headless client instance (`--net-test-client 127.0.0.1`) of the game. Assert: client connects, both `players` lists have 2 entries with sanitized avatars, the host starts level 1, both load it, the client's float position reaches the host within 1 s, then the client quits and the host shows the "other player left" error state without crashing. Exit code 0 on success.
- `tools/net_smoke.sh` second case: client joins `10.255.255.1` (unreachable): after 5 s the "Cannot reach host" error is set, exit code 0, no crash.

### Gate 4 (you check, needs 2 Android phones)
- [ ] Tests and net smoke pass.
- [ ] Both phones on the same Wi-Fi or one phone's hotspot. Phone A hosts, Phone B types the IP and joins. Both see both avatars.
- [ ] Race: the other player moves smoothly, puffs show, bumping works, obstacles match on both screens.
- [ ] The winner screen is right on both phones (R7).
- [ ] Turn Wi-Fi off on Phone B, choose Online, Join: error message, no crash (R8).
- [ ] Close the app on Phone B mid-race: Phone A shows "The other player left." and goes back to the menu.
- [ ] Record this video (lab Checkpoint 5).
- [ ] Commit: `Phase 4: online multiplayer`.

### Phase 4B (optional bonus, only if Phases 1 to 5 are done): Nakama backend
Internet play and an online leaderboard (bonus points). Server: `docker compose up -d` with the official Nakama compose file on a laptop or school server (ports 7350 API, 7351 console). Client: the `nakama-godot` addon. Add a third button in the Lobby, "Play over internet", that connects with `authenticate_device_async`, uses `add_matchmaker_async("*", 2, 2)`, and sends the same messages as Option A as match state (op codes: 1 position, 2 toot, 3 pop, 4 finish). Leaderboard `best_times_level_N` written by the server. Change `defaultkey` and the console password, and never commit them. Keep Option A working; the lab requires it.

---

## Phase 5: Polish, performance and release build

**Goal:** it looks and feels finished, runs smoothly on two different phones, every asset is credited, and a release APK is on GitHub (v1.0).

### Tasks
1. **Audio**: `tools/gen_sfx.py` (Python, standard library + `wave` + `math` + `random` only) generates original `.wav` files into `assets/audio/`: `toot_1..4` (low noisy buzz with pitch bend, 0.25 to 0.5 s), `bean`, `boing`, `pop`, `tap`, `countdown`, `go`, `win`, `lose`, `unlock`. Music: one CC0 loop `.ogg` the user downloads (for example from Kenney.nl or OpenGameArt, CC0 only) to `assets/audio/music.ogg`; if the file is missing, the game runs silently without errors. Music plays from the `Audio` autoload so it continues between scenes. Sound On/Off is saved (R10).
2. **Settings screen** (bonus): sound on/off, music volume, vibration on/off, graphics quality Low/High, show FPS. Low = no ripple trail, fewer particles, water with fewer subdivisions, render scale 0.75 if supported by the Compatibility renderer. High = everything on.
3. **Juice**: button press scale tween on every button, screen shake on pops and bumps, star pop-in on Result, confetti on wins, unlock sparkle on Level Select, slight float tilt and splash when landing a toot.
4. **Title screen**: the game logo text "Toot Tubes" in Fredoka with an outline, a live 3D background (your avatar bobbing on the water with a puff now and then), "Tap to start".
5. **Credits screen** + `docs/CREDITS.md`: every asset with author and license (Fredoka OFL, music CC0 source, GUT MIT, Godot MIT, generated sounds "original"). Required by the lab.
6. **App icon**: 1024 × 1024 PNG (a float with a green puff), set in Project Settings and the Android export preset (main, adaptive foreground and background).
7. **Performance pass**: add a hidden FPS and draw-call label (Settings → Show FPS). Check against the budget in Section 1. Reuse materials, use MultiMesh for repeats, turn off shadows, keep particle counts small, pre-warm particle materials during the countdown so the first toot does not stutter.
8. **Android release export**: package `com.itsd85.<team>.toottubes` (lowercase), name "Toot Tubes", portrait, permissions Internet + Access Network State, version 1.0 (code 1). Create a release keystore with `keytool` **on your computer**, set it in Editor Settings / the export preset, and never commit it. Export `export/TootTubes-v1.0.apk` with "Export With Debug" off.
9. **README.md** with the lab's exact headings (page 30): About the game (pitch + 2 screenshots), How to play, Offline and online modes (how to host and join), How to build (Godot version, export steps, run tests), Download (v1.0 release link), Playtest results, Credits, Paper.
10. **CI (optional)**: `.github/workflows/tests.yml` that runs `tools/setup_godot.sh` and `tools/run_tests.sh` on every push.
11. **Test matrix**: `docs/TEST_MATRIX.md` with the lab's table (page 23) for 2 phones.

### Automated tests
- Full test run plus net smoke pass.
- `tests/test_settings.gd`: sound off is saved and loaded; Audio plays nothing when sound is off; missing `music.ogg` does not cause an error.
- `tests/test_scenes_smoke.gd` still passes for every screen.

### Gate 5 (you check: final acceptance)
Go through the lab's R1 to R10 with the release APK on **two different phones**:
- [ ] R1 to R5: all 5 levels, goal text, results, locks, progress survives force-close.
- [ ] R6: airplane mode offline play.
- [ ] R7, R8: online match on two phones; Wi-Fi-off error.
- [ ] R9: installs from the APK file, portrait only, touch works.
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

**After the game (not Codex work, plan time for it):** playtest with 5+ testers using the lab forms (Phase 8 of the PDF), fix at least 3 issues and retest, demo video (2 to 3 min), the IEEE paper, the contribution log, then submit on Google Classroom. If you fix playtest issues, release v1.1.

---

## Time estimate (with Codex doing the coding)

| Phase | Work | Rough time |
|---|---|---|
| 1 | Foundation, save, avatar creator, tests | 2 to 3 h |
| 2 | 3D race core, Level 1 | 4 to 6 h |
| 3 | Obstacles, 5 levels, bots, menus | 4 to 6 h |
| 4 | Online 2-phone race | 4 to 6 h |
| 5 | Polish, release APK | 3 to 4 h |

About 2 full days if nothing goes badly wrong. Phase 2 (game feel) and Phase 4 (online) are the riskiest. If time runs out, cut in this order: Phase 4B, Settings extras, spike logs (Level 5 uses the other obstacles), avatar hats. **Never cut** anything in the R1 to R10 table.

## Known risks and fallbacks

| Risk | Fallback |
|---|---|
| 3D runs slowly on a cheap phone | Quality Low by default on first launch if FPS stays under 40 for 3 s; fewer particles; no ripple trail |
| Online movement looks jumpy | Raise sync rate to 30 Hz, increase interpolation delay to 100 ms |
| Godot version in Codex differs from yours | Set `GODOT_VERSION` in `tools/setup_godot.sh` to the exact version you use; open the project in your editor before each gate |
| Codex cannot see the game | It relies on the automated tests; the "You check" lists catch everything visual. Report what you see back to Codex with screenshots |
| Online fails only on phones | Check Android permissions (Phase 4 task 8), same Wi-Fi, hotspot instead of school Wi-Fi (some school networks block device-to-device traffic) |
