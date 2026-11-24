# ITSD 85 Lab: what the subject requires

Source: *ITSD 85 Lab: Mobile Game with Level Progression and Offline/Online
Multiplayer* (PDF, 39 pages, Oct 20, 2026). Page numbers refer to that PDF.

## Grade breakdown (p. 35)
| Part | Weight | Scored per |
|---|---|---|
| Lab work (game, phases 1–8, live demo) | **45%** | Team |
| Publication-ready paper (IEEE) | **35%** | Team |
| Submission and GitHub practice | **10%** | Team |
| Individual contribution (log + peer evaluation) | **10%** | Student |

## 1. Minimum game requirements R1–R10 (pp. 2–3)
| # | Requirement | How it is checked |
|---|---|---|
| R1 | 5+ levels, each harder or different | Instructor plays 1–3; video shows 4–5 |
| R2 | Clear goal per level | Goal text visible at level start |
| R3 | Win **and** lose conditions, result screen (stars/score/time), Retry / Next / Menu | Fail a level on purpose, then clear it |
| R4 | Level n+1 locked until n is cleared | Lock icon, cannot be opened |
| R5 | Progress saved, survives closing the app | Clear L2, force-close, reopen: L3 still unlocked |
| R6 | Offline mode in airplane mode (solo, vs computer, or 2 on one device) | Airplane mode on, play |
| R7 | Online: two players on two devices, same match, real time or turns | Two phones play one match |
| R8 | Offline/Online choice on the menu; clear message when online cannot connect | Wi-Fi off → Online → error, not crash |
| R9 | Real phone, one fixed orientation, touch controls | Installed on a team member's phone |
| R10 | Title screen, pause menu, sound on/off, readable text | Checked during demo |

**Co-op is allowed.** Online mode may be "race, compete, or cooperate" (p. 7),
and GDD section 8 lists "race / versus / co-op". The host must decide the
result; never trust the other phone (p. 20).

Bonus (up to +10): star unlocks, leaderboard or player names, settings,
tutorial/hints, accessibility, Nakama (Option B).

## 2. Technical rules
- Godot 4.7 standard (GDScript), **Compatibility** renderer (p. 8).
- 720×1280 portrait, stretch `canvas_items` / `expand`, Emulate Touch From Mouse (p. 9).
- Save with `ConfigFile` in `user://` (p. 10).
- **Option A (LAN host/join, ENet) is required for all teams**; Option B (Nakama) for a higher grade (p. 16).
- Join timeout about 5 s with "Cannot reach host…" message (p. 18).
- Disconnect → end match, message, back to menu. Online results may stay separate from offline unlocks (p. 20).
- Android permissions: Internet + Access Network State (p. 19).
- UI (p. 21):
  - Title → Main menu (Play, Settings, Credits) → Mode select → Level select / Lobby
  - Back button on every screen, plus the Android back gesture
  - Buttons about 120 px; body text 28 px or more
  - Pause menu: Resume, Restart, Sound, Quit
  - Music in an autoload; sound choice saved
  - 1024×1024 icon; in-game Credits screen
- Audio: **`.ogg` music, `.wav` effects** (p. 4).
- No characters, music or logos from commercial games; credit every asset (p. 21).
- Package: `com.itsd85.<teamname>.<gamename>`, lowercase (p. 22).

## 3. Checkpoints (pp. 8–26)
| # | Evidence |
|---|---|
| 1 | GDD (lab template) + photo of the paper prototype, approved |
| 2 | Every member clones the repo and runs it |
| 3 | **Video:** clear L1, fail L2, L3 unlocks only after L2 and stays unlocked after restart |
| 4 | **Screen recording:** airplane-mode test (Play Offline, clear L1, close, reopen) |
| 5 | **Video:** two phones in one online match, result screen on both, error when joining with Wi-Fi off |
| 6 | Screenshots of every screen **on a phone** + `CREDITS.md` |
| 7 | The APK + completed **phone test matrix** (2 different phones) |
| 8 | Completed playtest forms, averages table, action plan with **3+ fixes** |

