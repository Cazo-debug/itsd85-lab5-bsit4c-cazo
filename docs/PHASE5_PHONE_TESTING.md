# Phase 5: authorized physical-phone checks

The user explicitly authorized checks on the wirelessly connected TECNO CLA5
(Android 15, ARM64, Mali-G57 MC2, 1080 x 2436). This continues Phase 5; it does not
authorize publication or close the required second-phone-class/human gates.

## Current session

The installed game was version `0.4.1-water-riders` (code 7). Its APK and normal
924-byte save were backed up locally before the upgrade to `0.7.0-rc1` (code 11).
The backup and detailed reports remain in ignored `.bin/phase5-phone/`.

Title and gameplay captures have been inspected on the actual phone. The final
explicit subset run passes **129 checks**: rendering, menu taps, Settings/Back,
Home/resume without an active hold, separate real-time four-seat high/low course
completion, isolated saves/relaunch and preservation of the original save/display.
Its report is `.bin/phase5-phone/run-07-subset/results.json`: `passed: true`,
`native_pointer_tests_passed: false`, `game_installation_tested_this_run: false`.
It verifies that the installed APK's SHA-256 equals the patched local debug APK;
installation/reinstallation evidence comes from earlier runs, separately.

Native injection in earlier failed full runs produced two distinct AIM/HOLD IDs,
0.4167 seconds of integrated force, gas falling to 95.94%, and a 0.75-radian rider
orbit change. However, the instrumentation process failed to finish within its
20-second deadline. The queued-injection experiment also timed out and was
reverted. Full pointer release, HOLD drag-out and active-held Home cleanup remain
unaccepted on this phone. The subset flag skips those tests explicitly; it does
not convert their failed results into passing native-input acceptance.

## Real-time debug-build measurements

Both runs use Sky Garden, four occupied seats, the real gas/physics rules,
ordered checkpoints and moving hazards. Both finish in **110.9 seconds** with
zero recoveries. These are phone process-frame intervals, not compositor GPU
timings or a human playtest.

| Quality | Mean FPS | Median frame | P95 frame | Four-firing frames | Max draws | Max primitives | Battery temperature |
|---|---:|---:|---:|---:|---:|---:|---|
| High | 51.63 | 19.014 ms | 24.759 ms | 3,766 | 81 | 52,834 | 37.7 to 38.1 C |
| Low | 52.22 | 18.877 ms | 24.461 ms | 3,792 | 80 | 42,914 | 38.1 to 38.0 C |

The average is approximately 52 FPS on both settings, so steady 60 FPS remains an
optimization target. These short charging-device runs do not establish long heat
stability or the required second performance class. No new app script errors or
native fatal signals were recorded in the final subset.

The first physical run exposed a native `AudioTrack` SIGSEGV. The fault address
matched the first byte past the eight-second PCM music buffer. The original WAV
loop used its frame count as an exclusive endpoint, while Godot's mixer could
decode that endpoint. `Audio.looping()` now appends the first PCM frame as a guard
while preserving the full original samples and loop period. The stronger audio
tests check allocation bounds, unchanged source samples, the guard, and a
17-second mix across two full music wraps. This is consistent with the upstream
[WAV loop-boundary report](https://github.com/godotengine/godot/issues/119778).
The initial failed runs and app-specific native crash dumps are retained locally.

One later startup attempt stalled with a SurfaceView/EGL surface warning and no
QA telemetry; a verified-marker fresh launch and subsequent full starts reached
Title. Keep that observation visible in the record rather than using a warm
launch alone to assert universal cold-start stability.

## Reproduce

Run only against the phone explicitly authorized for testing. For wireless ADB,
use the paired connection endpoint shown by `adb mdns services`, rather than a
pairing-code port. No network scan or pairing reset is performed.

```powershell
.\tools\build_gate2_touch.ps1
.\tools\build_phase5.ps1
python tools/run_phone_checks.py --serial YOUR_PAIRED_IP:PORT --output .bin/phone-attempt-01
python -m unittest discover -s tools -p '*_checks.py'
```

The runner targets an existing debug prototype and backs up its normal save.
For the successfully measured subset, use the already installed, hash-verified
candidate and explicitly skip the currently failing pointer helper:

```powershell
python tools/run_phone_checks.py --serial YOUR_PAIRED_IP:PORT --use-installed --without-pointer-helper --output .bin/phone-subset-attempt-01
```

`--use-installed` refuses an APK hash mismatch and skips game installation and
reinstallation; it cannot supply upgrade evidence. The full default mode retains
the native pointer assertions and currently fails on this phone's instrumentation
timeout. Fourteen device-free runner tests cover emulator/physical target guards,
coordinate scaling, foreground protection, crash-log retention, subset-report
scope, installed-hash rejection and the earlier emulator safeguards.

The runner preserves physical screen size/density and keeps Wi-Fi connected.
Coordinates scale from the actual Godot viewport to the current physical display.
Foreground checks precede taps/captures; the native helper also checks foreground
ownership during a hold and cancels on Home. Pointer acceptance requires the
game's actual IDs, force, gas, release and audio state, together with successful
instrumentation completion; injection success alone is insufficient.

Only the debug game's isolated `phase5_android_qa.cfg` and explicit debug marker
are used for test progression. Cleanup removes the marker, compares the original
normal save byte for byte, removes a helper added by this test, and reopens the
normal game. The game is upgraded without clearing its data. Log capture is
restricted to remembered game-process IDs, including native crashes after a
process exits; unrelated app logs are not collected.

Final device verification confirms the original pre-upgrade save remains byte
identical, the helper and newly created QA files are removed, physical size/density
are unchanged, and the patched `0.7.0-rc1` / code 11 debug game is open normally.
The original version-7 APK and save remain backed up on the laptop. The release
APK is signed/resource-checked but has not been execution-tested on this phone.

High/low course profiles use the existing four-seat `CrewBrain` at
`Engine.time_scale == 1`. They use normal sustained input, gas, collisions and
checkpoints, without teleports or gas refills. Frame intervals come from the
phone's real process timestamps; draw calls/primitives and simultaneous-firing
frames are recorded. Battery service temperature is in tenths of a degree C.
Charging, capture overhead, run order and short run duration limit heat/performance
comparisons. Native screenshots can contain the owner's floating chat overlays,
so they remain private local evidence rather than committed artwork.

## Acceptance limits

- Android-injected pointers exercise the real phone input path; they are not a
  human touchscreen/ergonomics review.
- Wi-Fi stays enabled for wireless debugging. An idle `Net` during a local run
  establishes no network session, not airplane-mode acceptance.
- One phone cannot establish two performance classes or two/four-phone co-op.
- Haptic feel, listening quality, steering/camera feel, long heat stability,
  reference-art approval and release publication remain separate checks.
