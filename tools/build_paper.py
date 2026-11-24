"""Build the IEEE-format lab paper (docs/paper/paper.docx) and the cover sheet.

* Everything about the game, design and implementation is written from the real project.
* Every playtest number comes from docs/playtest/RESULTS.csv. With no data yet, those spots are
  highlighted placeholders. Nothing is invented.
Run from the repo root: python tools/paper_figures.py && python tools/build_paper.py
"""
import csv
import math
import re
from pathlib import Path

from docx import Document
from docx.enum.section import WD_SECTION
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_BREAK, WD_COLOR_INDEX
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Inches, Pt

ROOT = Path(__file__).resolve().parent.parent
PAPER = ROOT / "docs" / "paper"
ASSETS = PAPER / "assets"
RESULTS = ROOT / "docs" / "playtest" / "RESULTS.csv"
ACTIONS = ROOT / "docs" / "playtest" / "ACTIONS.csv"
FONT = "Times New Roman"
REPO = "https://github.com/Cazo-debug/itsd85-lab5-bsit4c-cazo"
TITLE = ("Design and Player Evaluation of Toot Tubes: A Level-Based Cooperative Mobile Game "
         "with Offline and LAN Multiplayer Built with Open-Source Tools")

ITEMS = [
    "The game was fun to play.",
    "I understood the goal of each level without help.",
    "The touch controls were easy and responsive.",
    "Each level felt a little harder than the last, but fair.",
    "Unlocking the next level made me want to keep playing.",
    "The win/lose result screen clearly showed how I did.",
    "Offline mode worked smoothly.",
    "Joining an online match was easy.",
    "The online match felt responsive.",
    "The graphics were clear and attractive.",
    "The sound and music fit the game.",
    "Text and buttons were easy to read and tap.",
    "The game ran without crashes or freezes.",
    "I would play this game again.",
    "I would recommend this game to a friend.",
]

REFERENCES = [
    'A. Sweetser and P. Wyeth, "GameFlow: A model for evaluating player enjoyment in games," ACM Comput. Entertain., vol. 3, no. 3, art. 3, Jul. 2005.',
    'M. Csikszentmihalyi, Flow: The Psychology of Optimal Experience. New York, NY, USA: Harper & Row, 1990.',
    'R. Likert, "A technique for the measurement of attitudes," Arch. Psychol., vol. 22, no. 140, pp. 1-55, 1932.',
    'J. Brooke, "SUS: A quick and dirty usability scale," in Usability Evaluation in Industry, P. W. Jordan et al., Eds. London, U.K.: Taylor & Francis, 1996, pp. 189-194.',
    'Godot Engine Documentation, "High-level multiplayer." [Online]. Available: https://docs.godotengine.org (accessed Nov. 2026).',
    'G. Fiedler, "Networking for game programmers," Gaffer On Games. [Online]. Available: https://gafferongames.com (accessed Nov. 2026).',
    '[[VERIFY full authors, title and pages]] Study by Bestard Lorigados, MacKenzie and Baljko on mobile movement controls (soft joystick, buttons, tilt), in Proc. HCI Int. (HCII), 2022.',
    '[[VERIFY authors]] "Understanding players\' interaction patterns with mobile game app UI via visualizations," arXiv:2110.08753, 2021.',
    '[[VERIFY authors and title]] Survey of latency compensation in games, Worcester Polytechnic Institute, Tech. Rep. 21-06, 2021.',
    'E. Ascarza, O. Netzer, and J. Runge, "Personalized game design for improved user retention and monetization in freemium games," working paper, Columbia Business School, Dec. 2023. [[VERIFY details]]',
    '[[VERIFY authors]] "From solo to social: Exploring the dynamics of player cooperation in a co-located cooperative exergame," arXiv:2504.00160, 2025.',
    '[[VERIFY authors]] "Beyond competitive gaming: How casual players evaluate and respond to teammate performance," arXiv:2508.19230, 2025.',
]


# ---------------------------------------------------------------- data

def load_rows() -> list:
    if not RESULTS.exists():
        return []
    with RESULTS.open(encoding="utf-8", newline="") as handle:
        return [r for r in csv.DictReader(handle) if (r.get("tester") or "").strip()]


def number(value) -> float:
    try:
        return float(str(value).strip())
    except ValueError:
        return math.nan


def stats(values: list) -> tuple:
    values = [v for v in values if not math.isnan(v)]
    if not values:
        return (math.nan, math.nan, 0)
    mean = sum(values) / len(values)
    if len(values) < 2:
        return (mean, 0.0, len(values))
    sd = math.sqrt(sum((v - mean) ** 2 for v in values) / (len(values) - 1))
    return (mean, sd, len(values))


def interpret(mean: float) -> str:
    if math.isnan(mean):
        return "-"
    if mean >= 4.2:
        return "Strongly agree"
    if mean >= 3.4:
        return "Agree"
    if mean >= 2.6:
        return "Neutral"
    if mean >= 1.8:
        return "Disagree"
    return "Strongly disagree"


def is_yes(value) -> bool:
    return str(value).strip().lower() in ("1", "yes", "y", "true")


MAIN = [r for r in load_rows() if (r.get("round") or "main").strip().lower() != "retest"]
RETEST = [r for r in load_rows() if (r.get("round") or "").strip().lower() == "retest"]
N = len(MAIN)
HAS_DATA = N > 0


def item_stats(rows: list, index: int) -> tuple:
    return stats([number(r.get(f"q{index}", "")) for r in rows])


