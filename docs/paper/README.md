# Paper files

| File | What it is |
|---|---|
| `paper.docx` / `paper.pdf` | The lab paper in IEEE two-column format (Word + PDF with embedded fonts) |
| `cover_sheet.docx` / `cover_sheet.pdf` | One-page cover sheet with the logo (not part of the IEEE paper or its page count) |
| `PAPER_OUTLINE.md`, `REFERENCES_TO_VERIFY.md` | Planning notes and reference candidates |
| `assets/` | Logo, diagrams and screenshots used by the paper |

Yellow `[highlighted]` text in the documents marks something that still has to be filled in
(playtest numbers, author email, instructor name, reference details).

## Rebuild after the playtest
1. Fill `docs/playtest/RESULTS.csv` (one row per tester, `round` = `main` or `retest`).
2. Optionally add `docs/playtest/ACTIONS.csv` with the columns `issue,testers,severity,fix,retest`.
3. From the repo root:
   ```
   python tools/paper_figures.py
   python tools/build_paper.py
   powershell -File tools/docx_to_pdf.ps1
   ```
   The tables, figures and numbers are computed from the CSV files; nothing is typed by hand.
4. Final submission: copy `paper.pdf` to `docs/paper.pdf` and rename the copy for Classroom as
   `ITSD85_Lab5_BSIT4C_Cazo_Paper.pdf`.
