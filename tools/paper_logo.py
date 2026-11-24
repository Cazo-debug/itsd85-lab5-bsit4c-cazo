"""Render the Toot Tubes logo lockup (icon + title + author) to docs/paper/assets/logo.png.

Uses Microsoft Edge in headless mode, so no extra Python packages are needed.
Run from the repo root: python tools/paper_logo.py
"""
import os
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "docs" / "paper" / "assets"
EDGE_CANDIDATES = [
    r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
    r"C:\Program Files\Microsoft\Edge\Application\msedge.exe",
]


def render(html_path: Path, png_path: Path, width: int, height: int) -> None:
    edge = next((p for p in EDGE_CANDIDATES if os.path.exists(p)), None)
    if edge is None:
        sys.exit("Microsoft Edge was not found")
    subprocess.run(
        [edge, "--headless", "--disable-gpu", "--default-background-color=00000000",
         f"--window-size={width},{height}", f"--screenshot={png_path}", html_path.as_uri()],
        check=True, capture_output=True)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    svg = (ROOT / "assets" / "icons" / "toot_tubes.svg").read_text(encoding="utf-8")
    font_uri = (ROOT / "assets" / "fonts" / "Fredoka.ttf").as_uri()
    html = f"""<!doctype html><meta charset="utf-8"><style>
@font-face{{font-family:F;src:url("{font_uri}");font-weight:100 900}}
html,body{{margin:0;background:transparent}}
.w{{width:1400px;height:560px;display:flex;align-items:center;gap:56px;padding:0 40px;box-sizing:border-box;font-family:F,sans-serif}}
svg{{width:440px;height:440px;filter:drop-shadow(0 10px 14px rgba(20,80,110,.35))}}
h1{{margin:0;font-size:150px;line-height:.95;font-weight:700;color:#1b8fb0;letter-spacing:2px;text-shadow:0 5px 0 #0f5f78}}
h1 span{{color:#ff766c;text-shadow:0 5px 0 #b6433b}}
p{{margin:14px 0 0;font-size:40px;color:#40586a;font-weight:500}}
.n{{margin-top:22px;font-size:32px;color:#4f9a2b;font-weight:700;letter-spacing:1px}}
</style><div class="w">{svg}<div><h1>TOOT<br><span>TUBES</span></h1>
<p>A cooperative shared-ring party game</p>
<div class="n">Carlos Fidel G. Castro &middot; Team Cazo</div></div></div>"""
    page = OUT / "_logo.html"
    page.write_text(html, encoding="utf-8")
    render(page, OUT / "logo.png", 1400, 560)
    page.unlink()
    print("wrote", OUT / "logo.png")


if __name__ == "__main__":
    main()
