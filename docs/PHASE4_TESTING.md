# Phase 4: shared-ring LAN checks

2026-11-05. Laptop implementation and validation only. Physical 2-phone and 4-phone acceptance remains deferred by the user's instruction; Phase 4's human/device gate stays open. Phase 5 has not started.

## Play on the laptop

Open the project in Godot and press F5, or run:

```powershell
& .\.bin\Godot_v4.7.2-stable_win64.exe --path .
```

Create/save a rider if needed, then **Play -> Host LAN crew**. A second running copy uses **Play -> Join LAN crew**, entering `127.0.0.1` on the same laptop. On another device, enter the host's displayed Wi-Fi IP instead. Every guest toggles Ready; the host chooses an unlocked course and starts. Two to four humans occupy seats on the same ring. Use WASD + Space or the AIM/HOLD pads. Focus loss requests a shared pause, so switching between laptop windows during a run requires host Resume. Each window shows its assigned rider with `(you)` in the lobby.

The host controls simulation, completion, resume, recovery, restart and return to lobby. Every rider can pause or leave. Guest departure immediately releases its input and makes its seat vacant; no automatic opponent or second ring appears. The host can finish with the remaining crew. New guests join in the lobby. Host departure or loss ends the session and returns guests to Mode Select with an explanation.

## Required automated commands

```powershell
& 'C:\Program Files\Git\bin\bash.exe' tools/run_tests.sh
& 'C:\Program Files\Git\bin\bash.exe' tools/net_smoke.sh
```

The smoke runner uses Python's standard library and separate real Godot processes. It runs host + 1 guest before host + 3 guests on ENet port 7777, followed by unreachable-port and abrupt-host-loss cases on isolated test ports. Reports and logs are stored under `.bin/phase4-validation/<timestamp>/`. It fails on nonzero exits, engine runtime errors, missing reports, failed assertions or differing cooperative results. It terminates only the children it launched. All saves use explicitly named disposable files.

Connected course checks use scripted seat drivers sending the normal network input contract and a 3x simulation clock. They do not teleport, bypass checkpoints or refill gas. Both ordered checkpoints and the shared finish must be reached; every occupied seat must contribute force. This verifies application logic and transport on loopback, not human coordination, wireless conditions or device performance.

Checks cover owned-seat spoofing, explicit release before expiry, loss of release/refresh packets, full 3D motion, gas, host-only physics, identical results, clean rematch, shared pause/resume, guest removal, host exit, recovery to Mode Select and byte-identical offline saves. Input units additionally cover nonfinite/range/type errors, rate limits, stale/out-of-order sequence numbers, old rounds, empty gas and stopped run state. The expiry fixture measures the actual receive timestamp, rather than assuming that multiple processes have identical frame timing.

Final evidence: **78/78 GUT tests, 7,642 assertions across 19 suites** (`.bin/phase4-final-tests.log`); **128/128 network checks** in `.bin/phase4-validation/20261105-110145/` (two peers 41, four peers 75, unreachable 6, abruptly killed host 6). The two-peer crew completed Sky Garden in **126.30 s**, the four-peer crew in **119.20 s**, both with zero recoveries and identical results on all peers. Rendered presentation fixtures pass six checks. These counts describe laptop automation only.

## Protocol and boundaries

- ENet port **7777**, `MAX_CLIENTS = 3`; host ID 1 owns seat 0. Three channels separate reliable lifecycle/release, ordered input and ordered snapshots.
- Guests send normalized aim/strength/held state at 30 Hz during ordinary real-time play. Host accepts only the sender's occupied seat, current round, increasing sequence and finite bounded strength/direction. Held messages are capped at 90 per second. Gas and depletion remain host-integrated; clients cannot supply gas, transforms, race clocks or results.
- Explicit releases are reliable. Unrefreshed input expires after **350 ms**, including packet loss. Sequence checks prevent a delayed held packet from overriding a newer release.
- The host sends position/orientation, linear/angular velocity, gas/aim/held/firing/depletion, rider orbit, route distance, recovery/checkpoint state, pickups, race clock and result. Guests interpolate frozen bodies, with collision and engine physics interpolation disabled. Only `Level.race_time` drives moving hazards on every peer.
- Ready/load barriers keep every peer in the same round. Round IDs reject stale input/snapshots after rematch. Initial connect timeout is 10 s, scene load timeout 15 s, and host heartbeat timeout 8 s in lobby or run. Normal ENet disconnects may be detected sooner.
- Online profiles and owners stay in session memory. They never replace the offline crew or saved avatars. Online results cannot unlock courses or write best times/stars. Leaving restores the prior offline result and mode.
- LAN needs no backend/account. Android internet/network-state permissions are enabled for ENet. Offline play never opens a network peer by itself. Original Godot transport reference: [high-level multiplayer](https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html).

## Presentation and Android handoff

`tools/verify_lan_ui.gd` creates labeled visual fixtures for Mode Select, a four-occupant lobby and the online result HUD. Captures are `docs/screenshots/phase4_*.png`; fixtures are not evidence of a network course completion. GUT checks portrait button bounds, the top safe area, 120 px touch targets and visible slot labels. No phone FPS claim follows from these checks.

Debug handoff: `export/TootTubes-phase4-lan-debug.apk`, **0.6.0-lan / code 10**, same package as previous debug builds, ARMv7 + ARM64. The export folder and signing material stay outside Git. Physical installation/touch/Back and wireless play remain unchecked.

APK: **57,915,202 bytes**, minimum API 24 / target API 36, v2/v3 signature verified. Manifest includes INTERNET, ACCESS_NETWORK_STATE and VIBRATE; archive contains the new runtime modules/lobby and excludes tests, tools, docs, addons, reference video and signing material. SHA-256: `0039B10532A0487F27BED7E7A3B4461F82390756938D381A60603B1E270676D7`.

## Gate 4: manual/device acceptance

- [ ] Two physical phones: join, ready, aim/hold/release, gas and shared finish.
- [ ] Four physical phones: four recognizable riders/owned controls, shared checkpoints/result and rematch.
- [ ] Wireless guest loss clears thrust and vacates only its seat; host loss shows an in-game message and returns to Mode Select.
- [ ] Wrong/unreachable IP and Back/Android Back recover safely; focus loss releases input and shared pause resumes correctly.
- [ ] Offline profiles, unlocks, stars/times and settings survive online play and app relaunch.
- [ ] Human coordination, wireless interpolation and phone performance accepted.

Keep this gate open until checked on the devices. Continue to Phase 5 only with a separate execution instruction.
