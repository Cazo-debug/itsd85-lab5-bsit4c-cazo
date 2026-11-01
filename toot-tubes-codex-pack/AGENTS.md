> This pack follows the root AGENTS.md, IMPLEMENTATION_PLAN.md and ENVIRONMENT_SPEC.md. Mirrored specifications are synchronized at revision time. Historical HTML/images do not override the user or v3 requirements.

# AGENTS.md: rules for Codex in this repo

Project: **Toot Tubes**, a Godot 4 mobile game for the ITSD 85 lab. The full plan is in `IMPLEMENTATION_PLAN.md`. Section 0 of that file is the source of truth for game rules; Section 2 lists the names and migration contracts every phase must keep. The v3 ENVIRONMENT_SPEC.md is the active environment/movement specification; old plans under docs/archive/ and the HTML sample are reference material only.

## How to work
- Do **one phase at a time**, only the phase you were asked for. Do not start the next phase.
- Before coding, read the whole phase, then list the files you will create or change. A request to edit a phase plan changes documentation only; do not execute that phase or mark its gates complete.
- At the end of a phase: run `tools/run_tests.sh` (and `tools/net_smoke.sh` from Phase 4 on), fix failures, update `docs/PROGRESS.md` (what was done, what tests pass, any known issues), and print the phase's **Gate** checklist so the user can check it by hand.
- If something in the plan cannot work as written, choose the simplest working option, write the reason in `docs/PROGRESS.md`, and tell the user.

## Godot and code rules
- Godot 4.x, **standard (GDScript) build**, renderer **Compatibility**. No C#, no GDExtension, no paid or closed assets.
- GDScript with static types (`var x: int`, `-> void`). Tabs for indentation.
- Keep names from the plan's contracts (`GameState`, `Net`, `Audio`, `SwimRing.set_thrust_input`, `CoursePath`, `Level.race_time`, `LevelDefs.LEVELS`, and so on). Keep `FloatPlayer.toot_toward` only for legacy compatibility until the new contract and replacement coverage pass.
- Build procedural art from primitive meshes and shared materials; generated ribbon meshes and matching simplified collision are required for curved/elevated courses. No downloaded models or textures.
- Exactly one physical shared ring, up to four cooperating riders. No second ring, opponent bots or 2-versus-2 racing. Full four-human LAN co-op belongs to Phase 4.
- Thrust is sustained per-seat input integrated at fixed physics steps; route geometry must include real curves and height changes. Do not restore a globally locked y=0 body or a one-impulse-per-tap primary control.
- Moving obstacles use **only** `Level.race_time` for motion. No per-obstacle timers or random numbers.
- Never trust data from the other phone: sanitize avatar data on the host; the host simulates the shared ring, validates seat inputs and decides cooperative completion.
- UI: Fredoka font, body text at least 28 px at 720 × 1280, buttons at least 120 px, nothing important in the top 80 px. Every screen has a Back button and handles the Android back gesture.
- Errors in online mode end on a clear in-game message and return to Mode Select. Never use OS dialogs, never crash or freeze.
- Prefer `CPUParticles3D`. Turn off real-time shadows. Use `MultiMeshInstance3D` for repeated small parts.

## Tests
- Tests live in `tests/` and use GUT (`addons/gut/`, committed).
- Headless run: `tools/run_tests.sh`. If `godot` is not installed, run `tools/setup_godot.sh` first.
- Every phase adds the tests listed in its section. Do not delete or weaken a test to make it pass.

## Git and secrets
- Commit at the end of each phase with the message given in its Gate.
- Never commit `.keystore`, `.jks`, export passwords, Nakama keys, `export/`, `.godot/`, `.bin/` or `*.apk`.
- Only original or CC0/OFL/MIT assets. Add every asset to `docs/CREDITS.md`. Do not copy characters, names, logos or music from any commercial game.
