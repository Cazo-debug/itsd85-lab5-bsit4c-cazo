"""Draw the paper figures (screen flow, architecture, completion chart).

Fig. 1 and Fig. 2 are fixed diagrams. Fig. 3 is drawn from docs/playtest/RESULTS.csv and
is skipped when there is no main-round data yet.
Run from the repo root: python tools/paper_figures.py
"""
import csv
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "docs" / "paper" / "assets"
RESULTS = ROOT / "docs" / "playtest" / "RESULTS.csv"
plt.rcParams["font.family"] = "serif"
plt.rcParams["font.serif"] = ["Times New Roman", "DejaVu Serif"]
NL = chr(10)


def box(ax, x, y, w, h, text, fill="#ffffff", size=8, bold=False):
    ax.add_patch(FancyBboxPatch((x, y), w, h, boxstyle="round,pad=0.02,rounding_size=0.06",
                                fc=fill, ec="black", lw=1.0))
    ax.text(x + w / 2, y + h / 2, text.replace("|", NL), ha="center", va="center", fontsize=size,
            fontweight="bold" if bold else "normal", linespacing=1.15)


def arrow(ax, a, b, text=None, style="-|>", dx=0.0, dy=0.07):
    ax.annotate("", xy=b, xytext=a, arrowprops=dict(arrowstyle=style, lw=1.0, color="black",
                                                    shrinkA=0, shrinkB=0))
    if text:
        ax.text((a[0] + b[0]) / 2 + dx, (a[1] + b[1]) / 2 + dy, text, ha="center", fontsize=6.5,
                style="italic")


def screen_flow() -> None:
    fig, ax = plt.subplots(figsize=(3.45, 3.3), dpi=300)
    ax.set_xlim(0, 3.45)
    ax.set_ylim(0, 3.3)
    ax.axis("off")
    box(ax, 0.1, 2.85, 0.8, 0.34, "Title", "#e6e6e6", 7.5)
    box(ax, 1.3, 2.85, 0.85, 0.34, "Main menu", "#e6e6e6", 7.5)
    box(ax, 2.55, 2.85, 0.8, 0.34, "Settings /|Credits", "#f7f7f7", 6.5)
    arrow(ax, (0.9, 3.02), (1.3, 3.02))
    arrow(ax, (2.15, 3.02), (2.55, 3.02), style="<|-|>")
    box(ax, 1.15, 2.2, 1.15, 0.38, "Mode select", "#e6e6e6", 7.5)
    arrow(ax, (1.72, 2.85), (1.72, 2.58))
    box(ax, 0.1, 1.45, 1.35, 0.5, "Crew setup|(offline, helpers)", "#ffffff", 7)
    box(ax, 2.0, 1.45, 1.35, 0.5, "Lobby|(host / nearby / IP)", "#ffffff", 7)
    arrow(ax, (1.4, 2.2), (0.8, 1.95), "Offline", dx=-0.3, dy=0.02)
    arrow(ax, (2.05, 2.2), (2.65, 1.95), "Online", dx=0.3, dy=0.02)
    box(ax, 1.05, 0.9, 1.35, 0.34, "Level select", "#e6e6e6", 7.5)
    arrow(ax, (0.8, 1.45), (1.4, 1.24))
    arrow(ax, (2.65, 1.45), (2.05, 1.24))
    box(ax, 0.1, 0.25, 1.0, 0.38, "Game|(HUD, pause)", "#ffffff", 7)
    box(ax, 1.25, 0.25, 1.05, 0.38, "Result|stars, time", "#ffffff", 7)
    box(ax, 2.45, 0.25, 0.9, 0.38, "Retry / Next|/ Menu", "#f7f7f7", 6.5)
    arrow(ax, (1.45, 0.9), (0.7, 0.63))
    arrow(ax, (1.1, 0.44), (1.25, 0.44))
    arrow(ax, (2.3, 0.44), (2.45, 0.44))
    fig.savefig(OUT / "fig1_screen_flow.png", bbox_inches="tight", pad_inches=0.04)
    plt.close(fig)