**Phone test matrix (p. 23), rows for Phone 1 and Phone 2:** installs and
opens · layout fits · touch works · progress saved after force-close · offline in
airplane mode · online match between the two phones · smooth frame rate ·
battery/heat OK after 10 minutes.

## 4. Playtest (Phase 8, pp. 24–26)
- **5+ players outside the team**, 15–20 min each, a fresh install, a second phone for online.
- One-sentence brief only (think aloud); play **L1–L3 offline + one online match**.
- Team fills in the **observation sheet**: tester, level, attempts, time, stuck points, quotes, bugs.
- Tester fills in the **feedback form**:
  - age range and gaming habits
  - 15 Likert items (1–5)
  - 5 open questions and an overall star rating
- Analysis:
  - mean per item; below 3.5 is a problem
  - completion rate per level; below 60% or more than 4 attempts means too hard
  - group the comments into themes
- Action plan: issue, testers, severity, fix, fixed?, retest. Fix the top issues and **retest with 2+ new players**.
- Ethics: consent from every tester, with a guardian for under-18s. Use codes T1, T2… with no names, faces or numbers (RA 10173).
- **Feature freeze** at the start of Week 5: fixes only.

## 5. Deliverables (p. 27)
- Git repo with the full project, `docs/GDD.md`, `docs/CREDITS.md`, and `README.md`.
- Installable **Android APK**.
- **Demo video, 2–3 min:**
  - title screen
  - level unlocking
  - **a win and a loss**
  - airplane mode
  - online match on two phones
- **Paper (PDF)** with the playtest results; forms and action plan in its appendix.
- Phone test matrix.
- Individual contribution log: what each member built, with commit links.
- **Live demo, 7 min:**
  - pitch (30 s)
  - L1 + an unlock (2 min)
  - airplane mode (1 min)
  - online match on a second phone (2 min)
  - top 3 playtest findings (1.5 min)

## 6. Submission (pp. 29–31)
**GitHub**
- Repo name `itsd85-lab<no>-<section>-<teamname>`.
- README headings:
  - About the game (pitch + 2 screenshots)
  - How to play
  - Offline and online modes
  - How to build
  - Download (v1.0 APK link)
  - Playtest results (top 3)
  - Credits
  - Paper (link to `docs/paper.pdf`)
- `docs/` contains `GDD.md`, `CREDITS.md`, `paper.pdf`, `screenshots/` and `playtest/` (anonymized).
- Never commit keystores, passwords, server keys or `export/`. The APK goes on the release, not in the repo.
- **Every member has commits under their own GitHub account** (use `Co-authored-by:` for pair work).
- Tag `v1.0` and publish a release with the **APK + paper.pdf**.
- If the repo is private, add the instructor as a collaborator.

**Google Classroom**
- Links: repo, v1.0 release, demo video.
- Files: `ITSD85_Lab<no>_<Section>_<TeamName>_Paper.pdf` and `ITSD85_Lab<no>_<Surname>_Contribution.pdf` (one per member).
- Private comment: team name, members, latest commit ID, phone models tested.
- Every member clicks Turn in. Resubmitting means pushing tag `v1.1`.

## 7. Paper (pp. 31–36, 35% of the grade)
- IEEE two-column conference template, **5–7 pages** (appendix not counted), PDF with embedded fonts.
- **12+ references** (IEEE style), **6+ from the last 5 years**.
- Sections:
  - Abstract (150–250 words, number of testers, ratings)
  - Index Terms
  - Introduction (research questions)
  - Related Work (6–10 sources)
  - Game Design (Fig. 1 screen flow, Table I level plan)
  - Implementation (Fig. 2 architecture, save/unlock listing of 20 lines or fewer, how the host decides the result)
  - Evaluation Method (participants, procedure, 15-item instrument, consent)
  - Results (Table III Likert M/SD/n for all 15 items, Fig. 3 completion per level, Table IV action plan with retest)
  - Discussion (answer the RQs, limitations)
  - Conclusion
  - Acknowledgment (mention any AI tool used)
  - References
- Appendix:
  - GDD
  - anonymized forms and observation sheets
  - test matrix
  - **answers to the 6 guide questions** (p. 28)
  - links
- Writing: third person, past tense; at most 2 game screenshots in the body.
