# Phone test matrix (lab Phase 7, Checkpoint 7)

Build tested: `TootTubes-v1.0` debug build (version 1.0, code 12) · Date: 2026-11-25

| Test | Phone 1: Infinix X6525, Android 13 (720x1612) | Phone 2: TECNO CLA5, Android 15 (1080x2436) |
|---|---|---|
| App installs and opens | Pass | Pass |
| Layout fits the screen, nothing cut off | Pass (title, menu, mode, lobby, race) | Pass (title, menu, mode, lobby, race) |
| Touch controls respond correctly (AIM + HOLD at the same time) | | |
| Progress saved after force-close (clear L2, force-close, reopen: L3 open) | | |
| Offline mode in airplane mode | | |
| Online match between the two phones (host on one, join on the other) | Pass – hosted; both phones loaded the same course and timer (Wi-Fi and hotspot). Finish and in-race movement not yet checked | Pass – joined as guest (Wi-Fi and hotspot) |
| Nearby game appears on the second phone without typing an IP (try Wi-Fi and phone hotspot) | Pass – host announced itself | Pass – listed within about 6 s on home Wi-Fi and on a hotspot; one tap joined |
| Wi-Fi off → Join shows an error message, no crash | | |
| Frame rate smooth (no visible stutter); Settings → Show FPS: ___ FPS | | |
| Battery/heat acceptable after 10 minutes | | |

Write **Pass** or **Fail** plus a short note (e.g. "Pass – 55 FPS", "Fail – button cut off at bottom").

Evidence files (recordings): Checkpoint 3 `______`, Checkpoint 4 `______`, Checkpoint 5 `______`.

Still to test: touch controls with both thumbs, progress after force-close, airplane mode, Wi-Fi off error, FPS, and heat after 10 minutes.
