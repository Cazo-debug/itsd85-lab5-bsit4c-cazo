# Gate 2 automated input and Android review

**Latest review: 2026-11-05.** Build **0.4.2-gate2 / code 8** adds a recovery-camera fix. Automated desktop acceptance passes; human play and physical-phone acceptance remain open. The user confirmed that no phone is available and requested completion of all other checks. The 2026-11-02 evidence below is retained as the earlier baseline.

Date: 2026-11-02. App build: 0.4.1-water-riders / code 7, commit ced4b7d.

## Desktop input completion

A new verifier feeds Godot mouse, physical-key and two-finger input events through the existing UI and CrewInput handlers. It configures **one Local rider plus three production Assistants**, clicks Play and Start Sky Garden, waits for the real countdown and finishes the real course. It never edits the ring transform or calls its thrust API. Assistant control remains the normal CrewBrain.

This is scripted integration/visual evidence, not a human feel test. Input.parse_input_event feeds the game rather than the operating-system keyboard/touchscreen. Synthetic events are flushed before assertions so queued event delivery is not mistaken for a stuck input.

Rendered result: **34 checks pass**, 110.32 s completion, 56 hold presses, 6,691 touch events, one solid contact and no fall/recovery. Both checkpoints were crossed. Tests include outside-finger release, retained drift, keyboard hold/release, pause clock/input cleanup, fresh input after resume, focus loss and Back to Crew Setup. Each real assistant contributed force.

Sampled rider center/head points stayed inside the safe play viewport for **100%** of sampled rendered frames. Screenshots also show the S-bend, bridge, climb/sweeper, hairpin, obstacle garden, holes and result. This does not prove visibility under every possible collision or direction.

Desktop Intel UHD Graphics, Compatibility, 720 x 1280: median **16.664 ms**, p95 **17.743 ms**, maximum **80 draw calls / 56,402 visible primitives**. Screenshot write frames and the following frames are excluded from timing samples. Phone FPS/heat cannot be inferred from this.

Independent regression: **55 tests / 2,298 assertions / 13 suites pass**. Hole/edge/mallet fixture: two safe crew recoveries and an actual mallet contact with about **41.98 degrees** peak physical tilt.

## Reproduce

```powershell
.\tools\run_tests.ps1
& .\.bin\Godot_v4.7.2-stable_win64_console.exe --path . --fixed-fps 60 --script tools/verify_gate2_inputs.gd
& .\.bin\Godot_v4.7.2-stable_win64_console.exe --headless --path . --fixed-fps 60 --script tools/verify_sky_recovery.gd
```

For headless input checking, add --headless. New captures use docs/screenshots/gate2_inputs_*.png. The JSON report uses .bin/gate2-input-result.json and all saves use the disposable user://gate2_inputs_verifier.cfg path. The real player save remains untouched.

## Android evidence

No physical phone was connected. The available Android 11 / API 30 Google APIs emulator supports ARM translation, so the delivered ARM APK installed successfully. Its initial profile exposed only OpenGL ES 2 and could not create the Godot graphics context. This is a failed runtime attempt and does not count as Android acceptance.

A separate ignored .bin/avd/TootTubesGate2 profile was prepared with GPU emulation and portrait dimensions. Existing emulator configuration/data are preserved; any reused data image is opened with -read-only. Final Android outcome is recorded below after the retry.

## Remaining Gate 2 acceptance

- [x] Automated one-local/three-assistant completion through UI/input handlers.
- [x] Mouse, keyboard and two-finger event lifecycle checks.
- [x] Camera sampling and rendered capture review.
- [x] New water/rider regression and physical recovery checks.
- [ ] Human control feel and a human-played completion.
- [ ] Physical phone installation/upgrade, two-finger hardware input, Back, sustained frame pacing and heat.

Android emulator acceptance is separate from the physical-phone gate. No Phase 3 work is included.

## 2026-11-05 recovery-camera correction

The rendered hole-recovery fixture exposed a camera defect: the ring returned to a distant checkpoint while the camera continued smoothing from the fall location. The recovered crew could be outside the view. `Level` now connects the existing `SwimRing.recovered` signal to `RouteCamera.snap`. Normal movement retains its damped follow. Manual recovery, automatic hole/edge recovery and Practice area changes share this signal.

The new regression exercises a checkpoint more than 50 metres from the starting camera, then checks immediate camera proximity and rider projection inside the viewport. The recovery verifier additionally checks all four rider head points against the safe play area after both hole and exposed-edge recovery. No previous tests or assertions were removed.

- Full required Bash runner: **56 tests / 2,302 assertions / 13 suites pass**.
- Focused run: **5 tests / 30 assertions pass** in `test_sky_run.gd`.
- Rendered corrected fixture: **two whole-crew recoveries**, one real mallet contact, **41.98 degrees** peak physical tilt; all crew projection checks pass.
- Before: [crew outside view after recovery](screenshots/gate2_final_hole_recovered.png).
- After: [crew visible after recovery](screenshots/gate2_corrected_hole_recovered.png).

The full rendered event-driver run before the correction passed 37 checks: 110.68 seconds, 56 hold presses, 6,712 touch events, eight contacts, zero recoveries and both checkpoints. Camera sampling kept all four rider head points inside the safe play area for every sampled frame. It included one desktop focus-loss resume. This is an input-integration run, not human-play evidence; it does not exercise the recovery defect by itself. Updated post-fix full-run measurements are recorded in PROGRESS.md.

The Android helper is test-only and excluded from the game APK. Its Windows PowerShell builder now loads both compression assemblies, handles keytool's normal stderr progress using its exit status, and deletes its disposable signing key. The Java helper checks the complete window dump for game focus, checks focus during a held gesture, and cancels only gestures it actually started.

