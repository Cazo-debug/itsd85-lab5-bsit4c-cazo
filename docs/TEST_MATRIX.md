# Phone test matrix (lab Phase 7, Checkpoint 7)

Build tested: `TootTubes-v1.0` debug build (version 1.0, code 12) · Date: 2026-11-25

| Test | Phone 1: Infinix X6525, Android 13 (720x1612) | Phone 2: TECNO CLA5, Android 15 (1080x2436) |
|---|---|---|
| App installs and opens | Pass | Pass |
| Layout fits the screen, nothing cut off | Pass (title, menu, mode, lobby, race) | Pass (title, menu, mode, lobby, race) |
| Touch controls respond correctly (AIM + HOLD at the same time) | Pass for one finger: HOLD turned yellow, gas dropped, ring moved. Two thumbs at once not tested | Not tested |
| Progress saved after force-close (clear L2, force-close, reopen: L3 open) | Pass for L1: force-closed, reopened; L1 kept 3 stars and best time, L2 open, L3-L5 locked. Clearing L2 not tested | Not tested |
| Offline mode in airplane mode | Pass – airplane mode on, no network interface; offline race ran with working controls | Not tested |
| Online match between the two phones (host on one, join on the other) | Pass – hosted; both phones loaded the same course and timer (Wi-Fi and hotspot). Finish and in-race movement not yet checked | Pass – joined as guest (Wi-Fi and hotspot) |
| Nearby game appears on the second phone without typing an IP (try Wi-Fi and phone hotspot) | Pass – host announced itself | Pass – listed within about 6 s on home Wi-Fi and on a hotspot; one tap joined |
| Star Scramble offline: Versus against an assistant rider (stars on the water, per-rider counts) | Pass – banner showed the rules, gold stars rendered, P1 ★3 / P2 ★2 (5 of 12) after one run, 56 FPS | Not tested |
| Star Scramble online: two phones, host picks Versus or Teams | Pass (Versus) – Infinix hosted, TECNO joined through Games nearby, host picked Versus and the guest lobby showed it; both phones showed the same star count (P2 ★1 at 195 s, ★5/12 at the end), 57–69 FPS; both result screens read "Player wins! 5 stars to 0. The host decided the winner." Screenshots in docs/screenshots/two_phone_star_scramble/. Teams 2v2 not tried on phones (needs 4 devices; passed in the LAN smoke test) | Pass (guest side of the same match, 60–61 FPS) |
| Wi-Fi off → Join shows an error message, no crash | Pass – airplane mode, typed 192.168.1.10; red message "Could not reach the host...", no crash | Not tested |
| Frame rate smooth (no visible stutter); Settings → Show FPS: ___ FPS | Pass – 65 FPS idle, 64 FPS moving (High quality) | Pass – 60 FPS at idle (High quality) |
| Battery/heat acceptable after 10 minutes | Inconclusive – battery 36.8 → 36.7 °C, but the run left Practice before 10 min | Inconclusive – 39.1 → 39.5 °C at 5 min, then USB dropped (battery about 10%) |

Write **Pass** or **Fail** plus a short note (e.g. "Pass – 55 FPS", "Fail – button cut off at bottom").

Evidence files (recordings): Checkpoint 3 `______`, Checkpoint 4 `______`, Checkpoint 5 `______`.

Still to test by hand: two thumbs at once, clearing L2 and then force-closing, the TECNO in airplane mode and Wi-Fi-off, and a continuous 10-minute play for heat.
