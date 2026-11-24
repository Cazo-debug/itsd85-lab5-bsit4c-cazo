"""Builds docs/demo/Toot_Tubes_Demo_Guide.html: one self-contained, phone-friendly page
(screenshots embedded) to read before and during the live demo.
Run: python tools/build_demo_guide.py"""
import base64
import io
import re
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SHOTS = ROOT / "docs" / "screenshots"
OUT = ROOT / "docs" / "demo" / "Toot_Tubes_Demo_Guide.html"


def img(rel: str, alt: str, width: int = 420) -> str:
    im = Image.open(SHOTS / rel).convert("RGB")
    im.thumbnail((width, width * 3))
    buf = io.BytesIO()
    im.save(buf, "JPEG", quality=72, optimize=True)
    data = base64.b64encode(buf.getvalue()).decode()
    return f'<img loading="lazy" src="data:image/jpeg;base64,{data}" alt="{alt}">'


def shot(rel: str, caption: str) -> str:
    return f"<figure>{img(rel, caption)}<figcaption>{caption}</figcaption></figure>"


P = "phone_infinix_x6525/"
T = "two_phone_star_scramble/"
Q = "qa_final/"

HTML = r"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Toot Tubes Demo Guide</title>
<style>
:root{--bg:#f3f9fd;--card:#ffffff;--ink:#12324a;--muted:#4f6b80;--line:#d5e6f1;--accent:#2f9e44;--accent-soft:#e3f5e7;--sky:#1c7ed6;--sky-soft:#e3f0fc;--warn:#b35c00;--warn-soft:#fff3e0;--code:#eef4f8}
@media (prefers-color-scheme: dark){:root:not([data-theme="light"]){--bg:#0e1a24;--card:#152634;--ink:#e6f0f7;--muted:#9db3c4;--line:#24394b;--accent:#51cf66;--accent-soft:#16301f;--sky:#74c0fc;--sky-soft:#13283a;--warn:#ffa94d;--warn-soft:#33240f;--code:#1b3042}}
:root[data-theme="dark"]{--bg:#0e1a24;--card:#152634;--ink:#e6f0f7;--muted:#9db3c4;--line:#24394b;--accent:#51cf66;--accent-soft:#16301f;--sky:#74c0fc;--sky-soft:#13283a;--warn:#ffa94d;--warn-soft:#33240f;--code:#1b3042}
*{box-sizing:border-box}
html{-webkit-text-size-adjust:100%}
body{margin:0;background:var(--bg);color:var(--ink);font:16px/1.55 system-ui,-apple-system,"Segoe UI",Roboto,sans-serif}
main{max-width:760px;margin:0 auto;padding:16px}
header.hero{padding:22px 16px 18px;background:linear-gradient(160deg,#4dabf7,#3bc9db);color:#fff;border-radius:18px;margin-bottom:14px}
header.hero h1{margin:0;font-size:30px;letter-spacing:.5px}
header.hero p{margin:6px 0 0}
.meta{font-size:14px;opacity:.95}
nav{position:sticky;top:0;z-index:5;background:var(--bg);padding:8px 0;margin:0 0 6px;display:flex;flex-wrap:wrap;gap:6px}
nav a{font-size:13px;padding:5px 10px;border-radius:999px;background:var(--sky-soft);color:var(--sky);text-decoration:none;font-weight:600}
section{background:var(--card);border:1px solid var(--line);border-radius:16px;padding:16px;margin:14px 0}
h2{margin:0 0 10px;font-size:21px}
h3{margin:16px 0 6px;font-size:17px}
p{margin:6px 0}
ul,ol{padding-left:20px;margin:6px 0}
li{margin:3px 0}
.say{background:var(--accent-soft);border-left:4px solid var(--accent);padding:10px 12px;border-radius:10px;margin:8px 0}
.say b:first-child{display:block;font-size:12px;text-transform:uppercase;letter-spacing:.06em;color:var(--accent);margin-bottom:2px}
.note{background:var(--warn-soft);border-left:4px solid var(--warn);padding:10px 12px;border-radius:10px;margin:8px 0}
.req{border:1px solid var(--line);border-radius:12px;padding:10px 12px;margin:8px 0}
.req .id{display:inline-block;min-width:38px;font-weight:800;color:var(--sky)}
.req .need{font-weight:700}
.req .how{margin-top:4px}
.req .show{margin-top:4px;font-size:14px;color:var(--muted)}
.pill{display:inline-block;font-size:12px;font-weight:700;padding:1px 8px;border-radius:999px;background:var(--accent-soft);color:var(--accent);margin-left:6px;vertical-align:middle}
.pill.warn{background:var(--warn-soft);color:var(--warn)}
.gallery{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:10px}
@media (min-width:600px){.gallery{grid-template-columns:repeat(3,minmax(0,1fr))}}
figure{margin:0}
figure img{width:100%;height:auto;display:block;border-radius:10px;border:1px solid var(--line)}
figcaption{font-size:13px;color:var(--muted);margin-top:4px;line-height:1.35}
table{width:100%;border-collapse:collapse;font-size:14px;table-layout:fixed}
td,th,code,p,li{overflow-wrap:anywhere}
body{overflow-x:hidden}
th,td{text-align:left;padding:7px 6px;border-bottom:1px solid var(--line);vertical-align:top}
th{color:var(--muted);font-weight:700}
.flow{display:grid;gap:8px;margin:8px 0}
.flow div{border:1px solid var(--line);border-radius:10px;padding:8px 10px;background:var(--sky-soft)}
.flow div b{color:var(--sky)}
details{border:1px solid var(--line);border-radius:12px;padding:0 12px;margin:8px 0;background:var(--card)}
details[open]{padding-bottom:10px}
summary{cursor:pointer;font-weight:700;padding:11px 0;list-style:none}
summary::-webkit-details-marker{display:none}
summary::before{content:"+ ";color:var(--sky)}
details[open] summary::before{content:"– "}
code{background:var(--code);padding:1px 5px;border-radius:5px;font-size:14px}
.steps li{margin:6px 0}
.time{font-weight:700;color:var(--sky)}
footer{color:var(--muted);font-size:13px;text-align:center;padding:12px 0 30px}
</style>
</head>
<body>
<main>
<header class="hero">
<h1>Toot Tubes</h1>
<p><b>Demo guide &amp; cheat sheet</b></p>
<p class="meta">ITSD 85 Lab 5 · Mobile Game with Level Progression and Offline/Online Multiplayer<br>
Carlos Fidel G. Castro · BSIT-4C · Team Cazo (solo) · Instructor: Renante Buntod</p>
</header>

<nav>
<a href="#pitch">Pitch</a><a href="#demo">Demo order</a><a href="#req">Requirements</a><a href="#screens">Screens</a><a href="#settings">Settings</a><a href="#tech">How it works</a><a href="#net">Connection</a><a href="#tools">Tools &amp; art</a><a href="#qa">Q&amp;A</a><a href="#limits">Limits</a>
</nav>

<section id="pitch">
<h2>1. What the app is (30-second pitch)</h2>
<div class="say"><b>Say this</b>Toot Tubes is a funny physics party game for Android. Up to four cartoon animals sit on one swim ring and push it through sky waterpark courses by farting. You aim with your left thumb and hold to fart with your right. There are five levels that unlock one by one, you can play offline in airplane mode, or with friends on phones on the same Wi-Fi, in Co-op, Versus or Teams 2v2, collecting stars.</div>
<ul>
<li><b>Goal of each level:</b> get the ring to the finish before the timer runs out.</li>
<li><b>Win:</b> cross the finish in time → 1–3 stars by time left. <b>Lose:</b> timer hits 0 → Retry.</li>
<li><b>Star Scramble:</b> 12 gold stars float on each course. The rider whose seat passes closest to a star takes it. In Versus or Teams, most stars wins.</li>
<li><b>Engine:</b> Godot 4.7.2 (GDScript), Android, portrait, touch controls.</li>
</ul>
</section>

<section id="demo">
<h2>2. Live demo order (7 minutes)</h2>
<p>This follows the lab PDF's live-demo plan (p. 27).</p>
<ol class="steps">
<li><span class="time">0:00 Pitch (30 s)</span> – read the box above, show the title screen.</li>
<li><span class="time">0:30 Level 1 + unlock (2 min)</span> – Play → Play offline → Start Sky Garden. Show the goal text, AIM + HOLD, the timer and stars. Open <b>Courses</b>: locked levels show a lock and can't be opened.</li>
<li><span class="time">2:30 Airplane mode (1 min)</span> – turn on airplane mode, Play offline still works. Close the app, reopen: progress is still there.</li>
<li><span class="time">3:30 Online on a second phone (2 min)</span> – both phones on the same Wi-Fi or hotspot. Phone A: <b>Host a game</b>, set <b>Mode: Versus</b>. Phone B: tap <b>Join …'s game</b>, Ready. Host taps <b>Start together</b>. Point at the matching star counts on both phones and the shared result "<i>… wins! The host decided the winner.</i>"</li>
<li><span class="time">5:30 Top 3 playtest findings (1.5 min)</span> – from your playtest results (fill these in after the playtest).</li>
</ol>
<div class="note"><b>Before the demo:</b> charge both phones, turn on Wi-Fi on both (or the hotspot), set brightness high, and open the app once so it's warm. Set Show FPS off in Settings if you don't want the number on screen.</div>
</section>

<section id="req">
<h2>3. What the PDF requires and how the app meets it</h2>
<h3>Minimum game requirements R1–R10</h3>

<div class="req"><span class="id">R1</span><span class="need">5+ levels, each harder or different</span><span class="pill">Met</span>
<div class="how">5 courses: Sky Garden, Canyon Switchbacks, Cloud Bridges, Spiral Springs, Festival Summit. Each adds new hazards (mallets, boulders, crushers on narrow bridges, currents and whirlpools, then all of them).</div>
<div class="show">Show: Courses screen.</div></div>

<div class="req"><span class="id">R2</span><span class="need">Clear goal per level</span><span class="pill">Met</span>
<div class="how">A banner at the start says the goal, e.g. "Reach the summit together in 240 s. Aim, then hold to fart!" plus the mode rules.</div>
<div class="show">Show: start of any level.</div></div>

<div class="req"><span class="id">R3</span><span class="need">Win and lose, result screen, Retry / Next / Menu</span><span class="pill">Met</span>
<div class="how">Win = finish in time (3/2/1 stars by time left). Lose = timer reaches 0. The result shows stars, time and star counts, with Retry, Next and Menu.</div>
<div class="show">Show: finish a level, or let the timer run out.</div></div>

<div class="req"><span class="id">R4</span><span class="need">Level n+1 locked until n is cleared</span><span class="pill">Met</span>
<div class="how">Locked courses are grey with a lock: "Locked – clear course 3 first". Tapping does nothing.</div>
<div class="show">Show: Courses screen.</div></div>

<div class="req"><span class="id">R5</span><span class="need">Progress saved after closing the app</span><span class="pill">Met</span>
<div class="how">Best stars and time per level are saved on the phone (<code>user://save.cfg</code>, Godot ConfigFile) <i>before</i> the result screen appears. Tested by force-closing on the phone.</div>
<div class="show">Show: close app from recents, reopen, open Courses.</div></div>

<div class="req"><span class="id">R6</span><span class="need">Offline mode works in airplane mode</span><span class="pill">Met</span>
<div class="how">Play offline: solo, or with up to 3 computer "assistant" riders. Versus against an assistant also works offline. No network code runs offline.</div>
<div class="show">Show: airplane mode on → Play offline.</div></div>

<div class="req"><span class="id">R7</span><span class="need">Online: two players, two devices, one match</span><span class="pill">Met</span>
<div class="how">2–4 phones on the same Wi-Fi or hotspot, real time. Tested on Infinix X6525 + TECNO CLA5: same ring, same stars, same result on both.</div>
<div class="show">Show: host + join on two phones.</div></div>

<div class="req"><span class="id">R8</span><span class="need">Offline/Online choice + clear error when online fails</span><span class="pill">Met</span>
<div class="how">"How do you want to play?" screen has OFFLINE and ONLINE. With Wi-Fi off, Join shows "Could not reach the host. Check its IP, Wi-Fi and port 7777." after about 5 s, with no crash. If the host leaves: "Host disconnected. Your offline progress is safe."</div>
<div class="show">Show: Wi-Fi off → Join.</div></div>

<div class="req"><span class="id">R9</span><span class="need">Real phone, one orientation, touch controls</span><span class="pill">Met</span>
<div class="how">Installed on two real Android phones. Portrait only. AIM pad (left thumb) and HOLD button (right thumb).</div>
<div class="show">Show: you're holding it.</div></div>

<div class="req"><span class="id">R10</span><span class="need">Title screen, pause menu, sound on/off, readable text</span><span class="pill">Met</span>
<div class="how">Title screen; pause menu with Resume, Restart, Recover crew, Sound, Quit; Sound On/Off in Settings and in pause (saved); large Fredoka font, big buttons.</div>
<div class="show">Show: tap Pause during a run.</div></div>

<h3>Technical rules from the PDF</h3>
<table>
<tr><th>Rule</th><th>In the app</th></tr>
<tr><td>Godot 4.7, GDScript, Compatibility renderer</td><td>Godot 4.7.2, GDScript, gl_compatibility</td></tr>
<tr><td>720×1280 portrait, canvas_items / expand</td><td>Yes</td></tr>
<tr><td>Save with ConfigFile in user://</td><td><code>user://save.cfg</code></td></tr>
<tr><td>Option A: LAN host/join with ENet</td><td>ENet on port 7777</td></tr>
<tr><td>About 5 s join timeout + message</td><td>5 s, "Could not reach the host…"</td></tr>
<tr><td>Disconnect → message, back to menu</td><td>Yes, offline progress kept</td></tr>
<tr><td>Internet + Access Network State permissions</td><td>Both enabled</td></tr>
<tr><td>Back button on every screen + Android back</td><td>Yes (Courses Back now returns to where you came from)</td></tr>
<tr><td>Music .ogg, effects .wav</td><td><code>sky_theme.ogg</code> + 10 WAV effects</td></tr>
<tr><td>No commercial characters/music; credit assets</td><td>All art and sound made in code; in-game Credits</td></tr>
<tr><td>Package com.itsd85.&lt;team&gt;.&lt;game&gt;</td><td><code>com.itsd85.cazo.toottubes</code></td></tr>
<tr><td>Host decides the result (p. 20)</td><td>Host checks finish/timer, awards stars, names the winner</td></tr>
</table>

<h3>Bonus items (up to +10)</h3>
<ul>
<li><b>Star unlocks / ratings</b> – 1–3 stars per level by time left.</li>
<li><b>Player names</b> – avatar creator with a name, shown over each rider and in results.</li>
<li><b>Settings</b> – sound, music volume, quality, vibration, reduced motion, show FPS.</li>
<li><b>Tutorial / hints</b> – goal banner, hint line under the HUD, Practice mode with no timer.</li>
<li><b>Accessibility</b> – reduced motion (gentler camera, no shake), low quality mode, big text.</li>
<li><b>Nearby join</b> – phones find the host automatically (no IP typing needed).</li>
</ul>
</section>

<section id="screens">
<h2>4. Screen tour</h2>
<p>Real screenshots from the phones. Flow: Title → Main menu → How do you want to play? → Crew setup or Lobby → Race → Pause / Result.</p>
<div class="gallery">
{G1}
</div>
<h3>Online match on two phones</h3>
<div class="gallery">
{G2}
</div>
</section>

<section id="settings">
<h2>5. Settings and options explained</h2>
<table>
<tr><th>Setting</th><th>What it does</th></tr>
<tr><td>Sound On/Off</td><td>Mutes everything. Saved on the phone. Also in the pause menu.</td></tr>
<tr><td>Music − / +</td><td>Music volume in steps (e.g. 70%).</td></tr>
<tr><td>Quality High/Low</td><td>Low = fewer clouds and particles for slow phones. Same physics.</td></tr>
<tr><td>Vibration</td><td>Short buzz on bumps and falls.</td></tr>
<tr><td>Reduced Motion</td><td>Gentler camera, no screen shake.</td></tr>
<tr><td>Show FPS</td><td>Shows frames per second (used for the phone test matrix).</td></tr>
</table>
<h3>Crew setup (offline)</h3>
<ul>
<li><b>Seats 1–4:</b> tap a seat, then "Seat:" cycles <i>Local rider → Empty → Assistant</i>. Assistant = computer rider.</li>
<li><b>Mode:</b> Co-op (shared stars) → Versus (each rider) → Teams 2v2 (seats 1+3 vs 2+4). Versus needs 2 riders; it falls back to Co-op if not enough.</li>
<li><b>Practice:</b> replays Level 1 sections with no timer.</li>
</ul>
<h3>Lobby (online, host only)</h3>
<ul>
<li><b>Course / change</b> and <b>Mode / change</b> – only the host can change these. Guests see them greyed out.</li>
<li><b>Ready</b> – guests tap Ready. <b>Start together</b> starts everyone at once.</li>
<li>After a match: <b>Rematch together</b>, <b>Return crew to lobby</b>, or <b>Leave crew</b>.</li>
</ul>
</section>

<section id="tech">
<h2>6. How it works (simple technical overview)</h2>
<h3>The game loop</h3>
<ul>
<li>The ring is one physics body. Each rider sits at a seat on its rim.</li>
<li>When you hold, your rider "farts" and pushes the ring <b>away from your seat</b>. All riders' pushes add up, so teamwork (or fighting) decides where the ring goes.</li>
<li>Each rider has a <b>gas meter</b>: it drains while farting and refills while resting. Beans refill it.</li>
<li>Falling into a hole or off the edge isn't a loss: the crew restarts at the last checkpoint while the clock keeps running.</li>
</ul>
<h3>Stars (Star Scramble)</h3>
<ul>
<li>12 stars per course, placed by a formula along the course (left, right, middle…), so every phone builds the <b>same</b> stars with no random numbers.</li>
<li>Each frame the host checks: which occupied seat is nearest to a star and within reach (about 1.9 m)? That rider gets it, once.</li>
<li>Co-op adds everyone's stars; Versus compares riders; Teams adds seats 1+3 vs 2+4.</li>
</ul>
<h3>Saving and unlocking</h3>
<ul>
<li>Saved with Godot's <code>ConfigFile</code> to <code>user://save.cfg</code> on the phone: best stars + best time per level, settings, avatars.</li>
<li>Clearing level n unlocks n+1. Save happens <i>before</i> the result screen, so closing the app right after a win doesn't lose it.</li>
<li>Online results don't change offline unlocks (allowed by the PDF).</li>
</ul>
</section>

<section id="net">
<h2>7. The connection (why it works on Wi-Fi and hotspot)</h2>
<div class="flow">
<div><b>1. Host a game</b> – Phone A opens a game server on <b>port 7777</b> (Godot ENet, which runs on UDP).</div>
<div><b>2. "I'm here!"</b> – once a second, Phone A shouts a tiny message to the whole local network (UDP broadcast on <b>port 7778</b>) with its name.</div>
<div><b>3. Games nearby</b> – Phone B listens on 7778, sees the message and shows "Join Player's game". Typing the IP is the backup.</div>
<div><b>4. Join</b> – Phone B connects to A's IP on 7777. If nothing answers in 5 s → clear error message.</div>
<div><b>5. Play</b> – B sends only <i>its own</i> aim + hold. A runs the physics, awards stars and sends the ring position 20 times per second to everyone.</div>
<div><b>6. Result</b> – A decides finish/time-out and the winner, and sends one result to all phones.</div>
</div>
<h3>Why the hotspot works without internet</h3>
<p>A phone hotspot is a small <b>local network</b>, just like home Wi-Fi. Both phones get local addresses (like 192.168.x.x) on it. The game never goes to the internet; it only talks phone-to-phone inside that local network. So the hotspot doesn't even need mobile data. Broadcast messages also stay inside that local network, which is why "Games nearby" shows up there too.</p>
<h3>Why the host decides (and guests can't cheat)</h3>
<ul>
<li>Only one phone runs the real physics, so all phones always agree on where the ring is and who got which star.</li>
<li>Guests can't send "I won" or "I got a star". The host checks each message: only your own seat, not too often, not too strong.</li>
<li>Small lag is hidden by smoothing (interpolation) on guests. If a guest's input stops arriving, it expires so the ring doesn't keep pushing.</li>
<li>Important messages (start, ready, result) are sent <b>reliably</b>; the ring updates are sent fast because a new one arrives every 50 ms anyway.</li>
</ul>
<h3>If something goes wrong</h3>
<ul>
<li>Guest leaves → their seat becomes empty, the match continues.</li>
<li>Host leaves → guests see "Host disconnected. Your offline progress is safe." and go back to the play menu.</li>
<li>Not on the same network → nothing shows in Games nearby; Join by IP gives the error after 5 s.</li>
</ul>
</section>

<section id="tools">
<h2>8. Tools, sources and how the art was made</h2>
<table>
<tr><th>Tool</th><th>Used for</th></tr>
<tr><td>Godot 4.7.2 (MIT)</td><td>Game engine, GDScript code, Android export</td></tr>
<tr><td>GUT 9.7.1 (MIT)</td><td>Automated tests (132 tests), not shipped in the app</td></tr>
<tr><td>Android SDK, JDK 17, adb</td><td>Building the APK, installing and testing on the phones</td></tr>
<tr><td>Python + ffmpeg</td><td>Generating the original sound effects and music (.wav / .ogg)</td></tr>
<tr><td>Fredoka font (SIL OFL)</td><td>The only outside asset – the rounded game font</td></tr>
<tr><td>Git + GitHub</td><td>Version control, repo <code>itsd85-lab5-bsit4c-cazo</code></td></tr>
<tr><td>AI coding assistant</td><td>Helped with parts of code and docs; reviewed, tested and edited by the author (disclosed in the paper)</td></tr>
</table>
<h3>How the animal riders were made</h3>
<ul>
<li><b>No downloaded models.</b> Every animal (hippo, pig, panda, penguin, bunny, cat) is built from code.</li>
<li>The body is a <b>lathed</b> shape: draw a side outline (a pear shape) and spin it around a vertical line, like a potter's wheel. Ears, snouts, tails and arms are smaller spun or stretched shapes.</li>
<li>A <b>toon shader</b> gives the flat cartoon shading and outline-like rim light. It also adds wiggle, tail wag and butt glow when farting.</li>
<li>The fart cloud texture is drawn pixel by pixel in code.</li>
</ul>
<h3>How the environment was made</h3>
<ul>
<li>Each course is a <b>curved path</b> (a spline). The code sweeps a water channel and cliff walls along it, like squeezing toothpaste along a line.</li>
<li>The water is a <b>shader</b>: waves, foam and sparkles come from sine-wave formulas, not images.</li>
<li>Hazards (mallets, crushers, boulders, whirlpools) are simple shapes (boxes, cylinders, spheres) that move with code.</li>
<li>Clouds, balloons, flags and islands are also generated in code. Sound and music were synthesized by a Python script.</li>
</ul>
</section>

<section id="qa">
<h2>9. Cheat sheet: possible questions</h2>

<details><summary>Why farts and one shared ring?</summary><p>It's a funny, simple control (aim + hold) that everyone gets in seconds. Sharing one ring forces cooperation: your push affects everyone. Stars add competition inside the same ring.</p></details>

<details><summary>Is it co-op or competitive?</summary><p>Both. The PDF allows "race, compete, or cooperate". Co-op shares the star total; Versus is every rider for themselves; Teams 2v2 is seats 1+3 vs 2+4. The host picks the mode.</p></details>

<details><summary>How many players?</summary><p>Offline: you plus up to 3 computer assistants on one phone. Online: 2–4 phones, one rider each.</p></details>

<details><summary>How are the 1–3 level stars calculated?</summary><p>Finish with more than 50% of the time left = 3 stars, more than 25% = 2, otherwise 1. Timer reaches 0 = lose.</p></details>

<details><summary>How do you know who gets a gold star?</summary><p>The host checks every frame: the nearest rider whose seat is within reach of the star gets it, once. A tie goes to the lower seat number. Guests just display what the host says.</p></details>

<details><summary>Where is progress saved? What if I close the app?</summary><p>In <code>user://save.cfg</code> on the phone using Godot's ConfigFile. It saves before the result screen appears, so force-closing doesn't lose the unlock.</p></details>

<details><summary>Why does the host decide the winner?</summary><p>So there's one truth. If each phone decided, they could disagree (lag) or a modified phone could cheat. Guests only send their aim and hold; the host validates them and sends the result.</p></details>

<details><summary>How does the other phone find the game without typing an IP?</summary><p>The host broadcasts a small "here I am" message once a second on UDP port 7778. Other phones listen and list it under Games nearby. Typing the IP still works as a backup.</p></details>

<details><summary>Why did it work on a hotspot with no internet?</summary><p>A hotspot is a local network. Both phones get local IPs and talk directly. The game never needs the internet.</p></details>

<details><summary>What if the Wi-Fi is off or the host is unreachable?</summary><p>After about 5 seconds: "Could not reach the host. Check its IP, Wi-Fi and port 7777." No crash, you stay on the menu.</p></details>

<details><summary>What happens if someone disconnects mid-match?</summary><p>A guest leaving → their seat becomes empty and the match goes on. The host leaving → guests get "Host disconnected. Your offline progress is safe." and return to the menu.</p></details>

<details><summary>How do you handle lag?</summary><p>The host sends the ring state 20 times a second; guests smooth between updates. Inputs expire if they stop arriving, so a rider can't get stuck pushing.</p></details>

<details><summary>Why LAN (Option A) and not an online server (Nakama)?</summary><p>Option A is required for all teams. It needs no server, no account and no internet, and it works on any Wi-Fi or hotspot. Option B (Nakama) is optional for extra credit and was not done.</p></details>

<details><summary>Why the Compatibility renderer?</summary><p>The lab requires it. It uses OpenGL ES 3, which runs on low-cost Android phones like the ones tested.</p></details>

<details><summary>Where did the art and sounds come from?</summary><p>All original, made in code: animals from lathed shapes with a toon shader, courses swept along curves, water from a shader, sounds synthesized in Python. The only outside asset is the Fredoka font (SIL OFL). Credits are in the app and in <code>docs/CREDITS.md</code>.</p></details>

<details><summary>Did you use AI?</summary><p>Yes, an AI coding assistant helped with parts of the code and documentation. I reviewed, tested and edited everything, and it's disclosed in the paper's acknowledgment.</p></details>

<details><summary>How did you test it?</summary><p>132 automated tests (GUT), a network test that runs real host and guest game processes (6 scenarios, including Versus and Teams), and a phone test matrix on two phones: Infinix X6525 and TECNO CLA5.</p></details>

<details><summary>How smooth is it?</summary><p>About 56–69 FPS on the Infinix and around 60 FPS on the TECNO during online play. Low quality mode is there for slower phones.</p></details>

<details><summary>What are the ports and the package name?</summary><p>Game: port 7777 (ENet/UDP). Discovery: port 7778 (UDP broadcast). Package: <code>com.itsd85.cazo.toottubes</code>.</p></details>

<details><summary>Why can't the computer assistants beat me in Versus?</summary><p>They push the ring with the same rules but don't hunt stars on purpose, so they're a light opponent. Versus is best with two real players.</p></details>

<details><summary>Does online play unlock levels?</summary><p>No. Online results stay separate from offline unlocks, which the PDF allows. Unlocks come from the offline campaign.</p></details>
</section>

<section id="limits">
<h2>10. Honest limits (if asked)</h2>
<ul>
<li>Teams 2v2 was tested in the automated network test, not on four real phones (only two phones available).</li>
<li>Computer assistants don't chase stars, so Versus vs the computer is easy.</li>
<li>Online needs both phones on the same local network (no internet play).</li>
<li>A continuous 10-minute heat test and a two-thumb touch test were not completed on the phones.</li>
<li>Outside playtest results go here after the playtest: <span class="pill warn">to fill in</span></li>
</ul>
</section>

<footer>Toot Tubes · ITSD 85 Lab 5 · Carlos Fidel G. Castro (Cazo-debug)</footer>
</main>
</body>
</html>
"""

G1 = "\n".join([
    shot(P + "01_title.png", "Title screen"),
    shot(P + "02_main_menu.png", "Main menu: Play, Courses, Avatar, Settings, Credits"),
    shot(P + "03_avatar_editor.png", "Avatar creator: name, animal, outfit, float"),
    shot(Q + "04_mode_select_nearby.png", "Offline or online choice (R8)"),
    shot(Q + "05_crew_versus.png", "Crew setup: seats, assistants, mode"),
    shot(Q + "01_courses.png", "Courses: locked levels (R4)"),
    shot(P + "07_level_goal.png", "Goal banner at level start (R2)"),
    shot(P + "08_fart_burst.png", "Hold to fart: the ring is pushed"),
    shot(P + "13_star_scores.png", "Race HUD: stars per rider, timer, gas"),
    shot(Q + "06_pause.png", "Pause menu with Sound (R10)"),
    shot(Q + "02_settings.png", "Settings (saved on the phone)"),
    shot(Q + "03_credits.png", "In-game Credits"),
    shot(Q + "07_join_error_wifi_off_tecno.png", "Wi-Fi off: clear join error (R8)"),
    shot(Q + "08_host_disconnected_tecno.png", "Host left: message, back to menu"),
])
G2 = "\n".join([
    shot(T + "01_host_lobby_versus.png", "Host lobby: Mode Versus"),
    shot(T + "02_guest_lobby_versus.png", "Guest joined via Games nearby"),
    shot(T + "03_host_race_star.png", "Host phone during the race"),
    shot(T + "04_guest_race_star.png", "Guest phone: same stars, same time"),
    shot(T + "08_host_result_named.png", "Host result: Player P2 wins"),
    shot(T + "09_guest_result_named.png", "Guest result: same, decided by host"),
])

OUT.parent.mkdir(parents=True, exist_ok=True)
OUT.write_text(HTML.replace("{G1}", G1).replace("{G2}", G2), encoding="utf-8")
print(OUT, round(OUT.stat().st_size / 1024), "KB")
