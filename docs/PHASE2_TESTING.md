# Check Phase 2

## Run on your computer

Open PowerShell in the project folder:

```powershell
& .\.bin\Godot_v4.7.2-stable_win64.exe --editor --path .
```

Press **F5**. Choose **Tap to start**, save an avatar if prompted, then **Play → Play Level 1**.

1. Wait for **3, 2, 1, TOOT!**. Taps during the countdown must do nothing.
2. Click ahead of your float on the water. One click should spend one of three gas charges. Drift should slow naturally.
3. Spend all three charges. Each charge refills after 1.5 seconds. Collect a brown bean to refill one immediately.
4. Bump an orange bank or island. Your float should bounce and stay inside the course.
5. Watch the moving water, green/selected-color puffs, white ripple rings and smooth camera. The goal appears at the start, and the timer/progress dot update.
6. Reach the yellow finish ring within 75 seconds. A brief stars message appears, then you return to the menu. Let time run out on another attempt to check losing/retry.
7. Use **Back** or **Escape** to leave a race. HUD buttons must not spend gas. The full pause menu arrives in Phase 3; sound effects arrive in Phase 5.

In Godot, use **Debugger → Monitors** for FPS, draw calls and primitives, or the **Profiler** to inspect spikes. Target 60 FPS on the desktop and mid-range phone; low-end phone target is at least 30 FPS. Desktop tests do not establish phone performance.

## Automated checks

```powershell
.\tools\run_tests.ps1
& .\.bin\Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 --path . --script tools/verify_level_one.gd
```

Expected: **19 passing tests / 335 assertions**, followed by a verifier message with a successful finish, eight pickups and three stars. The verifier uses a disposable save file and does not overwrite your normal avatar/progress save. Its waypoint driver is test tooling, not an in-game bot.

## Try the debug APK on your phone

1. Copy `export/TootTubes-phase2-debug.apk` to your Android phone.
2. Open it in the phone's file manager and allow installation from that app if Android asks. Requires Android 7 or later, ARMv7/ARM64.
3. Open **Toot Tubes**, create an avatar, then play Level 1 using taps. Confirm portrait orientation, readable UI, response, collision, and smooth movement.
4. Record any problem with the phone model, action, screenshot/video and what happened.

To rebuild on this computer:

```powershell
& .\.bin\Godot_v4.7.2-stable_win64_console.exe --headless --path . --export-debug "Android Debug" export/TootTubes-phase2-debug.apk
```

On another computer: install Godot's matching 4.7.2 export templates, configure **Editor Settings → Export → Android** with JDK 17 and the Android SDK, then clear **Custom Template → Debug** in the export preset to use the installed template. Keep credentials/keystores and exported APKs outside Git. This is a development build, not the Phase 5 release.