def overall() -> tuple:
    return stats([number(r.get("overall_stars", "")) for r in MAIN])


def completion(level: int) -> tuple:
    answered = [r for r in MAIN if str(r.get(f"l{level}_cleared", "")).strip() != ""]
    if not answered:
        return (math.nan, 0)
    return (100.0 * sum(is_yes(r[f"l{level}_cleared"]) for r in answered) / len(answered), len(answered))


def ph(text: str) -> str:
    return f"[[{text}]]"


def fmt(value: float, digits: int = 2) -> str:
    return "-" if math.isnan(value) else f"{value:.{digits}f}"


# ---------------------------------------------------------------- low-level docx helpers

def set_font(run, size: float, bold=None, italic=None, small_caps=False, mono=False) -> None:
    name = "Courier New" if mono else FONT
    run.font.name = name
    run.font.size = Pt(size)
    rpr = run._element.get_or_add_rPr()
    fonts = rpr.find(qn("w:rFonts"))
    if fonts is None:
        fonts = OxmlElement("w:rFonts")
        rpr.append(fonts)
    for attr in ("w:ascii", "w:hAnsi", "w:cs", "w:eastAsia"):
        fonts.set(qn(attr), name)
    if bold is not None:
        run.bold = bold
    if italic is not None:
        run.italic = italic
    run.font.small_caps = small_caps


def add_runs(paragraph, text: str, size: float, bold=None, italic=None, small_caps=False, mono=False) -> None:
    """Text may contain [[placeholder]] spans, which are highlighted yellow."""
    for part in re.split(r"(\[\[.*?\]\])", text):
        if not part:
            continue
        if part.startswith("[[") and part.endswith("]]"):
            run = paragraph.add_run("[" + part[2:-2] + "]")
            run.font.highlight_color = WD_COLOR_INDEX.YELLOW
        else:
            run = paragraph.add_run(part)
        set_font(run, size, bold, italic, small_caps, mono)


def fmt_par(paragraph, align, before=0.0, after=0.0, first=None, left=None, hanging=None, line=1.0, keep_next=False) -> None:
    pf = paragraph.paragraph_format
    pf.alignment = align
    pf.space_before = Pt(before)
    pf.space_after = Pt(after)
    pf.line_spacing = line
    pf.keep_with_next = keep_next
    if first is not None:
        pf.first_line_indent = Inches(first)
    if left is not None:
        pf.left_indent = Inches(left)
    if hanging is not None:
        pf.left_indent = Inches(hanging)
        pf.first_line_indent = Inches(-hanging)


def set_columns(section, count: int, space_twips: int = 360) -> None:
    sect_pr = section._sectPr
    for old in sect_pr.findall(qn("w:cols")):
        sect_pr.remove(old)
    cols = OxmlElement("w:cols")
    cols.set(qn("w:num"), str(count))
    cols.set(qn("w:space"), str(space_twips))
    sect_pr.append(cols)


def page_setup(section) -> None:
    section.page_width = Inches(8.5)
    section.page_height = Inches(11)
    section.left_margin = section.right_margin = Inches(0.625)
    section.top_margin = Inches(0.75)
    section.bottom_margin = Inches(1.0)


def cell_borders(table, top_bottom_only=True) -> None:
    tbl_pr = table._tbl.tblPr
    borders = OxmlElement("w:tblBorders")
    for edge in ("top", "bottom", "insideH"):
        el = OxmlElement(f"w:{edge}")
        el.set(qn("w:val"), "single")
        el.set(qn("w:sz"), "4")
        el.set(qn("w:color"), "000000")
        borders.append(el)
    tbl_pr.append(borders)


# ---------------------------------------------------------------- document builder

