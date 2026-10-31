# Phase 1 progress — 2026-10-31

Phase 1 implemented. Stopped at Gate 1; Phase 2 has not started.

## Delivered

- Godot 4.7.2 standard project, Compatibility, 720 × 1280 portrait, mouse-to-touch, 60 Hz physics, manual Android Back handling.
- ConfigFile progress, bounded level unlocks, best stars/times, avatar/settings/tutorial persistence, reset and star thresholds. Online completion cannot alter offline progress.
- Defensive avatar sanitization, seeded randomization API, six skin tones, eight outfits, four floats, five hats and four toot colors.
- Original low-poly primitive rider/float/hat model with shared materials and no shadows. Colored primitive puff previews show the toot selection.
- Rotating 3D avatar creator on a water disc; scrollable controls keep 120 px touch sizes, 28+ px text and the top 80 px clear. Name input, option wraparound, Randomize, Save and Back.
- Title, Main Menu, Avatar Creator, Mode Select, Settings and Credits navigation. Mode Select/Settings remain Phase 1 placeholders. Title Back exits; other screens return appropriately. Android Back and desktop Escape share navigation.
- Shared Fredoka theme and included OFL license; GUT 9.6.1 committed with upstream license.
- Bash setup/test runners and native PowerShell equivalents. Local editor downloads live in ignored `.bin/`.
- GDD, credits, README and rendered screenshots under `docs/screenshots/`.

## Validation

Run on Windows with Godot 4.7.2 standard and GUT 9.6.1:

```text
bash tools/run_tests.sh
Scripts               3
Tests                11
Passing Tests        11
Asserts             239
All tests passed!
```

The native PowerShell runner also passed the same 11 tests / 239 assertions. Coverage: progression bounds/replays, best results, save/reload/reset, star boundaries, offline protection, invalid avatar payloads, randomization, every model option, first-use/returning navigation, Back requests, creator controls/save, and recursive loading/instantiation/freeing of all seven Phase 1 scenes. Save tests use disposable paths and preserve the player's normal save.

Rendered Compatibility checks on Intel UHD Graphics: Title, Avatar Creator and Main Menu captured at 720 × 1280; every avatar option cycled without runtime errors. Screenshots visually inspected. This is desktop evidence, not Android/touch/device-performance acceptance. Automated navigation routes were checked; the manual F5 and close/reopen gate remains for the user.

## Decisions and limitations

- The plan defaults its bootstrap to 4.7-stable; the currently available 4.7.2-stable patch was pinned consistently instead. `GODOT_VERSION` remains configurable.
- Added PowerShell runners because Bash is not on this Windows PATH; the required `.sh` runner was run using Git Bash.
- Downloaded Fredoka from its official Google Fonts repository rather than leaving the project on a fallback font.
- Creator controls scroll to fit their required touch sizes beneath the preview. Its toot color is represented by primitive puff meshes; gameplay particles belong to Phase 2.
- The lab PDF/11-heading template is unavailable in the supplied materials. `GDD.md` has 11 explicitly provisional headings; exact heading alignment awaits that source.
- Audio and Net are intentional stubs. No racing, networking, APK, phone validation or publication was attempted in Phase 1.
- Reset clears campaign progress/tutorial state and preserves avatar/settings.

## Gate 1 — user checks

- [x] `tools/run_tests.sh` passes; result shown above.
- [ ] Press F5 in Godot: Title → Avatar Creator → Main Menu. Window is portrait.
- [ ] Change every avatar option and confirm the preview updates. Check Randomize. Save, close Godot and run again: the avatar persists.
- [x] Commit with `Phase 1: foundation, save system, avatar creator`.

Do not start Phase 2 until the user completes the manual gate and asks for that phase.
