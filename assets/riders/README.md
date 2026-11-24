# Rider models (optional)

The game ships with sculpted procedural animals (`scripts/RiderModel.gd`).
To use a real 3D model instead, put a file here named after the animal:

| Avatar "Animal" option | File name |
|---|---|
| Hippo | `hippo.glb` |
| Pig | `pig.glb` |
| Panda | `panda.glb` |
| Penguin | `penguin.glb` |
| Bunny | `bunny.glb` |
| Cat | `cat.glb` |

`.gltf`, `.fbx` (Godot 4.3+ imports FBX natively) and `.tscn` also work.
`RiderModel` loads the file automatically and falls back to the sculpted animal
when no file is present. No code change is needed.

## Model requirements

- Faces **+Z** (glTF default), origin at the seat (bottom of the rider).
- It is scaled automatically to about 1.9 m tall.
- A rigged model plays its first animation named `Sit`, `Sitting`, `sit`,
  `Idle` or `idle` (looped). Without one, the first clip plays.
- Best result: a **seated pose**, leaning forward, hands low at the sides
  (the float has grab handles there). Re-pose quadruped packs in Blender.
- Keep it low-poly (under ~3k triangles per rider) for phones.

## Free CC0 sources

- Quaternius: LowPoly Animated Animals (CC0, FBX/OBJ/Blend):
  https://quaternius.itch.io/lowpoly-animated-animals
- Quaternius: all CC0 uploads on OpenGameArt:
  https://opengameart.org/content/all-cc0-uploader-quaternius
- Kenney: Animated Characters 1 and 2 (CC0, rigged humans, useful as rig/pose
  references): https://opengameart.org/content/animated-characters-1

These animals are walk/run quadrupeds, not seated riders. Re-pose them in
Blender (sit, lean forward, arms to the sides) and export as `.glb`.

## Before committing a model

1. Confirm the licence is CC0 (or OFL/MIT) on the download page.
2. Add the file, author, source URL and licence to `docs/CREDITS.md`.
3. `AGENTS.md` currently says "No downloaded models". Update that rule
   (team decision) before committing third-party models.
