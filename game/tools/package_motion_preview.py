#!/usr/bin/env python3
"""Package unmodified Godot captures for animation review (Pillow, QA only)."""
from pathlib import Path
import json
from PIL import Image, ImageDraw, ImageChops

OUT = Path(__file__).resolve().parents[1] / "tests/output"
FRAMES = OUT / "stage1_motion"


def animation(prefix, durations):
    frames = [Image.open(p).convert("RGB") for p in sorted(FRAMES.glob(prefix + "_*.png"))]
    if not frames:
        raise RuntimeError("Run stage1_motion_preview.gd with the real renderer first")
    frames[0].save(OUT / ("stage1_" + prefix + ".gif"), save_all=True,
                   append_images=frames[1:], duration=durations, loop=0)
    differences = [ImageChops.difference(a, b).getbbox() is not None
                   for a, b in zip(frames, frames[1:])]
    return frames, {"frames": len(frames), "changing_transitions": sum(differences),
                    "durations_ms": durations}


village, environment = animation("village", 100)
# GIF stores 10ms units. Alternating 20/10/20 approximates 60Hz without slowing it.
slash, attack = animation("slash", [20, 10, 20] * 6)
death, collapse = animation("death", 50)
selected = [0, 2, 4, 5, 6, 8, 10, 12, 14]
sheet = Image.new("RGB", (5 * 256, 2 * 218), "#203a3e")
draw = ImageDraw.Draw(sheet)
for cell, index in enumerate(selected):
    crop = slash[index].crop((256, 124, 384, 224)).resize((256, 200), Image.Resampling.NEAREST)
    x, y = (cell % 5) * 256, (cell // 5) * 218
    sheet.paste(crop, (x, y))
    draw.text((x + 4, y + 202), f"capture {index:02} / physics 60Hz", fill="#f6e3b0")
sheet.save(OUT / "stage1-slash-contact.png")
death_sheet = Image.new("RGB", (4 * 256, 2 * 218), "#203a3e")
draw = ImageDraw.Draw(death_sheet)
for cell, index in enumerate([0, 3, 6, 9, 12, 15, 18, 21]):
    crop = death[index].crop((256, 124, 384, 224)).resize((256, 200), Image.Resampling.NEAREST)
    x, y = (cell % 4) * 256, (cell // 4) * 218
    death_sheet.paste(crop, (x, y))
    draw.text((x + 4, y + 202), f"death sample {index:02} / 50ms", fill="#f6e3b0")
death_sheet.save(OUT / "art-refresh-death-contact.png")
result = {"environment": environment, "attack": attack, "death": collapse,
          "note": "Actual engine frames; exact damage/contact is asserted by art_contract_test.gd."}
(OUT / "stage1-motion-review.json").write_text(json.dumps(result, indent=2) + "\n")
assert environment["changing_transitions"] > 0 and attack["changing_transitions"] > 0
print(json.dumps(result))