### Reproduce the corrected checks

```powershell
& 'C:\Program Files\Git\bin\bash.exe' tools/run_tests.sh
& .\.bin\Godot_v4.7.2-stable_win64_console.exe --path . --fixed-fps 60 --script tools/verify_gate2_inputs.gd -- --capture-prefix=gate2_review
& .\.bin\Godot_v4.7.2-stable_win64_console.exe --path . --fixed-fps 60 --script tools/verify_sky_recovery.gd -- --capture --capture-prefix=gate2_recovery_review
& .\.bin\Godot_v4.7.2-stable_win64_console.exe --path . --fixed-fps 60 --script tools/verify_gate2_inputs.gd -- --no-capture
.\tools\build_gate2_touch.ps1
```

Run the timing sample with the emulator, capture/encoding tools and other game checks stopped. `--no-capture` disables screenshot writes; its frame counters still measure rendered desktop gameplay. The input report remains `.bin/gate2-input-result.json`; each run replaces that report. Keep each verification log if comparing runs. Use a fresh capture prefix to retain historical images.

### Phone handoff

Latest phone APK: `export/TootTubes-phase2-gate2-debug.apk`, **0.4.2-gate2 / code 8**, **57,855,109 bytes**. Signature verification passes v2/v3. Package/minimum Android API remain `com.itsd85.toottubes.prototype` / 24; both ARMv7 and ARM64 libraries are present. Archive inspection confirms Level01, WaterStyle and RiderOrbit and excludes tests, tools, documentation, reference pack/video and credentials.

SHA-256: `FAD1C70BB8361E0899DA1428421F9377F5A3E369671F347ED1006E41EFF999AC`.

When a physical device is available, select its serial explicitly:

```powershell
adb devices -l
adb -s DEVICE_SERIAL install -r export/TootTubes-phase2-gate2-debug.apk
```

`install -r` requests an upgrade retaining existing data. Do not uninstall or clear game data to bypass a signing mismatch. Check the upgrade, saved crew, portrait, two-finger aim/hold/release, drag outside, Home/resume, Android Back, a full human-played completion, and sustained four-rider frame pacing and heat. Hardware checks remain unchecked until performed.

### Android emulator outcome, 2026-11-05

The isolated Android 11 / API 30 emulator was booted at 720 x 1280 with host GPU rendering and `GLESDynamicVersion`. It used a read-only overlay of the existing data image; the original emulator profile/data were preserved. GLES 3.1 initialization now succeeds. The delivered **ARM** code 8 APK installed and started the engine, but stalled before a usable game screen under ARM translation. This is an unsuccessful ARM runtime check, not Android phone acceptance.

A separate **x86_64 emulator-only** export of the same code 8 source was produced in ignored `.bin/gate2-emulator-x86_64.apk`. The production preset was restored to ARMv7 + ARM64 afterward. This native emulator build rendered the title, avatar creator, Main Menu, Crew Setup and untimed Practice. Scripted touch saved the avatar and reached the course. The QA helper reported `passed=true` with **39 accepted Android touchscreen events** across three two-pointer sequences in Practice. After release the rendered HOLD control returned to its inactive color. Android navigation also returned from the game to the menu.

These are supplemental smoke checks. Event acceptance is not a force/gas assertion or a complete course test. Very short ADB menu taps were inconsistent; longer stationary swipe gestures were used to navigate. The helper also returned `passed=false`, zero events and `Touch was rejected` on attempted injections outside active gameplay; that does not establish the separate foreground-guard rejection path. Do not promote these observations to reliable hardware input, Android frame pacing, heat or human-play acceptance.

Native emulator captures: [title](screenshots/gate2_android_native_title.png), [crew](screenshots/gate2_android_native_crew.png), [Practice](screenshots/gate2_android_native_practice.png), [released](screenshots/gate2_android_native_released.png), [Back/menu](screenshots/gate2_android_native_back.png). The QA helper was uninstalled, the game stopped, and the owned emulator processes stopped before final desktop profiling. No physical phone or player's normal desktop save was used.

To repeat the helper on an explicitly selected test device, build it, install its ignored APK, open the game and enter active gameplay first. Coordinates below assume 720 x 1280; adjust them for the device. A successful instrumentation result means `passed=true`; Android's successful instrumentation code is `-1`.

```powershell
.\tools\build_gate2_touch.ps1
adb -s DEVICE_SERIAL install .bin/gate2-touch/gate2-touch.apk
adb -s DEVICE_SERIAL shell am instrument -w -e aim_x 160 -e aim_y 1063 -e gas_x 560 -e gas_y 1130 -e duration_ms 1500 -e rest_ms 700 -e cycles 3 com.itsd85.toottubes.qa/.Gate2Touch
adb -s DEVICE_SERIAL uninstall com.itsd85.toottubes.qa
```

The helper uses a fresh disposable signing identity each build. Uninstall a previous installation of **only the QA helper** before installing a newly signed helper. Never uninstall the game as part of these QA commands.

### Final post-fix desktop run

With the emulator stopped and screenshot capture disabled: **36 checks pass**, **110.32 s**, **56** hold presses, **6,691** touch events, one contact, zero recoveries, both checkpoints, zero incidental focus resumes and **100% sampled rider head-point visibility** in the defined safe play area. Median frame time **16.661 ms**, p95 **18.572 ms**, sampled maxima **80 draw calls / 56,402 visible primitives**, Intel UHD Graphics / Compatibility / 720 x 1280. No other game check or recording/encoding was running. Detailed final gate status is in [PROGRESS.md](PROGRESS.md).
