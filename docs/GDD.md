# Toot Tubes - Game Design Document

Status: Phase 1 foundation. These 11 headings are provisional because the lab PDF and its exact template were not supplied. Game rules below follow IMPLEMENTATION_PLAN.md Section 0; future features are planned, not shipped.

## 1. Title and pitch
Toot Tubes: players on pool floats race through an original 3D water park. The only way to move is to toot.

## 2. Audience and platform
ITSD 85, BSIT-4C lab project. Android APK, portrait, one-thumb touch input. Godot 4.7.2 standard/GDScript, Compatibility renderer.

## 3. Core gameplay and controls
Tap the water to push the float toward that point. Carry up to 3 toots; recover one every 1.5 seconds. Beans instantly refill one. Water drag slows the float; floats and obstacles collide. Spikes pop the float, followed by a 1-second respawn at the last checkpoint while race time continues.

## 4. Goals, win and loss
Offline: finish before time expires and before every bot. Lose if the timer expires or a bot finishes first. Win with more than 50% time remaining: 3 stars; more than 25%: 2; otherwise: 1. Lost runs receive 0 stars.

## 5. Level progression
| Level | Name | Goal | Time | Bots | Challenge |
|---|---|---|---|---|---|
| 1 | Lazy River | Toot to the finish ring in 75 seconds | 75 s | 0 | Tutorial, beans, current, arrows |
| 2 | Bumper Bay | Beat Bubbles to the finish in 60 seconds | 60 s | 1 | Round bumper islands |
| 3 | Sweeper Spin | Beat Bubbles past the sweepers in 60 seconds | 60 s | 1 | Sweepers and spikes |
| 4 | Whirl Pool | Beat Bubbles through the whirlpools in 55 seconds | 55 s | 1 | Whirlpools, moving spikes, fewer beans |
| 5 | Grand Toot | Beat Bubbles and Fizz in 70 seconds | 70 s | 2 | Longer combined course and spike logs |
Wins unlock the next level up to 5. Save best stars, best times, unlocks, avatar and settings locally. Online results never change campaign progression.

## 6. Modes and multiplayer
Offline campaign works in airplane mode. Online supports exactly two phones on the same Wi-Fi, ENet port 7777, host/join by IP. Host sanitizes avatar data and validates the winner. Connection errors return to Mode Select with an in-game message. Nakama internet play is optional after Phases 1-5.

## 7. Characters and customization
Original chunky rider built from capsules and spheres. Name up to 12 printable characters, 6 skin tones, 8 outfits, donut/striped/duck/lifebuoy floats, none/cap/crown/propeller/bucket hats, green/purple/pink/yellow toot colors. Avatar persists locally and is shared online later.

## 8. Visual style
Bright low-poly original water park, tilted camera, turquoise water, orange sand with green rims, dark spikes, white ripples and colored puffs. Shared materials, primitive meshes, Fredoka typography. No commercial characters, models, textures, logos or music. No real-time shadows.

## 9. Audio
Planned original generated WAV effects, optional user-supplied CC0 OGG music, saved sound toggle. Phase 1 includes silent Audio method stubs only.

## 10. Interface and accessibility
Title -> Avatar Creator on first use -> Main Menu -> Mode Select. Avatar, Settings and Credits return to Main Menu. Android Back and visible Back buttons; Title exits. 720 x 1280 reference viewport, minimum 28 px body type, 120 px buttons, 80 px top safe area. Creator scrolls options to preserve touch sizes. Settings and Mode Select remain placeholders in Phase 1.

## 11. Technical plan and validation
Phases: foundation -> race core -> offline campaign -> LAN multiplayer -> polish/release. GUT automated tests and manual gates per phase. Target 60 FPS mid-range / 30 FPS low-end, under 150 draw calls and 60k visible triangles, APK under 60 MB. These are future device acceptance targets, not Phase 1 measurements. Git-tracked GUT, no secrets or generated exports committed. Required phone tests remain human acceptance work.