class Paper:
    def __init__(self) -> None:
        self.doc = Document()
        style = self.doc.styles["Normal"]
        style.font.name = FONT
        style.font.size = Pt(10)
        page_setup(self.doc.sections[0])
        self.fig = 0
        self.tab = 0
        self.roman = 0

    def p(self, text: str, size=10, align=WD_ALIGN_PARAGRAPH.JUSTIFY, first=0.17, bold=None, italic=None,
          before=0.0, after=3.0, keep_next=False):
        paragraph = self.doc.add_paragraph()
        add_runs(paragraph, text, size, bold, italic)
        fmt_par(paragraph, align, before, after, first, keep_next=keep_next)
        return paragraph

    def heading(self, text: str) -> None:
        self.roman += 1
        numerals = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]
        paragraph = self.doc.add_paragraph()
        add_runs(paragraph, f"{numerals[self.roman - 1]}. {text.upper()}", 10, small_caps=False)
        fmt_par(paragraph, WD_ALIGN_PARAGRAPH.CENTER, 8, 4, keep_next=True)

    def plain_heading(self, text: str) -> None:
        paragraph = self.doc.add_paragraph()
        add_runs(paragraph, text.upper(), 10)
        fmt_par(paragraph, WD_ALIGN_PARAGRAPH.CENTER, 8, 4, keep_next=True)

    def sub(self, letter: str, text: str) -> None:
        paragraph = self.doc.add_paragraph()
        add_runs(paragraph, f"{letter}. {text}", 10, italic=True)
        fmt_par(paragraph, WD_ALIGN_PARAGRAPH.LEFT, 4, 2, keep_next=True)

    def caption_table(self, title: str) -> None:
        self.tab += 1
        numerals = ["I", "II", "III", "IV", "V", "VI"]
        paragraph = self.doc.add_paragraph()
        add_runs(paragraph, f"TABLE {numerals[self.tab - 1]}", 8, small_caps=False)
        fmt_par(paragraph, WD_ALIGN_PARAGRAPH.CENTER, 6, 0, keep_next=True)
        paragraph = self.doc.add_paragraph()
        add_runs(paragraph, title.upper(), 8)
        fmt_par(paragraph, WD_ALIGN_PARAGRAPH.CENTER, 0, 3, keep_next=True)

    def table(self, header: list, rows: list, widths: list, size=7.5, bold_first=False) -> None:
        table = self.doc.add_table(rows=1, cols=len(header))
        table.alignment = WD_TABLE_ALIGNMENT.CENTER
        table.autofit = False
        cell_borders(table)
        for i, text in enumerate(header):
            cell = table.rows[0].cells[i]
            cell.width = Inches(widths[i])
            paragraph = cell.paragraphs[0]
            add_runs(paragraph, text, size, bold=True)
            fmt_par(paragraph, WD_ALIGN_PARAGRAPH.LEFT, 1, 1)
        for row in rows:
            cells = table.add_row().cells
            for i, text in enumerate(row):
                cells[i].width = Inches(widths[i])
                paragraph = cells[i].paragraphs[0]
                add_runs(paragraph, str(text), size, bold=True if (bold_first and i == 0) else None)
                fmt_par(paragraph, WD_ALIGN_PARAGRAPH.LEFT, 1, 1)
        spacer = self.doc.add_paragraph()
        fmt_par(spacer, WD_ALIGN_PARAGRAPH.LEFT, 0, 4)

    def figure(self, image: Path, caption: str, width=3.35) -> None:
        paragraph = self.doc.add_paragraph()
        paragraph.add_run().add_picture(str(image), width=Inches(width))
        fmt_par(paragraph, WD_ALIGN_PARAGRAPH.CENTER, 4, 2, keep_next=True)
        self.fig += 1
        cap = self.doc.add_paragraph()
        add_runs(cap, f"Fig. {self.fig}. {caption}", 8)
        fmt_par(cap, WD_ALIGN_PARAGRAPH.CENTER, 0, 6)

    def listing(self, title: str, code: str) -> None:
        cap = self.doc.add_paragraph()
        add_runs(cap, title, 8)
        fmt_par(cap, WD_ALIGN_PARAGRAPH.LEFT, 2, 2, keep_next=True)
        for line in code.split("\n"):
            paragraph = self.doc.add_paragraph()
            add_runs(paragraph, line if line else " ", 6.5, mono=True)
            fmt_par(paragraph, WD_ALIGN_PARAGRAPH.LEFT, 0, 0, left=0.05)
        spacer = self.doc.add_paragraph()
        fmt_par(spacer, WD_ALIGN_PARAGRAPH.LEFT, 0, 4)

    def reference_list(self) -> None:
        for number_, text in enumerate(REFERENCES, 1):
            paragraph = self.doc.add_paragraph()
            add_runs(paragraph, f"[{number_}] {text}", 8)
            fmt_par(paragraph, WD_ALIGN_PARAGRAPH.JUSTIFY, 0, 2, hanging=0.3)


# ---------------------------------------------------------------- paper content

SAVE_LISTING = """func complete_level(level, stars, time_used):
    if mode != "offline" or not is_unlocked(level) \\
            or stars < 1 or not is_finite(time_used) \\
            or time_used < 0.0:
        return
    best_stars[level] = maxi(best_stars.get(level, 0),
            clampi(stars, 1, 3))
    best_times[level] = minf(best_times.get(level, INF),
            time_used)
    unlocked_level = maxi(unlocked_level,
            mini(level + 1, TOTAL_LEVELS))
    save_progress()          # ConfigFile -> user://save.cfg

func is_unlocked(level) -> bool:
    return level >= 1 and level <= unlocked_level \\
            and level <= TOTAL_LEVELS"""

LEVEL_ROWS = [
    ["1", "Sky Garden", "Learn aim and hold; bends, bridge, climb, hairpin; bumpers, current, sweeper, mallet, crossbar, 2 holes", "240"],
    ["2", "Canyon Switchbacks", "Paired swinging mallets, sliding spiked gate, rolling boulders, exposed bend", "260"],
    ["3", "Cloud Bridges", "Very narrow bridges with timed crushers and high drops", "270"],
    ["4", "Spiral Springs", "Side currents and whirlpools on a climbing spiral", "290"],
    ["5", "Festival Summit", "Longest course; every hazard type combined (11 hazards)", "300"],
]


def abstract_text() -> str:
    if HAS_DATA:
        mean, sd, n = overall()
        rating = f"The mean overall rating was M = {fmt(mean)} out of 5 (SD = {fmt(sd)}, n = {n})."
        who = f"{N} players outside the development team"
    else:
        rating = f"The mean overall rating was {ph('M = ?, SD = ?')} out of 5."
        who = f"{ph('n')} players outside the development team"
    return (
        "Casual cooperative games usually need accounts, servers or large screens, which makes them "
        "hard to play in a classroom or at home. This paper presents Toot Tubes, an Android game "
        "in which up to four cartoon animals share one swim ring and steer it through five "
        "sky-waterpark courses by pushing it with sustained, per-rider thrust. Twelve collectible stars per course add a score that is shared by the crew (Co-op), individual (Versus) or per team (Teams 2v2). The game was built "
        "with the open-source Godot 4 engine and has an offline campaign with computer helper "
        "riders, a persistent level-unlocking system, and a host-authoritative LAN mode for two to "
        "four phones on the same Wi-Fi network or hotspot, with automatic discovery of nearby games. "
        f"A playtest with {who} measured usability, difficulty and online play with a 15-item "
        "five-point questionnaire, observation sheets, and a retest after fixes. "
        f"{rating} Completion rates, the participants' main themes and the fixes that followed are "
        "reported, together with the limitations of a small, single-school sample. The results "
        "inform design guidance for low-cost cooperative mobile games."
    )


