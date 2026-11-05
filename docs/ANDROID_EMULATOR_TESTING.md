# Phase 5 Android emulator checks

This checks Android input, lifecycle, settings and offline gameplay on the laptop. It does not replace ARM-phone installation, wireless multiplayer, physical touch/haptics, heat or human playtesting. Use the final JSON result, captures and runtime log together.

**Current result, 2026-11-05: partial behavior evidence; rendering acceptance failed.** The software-rendered x86-64 fixture passed 55 native-control/lifecycle/offline/save checks, but its captures were flat blue and its log contained shader errors. Host GPU mode reached GLES 3.1 without those shader errors but did not reach the first Title snapshot within 120 seconds. ANGLE fell back to the faulty SwiftShader renderer on this installed SDK. The runner now rejects blank captures and runtime errors. No passing Android rendering or ARM-phone execution claim is made.

## Run

Requires the project's Godot binary/templates, Android SDK/emulator, an installed Android system image/AVD, JDK 17, Python and Pillow. Pillow is used only to inspect test screenshots, not by the game.

```powershell
.\tools\build_gate2_touch.ps1
& .\.bin\Godot_v4.7.2-stable_win64_console.exe --headless --path . --export-debug 'Android Emulator QA' .bin/phase5-emulator-x86_64.apk
python tools/run_android_checks.py --serial emulator-5580 --start-avd TEMPO_Phase3A_Test
python -m unittest discover -s tools -p test_android_checks.py
```

To retry only Android startup and rendering, without installing the native touch
helper or running a course, use a fresh evidence folder:

```powershell
python tools/run_android_checks.py --serial emulator-5580 --start-avd TEMPO_Phase3A_Test --startup-only --output .bin/android-startup-attempt-01
```

Choose a new folder name for each attempt. The report explicitly labels this as
startup/rendering only; passing it cannot establish gameplay acceptance. Emulator
boot failures also produce a failed `results.json` with the exception reason,
replacing any stale passing result in that folder. Logs, screenshots and the AVD
configuration-restoration record use the selected folder together.

The latest focused diagnostic was stopped under heavy laptop memory pressure
(less than 300 MB available during boot). The emulator reached its boot-ready
signal around shutdown; APK installation then failed, so this attempt produced
no new app-rendering or gameplay evidence. Its original AVD configuration was
restored, and its process tree was stopped. Keep sufficient RAM/disk available
before another run; do not close unrelated applications automatically.

Replace the AVD name with an existing compatible local test AVD. The runner uses its own read-only session, host GPU, dynamic GLES version detection, 720 x 1280, two cores, 1 GB RAM by default, no snapshots, no visible emulator window and no microphone/audio capture. `--memory 1536` and `--gpu angle_indirect` are optional diagnostics, not a known fix for this installed SDK. It refuses an occupied emulator port. Configuration is backed up and restored after the session, including failed startup; `emulator-restored.json` records that restoration. No router/firewall settings are changed.

For an already running compatible emulator, omit `--start-avd`. The serial must explicitly identify an emulator or local emulator TCP endpoint, and `ro.kernel.qemu` must equal `1` before installing or changing anything. Physical-phone serials are refused. The runner never uninstalls the game. Its disposable touch helper may be replaced if its temporary signing identity differs.

The emulator-only preset exports **x86-64** into ignored `.bin/`, using the same GDScript, art, settings and physics as the game. The normal debug/release phone presets remain **ARMv7 + ARM64**. This avoids an unsupported instruction in the installed Android 11 emulator's older ARM translation layer. A successful x86-64 run does not establish that the ARM phone APK executes successfully on a physical device.

## Checks and evidence

| Area | Required evidence |
|---|---|
| Startup/menus/settings | Real Android taps follow Title, Main Menu, Settings, Mode Select and Crew Setup; Back navigation and saved preferences survive a fresh process and same-version APK reinstall |
| Native two-finger control | Android MotionEvents enter the real input adapter; distinct AIM/HOLD IDs, held/firing state, actual accumulated physical force and gas drain are observed |
| Release | Both controls/audio clear after release; force stops accumulating; dragging HOLD outside clears thrust while AIM remains owned |
| Home/resume | Foreground guard cancels injected pointers; Home/resume pauses and clears input/audio; Resume does not restart old input |
| Offline | Emulator airplane mode is enabled; a separately labeled 3x scripted driver completes Sky Garden using the normal four-seat thrust/gas/physics contract, ordered checkpoints and save flow |
| Relaunch/isolation | Saved stars, best time, unlock and preferences survive a new Android process; the normal save's hash remains unchanged |
| Rendering/runtime | Central screenshot content must contain more than 64 colors; uniform/blank frames fail. Godot script/render errors and fatal exceptions fail the run. Captures still require visual inspection |

The native-input portion has no scripted steering. The separate accelerated solvability mode uses the existing `CrewBrain`; it never teleports, refills gas or changes route geometry. Its timing is not performance evidence.

`scripts/AndroidCheck.gd` is an opt-in developer probe. For Android debug builds the runner writes a marker inside the app's private files, then removes it on exit. Ordinary startup has no QA navigation action; release phone builds ignore that private debug marker. Test preferences/progression use `phase5_android_qa.cfg`, not `save.cfg`. The exported launcher's security policy discards arbitrary engine command-line extras, so the runner does not depend on those extras.

Reports live in `.bin/phase5-android/`: `results.json`, `environment.json`, `logcat.txt`, native instrumentation logs, title/settings/held/pause/result PNGs, emulator log and configuration-restoration report. `results.json` is reset to failed startup before each attempt; a missing/failed run cannot reuse an old passing report. The final result is not accepted solely because touch injection returned success or the app process stayed alive.

Use `--output` to keep another attempt separate. Seven device-free regression
tests cover physical-serial refusal, blank-frame rejection, nonblank capture,
AVD restoration, evidence isolation, startup-only scope and failed-boot reporting.

This session's partial run is preserved separately as `.bin/phase5-android-logic-only.json` with overall `passed: false` and `logic_passed: true`; the accompanying failed render is explicit. The final default-lighting host/ANGLE attempts are not passing runs. `.bin/phase5-emulator-preservation.json` verifies unchanged SHA-256/length of the original AVD's userdata/encryption images and byte-identical configuration restoration. Three temporary overlays created by this session were identified by path/time/backing-image metadata and removed after their emulator processes stopped; older/unrelated overlays were preserved.

## Renderer limitations found during setup

The old SwiftShader backend produced a flat blue screen while control and physics logic continued to work. Its shader-link error matched [Godot issue 109550](https://github.com/godotengine/godot/issues/109550). A lower light-capacity experiment did not resolve it and was reverted. The runner requires visible capture content and clean runtime logs to reject this case.

Host GPU mode also needs `GLESDynamicVersion` enabled: the installed emulator otherwise advertises GLES 2 and the game fails to create its required GLES 3 context. These are emulator setup constraints, not proof of an equivalent problem on real phone GPUs. Phone rendering and performance gates stay open.
