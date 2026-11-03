"""Copies the README's images out of the executed notebooks into .Documentation/imgs, each
the figure one cell drew as the notebook keeps it, so the README shows what the notebooks
printed. Run it after dev/run.sh, in the image or any Python."""

import base64
import json
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent

# the notebook, its code cell counted from 1, and the image's name in .Documentation/imgs
IMAGES = [
    ("01-data/01-six-exchanges.ipynb", 7, "211101.png"),
    ("02-charts/04-figures.ipynb", 6, "211102.png"),
    ("03-strategies/08-coin-margined.ipynb", 4, "211103.png"),
    ("04-research/01-a-search.ipynb", 6, "211104.png"),
    ("05-reinforcement-learning/05-branching.ipynb", 4, "211105.png"),
]


def figure(notebook, cell):
    book  = json.loads((ROOT / notebook).read_text(encoding="utf-8"))
    code  = [each for each in book["cells"] if each["cell_type"] == "code"]
    drawn = [output["data"]["image/png"] for output in code[cell - 1]["outputs"]
             if "image/png" in output.get("data", {})]
    if len(drawn) != 1:
        raise SystemExit(f"{notebook}: code cell {cell} holds {len(drawn)} figures, not one; "
                         f"run it, or name the cell that draws the figure")
    return base64.b64decode(drawn[0])


folder = ROOT / ".Documentation" / "imgs"
folder.mkdir(parents=True, exist_ok=True)

for notebook, cell, name in IMAGES:
    (folder / name).write_bytes(figure(notebook, cell))
    print(f"{name}  {notebook}, cell {cell}")
