#!/usr/bin/env python3
"""Validate regular-grid PNG exports against a local art specification (Pillow)."""
import argparse
import json
import math
import re
import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    raise SystemExit("Pillow is required. Install in a project venv: python -m pip install Pillow")

NAME = re.compile(r"[a-z][a-z0-9]*(?:_[a-z0-9]+)*\Z")
KINDS = {"player", "npc", "enemy", "item", "tileset", "prop", "vfx", "ui"}


def require(condition, message):
    if not condition:
        raise ValueError(message)


def integer(value, minimum=0):
    return type(value) is int and value >= minimum


def positive(value):
    return type(value) in (int, float) and math.isfinite(value) and value > 0


def pair(value, minimum=0):
    return isinstance(value, list) and len(value) == 2 and all(integer(v, minimum) for v in value)


def local_path(root, value):
    require(isinstance(value, str) and value and "\\" not in value, "path must be a relative POSIX path")
    path = Path(value)
    require(not path.is_absolute() and ".." not in path.parts and ":" not in value,
            "path must stay inside --root")
    result = (root / path).resolve()
    require(result.is_relative_to(root), "path resolves outside --root")
    return result


def palette_colors(values):
    require(isinstance(values, list) and values, "palette must be a nonempty array of #RRGGBB colors")
    colors = set()
    for color in values:
        require(isinstance(color, str) and re.fullmatch(r"#[0-9a-fA-F]{6}", color),
                "palette colors must use #RRGGBB")
        colors.add(tuple(bytes.fromhex(color[1:])))
    return colors


def read_spec(path):
    with Path(path).open(encoding="utf-8") as handle:
        spec = json.load(handle)
    require(isinstance(spec, dict) and type(spec.get("schema_version")) is int
            and spec["schema_version"] == 1, "schema_version must be 1")
    require(isinstance(spec.get("assets"), list) and spec["assets"], "assets must be a nonempty array")
    if "palette" in spec:
        palette_colors(spec["palette"])
    return spec


