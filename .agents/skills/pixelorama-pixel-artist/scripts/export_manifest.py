#!/usr/bin/env python3
"""Build checked frame metadata and optional Godot 4 SpriteFrames resources, offline."""
import argparse
import json
import os
import sys
import tempfile
from pathlib import Path

from check_animation_sheet import durations_ms, inspect_animations
from validate_assets import local_path, read_spec, require


def build_manifest(spec, root):
    report = inspect_animations(spec, root)
    require(report["ok"], "validation failed:\n" + "\n".join(report["errors"]))
    by_id = {item["id"]: item for item in report["assets"]}
    assets = []
    for asset in spec["assets"]:
        item = {key: asset[key] for key in ("id", "kind", "design_id", "source", "credit", "sheet", "frame_size", "pivot")}
        item.update({"sheet_frame_count": asset["sheet_frame_count"], "grid": by_id[asset["id"]]["grid"],
                     "bounds": by_id[asset["id"]]["bounds"], "animations": []})
        for key in ("palette", "tile_size", "alpha_mode", "persistent"):
            if key in asset:
                item[key] = asset[key]
        width, height = asset["frame_size"]
        columns = item["grid"][0]
        for animation in asset["animations"]:
            clip = {key: animation[key] for key in ("name", "state", "fps", "loop")}
            clip["direction"] = animation.get("direction", "none")
            clip["frame_count"] = len(animation["frames"])
            clip["frames"] = [{"sheet_index": index,
                               "rect": [index % columns * width, index // columns * height, width, height],
                               "duration_ms": duration}
                              for index, duration in zip(animation["frames"], durations_ms(animation))]
            clip["unique_drawings"] = next(r["unique_drawings"] for r in report["animations"]
                                             if r["asset"] == asset["id"] and r["name"] == animation["name"])
            if "contact_frame" in animation:
                clip["contact_frame"] = animation["contact_frame"]
                clip["contact_time_ms"] = sum(durations_ms(animation)[:animation["contact_frame"]])
            item["animations"].append(clip)
        assets.append(item)
    result = {"schema_version": 1, "format": "pixelorama_pixel_artist", "assets": assets}
    if "palette" in spec:
        result["palette"] = spec["palette"]
    return result


def godot_resource(asset):
    frames = [frame for clip in asset["animations"] for frame in clip["frames"]]
    lines = [f'[gd_resource type="SpriteFrames" load_steps={len(frames) + 2} format=3]', "",
             f'[ext_resource type="Texture2D" path={json.dumps("res://" + asset["sheet"])} id="1"]', ""]
    for number, frame in enumerate(frames):
        lines.extend([f'[sub_resource type="AtlasTexture" id="Frame_{number}"]',
                      'atlas = ExtResource("1")',
                      'region = Rect2(%s)' % ", ".join(map(str, frame["rect"])), ""])
    clips, number = [], 0
    for clip in asset["animations"]:
        entries = []
        for frame in clip["frames"]:
            # SpriteFrames stores relative durations, not milliseconds.
            relative = frame["duration_ms"] * clip["fps"] / 1000.0
            entries.append('{"duration": %s, "texture": SubResource("Frame_%s")}' % (repr(relative), number))
            number += 1
        clips.append('{"frames": [%s], "loop": %s, "name": &%s, "speed": %s}' %
                     (", ".join(entries), str(clip["loop"]).lower(), json.dumps(clip["name"]), repr(float(clip["fps"]))))
    lines.extend(["[resource]", "animations = [\n" + ",\n".join(clips) + "\n]",
                  'metadata/design_id = ' + json.dumps(asset["design_id"]),
                  'metadata/pivot = Vector2(%s)' % ", ".join(map(str, asset["pivot"])), ""])
    return "\n".join(lines)


def atomic_write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", dir=path.parent, delete=False) as handle:
        temporary = Path(handle.name)
        handle.write(text)
    try:
        os.replace(temporary, path)
    finally:
        temporary.unlink(missing_ok=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("spec", type=Path)
    parser.add_argument("--root", type=Path, help="Godot res:// root; defaults to spec's directory")
    parser.add_argument("--output", required=True, type=Path, help="generated JSON; never merge over an unrelated registry")
    parser.add_argument("--godot-dir", help="optional resource folder relative to --root; tilesets use manual TileSet setup")
    parser.add_argument("--force", action="store_true", help="replace previously generated files")
    args = parser.parse_args()
    try:
        root = (args.root or args.spec.resolve().parent).resolve()
        require(args.output.resolve() != args.spec.resolve(), "output must not overwrite the input specification")
        manifest = build_manifest(read_spec(args.spec), root)
        outputs = {}
        if args.godot_dir:
            destination = local_path(root, args.godot_dir)
            for asset in manifest["assets"]:
                if asset["kind"] != "tileset":
                    path = destination / (asset["id"] + ".tres")
                    asset["godot_resource"] = "res://" + path.relative_to(root).as_posix()
                    outputs[path.resolve()] = godot_resource(asset)
        manifest_path = args.output.resolve()
        require(manifest_path not in outputs, "JSON output collides with a resource path")
        outputs[manifest_path] = json.dumps(manifest, indent=2, ensure_ascii=False, allow_nan=False) + "\n"
        for path in outputs:
            require(args.force or not path.exists(), f"{path} already exists; use --force only for generated outputs")
            require(path != args.spec.resolve(), "resource output collides with input specification")
            require(path not in {local_path(root, a["sheet"]) for a in manifest["assets"]},
                    "output collides with a source PNG")
        for path, text in outputs.items():
            atomic_write(path, text)
        print(f"Wrote {len(manifest['assets'])} assets to {manifest_path}; {len(outputs) - 1} SpriteFrames resources")
        return 0
    except (ValueError, OSError, TypeError, KeyError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