def build_paper() -> Document:
    P = Paper()
    doc = P.doc

    # --- title block (single column)
    title = doc.add_paragraph()
    add_runs(title, TITLE, 20, bold=None)
    fmt_par(title, WD_ALIGN_PARAGRAPH.CENTER, 0, 8, line=1.0)
    author = doc.add_paragraph()
    add_runs(author, "Carlos Fidel G. Castro", 11)
    fmt_par(author, WD_ALIGN_PARAGRAPH.CENTER, 0, 0)
    for line in ["Team Cazo, Section BSIT-4C", "College of Information Sciences and Computing",
                 "Central Mindanao University, Musuan, Maramag, Bukidnon, Philippines",
                 "carlosfidelcaatro@gmail.com"]:
        paragraph = doc.add_paragraph()
        add_runs(paragraph, line, 9, italic=True)
        fmt_par(paragraph, WD_ALIGN_PARAGRAPH.CENTER, 0, 0)
    gap = doc.add_paragraph()
    fmt_par(gap, WD_ALIGN_PARAGRAPH.CENTER, 0, 4)

    body = doc.add_section(WD_SECTION.CONTINUOUS)
    page_setup(body)
    set_columns(body, 2)

    # --- abstract
    paragraph = doc.add_paragraph()
    add_runs(paragraph, "Abstract", 9, bold=True, italic=True)
    add_runs(paragraph, "—" + abstract_text(), 9, bold=True)
    fmt_par(paragraph, WD_ALIGN_PARAGRAPH.JUSTIFY, 0, 4, first=0.0)
    paragraph = doc.add_paragraph()
    add_runs(paragraph, "Index Terms", 9, bold=True, italic=True)
    add_runs(paragraph, "—mobile game, level design, multiplayer, cooperative play, playtesting, Godot, user experience", 9, bold=True)
    fmt_par(paragraph, WD_ALIGN_PARAGRAPH.JUSTIFY, 0, 4, first=0.0)

    # --- I. Introduction
    P.heading("Introduction")
    P.p("Short cooperative games are an easy way for friends to play together, yet many of them "
        "depend on online accounts, a data connection or a console. Students and families often "
        "have only a few mid-range Android phones and a shared Wi-Fi network or phone hotspot. "
        "Toot Tubes was designed for that situation: a game that starts in seconds, works "
        "without internet, and lets up to four people cooperate on one shared object.")
    P.p("In the game, up to four animal riders sit on one inflatable ring. Each rider pushes the ring "
        "by holding a button, and the combined pushes steer it along a winding waterway to the finish "
        "before time runs out. The idea is that good play needs timing and talking, not fast reflexes "
        "alone. Because the ring is shared, a single mistake affects the whole crew, which makes "
        "difficulty and clarity of controls especially important [1], [2].")
    P.p("This work follows three research questions suggested by the course:")
    P.p("RQ1: Does the level-unlocking system motivate players to continue?", first=0.0, after=1)
    P.p("RQ2: How usable are the offline and online modes on a real phone?", first=0.0, after=1)
    P.p("RQ3: Which design changes did playtest feedback lead to, and did they improve the retest results?", first=0.0)
    P.p("The rest of the paper is organized as follows. Section II reviews related work, Section III "
        "describes the game design, Section IV explains the implementation, Section V describes the "
        "evaluation method, Section VI reports the results, and Sections VII and VIII discuss them "
        "and conclude.")
    P.p("The contributions are (a) a complete five-level cooperative game with offline and LAN modes, "
        "(b) a host-authoritative design with automatic discovery of nearby games, so that players "
        "do not need to type an IP address, and (c) a playtest study with a documented action plan.")

    # --- II. Related work
    P.heading("Related Work")
    P.p("Player enjoyment is often explained with flow, the balance between challenge and skill "
        "[2]. GameFlow turned this idea into criteria for evaluating games, including clear goals, "
        "feedback and a fitting challenge [1]. Studies of mobile games link a good balance of "
        "difficulty to continued play, and a randomized field experiment found that an easier "
        "game raised engagement and retention [10]. Toot Tubes applies this by giving each level its "
        "own goal and time limit, offering a no-timer practice mode and returning a fallen crew to a "
        "checkpoint instead of ending the run.")
    P.p("Touch controls are a second concern. Comparisons of soft joysticks, buttons and tilt show "
        "that the control scheme changes how challenging a mobile game feels [7], and analyses of "
        "players' touch positions are used to size and place virtual controls [8]. Toot Tubes uses "
        "two large thumb controls (an aim pad and a hold button) and keeps nothing important at the "
        "top of the screen.")
    P.p("For cooperative play, recent work examines how players share control and react to "
        "teammates' mistakes. In a co-located cooperative exergame, the design of cooperation "
        "changed enjoyment and motivation [11], and casual players responded to teammate "
        "performance in ways that affected frustration [12]. In multiplayer networking, an "
        "authoritative host keeps the game state consistent, and the cost is latency, which "
        "compensation techniques try to hide [6], [9]. Godot provides a high-level multiplayer "
        "API on top of the ENet protocol [5].")
    P.p("Toot Tubes differs from these works in three ways. It has one physical ring that all riders "
        "move together, so rivalry in Versus and Teams is about who claims the stars on that shared ring, "
        "not about separate vehicles. Thrust is sustained and "
        "per-rider rather than a single tap. And the whole game, including nearby-game discovery, "
        "runs on a plain local network without any server.")

    # --- III. Game design
    P.heading("Game Design")
    P.sub("A", "Mechanic, goal and rules")
    P.p("Every player has an AIM pad (left thumb) and a HOLD button (right thumb). Aiming moves the "
        "rider around the rim of the ring toward the chosen direction. Holding the button makes the "
        "rider push the ring away from its seat while a gas cloud bursts out behind it. Each rider "
        "has an individual gas meter that drains while pushing and refills while resting, and "
        "beans on the course refill it. The pushes of all riders combine on the single ring.")
    P.p("The goal of every level is to bring the ring to the finish before the time limit. Crossing "
        "the line in time is a win. More than half of the time left earns three stars, more than a "
        "quarter earns two, and anything else earns one. When the timer reaches zero the level is "
        "lost and the result screen offers Retry. Falling off the course is not a loss: the crew "
        "restarts at the last of two checkpoints while the clock keeps running.")
    P.p("On top of the race, every course holds twelve collectible stars (Star Scramble). The nearest "
        "rider whose seat passes within reach of a star takes it, so riders must steer the ring together "
        "and also rotate around the rim to claim stars. Before a run the players choose a mode: in Co-op "
        "the crew shares one star total, in Versus every rider plays for themselves, and in Teams 2v2 "
        "seats 1 and 3 play against seats 2 and 4. The ring is shared in every mode, so the whole crew "
        "still has to reach the finish, and the star total decides the winner.")
    P.sub("B", "Levels, difficulty and unlocking")
    P.caption_table("Level plan")
    P.table(["#", "Level", "What is new or harder", "Time (s)"], LEVEL_ROWS, [0.28, 0.85, 1.77, 0.5], size=7)
    P.p("Table I shows how the courses grow harder: Level 1 teaches the controls, and each later level "
        "adds a new hazard family, with narrower paths or longer routes. Only Level 1 is open at the "
        "start. Clearing level n unlocks level n+1, and locked levels show a lock and cannot be opened. "
        "Best stars and best times are stored on the phone.")
    P.sub("C", "Offline and online modes")
    P.p("Offline mode needs no network. One player controls a rider and may add up to three computer "
        "helper riders that follow the same gas and physics rules; in Versus or Teams the player races the helpers for stars. Online mode is cooperative and real "
        "time: two to four phones on the same Wi-Fi network or hotspot join one crew. Online results "
        "do not change offline unlocks. Fig. 1 shows the screens and how players move between them.")
    P.figure(ASSETS / "fig1_screen_flow.png", "Screen flow of Toot Tubes. Every screen has a Back button and handles the Android back gesture.")
    P.sub("D", "Interface design")
    P.p("The interface was designed for one-handed use in portrait orientation on a phone. Body text is "
        "at least 28 px and buttons at least 120 px at the 720 × 1280 design size, nothing important "
        "sits in the top 80 px, and the Fredoka font keeps text readable. The pause menu offers Resume, "
        "Restart, Recover, Sound and Quit, and the sound setting is saved. Offline and online choices "
        "are two separate, clearly labelled sections on the mode screen, and a problem such as a "
        "failed join appears as a message directly under the Join button instead of an operating "
        "system dialog.")

    # --- IV. Implementation
    P.heading("Implementation")
    P.sub("A", "Engine and structure")
    P.p("The game was written in GDScript with Godot 4.7 (standard build, Compatibility renderer) "
        "and exported as an Android APK in portrait at 720 × 1280. All art is generated in code from "
        "primitive meshes, shared materials and shaders, and all sound effects and music are "
        "synthesized by a script, so no third-party media is bundled. Four autoloads hold shared "
        "state: GameState (progress and crew), Net (networking), Audio and the settings flow. "
        "A Level node builds a course from a path definition, and a SwimRing node simulates the "
        "shared ring. More than one hundred automated GUT tests and a LAN smoke test protect these "
        "parts.")
    P.p("Thrust is a sustained input integrated at fixed physics steps, and the courses have real "
        "curves and height changes. Every moving obstacle takes its position only from the level's "
        "race time, so the same course moves identically on every phone without any extra messages.")
    P.sub("B", "Save and unlock system")
    P.p("Progress is saved with Godot's ConfigFile in user://save.cfg. Listing 1 shows the core of the "
        "unlock rule. The file is written to a temporary file and then renamed, so a crash cannot "
        "leave a half-written save, and a backup is made before any migration. A level result is "
        "stored only in offline mode, which keeps online matches from changing unlocks.")
    P.listing("Listing 1. Unlock rule (simplified).", SAVE_LISTING)
    P.sub("C", "Networking and result authority")
    P.p("Online play uses ENet on port 7777 for up to four phones. One phone hosts. The host "
        "simulates the shared ring, validates every guest message, and decides the result. A guest "
        "sends only the aim direction and hold state of its own seat; the host checks the seat, "
        "rate and strength and lets old inputs expire, so a lost message can never leave thrust "
        "stuck on. The host also awards each star to the nearest rider in reach and adds up the "
        "scores, so a guest can never give itself a star. The host sends the ring state, each rider's "
        "gas, the star scores and the run state (timer, checkpoint, finish, winner) to every guest, and "
        "guests interpolate between updates (Fig. 2).")
    P.figure(ASSETS / "fig2_architecture.png", "Architecture. The host simulates the ring and decides the result; guests send only their own seat's input.")
    P.p("The usual way to join in a lab setting is to type the host's IP address, which first "
        "testing showed to be too technical for casual players. The host therefore announces "
        "the game once per second with a small UDP broadcast on port 7778, and other phones list "
        "it as a one-tap Join button. Typing the IP address stays as a fallback for networks that "
        "block broadcast. Joining times out after 5 seconds with a message that tells the player "
        "to check the Wi-Fi. If the host leaves, guests see a clear message and return to Mode "
        "Select; if a guest leaves, that seat becomes vacant and the match continues.")
    P.sub("D", "Build, testing and performance")
    P.p("The project has more than one hundred automated GUT tests with over eight thousand assertions. "
        "They cover the save and unlock rules, course geometry, hazard determinism, input handling, "
        "the interface and the network input gate. A separate LAN smoke test starts real game "
        "processes and checks a two-player crew, a four-player crew, an unreachable host and the loss "
        "of the host. Builds were also installed on a physical phone and driven with touch input "
        "to check the screens, the pause menu and the Android back gesture.")
    P.p("In a profiling run on one mid-range Android phone (Android 13, 720 × 1612), the game "
        "averaged about 48–50 frames per second on the High quality setting and about 61–64 on "
        "Low, with all four riders pushing. A Low setting reduces particles and decorations without "
        "changing the physics, and the High setting lowers the 3D resolution when the frame rate drops. "
        "Fig. 3 shows two screens captured on the phone.")
    P.figure(ASSETS / "fig_screenshots.png", "Screens on the phone: (a) the goal banner at the start of Level 1 and (b) a rider pushing the shared ring.", width=2.5)

    # --- V. Evaluation method
    P.heading("Evaluation Method")
    P.sub("A", "Participants")
    if HAS_DATA:
        ages = {}
        habits = {}
        for r in MAIN:
            ages[r.get("age_range", "?").strip()] = ages.get(r.get("age_range", "?").strip(), 0) + 1
            habits[r.get("play_frequency", "?").strip()] = habits.get(r.get("play_frequency", "?").strip(), 0) + 1
        P.p(f"{N} participants outside the development team took part (codes T1–T{N}). "
            "Their profile is shown in Table II.")
        P.caption_table("Participant profile")
        P.table(["Group", "Category", "n"],
                [["Age range", k, v] for k, v in sorted(ages.items())] +
                [["Play frequency", k, v] for k, v in sorted(habits.items())], [1.2, 1.4, 0.7])
    else:
        P.p(f"{ph('n')} participants outside the development team took part (codes T1–T{ph('n')}). "
            "Their profile is shown in Table II.")
        P.caption_table("Participant profile")
        P.table(["Group", "Category", "n"],
                [["Age range", ph("pending playtest data"), "-"], ["Play frequency", ph("pending playtest data"), "-"]],
                [1.2, 1.4, 0.7])
    P.sub("B", "Devices and procedure")
    P.p(f"Sessions ran on two Android phones: an Infinix X6525 (Android 13) and {ph('second phone model and Android version')}. "
        "Online matches used the same Wi-Fi network or one phone's hotspot.")
    P.p("Each session lasted 15 to 20 minutes on a freshly installed build. Testers received a "
        "one-sentence brief and were asked to think aloud. They played Levels 1–3 offline and one "
        "online match with a second phone. An observer filled in an observation sheet with attempts, "
        "time, stuck points, quotes and bugs. After playing, each tester completed the feedback form. "
        "After the top issues were fixed, new players repeated the session as a retest.")
    P.sub("C", "Instrument and analysis")
    P.p("The form had 15 statements rated from 1 (strongly disagree) to 5 (strongly agree) [3], "
        "five open questions and an overall star rating. Item means were interpreted as 4.20–5.00 "
        "strongly agree, 3.40–4.19 agree, 2.60–3.39 neutral, 1.80–2.59 disagree and "
        "1.00–1.79 strongly disagree; a mean below 3.5 was treated as a problem area. A level "
        "with a completion rate below 60% or more than four attempts per tester was treated as too "
        "hard. Open answers were grouped into themes. No validated scale such as the System Usability "
        "Scale [4] was used.")
    P.sub("D", "Ethics and privacy")
    P.p("Every tester gave consent before playing, and testers under 18 needed a guardian's consent. "
        "No names, faces or phone numbers were recorded; testers appear only as T1, T2 and so on, "
        "in line with the Philippine Data Privacy Act of 2012 (RA 10173). All data in this paper "
        "were anonymized, and all results are reported, including low scores.")

    # --- VI. Results
    P.heading("Results")
    if HAS_DATA:
        mean, sd, n = overall()
        P.p(f"The overall rating was M = {fmt(mean)} (SD = {fmt(sd)}, n = {n}). Table III lists the "
            "mean, standard deviation and number of answers for every item.")
    else:
        P.p(f"The overall rating was {ph('M = ?, SD = ?, n = ?')}. Table III lists the mean, standard "
            "deviation and number of answers for every item.")
    P.caption_table("Likert results, main round")
    rows = []
    for i, text in enumerate(ITEMS, 1):
        mean, sd, n = item_stats(MAIN, i)
        rows.append([i, text, fmt(mean), fmt(sd), n if n else "-", interpret(mean)])
    P.table(["#", "Statement", "M", "SD", "n", "Meaning"], rows, [0.3, 1.55, 0.3, 0.3, 0.25, 0.7], size=6.5)
    if HAS_DATA:
        parts = []
        for level in (1, 2, 3):
            rate, n = completion(level)
            attempts = stats([number(r.get(f"l{level}_attempts", "")) for r in MAIN])[0]
            parts.append(f"Level {level} {fmt(rate, 0)}% (mean attempts {fmt(attempts, 1)})")
        P.p("Completion rates were " + "; ".join(parts) + " (Fig. 4).")
        if (ASSETS / "fig3_completion.png").exists():
            P.figure(ASSETS / "fig3_completion.png", "Completion rate per level, main round.")
        online = [r for r in MAIN if str(r.get("online_completed", "")).strip() != ""]
        if online:
            done = sum(is_yes(r["online_completed"]) for r in online)
            P.p(f"{done} of {len(online)} pairs completed the online match.")
        low = [(i, item_stats(MAIN, i)[0]) for i in range(1, 16) if item_stats(MAIN, i)[0] < 3.5]
        if low:
            P.p("Items below the 3.5 threshold were " + ", ".join(f"item {i} (M = {fmt(m)})" for i, m in low) + ".")
    else:
        P.p(f"Completion rates per level were {ph('L1 %, L2 %, L3 %')} (Fig. 4), with mean attempts of "
            f"{ph('?')}. {ph('Fig. 4 and the themes are added from RESULTS.csv after the playtest.')}")
    P.p(f"The main themes in the open answers were {ph('themes from the observation sheets and forms')}.")
    P.caption_table("Action plan and retest")
    if ACTIONS.exists():
        with ACTIONS.open(encoding="utf-8", newline="") as handle:
            action_rows = [[r.get("issue", ""), r.get("testers", ""), r.get("severity", ""), r.get("fix", ""), r.get("retest", "")] for r in csv.DictReader(handle)]
    else:
        action_rows = [[ph("pending"), "-", "-", "-", "-"]]
    P.table(["Issue", "Testers", "Severity", "Fix", "Retest"], action_rows, [0.9, 0.45, 0.5, 1.0, 0.5], size=6.5)

    # --- VII. Discussion
    P.heading("Discussion")
    P.p(f"RQ1 (unlocking). {ph('Answer with items 5 and 14 and the completion rates.')} "
        f"RQ2 (usability). {ph('Answer with items 3, 7, 8, 9, 12 and 13.')} "
        f"RQ3 (design changes). {ph('Describe the fixes in Table IV and the retest effect.')}")
    P.p("Compared with the literature, a clear goal per level, a fair difficulty curve and responsive "
        "controls are the main drivers of enjoyment [1], [10]. The cooperative design also relies on "
        "shared responsibility, so a teammate's mistake can feel frustrating [12].")
    P.p("Three design decisions are worth reporting for similar low-cost cooperative games. First, "
        "letting the host decide the result and letting guests send only their own input kept "
        "all phones consistent without any server, which matches the authority model described in "
        "the networking literature [6], [9]. Second, joining by a one-tap list of nearby games "
        "replaced typing an IP address, because an address is a technical detail that casual "
        "players should not need to know; the IP field remains only for networks that block "
        "broadcast. Third, drawing every course, rider and sound in code kept the project small "
        "and free of licensing problems, at the cost of more programming time.")
    P.p("The study has limits. The sample was small and consisted of classmates and acquaintances "
        "from one school; the game was tested on a small number of Android phones and only on Wi-Fi "
        "or a hotspot; and a validated scale was not used. The playtest cannot show long-term "
        "retention, and the online results depend on the quality of the local network.")

    # --- VIII. Conclusion
    P.heading("Conclusion and Future Work")
    P.p("Toot Tubes shows that a complete cooperative mobile game with five levels, saved "
        "progress and host-authoritative LAN play for up to four phones can be built with only "
        "open-source tools. " + (f"The playtest with {N} players suggests {ph('main finding')}."
                                 if HAS_DATA else f"The playtest with {ph('n')} players suggests {ph('main finding')}."))
    P.p("Future work includes a larger study with more phone models, an optional internet mode, "
        "more levels and accessibility options such as larger controls and a colour-blind palette.")

    P.plain_heading("Acknowledgment")
    P.p("The author thanks the course instructor and the playtesters. AI coding assistants were used "
        "for parts of the programming, documentation and the drafting of this paper. The author "
        "reviewed, tested and edited the results and is responsible for the content.")

    P.plain_heading("References")
    P.reference_list()

    # --- Appendix (not counted in the pages)
    break_par = doc.add_paragraph()
    break_par.add_run().add_break(WD_BREAK.PAGE)
    P.plain_heading("Appendix")
    P.sub("A", "Links")
    for label, link in [("Source code", REPO), ("Release v1.0 (APK and paper)", REPO + "/releases/tag/v1.0"),
                        ("Demo video", ph("link"))]:
        P.p(f"{label}: {link}", first=0.0, after=1)
    P.sub("B", "Supporting documents in the repository")
    for text in ["Game design document: docs/GDD.md", "Phone test matrix: docs/TEST_MATRIX.md",
                 "Anonymized forms and results: docs/playtest/", "Asset credits: docs/CREDITS.md"]:
        P.p(text, first=0.0, after=1)
    P.sub("C", "Answers to the guide questions")
    answers = [
        ("Which levels are open and where is that stored?",
         "GameState keeps unlocked_level; level n is open when n ≤ unlocked_level. Clearing level n sets it to "
         "at least n+1. It is stored with the best stars and times in a ConfigFile at user://save.cfg on the phone."),
        ("What happens if the connection drops during an online match?",
         "The game runs on a local network, so the relevant failure is a lost Wi-Fi link. Guests that lose the host see "
         "a clear message and return to Mode Select. If a guest leaves, its seat becomes vacant and the host continues. "
         "Peers that stay silent for 8 seconds are treated as lost, and nothing crashes or freezes."),
        ("Why should the host decide the winner?",
         "Each phone could report a different result because of latency or tampering, and in Versus or Teams a phone "
         "could simply claim every star. The host simulates the one shared ring, awards each star to the nearest rider "
         "in reach, validates guest inputs, adds up the scores and sends one result with the winner, so every phone "
         "shows the same outcome and a guest cannot change it."),
        ("Which playtest finding surprised the team most?", ph("fill in after the playtest")),
        ("Which statement scored lowest, and what would be done with one more week?", ph("fill in after the playtest")),
        ("Android versus iOS?",
         "Android was chosen because the team's phones and the course supported it and because Godot exports an APK "
         "without a paid developer account. It made installing and testing over USB easy; the tradeoff is a wide range "
         "of screen sizes and hardware, which called for a Low quality setting and safe-area handling."),
    ]
    for i, (question, answer) in enumerate(answers, 1):
        P.p(f"{i}. {question}", first=0.0, bold=True, after=0, keep_next=True)
        P.p(answer, first=0.0, after=3)
    return doc


