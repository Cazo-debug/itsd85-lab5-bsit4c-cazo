# Paper outline: Toot Tubes (IEEE two-column, 5–7 pages)

Working draft of the structure and the facts already known. Fill the `[ ]` items after the
playtest. **Do not invent numbers.** Write in third person, past tense. Mention AI tools in the
Acknowledgment. Rubric weights in brackets (paper rubric, 100 points).

## Title [10 with abstract]
Specific title, for example: *Toot Tubes: A Cooperative Shared-Ring Mobile Game with Level Progression and LAN Multiplayer, and a Playtest Study*

## Abstract (150–250 words) [10]
Must contain: concept, method, **number of testers**, **key ratings**, conclusion.
- Concept: up to four animal riders push one shared swim ring through five sky waterpark courses.
- Method: Godot 4 Android game, offline campaign plus LAN co-op, playtest with [n] testers.
- Result: [mean of the overall rating], [completion rate per level], [3 fixes verified by retest].

Index Terms: mobile games, cooperative play, Godot, level progression, playtesting, LAN multiplayer.

## I. Introduction and research questions [10]
Motivation: casual co-op on one phone or one Wi-Fi without accounts.
Suggested research questions (answerable with the playtest data):
- RQ1: Do players understand and use the AIM + HOLD touch controls within the first level?
- RQ2: Does the five-level difficulty curve stay within a fair range (completion at least 60%, at most 4 attempts)?
- RQ3: Can two players start an online match without help?

## II. Related work (6–10 sources, synthesized) [10]
Group by theme, not one-by-one: touch controls, difficulty and flow, cooperative play, network authority. State how Toot Tubes differs (one shared physical ring, sustained per-seat thrust, host-authoritative). See `REFERENCES_TO_VERIFY.md`.

## III. Game design [10]
- Mechanic and rules (GDD sections 3–4). **Fig. 1:** screen flow. **Table I:** level plan (GDD section 5: five levels, 240–300 s).
- Unlocking and stars (GDD section 6). Both modes (sections 7–8).

## IV. Implementation [10]
- **Fig. 2:** architecture (autoloads `GameState`, `Net`, `Audio`; `Level`; `SwimRing`; `LanDiscovery`).
- Save/unlock listing, 20 lines or fewer (from `GameState`, saved with `ConfigFile` in `user://save.cfg`).
- Networking: ENet on port 7777, up to 4 phones; guests send only their own seat's aim and hold state; the **host simulates the ring and decides the result**; nearby games found by a UDP broadcast on port 7778.
- Error handling: 5 s join timeout, clear message, return to Mode Select.

## V. Evaluation method and ethics [15]
- Participants: [n] testers outside the team, codes T1–T[n], age ranges, play habits.
- Procedure: fresh install, one-sentence brief, think aloud, L1–L3 offline + one online match, 15–20 min.
- Instrument: 15 Likert items, 5 open questions, overall stars (`docs/playtest/FEEDBACK_FORM.md`), observation sheet.
- Analysis: mean and SD per item, below 3.5 = problem; completion per level, below 60% or more than 4 attempts = too hard; themes from comments.
- Ethics: consent for every tester (guardian if under 18), anonymous codes, no names or faces (RA 10173).

## VI. Results [20]
- **Table II:** participants. **Table III:** Likert M / SD / n for all 15 items (from `RESULTS.csv`).
- **Fig. 3:** completion rate per level.
- Themes from open answers. **Table IV:** action plan (issue, testers, severity, fix, fixed?, **retest**).
- Phone test matrix summary (two phones).

## VII. Discussion and conclusion [10]
Answer each RQ with data, compare with the literature, state honest limitations (small sample, same Wi-Fi only, one Android version family, testers from one school).

## Acknowledgment
AI coding assistants were used for parts of the programming and documentation; the author reviewed and tested the results.

## References [5 with format]
12+ IEEE references, 6+ from 2021 or later, every one cited in the text.

## Appendix (not counted in the pages)
GDD, anonymized forms and observation sheets, phone test matrix, **answers to the 6 guide questions** (lab PDF p. 28), links to the repo, release and demo video.

---
## Facts to reuse (already true in the project)
- Five levels, 240 / 260 / 270 / 290 / 300 s; every level has two checkpoints and its own goal text.
- Offline works in airplane mode; assistant riders fill empty seats.
- Online: ENet, 2–4 phones, host-authoritative, 5 s join timeout.
- Phone performance (Infinix X6525, Android 13): about 48–50 FPS on High and about 61–64 FPS on Low with four riders.
- Automated tests: 100+ GUT tests plus a LAN smoke test.
