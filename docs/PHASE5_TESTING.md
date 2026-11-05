# Phase 5: local acceptance and remaining device checks

2026-11-05. Laptop-first validation of the current audio/settings polish. This is not full release acceptance. Physical phones, wireless LAN, two phone performance classes and human playtesting remain pending. No publication was performed.

## What is tested here

| Area | Current local evidence | Limit |
|---|---|---|
| Game rules, physics and storage | 85 GUT tests, 7,807 assertions, 21 suites | Automated cases, not human feel |
| Campaign | 102 menu/normal-input checks; all five courses completed with no recoveries | Scripted steering with the real gas/physics rules |
| Save/relaunch | 12 checks in a separate process | Disposable campaign save, not an Android upgrade |
| Controls | 36 checks, 6,691 touch events plus mouse/key checks, 56 holds; Sky Garden completed in 110.32 s | Synthetic Godot input, not an Android touchscreen |
| LAN | 128 checks in separate two/four-peer processes | Real ENet over loopback, not Wi-Fi or four humans |
| Settings/title/audio | 39 checks each in standalone headless and rendered Windows runs | Mixer PCM is checked; listening quality needs a person |
| Packaging | Android debug/release exports, signatures and resource inspection; embedded Windows EXE | Android execution/install/Back/vibration still needs a compatible runtime |
| Rendering | Portrait captures inspected; four-rider high/low full-course profiling below | Laptop GPU counters do not establish phone FPS or heat |
| Android emulator continuation | 55 native-control/lifecycle/offline/save checks in a failed-render x86-64 fixture | Flat captures/shader errors; later hardware-backed starts timed out. Overall emulator acceptance remains failed |

The LAN cases include owned-seat spoof rejection, explicit reliable release, lost-refresh expiry, gas and 3D motion, ordered checkpoints, identical shared results, pause/rematch, vacancy, unreachable host and abrupt host-process death. Offline save files remain byte-identical and prior offline result/mode are restored. The explicit-release fixture waits for the host to observe a real held packet before asking the guest to release; it does not assume identical process frame timing.

The later [Android emulator continuation](ANDROID_EMULATOR_TESTING.md) adds actual Android MotionEvent injection and Back/Home/airplane-mode checks, plus strict image/runtime failure detection. Its behavior evidence does not close the Android rendering gate. The separate x86-64 QA export does not replace the ARM phone APKs.

Low quality reduces decorative clouds and particle counts. It retains all four riders, route geometry, hazards, collision, mass, gas and cooperative physics. Reduced motion softens camera yaw; there is no impact shake. Preferences persist without changing the version-2 save format.

## Run checks

From PowerShell in the project root:

```powershell
& 'C:\Program Files\Git\bin\bash.exe' tools/run_tests.sh
& 'C:\Program Files\Git\bin\bash.exe' tools/net_smoke.sh

# Run these two campaign commands in this order, in separate processes.
& .\.bin\Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 --path . --script tools/verify_campaign_flow.gd -- --prefix=phase5-campaign
& .\.bin\Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 --path . --script tools/verify_campaign_flow.gd -- --reload --prefix=phase5-reload

& .\.bin\Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 --path . --script tools/verify_gate2_inputs.gd

# Source UI/settings/mixer check; creates only an isolated test save.
& .\.bin\Godot_v4.7.2-stable_win64_console.exe --path . --max-fps 60 -- --build-check --report=res://.bin/phase5-source-rendered.json --capture

# Build local candidates; then test the EXE from a fresh directory with no project.
.\tools\build_phase5.ps1
python tools/verify_portable.py
python tools/verify_portable.py --rendered
```

The release template starts the normal main scene. The opt-in `--build-check` user argument launches the packaged verifier; editor-style `--script` is not used to claim release verification. Ordinary startup has no automatic test mode. The verifier uses `user://phase5_build_check.cfg`, deletes its test save and never saves to `user://save.cfg`.

