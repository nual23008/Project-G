"""Shared packing only. Art authors own disjoint asset IDs and manifest fragments."""
from pathlib import Path
import json
import math
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / 'assets/art_refresh'
SHEETS = BASE / 'sheets'
RES = ROOT / 'resources/art'
for folder in [SHEETS, RES, BASE / 'manifests', BASE / 'previews']:
    folder.mkdir(parents=True, exist_ok=True)


def canvas(w, h):
    return Image.new('RGBA', (w, h))


def source(name, size, margin=4):
    """Normalize alpha and integer-scale a project-owned source onto a fixed canvas."""
    im = Image.open(ROOT / 'assets/art_v3/sources' / (name + '.png')).convert('RGBA')
    im.putalpha(im.getchannel('A').point(lambda a: 255 if a >= 210 else 0))
    box = im.getchannel('A').getbbox()
    if not box:
        raise ValueError(name + ' has no opaque source pixels')
    im = im.crop(box)
    im.thumbnail((size[0] - margin * 2, size[1] - margin * 2), Image.Resampling.NEAREST)
    result = canvas(*size)
    result.alpha_composite(im, ((size[0] - im.width) // 2, size[1] - margin - im.height))
    return result


def register(registry, name, states, pivot, source_note, **extra):
    images, meta = [], {}
    for state, (frames, fps, loop) in states.items():
        if len(frames) > 1:
            assert len({f.tobytes() for f in frames}) > 1, (name, state, 'duplicate animation')
        meta[state] = {'indices': list(range(len(images), len(images) + len(frames))),
                       'count': len(frames), 'fps': fps, 'loop': loop}
        images.extend(frames)
    w, h = images[0].size
    assert all(f.size == (w, h) for f in images)
    cols = min(12, len(images))
    sheet = canvas(w * cols, h * math.ceil(len(images) / cols))
    for i, im in enumerate(images):
        sheet.alpha_composite(im, ((i % cols) * w, (i // cols) * h))
    sheet.save(SHEETS / (name + '.png'))
    texture = f'res://assets/art_refresh/sheets/{name}.png'
    write_resource(name, texture, (w, h), cols, meta)
    registry[name] = {'resource': f'res://resources/art/{name}.tres', 'texture': texture,
                      'frame_size': [w, h], 'pivot': list(pivot), 'columns': cols,
                      'states': meta, 'source': source_note, 'backend': 'SpriteFrames',
                      'revision': 'art_refresh', **extra}
    return sheet


def write_resource(name, texture, size, columns, states):
    w, h = size
    textures = list(dict.fromkeys([texture] + [s.get('texture', texture) for s in states.values()]))
    ids = {path: str(i + 1) for i, path in enumerate(textures)}
    lines = ['[gd_resource type="SpriteFrames" format=3]']
    lines += [f'[ext_resource type="Texture2D" path="{path}" id="{ids[path]}"]' for path in textures]
    animations = []
    for state, info in states.items():
        frames = []
        cols = int(info.get('columns', columns))
        path = info.get('texture', texture)
        for fi, index in enumerate(info['indices']):
            sub = f'{state}_{fi}'
            lines += [f'[sub_resource type="AtlasTexture" id="{sub}"]',
                      f'atlas = ExtResource("{ids[path]}")',
                      f'region = Rect2({index % cols * w}, {index // cols * h}, {w}, {h})']
            frames.append('{"duration":1.0,"texture":SubResource("' + sub + '")}')
        animations.append('{"name":&"' + state + '","speed":' + str(info['fps']) +
                          ',"loop":' + str(info['loop']).lower() + ',"frames":[' + ','.join(frames) + ']}')
    lines += ['[resource]', 'animations = [' + ',\n'.join(animations) + ']']
    (RES / (name + '.tres')).write_text('\n'.join(lines) + '\n')


def fragment(group, registry):
    (BASE / 'manifests' / (group + '.json')).write_text(json.dumps(registry, indent=2, ensure_ascii=False) + '\n')