def validate_one(asset, root, default_palette):
    require(isinstance(asset, dict), "asset must be an object")
    require(isinstance(asset.get("id"), str) and NAME.fullmatch(asset["id"]),
            "id must use lowercase snake_case")
    require(isinstance(asset.get("design_id"), str) and asset["design_id"].strip(),
            "design_id is required")
    require(asset.get("kind") in KINDS, "unknown kind")
    for key in ("source", "credit"):
        require(isinstance(asset.get(key), str) and asset[key].strip(), f"{key} is required")
    require(pair(asset.get("frame_size"), 1), "frame_size must be [positive width, positive height]")
    width, height = asset["frame_size"]
    require(pair(asset.get("pivot")), "pivot must be a nonnegative integer pair")
    require(asset["pivot"][0] <= width and asset["pivot"][1] <= height, "pivot is outside the frame")
    path = local_path(root, asset.get("sheet"))
    require(path.suffix.lower() == ".png" and path.is_file(), "sheet must be an existing PNG")
    require(path.stem == asset["id"], "PNG basename must match asset id")
    with Image.open(path) as original:
        require(original.format == "PNG" and getattr(original, "n_frames", 1) == 1,
                "sheet must be a single-image PNG, not an animated PNG")
        has_alpha = "A" in original.getbands() or "transparency" in original.info
        image = original.convert("RGBA")
    require(image.width % width == 0 and image.height % height == 0,
            f"sheet {image.size} is not divisible by frame_size {asset['frame_size']}")
    columns, rows = image.width // width, image.height // height
    count = asset.get("sheet_frame_count")
    require(integer(count, 1) and count <= columns * rows, "sheet_frame_count exceeds grid capacity or is invalid")
    require_transparency = asset.get("require_transparency", True)
    require(type(require_transparency) is bool, "require_transparency must be boolean")
    require(not require_transparency or has_alpha, "PNG has no alpha channel/transparency entry")
    alpha_mode = asset.get("alpha_mode", "binary")
    require(alpha_mode in ("binary", "smooth"), "alpha_mode must be binary or smooth")
    if alpha_mode == "binary":
        require(not any(image.getchannel("A").histogram()[1:255]), "partial alpha found in binary pixel art")
    palette = asset.get("palette", default_palette)
    if "palette" in asset:
        palette_colors(asset["palette"])
    if palette is not None:
        colors = palette_colors(palette)
        unexpected = {pixel[:3] for _, pixel in image.getcolors(image.width * image.height) if pixel[3] > 0} - colors
        require(not unexpected, f"{len(unexpected)} visible RGB colors are outside the palette")
    padding = asset.get("edge_padding", 0)
    require(integer(padding) and padding * 2 < min(width, height), "edge_padding is invalid")
    empty = asset.get("allow_empty_frames", [])
    require(isinstance(empty, list) and all(integer(i) and i < count for i in empty),
            "allow_empty_frames must list sheet indices within sheet_frame_count")
    animations = asset.get("animations")
    require(isinstance(animations, list) and animations, "animations must be nonempty")
    names, used = set(), set()
    for animation in animations:
        require(isinstance(animation, dict), "animation must be an object")
        name = animation.get("name")
        require(isinstance(name, str) and NAME.fullmatch(name) and name not in names,
                "animation names must be unique lowercase snake_case")
        names.add(name)
        state = animation.get("state")
        require(isinstance(state, str) and NAME.fullmatch(state), f"{name}: state is required")
        direction = animation.get("direction", "none")
        require(direction in ("up", "down", "left", "right", "none"), f"{name}: invalid direction")
        frames = animation.get("frames")
        require(isinstance(frames, list) and frames
                and all(integer(i) and i < count for i in frames), f"{name}: frames outside declared sheet count")
        require(positive(animation.get("fps")), f"{name}: fps must be finite and positive")
        require(type(animation.get("loop")) is bool, f"{name}: loop must be boolean")
        durations = animation.get("durations_ms")
        require("durations_ms" not in animation or (isinstance(durations, list) and len(durations) == len(frames)
                                     and all(positive(d) for d in durations)),
                f"{name}: durations_ms must contain one positive duration per playback frame")
        if "contact_frame" in animation:
            require(integer(animation["contact_frame"]) and animation["contact_frame"] < len(frames),
                    f"{name}: contact_frame must be an animation-local index")
        require(integer(animation.get("min_unique", 2 if len(frames) > 1 else 1), 1),
                f"{name}: min_unique must be positive")
        used.update(frames)
    persistent = asset.get("persistent", asset["kind"] != "vfx")
    require(type(persistent) is bool, "persistent must be boolean")
    if persistent:
        require(any(a["state"] in ("idle", "ambient") and a["loop"] for a in animations),
                "persistent assets require an idle/ambient loop")
    if asset["kind"] == "vfx":
        require(any(a["state"] == "play" and not a["loop"] for a in animations),
                "transient VFX require a non-looping play sequence")
    if asset["kind"] == "tileset":
        require(pair(asset.get("tile_size"), 1) and asset["tile_size"] == asset["frame_size"],
                "tileset tile_size must match frame_size (one tile per grid cell)")
    bounds = {}
    for index in range(columns * rows):
        x, y = index % columns * width, index // columns * height
        alpha = image.crop((x, y, x + width, y + height)).getchannel("A")
        bbox = alpha.getbbox()
        if index >= count:
            require(bbox is None, f"undeclared grid cell {index} contains pixels")
        if index in used:
            require(bbox is not None or index in empty, f"frame {index} is empty; declare intentional blanks")
            require(not require_transparency or alpha.getextrema()[0] == 0,
                    f"frame {index} has no fully transparent background pixels")
            if bbox and padding:
                require(bbox[0] >= padding and bbox[1] >= padding
                        and bbox[2] <= width - padding and bbox[3] <= height - padding,
                        f"frame {index} touches the {padding}px edge guard")
            bounds[str(index)] = list(bbox) if bbox else None
    return {"id": asset["id"], "size": list(image.size), "grid": [columns, rows],
            "sheet_frame_count": count, "referenced_frames": len(used),
            "unused_declared_frames": sorted(set(range(count)) - used), "bounds": bounds}


def validate_spec(spec, root):
    root = Path(root).resolve()
    errors, reports, ids, sheets, designs = [], [], set(), set(), {}
    for index, asset in enumerate(spec["assets"]):
        label = asset.get("id", f"asset[{index}]") if isinstance(asset, dict) else f"asset[{index}]"
        try:
            report = validate_one(asset, root, spec.get("palette"))
            require(asset["id"] not in ids, "duplicate asset id")
            sheet = local_path(root, asset["sheet"])
            require(sheet not in sheets, "different types must have their own sheet")
            palette = asset.get("palette", spec.get("palette"))
            signature = (asset["frame_size"], asset["pivot"],
                         frozenset(palette_colors(palette)) if palette is not None else None)
            previous = designs.get(asset["design_id"], signature)
            require(previous == signature, "frame_size/pivot/palette disagree within design_id")
            ids.add(asset["id"])
            sheets.add(sheet)
            designs[asset["design_id"]] = signature
            reports.append(report)
        except (ValueError, OSError, TypeError, KeyError) as error:
            errors.append(f"{label}: {error}")
    return {"ok": not errors, "assets": reports, "errors": errors}


def emit_report(report, destination=None):
    rendered = json.dumps(report, indent=2, ensure_ascii=False, allow_nan=False) + "\n"
    if destination:
        Path(destination).write_text(rendered, encoding="utf-8")
    print(rendered, end="")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("spec", type=Path)
    parser.add_argument("--root", type=Path, help="PNG root; defaults to spec's directory")
    parser.add_argument("--json-report", type=Path)
    args = parser.parse_args()
    try:
        report = validate_spec(read_spec(args.spec), args.root or args.spec.resolve().parent)
        emit_report(report, args.json_report)
        return 0 if report["ok"] else 1
    except (ValueError, OSError, TypeError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