GUT's post-run hook and the UI/network verifiers stop audio and let queued mixer commands retire before process exit. Assertions and failing exit codes remain unchanged. The deliberately invalid save destination test emits its expected warning; final runs have no resource-leak/runtime errors.

## Rendered profiling

Run alone, with no other tests/exports or screenshots during racing:

```powershell
& .\.bin\Godot_v4.7.2-stable_win64_console.exe --path . --max-fps 60 --script tools/verify_sky_garden.gd -- --level=5 --crew=4 --seed=4 --quality=high --resume-on-focus
& .\.bin\Godot_v4.7.2-stable_win64_console.exe --path . --max-fps 60 --script tools/verify_sky_garden.gd -- --level=5 --crew=4 --seed=4 --quality=low --resume-on-focus
```

Festival Summit, Intel UHD Graphics, Compatibility, 720 x 1280. The verifier requires samples with all four riders firing and fewer than 150 draw calls / 60,000 visible primitives. Results are in `.bin/course_result_5_4_4.json` and `_low.json`. Finish-time samples exclude intro, pause and result image writes. Focus-loss resumes are counted explicitly.

| Quality | Finish s | Median ms | p95 ms | Max draw calls | Max primitives | Four-firing frames | Contacts / recoveries |
|---|---:|---:|---:|---:|---:|---:|---|
| High | 125.73 | 16.665 | 17.079 | 74 | 57,225 | 4,814 | 8 / 0 |
| Low | 125.73 | 16.666 | 17.188 | 73 | 47,305 | 4,815 | 8 / 0 |

Both had zero focus resumes and identical simulated gas/force/finish outcomes. Low quality reduced peak visible primitives by about 17%; both runs were already near the 60 FPS cap. These samples do not establish a phone speed improvement.

## Local build handoff

- Windows portable: `export/TootTubes-0.7.0-rc1.exe`. Double-click to play; the game pack is embedded. The EXE is not publisher-code-signed.
- Android development: `export/TootTubes-phase5-debug.apk`, package `com.itsd85.toottubes.prototype`.
- Android local release candidate: `export/TootTubes-0.7.0-rc1-release.apk`, separate package `com.itsd85.toottubes`.

Both APKs are version `0.7.0-rc1`, code 11, ARMv7 + ARM64, minimum API 24 / target 36. V2/V3 signatures verify. Licenses, icon, all 11 original audio assets and runtime modules are included; tests/tooling/docs/reference media/signing material are excluded. `export/phase5-builds.json` records sizes and SHA-256 hashes. Build outputs stay ignored by Git.

Private release signing material stays outside the repository in the current user's protected local signing directory. Its saved credential uses Windows DPAPI; never print it or copy it into project files. The builder reuses the matching identity, trims the encrypted file's trailing newline and restores its process environment afterward. These are local candidates; publication and signing-identity backup/transfer remain separate decisions.

## Gate 5: remaining acceptance

- [x] Original sustained four-seat audio, event effects/music, saved sound/quality/motion/vibration/FPS settings, four-rider title/icon and bundled notices.
- [x] Automated rules/campaign/save/input/LAN checks and standalone Windows UI/audio checks.
- [x] Local Android/Windows candidates and APK signature/resource inspection.
- [ ] Full Android emulator rendering acceptance: current SDK/backend combination fails; preserve its partial behavior evidence separately.
- [ ] Two physical phone classes: four riders firing amid moving hazards; FPS/frame pacing, sustained heat, audio and quality comparison.
- [ ] Android install/upgrade, portrait/touch targets, independent two-finger release, Back/Home/resume, saved preferences and vibration.
- [ ] Physical airplane-mode campaign completion/retry/relaunch; actual two-phone and four-phone Wi-Fi finish/rematch/disconnect.
- [ ] Human review of steering, camera, water/rider visuals, sound balance and obstacle difficulty.
- [ ] Release approval/publication and final Phase 5 commit after phase handoff; no release has been published.

The original lab rubric PDF is still unavailable; exact rubric alignment remains provisional. Keep the hardware/human gates open.