# ---------------------------------------------------------------- cover sheet

def center(doc, text, size=12, bold=False, before=0, after=0, italic=False):
    paragraph = doc.add_paragraph()
    add_runs(paragraph, text, size, bold=bold, italic=italic)
    fmt_par(paragraph, WD_ALIGN_PARAGRAPH.CENTER, before, after, line=1.15)
    return paragraph


def build_cover() -> Document:
    doc = Document()
    doc.styles["Normal"].font.name = FONT
    section = doc.sections[0]
    section.page_width = Inches(8.27)
    section.page_height = Inches(11.69)
    for side in ("left_margin", "right_margin", "top_margin", "bottom_margin"):
        setattr(section, side, Inches(1))
    # header block with the two institution logos if they exist
    table = doc.add_table(rows=1, cols=3)
    table.autofit = False
    widths = [1.1, 4.0, 1.1]
    for i, width in enumerate(widths):
        table.rows[0].cells[i].width = Inches(width)
    for index, name in ((0, "cmu_logo.png"), (2, "cicc_logo.png")):
        logo = ASSETS / name
        if logo.exists():
            cell_par = table.rows[0].cells[index].paragraphs[0]
            cell_par.add_run().add_picture(str(logo), width=Inches(0.95))
            cell_par.alignment = WD_ALIGN_PARAGRAPH.CENTER
    middle = table.rows[0].cells[1]
    lines = [("REPUBLIC OF THE PHILIPPINES", True), ("Bukidnon", False), ("Central Mindanao University", True),
             ("Musuan, Maramag, Bukidnon", False), ("College of Information Sciences and Computing", True)]
    first = True
    for text, bold in lines:
        paragraph = middle.paragraphs[0] if first else middle.add_paragraph()
        first = False
        add_runs(paragraph, text, 11, bold=bold)
        fmt_par(paragraph, WD_ALIGN_PARAGRAPH.CENTER, 0, 0)
    center(doc, "", 12, before=10)
    center(doc, "ITSD 85 Lab 5: Mobile Game with Level Progression and Offline/Online Multiplayer", 11, before=24, after=6)
    center(doc, "DESIGN AND PLAYER EVALUATION OF TOOT TUBES:", 12, bold=True)
    center(doc, "A LEVEL-BASED COOPERATIVE MOBILE GAME WITH OFFLINE AND LAN MULTIPLAYER BUILT WITH OPEN-SOURCE TOOLS", 12, bold=True, after=14)
    paragraph = doc.add_paragraph()
    paragraph.add_run().add_picture(str(ASSETS / "logo.png"), width=Inches(4.6))
    fmt_par(paragraph, WD_ALIGN_PARAGRAPH.CENTER, 8, 14)
    center(doc, "TEAM CAZO – BSIT 4C", 12, bold=True, after=6)
    center(doc, "CARLOS FIDEL G. CASTRO", 11, after=2)
    center(doc, "GitHub: Cazo-debug", 11, after=18)
    center(doc, "SUBMITTED TO:", 11, bold=True, after=2)
    paragraph = doc.add_paragraph()
    add_runs(paragraph, "Renante Buntod", 11)
    fmt_par(paragraph, WD_ALIGN_PARAGRAPH.CENTER, 0, 0)
    center(doc, "Course Instructor — ITSD 85", 11, after=24)
    center(doc, "NOVEMBER 2026", 11, bold=True)
    return doc


if __name__ == "__main__":
    PAPER.mkdir(parents=True, exist_ok=True)
    build_paper().save(PAPER / "paper.docx")
    build_cover().save(PAPER / "cover_sheet.docx")
    print("wrote paper.docx and cover_sheet.docx", "(with playtest data)" if HAS_DATA else "(playtest placeholders)")
