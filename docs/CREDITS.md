# Credits and licenses

- Game concept, source code and primitive-mesh rider/float/hat artwork: original project work. No downloaded 3D models or textures.
- Phase 2 water/ripple shaders, CPU particle effects, course primitives, finish flag tiles and HUD drawings: original project work; no additional third-party artwork or audio.
- Fredoka variable font: The Fredoka Project Authors. SIL Open Font License 1.1. Source: https://github.com/google/fonts/tree/main/ofl/fredoka . Font and copyright/license notice: `assets/fonts/Fredoka.ttf`, `assets/fonts/OFL.txt`.
- GUT 9.6.1: Butch Wesley and contributors, MIT. Source: https://github.com/bitwes/Gut/releases/tag/v9.6.1 . License committed at `addons/gut/LICENSE.md`.
- GUT's bundled development UI includes Anonymous Pro (Mark Simonson), Courier Prime (Quote-Unquote Apps / Alan Dague-Greene), Lobster Two (Pablo Impallari) and a Source Code Pro bitmap font (Adobe). These are development-tool assets under SIL OFL, not game artwork; upstream font notice is at `addons/gut/fonts/OFL.txt`. Exclude test tooling from the eventual release export.
- Godot Engine 4.7.2: Godot Engine contributors, MIT. https://godotengine.org/license/ . Editor binary is downloaded locally into ignored `.bin/` and is not committed. Preserve Godot notices in eventual exports.
- Audio: no audio assets were included in Phase 1. Current Phase 5 original synthesized effects/music are credited below; no external recordings are used.

Additional bundled GUT font copyright/license notices are preserved in `docs/licenses/` from the corresponding Google Fonts OFL family directories.

## Sky environment revision (2026-11-01)

Original procedural Godot scenery: striped cliffs, clouds, floating islands, umbrellas, balloons and checker/finish markers. Visual design is the author's own; no commercial game assets, models, screenshots or external web fonts are bundled. The social-media screenshot and reference HTML/images are design references only. Fredoka remains the in-game font under the existing OFL credit.

Hole correction: original procedural open cylinder shafts and foam torus rims, based on the user-supplied environment specification.

Revised Phase 1 crew foundation (2026-11-01): original procedural shared inflatable ring, central platform, seat pads and separate rider models, reusing the existing original palette/hat geometry and shared materials. No new external artwork or audio assets.

Revised Phase 2 (2026-11-02): original 3D Sky Garden spline layout, generated ribbon/bank collision, route-space water/cliff shaders, hole shafts, primitive hazards, shared-ring mesh batching, pooled rider jets and crew HUD. No new third-party artwork or sound assets. Reference video and images remain outside the Android package.

Phase 2 feedback revision (2026-11-02): original lit procedural water shader, shared analytic water waves, bank/hole foam, caustics, wake/spray, moving outward rider poses and clothed red thrust panels. No new third-party media, models, textures or sounds. Godot shader/interpolation references: https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/spatial_shader.html and https://docs.godotengine.org/en/4.7/tutorials/physics/interpolation/advanced_physics_interpolation.html .

Phase 3 (2026-11-05): original Canyon Switchbacks, Cloud Bridges, Spiral Springs and Festival Summit route data, palette variations, procedural crushers, spiked sliding gates, marked boulders and batched whirlpool/current markings; campaign, result and pause presentation. Reuses the existing original rider/water/scenery systems and OFL Fredoka font. No downloaded artwork, models, textures, audio or new third-party assets.

Phase 4 (2026-11-05): original LAN lobby, mode/result presentation and `docs/screenshots/phase4_mode_select.png`, `phase4_lobby_four.png`, `phase4_shared_result.png`, rendered from the existing original procedural game artwork with OFL Fredoka. ENet support is supplied by Godot under its existing license. No new third-party media, models, textures or audio.

Phase 5 (2026-11-05): original four-rider vector icon at `assets/icons/toot_tubes.svg`; original synthesized mono WAV assets at `assets/audio/`: `thrust_attack`, `thrust_loop`, `thrust_release`, `impact`, `fall`, `pickup`, `ui`, `checkpoint`, `win`, `timeout` and `sky_theme`. All are reproducible with `tools/generate_audio.py`; the repeating melody is an original procedural composition. No recordings, downloaded samples or commercial game media were used. The new title/settings/feedback presentation reuses the original procedural meshes and OFL Fredoka. In-game Credits includes `assets/licenses/NOTICE.txt`, full Fredoka OFL text and the engine's own MIT/third-party notices.

Rider and fart revision (2026-11-21): original sculpted animal riders (hippo, pig, panda, penguin, bunny, cat) built from lathed and tapered procedural meshes; original cel/rim shader `shaders/toon.gdshader`; soft fart puffs use a gradient texture generated in code (no image file). The animal designs are original and are not copied from any game. No downloaded models, textures or sounds.

Wrap-up (2026-11-22): the music loop is now `assets/audio/sky_theme.ogg` (OGG Vorbis, encoded from the same original synthesized track by `tools/generate_audio.py` with ffmpeg), following the lab rule of `.ogg` for music and `.wav` for short effects. Effects stay original WAV files.

Graphics and game-feel pass (2026-11-22): all new art is original and generated in code, with no image, model or sound files added.
- Riders: one sculpted pear-shaped body per animal with the butt built into the silhouette (`RiderSculpt.pear_body`), plus new tails, back markings and happy-eye faces. Secondary motion (jiggle, arm flail, tail wag, butt glow) runs in the original `shaders/toon.gdshader`.
- Water: the original stylized `shaders/route_water.gdshader` uses a 128 x 128 tiling pattern built from sine formulas at runtime (`RaceEffects.water_pattern`: caustic web, flow streaks, foam noise, sparkles).
- Effects: the cartoon fart puff (`RaceEffects.puff_texture`) and cloud card (`SkyDecor.cloud_texture`) textures are drawn pixel by pixel in code. Foam rings, droplets and splashes are procedural meshes and CPU particles.
- Scenery: original `shaders/flag.gdshader` (waving pennants), `shaders/bob.gdshader` (floating hot-air and party balloons), and updated `sky.gdshader` and `route_cliff.gdshader`.
- The reference clip `snaptik_7696703905740164374_v3.mp4` was used only to judge feel and polish. No characters, art, levels or colours were copied from it, and it is not in any export.