def architecture() -> None:
    fig, ax = plt.subplots(figsize=(3.45, 3.5), dpi=300)
    ax.set_xlim(0, 3.45)
    ax.set_ylim(0, 3.5)
    ax.axis("off")
    ax.add_patch(FancyBboxPatch((0.05, 1.5), 3.35, 1.95, boxstyle="round,pad=0.02,rounding_size=0.05",
                                fc="#f4f4f4", ec="black", lw=1.0, ls="--"))
    ax.text(0.15, 3.28, "Host phone (authority)", fontsize=7.5, fontweight="bold", va="center")
    box(ax, 0.15, 2.45, 0.95, 0.55, "Level +|race_time", "#ffffff", 7)
    box(ax, 1.25, 2.45, 0.95, 0.55, "SwimRing|(shared ring)", "#ffffff", 7)
    box(ax, 2.4, 2.45, 0.95, 0.55, "GameState|(save.cfg)", "#ffffff", 7)
    box(ax, 0.15, 1.65, 0.95, 0.55, "NetInputGate|(validates)", "#ffffff", 7)
    box(ax, 1.25, 1.65, 0.95, 0.55, "Net (ENet|port 7777)", "#e6e6e6", 7, True)
    box(ax, 2.4, 1.65, 0.95, 0.55, "LanDiscovery|(UDP 7778)", "#ffffff", 7)
    arrow(ax, (0.62, 2.2), (0.62, 2.45), style="<|-|>")
    arrow(ax, (1.72, 2.2), (1.72, 2.45), style="<|-|>")
    arrow(ax, (1.1, 1.92), (1.25, 1.92), style="<|-|>")
    arrow(ax, (2.2, 1.92), (2.4, 1.92), style="<|-|>")
    box(ax, 0.15, 0.1, 1.5, 0.75, "Guest phones 1..3|send their own seat:|aim + hold only", "#ffffff", 7)
    box(ax, 1.85, 0.1, 1.5, 0.75, "Guest phones|receive ring state,|gas, timer, result", "#ffffff", 7)
    arrow(ax, (0.9, 0.85), (1.4, 1.65), "inputs", dx=-0.25, dy=0.0)
    arrow(ax, (2.05, 1.65), (2.6, 0.85), "snapshots", dx=0.35, dy=0.0)
    ax.text(1.72, 1.12, "Wi-Fi or hotspot", ha="center", fontsize=6.5, style="italic")
    fig.savefig(OUT / "fig2_architecture.png", bbox_inches="tight", pad_inches=0.04)
    plt.close(fig)


def completion() -> bool:
    if not RESULTS.exists():
        return False
    with RESULTS.open(encoding="utf-8", newline="") as handle:
        rows = [r for r in csv.DictReader(handle) if r.get("round") == "main" and r.get("tester")]
    if not rows:
        return False
    rates = []
    for level in ["l1", "l2", "l3"]:
        answered = [r for r in rows if r.get(f"{level}_cleared", "") != ""]
        cleared = [r for r in answered if r[f"{level}_cleared"].strip().lower() in ("1", "yes", "y", "true")]
        rates.append(100.0 * len(cleared) / len(answered) if answered else 0.0)
    fig, ax = plt.subplots(figsize=(3.45, 2.1), dpi=300)
    bars = ax.bar(["Level 1", "Level 2", "Level 3"], rates, color="#9a9a9a", edgecolor="black")
    ax.axhline(60, color="black", ls="--", lw=0.8)
    ax.text(2.45, 62, "60% threshold", ha="right", fontsize=6.5)
    ax.set_ylim(0, 110)
    ax.set_ylabel("Completion rate (%)", fontsize=8)
    ax.tick_params(labelsize=7.5)
    for bar, rate in zip(bars, rates):
        ax.text(bar.get_x() + bar.get_width() / 2, rate + 2, f"{rate:.0f}%", ha="center", fontsize=7.5)
    fig.savefig(OUT / "fig3_completion.png", bbox_inches="tight", pad_inches=0.04)
    plt.close(fig)
    return True


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    screen_flow()
    architecture()
    print("fig3 drawn" if completion() else "fig3 skipped (no main-round data yet)")
