#!/usr/bin/env python3
"""Check real drawing counts and timing after validating the PNG art specification."""
import argparse
import sys
from pathlib import Path

from validate_assets import Image, emit_report, read_spec, require, validate_spec


def durations_ms(animation):
    return animation.get("durations_ms", [1000.0 / animation["fps"]] * len(animation["frames"]))


def inspect_animations(spec, root, asset_id=None):
    report = validate_spec(spec, root)
    report["animations"] = []
    if not report["ok"]:
        return report
    selected = [a for a in spec["assets"] if asset_id is None or a["id"] == asset_id]
    require(selected, f"asset not found: {asset_id}")
    for asset in selected:
        with Image.open(Path(root) / asset["sheet"]) as original:
            image = original.convert("RGBA")
        width, height = asset["frame_size"]
        columns = image.width // width
        for animation in asset["animations"]:
            drawings = []
            for index in animation["frames"]:
                x, y = index % columns * width, index // columns * height
                frame = image.crop((x, y, x + width, y + height))
                # Invisible RGB must not turn identical visible frames into "new" drawings.
                pixels = bytearray(frame.tobytes())
                for offset in range(0, len(pixels), 4):
                    if pixels[offset + 3] == 0:
                        pixels[offset:offset + 3] = b"\x00\x00\x00"
                drawings.append(bytes(pixels))
            unique = len(set(drawings))
            minimum = animation.get("min_unique", 2 if len(drawings) > 1 else 1)
            if animation["state"] in ("idle", "ambient", "play"):
                minimum = max(2, minimum)
            if unique < minimum:
                report["errors"].append(f"{asset['id']}/{animation['name']}: {unique} visible drawings; need {minimum}")
            durations = durations_ms(animation)
            item = {"asset": asset["id"], "name": animation["name"], "playback_frames": len(drawings),
                    "unique_drawings": unique, "reused_drawings": len(drawings) - unique,
                    "adjacent_holds": [i for i in range(1, len(drawings)) if drawings[i] == drawings[i - 1]],
                    "loop_boundary_same_drawing": bool(animation["loop"] and drawings[0] == drawings[-1]),
                    "durations_ms": durations, "total_ms": sum(durations)}
            if "contact_frame" in animation:
                item["contact_time_ms"] = sum(durations[:animation["contact_frame"]])
            report["animations"].append(item)
    report["ok"] = not report["errors"]
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("spec", type=Path)
    parser.add_argument("--root", type=Path, help="PNG root; defaults to spec's directory")
    parser.add_argument("--asset", help="check drawing/timing details for one asset (all PNGs still validated)")
    parser.add_argument("--json-report", type=Path)
    args = parser.parse_args()
    try:
        report = inspect_animations(read_spec(args.spec), args.root or args.spec.resolve().parent, args.asset)
        emit_report(report, args.json_report)
        return 0 if report["ok"] else 1
    except (ValueError, OSError, TypeError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
