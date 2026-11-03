#!/usr/bin/env python3
"""New authored ground materials and motes, built from empty integer canvases.

No previous terrain/sprite sheet is an input. Each material/frame is persisted
as an editable character grid and rendered by the installed pixel_draw tool.
Godot layout deliberately preserves gameplay's sixteen-pixel tile contract.
"""
from pathlib import Path
import importlib.util
import json
import math
import subprocess
from PIL import Image, ImageDraw
from art_refresh_common import ROOT, BASE, SHEETS, canvas, write_resource, register, fragment

PIXEL_DRAW = Path('/home/luan/.codex/plugins/cache/pixel-studio/godot-pixel-studio/0.1.0/scripts/pixel_draw.py')
_spec = importlib.util.spec_from_file_location('refresh_pixel_draw', PIXEL_DRAW)
pixel_draw = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(pixel_draw)
PREVIEW = BASE / 'previews/world'
GRIDS = PREVIEW / 'source_grids'
REGISTRY = {}

# The project's existing material ramps; all silhouettes and clusters below are
# newly drawn. No resampling, blend tones, noise texture or image input is used.
C = {
    'grass_shadow': '#214c43', 'grass': '#315b43', 'grass_patch': '#47704a',
    'grass_light': '#64814e', 'grass_tip': '#87915c',
    'stone_shadow': '#726952', 'stone_edge': '#938368', 'stone': '#ad9474',
    'stone_lit': '#d0bc91', 'stone_glint': '#f6e3b0',
    'water_shadow': '#214c58', 'water': '#346b70',
    'water_lit': '#508b87', 'water_crest': '#80b4a4',
    'mote': '#f0bc73', 'mote_core': '#ffe2a0',
}


def grid_render(im, label):
    """Keep an exact editable grid, then ask pixel_draw to produce the pixels."""
    colors = sorted(set(im.get_flattened_data()))
    symbols = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@$%^&*()_+-=[]{};<>?,/'
    if len(colors) > len(symbols):
        raise ValueError((label, len(colors), 'too many intentional colors'))
    palette = {color: symbols[i] for i, color in enumerate(colors)}
    path = GRIDS / (label + '.txt')
    path.parent.mkdir(parents=True, exist_ok=True)
    rows = ['name: refresh-world-' + label, 'legend:']
    for color in colors:
        rows.append('  "' + palette[color] + '": "#' + ''.join(f'{c:02x}' for c in color) + '"')
    px = im.load()
    rows.append('grid:')
    rows.extend(''.join(palette[px[x, y]] for x in range(im.width)) for y in range(im.height))
    path.write_text('\n'.join(rows) + '\n')
    return pixel_draw.render_grid(pixel_draw.parse_spec(path))


def grass(variation, frame):
    im = canvas(16, 16)
    d = ImageDraw.Draw(im)
    d.rectangle((0, 0, 15, 15), fill=C['grass'])
    # Quiet connected moss islands, with one deliberate blade cluster per tile.
    islands = [
        [(0, 8), (3, 7), (6, 8), (6, 11), (3, 12), (0, 11)],
        [(8, 1), (12, 0), (15, 2), (15, 5), (11, 6), (8, 4)],
        [(1, 0), (5, 0), (7, 3), (5, 5), (1, 4)],
        [(8, 10), (12, 9), (15, 11), (15, 14), (10, 15), (8, 13)],
    ]
    polygon = islands[variation % 4]
    d.polygon(polygon, fill=C['grass_shadow'] if variation < 4 else C['grass_patch'])
    blades = [(10, 11), (4, 11), (11, 7), (5, 5), (10, 10), (4, 10), (12, 8), (5, 6)]
    x, y = blades[variation]
    phase = (frame + variation) % 4
    lean = [-1, 0, 1, 0][phase]
    d.line((x, y, x - 1, y - 2), fill=C['grass_patch'])
    d.line((x, y, x + 1, y - 3), fill=C['grass_patch'])
    d.line((x, y - 1, x + lean, y - 3), fill=C['grass_light'])
    # Second leaf has a quarter-cycle delay; return pose is not a duplicate.
    d.line((x + 3, y + 1, x + 3 + [0, -1, 0, 1][phase], y - 1), fill=C['grass_patch'])
    for tx,ty in [(2+variation%3,14),(12-variation%3,4),(7,8+variation%2)]:
        d.line((tx,ty,tx-2,ty-2),fill=C['grass_shadow'])
        d.line((tx,ty,tx+2,ty-3),fill=C['grass_patch'])
        d.line((tx,ty-1,tx+lean,ty-4),fill=C['grass_light'] if ty == 14 else C['grass_patch'])
        d.point((tx+lean,ty-4),fill=C['grass_tip'] if ty == 14 else C['grass_light'])
    return im


STONE_SHAPES = [
    [(2, -2), (10, -3), (16, 1), (15, 5), (10, 9), (3, 8), (-2, 3)],
    [(-3, 6), (2, 9), (8, 10), (9, 16), (3, 19), (-2, 17)],
    [(12, 8), (18, 5), (20, 15), (16, 19), (10, 17), (10, 12)],
]


def turn_point(point, turns):
    x, y = point
    for _ in range(turns):
        x, y = 15 - y, x
    return x, y


def flagstone(variation, frame):
    im = canvas(16, 16)
    d = ImageDraw.Draw(im)
    d.rectangle((0, 0, 15, 15), fill=C['stone_shadow'])
    tones = [C['stone_lit'], C['stone'], C['stone']]
    # Hand-set faceted slabs, not little rectangles or randomized brick rows.
    for i, original in enumerate(STONE_SHAPES):
        polygon = [turn_point(p, variation % 4) for p in original]
        d.polygon(polygon, fill=tones[(i + variation // 4) % 3])
        # Each rotated slab is relit from the upper-left; geometry rotates,
        # material lighting does not. Mortar joints run diagonally, not in rows.
        edges = list(zip(polygon, polygon[1:] + polygon[:1]))
        a, b = min(edges, key=lambda edge: sum(edge[0]) + sum(edge[1]))
        d.line((a[0], a[1], b[0], b[1]), fill=C['stone_lit'])
    # Two moss clusters sit in seams, never speckled over the stone faces.
    mx, my = turn_point((8, 10), variation % 4)
    d.line((mx, my, mx, my + 1), fill=C['grass_patch'])
    # Only a tiny wet bevel catches warm light. Slab silhouettes stay fixed.
    phase = (frame + variation) % 4
    x, y = turn_point((4, 5), variation % 4)
    # Two adjacent wet-bevel pixels catch/release light in sequence. Their
    # two-tone combinations make all four frames distinct without a flash.
    reflections = [('stone', 'stone'), ('stone', 'stone_lit'),
                   ('stone_lit', 'stone_lit'), ('stone_lit', 'stone')]
    first, second = reflections[phase]
    d.point((x, y), fill=C[first])
    d.point((x + 1, y), fill=C[second])
    for cx,cy in [(3,11),(13,6)]:
        cx,cy=turn_point((cx,cy),variation%4)
        d.line((cx,cy,cx+1,cy+2),fill=C['stone_shadow'])
        d.point((cx-1,cy),fill=C['stone_edge'])
    return im


def water(variation, frame):
    im = canvas(16, 16)
    d = ImageDraw.Draw(im)
    d.rectangle((0, 0, 15, 15), fill=C['water_shadow'])
    phase = (frame + variation) % 4
    # Wrapped stepped wavelets keep the image seamless; only water moves.
    for j, (start_x, start_y, length) in enumerate([(1, 4, 6), (9, 11, 5)]):
        x = (start_x + 2 * phase + variation * 3) % 16
        y = start_y + [0, 0, 1, 0][phase] - variation % 2
        for wrap in [-16, 0, 16]:
            xx = x + wrap
            d.line((xx, y, xx + 1, y), fill=C['water'])
            d.line((xx + 2, y - 1, xx + length - 2, y - 1), fill=C['water_lit'])
            d.line((xx + length - 1, y, xx + length, y), fill=C['water'])
            if j == 0 and phase in [1, 2]:
                d.line((xx + 2, y - 1, xx + 3, y - 1), fill=C['water_crest'])
    for xx,yy in [(2,14),(11,6)]:
        xx=(xx+phase+variation)%16
        d.line((xx,yy,xx+2,yy),fill=C['water'])
        d.point(((xx+1)%16,yy-1),fill=C['water_lit'])
    return im


def shore(variation, frame):
    im = canvas(16, 16)
    d = ImageDraw.Draw(im)
    d.rectangle((0, 0, 15, 15), fill=C['grass_shadow'])
    # Broad damp earth and rounded little pebbles collect at the pond edge.
    d.polygon([(0, 3), (5, 2), (10, 4), (15, 3), (15, 15), (0, 15)], fill=C['stone_shadow'])
    d.polygon([(1, 7), (3, 5), (6, 5), (8, 7), (7, 9), (3, 10), (1, 9)], fill=C['stone_edge'])
    d.line((3, 6, 5, 6), fill=C['stone'])
    d.polygon([(11, 11), (13, 10), (15, 12), (14, 14), (11, 14), (10, 13)], fill=C['stone_edge'])
    d.line((12, 11, 13, 11), fill=C['stone_lit'])
    # Moss leaves lean a single pixel, rooted at the same point in all phases.
    phase = (frame + variation) % 4
    x = 9 if variation % 2 else 3
    y = 3
    d.line((x, y + 2, x + [-1, 0, 1, 0][phase], y), fill=C['grass_patch'])
    d.line((x + 2, y + 2, x + 2 + [0, 1, 0, -1][phase], y + 1), fill=C['grass_light'])
    return im


def terrain():
    atlas = canvas(512, 64)
    functions = [grass, flagstone, water, shore]
    rows = []
    for row, func in enumerate(functions):
        phases = []
        for phase in range(4):
            variants = []
            for variant in range(8):
                tile = grid_render(func(variant, phase), f'terrain/{row}-{variant}-{phase}')
                atlas.alpha_composite(tile, (phase * 128 + variant * 16, row * 16))
                variants.append(tile)
            phases.append(variants)
        rows.append(phases)
    atlas.save(SHEETS / 'terrain.png')
    path_atlas = canvas(1024, 64)
    for phase in range(4):
        for variation in range(4):
            for mask in range(16):
                tile = rows[1][phase][variation].copy()
                ground = rows[0][phase][variation]
                # Same bit contract as Village: L=1 R=2 U=4 D=8.
                for bit in [1, 2, 4, 8]:
                    if mask & bit:
                        continue
                    for along in range(16):
                        depth = [2, 2, 1, 1, 2, 3, 2, 2][(along + variation * 2) % 8]
                        for across in range(depth):
                            x, y = ((across, along) if bit == 1 else
                                    (15 - across, along) if bit == 2 else
                                    (along, across) if bit == 4 else (along, 15 - across))
                            tile.putpixel((x, y), ground.getpixel((x, y)))
                tile = grid_render(tile, f'paths/{variation}-{mask}-{phase}')
                path_atlas.alpha_composite(tile, (phase * 256 + mask * 16, variation * 16))
    path_atlas.save(SHEETS / 'paths.png')
    texture = 'res://assets/art_refresh/sheets/terrain.png'
    path_texture = 'res://assets/art_refresh/sheets/paths.png'
    for row, (name, fps) in enumerate([('grass', 2), ('stone_path', .8), ('water', 5), ('shore', 1.2)]):
        meta = {'idle': {'indices': [row * 32 + phase * 8 for phase in range(4)],
                         'count': 4, 'fps': fps, 'loop': True}}
        if name == 'stone_path':
            meta['edges'] = {'indices': [0, 16, 32, 48], 'count': 4,
                             'fps': .8, 'loop': True,
                             'texture': path_texture, 'columns': 64}
        write_resource(name, texture, (16, 16), 32, meta)
        REGISTRY[name] = {
            'resource': f'res://resources/art/{name}.tres', 'texture': texture,
            'frame_size': [16, 16], 'pivot': [0, 0], 'columns': 32,
            'states': meta, 'backend': 'TileSetAtlasSource', 'revision': 'art_refresh',
            'source': 'New original hand-authored material geometry from empty canvases; editable world grids rendered by pixel_draw.py; no old asset pixels used',
            'ambient': {'grass': 'rooted blade tips lean one pixel; quiet moss islands remain fixed',
                        'stone_path': 'tiny wet stone bevel catches warm light; fixed slab geometry',
                        'water': 'wrapped stepped wavelets flow in four distinct phases',
                        'shore': 'rooted moss leaf tips move gently; stones remain rigid'}[name],
        }
    return rows


def motes():
    fireflies = []
    for phase in range(8):
        im = canvas(8, 8)
        d = ImageDraw.Draw(im)
        alpha = [48, 80, 128, 176, 208, 184, 136, 88][phase]
        wing_y = 3 if phase % 2 == 0 else 4
        d.line((1, wing_y, 2, wing_y), fill=(240, 188, 115, alpha // 2))
        d.line((5, wing_y, 6, wing_y), fill=(240, 188, 115, alpha // 2))
        d.rectangle((3, 3, 4, 4), fill=(255, 226, 160, alpha))
        fireflies.append(grid_render(im, f'firefly/{phase}'))
    register(REGISTRY, 'firefly', {'idle': (fireflies, 6, True)}, (4, 4),
             'New original lantern-moth pixel design from empty 8x8 canvas; eight real wing/pulse frames rendered through pixel_draw.py')
    glows = []
    for phase in range(4):
        # A two-pixel feature scale keeps the light bands crisp at game zoom.
        small = canvas(32, 32)
        d = ImageDraw.Draw(small)
        for radius, alpha in [(15, 4), (12, 6), (9, 9), (6, 12), (3, 16)]:
            a = alpha + [0, 2, 4, 2][phase]
            d.ellipse((16 - radius, 16 - radius, 16 + radius, 16 + radius), fill=(240, 188, 115, a))
        # The fourth phase differs in the two innermost light bands only.
        if phase == 3:
            d.ellipse((13, 13, 19, 19), fill=(240, 188, 115, 17))
        im = small.resize((64, 64), Image.Resampling.NEAREST)
        glows.append(grid_render(im, f'glow/{phase}'))
    register(REGISTRY, 'glow', {'idle': (glows, 3, True)}, (32, 32),
             'New original stepped amber lamp-light design from blank canvas; discrete alpha bands at two-pixel feature scale; four material intensity frames rendered by pixel_draw.py')


def preview(rows):
    PREVIEW.mkdir(parents=True, exist_ok=True)
    phases = []
    for phase in range(4):
        im = canvas(256, 144)
        # Small village-material sampler: meadow, path cross and a calm pond.
        for y in range(9):
            for x in range(16):
                im.alpha_composite(rows[0][phase][(x * 3 + y * 5) % 8], (x * 16, y * 16))
        paths = Image.open(SHEETS / 'paths.png')
        cells = {(x, y) for y in range(9) for x in [5, 6, 7]}
        cells |= {(x, y) for y in [4, 5, 6] for x in range(1, 15)}
        for x, y in cells:
            mask = sum(bit for bit, dx, dy in [(1, -1, 0), (2, 1, 0), (4, 0, -1), (8, 0, 1)] if (x + dx, y + dy) in cells)
            v = (x * 7 + y * 3) % 4
            tile = paths.crop((phase * 256 + mask * 16, v * 16, phase * 256 + mask * 16 + 16, v * 16 + 16))
            im.alpha_composite(tile, (x * 16, y * 16))
        for y in range(1, 4):
            for x in range(10, 15):
                row = 3 if y in [1, 3] or x in [10, 14] else 2
                im.alpha_composite(rows[row][phase][(x + y) % 8], (x * 16, y * 16))
        phases.append(im)
    phases[0].resize((1024, 576), Image.Resampling.NEAREST).save(PREVIEW / 'new_world_sampler.png')
    # A twenty-second sample closes every material's actual loop: grass2s,
    # stone5s, water.8s, shore10/3s. The phase contact below is a separate sheet.
    motion = []
    for step in range(200):
        seconds = step / 10
        grass_phase = int(seconds * 2) % 4
        stone_phase = int(seconds * .8) % 4
        water_phase = int(seconds * 5) % 4
        shore_phase = int(seconds * 1.2) % 4
        im = phases[grass_phase].copy()
        for x, y in cells:
            box = (x * 16, y * 16, x * 16 + 16, y * 16 + 16)
            im.paste(phases[stone_phase].crop(box), box[:2])
        for y in range(1, 4):
            for x in range(10, 15):
                phase = shore_phase if y in [1, 3] or x in [10, 14] else water_phase
                box = (x * 16, y * 16, x * 16 + 16, y * 16 + 16)
                im.paste(phases[phase].crop(box), box[:2])
        motion.append(im)
    motion[0].save(PREVIEW / 'new_world_sampler.gif', save_all=True, append_images=motion[1:], duration=100, loop=0, disposal=2)
    contact = canvas(512, 288)
    for i, im in enumerate(phases):
        contact.alpha_composite(im, ((i % 2) * 256, (i // 2) * 144))
    contact.resize((1024, 576), Image.Resampling.NEAREST).save(PREVIEW / 'world_phase_contact.png')
    # Source material strip at native scale and x4; a useful import/layout reference.
    material = canvas(128, 64)
    for row in range(4):
        for v in range(8):
            material.alpha_composite(rows[row][0][v], (v * 16, row * 16))
    material.resize((768, 384), Image.Resampling.NEAREST).save(PREVIEW / 'new_material_strip.png')
    material.save(PREVIEW / 'new_material_strip_native.png')
    (PREVIEW / 'asset-brief.txt').write_text(
        'Must read as quiet emerald meadow, hand-set cream flagstones and calm teal pond.\n'
        'Tile16x16, terrain512x64 with phase offsets128; paths1024x64 with phase offsets256.\n'
        'One-pixel material features; lamp glow2px. Light top-left.\n'
        'Every idle has four real frames (firefly eight), no global texture scroll or scaling.\n'
        'Root must check active TileSet animation and seam/collision preservation in Godot.\n'
        'Source pixels: all new drawings; previous assets are not inputs.\n')
    (PREVIEW / 'palette.json').write_text(json.dumps(C, indent=2) + '\n')


def review():
    forge = Path('/home/luan/.codex/plugins/cache/pixel-studio/pixel-art-forge/0.2.0/skills/pixel-art-forge/scripts/pixel_forge.py')
    report = {'states': {}, 'all_cells': {}, 'new_pixels_source':
              'All material geometry was authored on blank canvases; no previous asset was an input.'}
    for name, entry in REGISTRY.items():
        for state, meta in entry['states'].items():
            path = ROOT / meta.get('texture', entry['texture'])[6:]
            sheet = Image.open(path).convert('RGBA')
            w, h = entry['frame_size']
            cols = meta.get('columns', entry['columns'])
            frames = [sheet.crop(((i % cols) * w, (i // cols) * h,
                                  (i % cols + 1) * w, (i // cols + 1) * h)) for i in meta['indices']]
            changed = [sum(a != b for a, b in zip(frames[i].get_flattened_data(), frames[(i + 1) % len(frames)].get_flattened_data()))
                       for i in range(len(frames))]
            distinct = len({im.tobytes() for im in frames})
            assert distinct == len(frames), (name, state, distinct, len(frames))
            paths = []
            for i, im in enumerate(frames):
                target = PREVIEW / 'audit_frames' / name / state / f'{i}.png'
                target.parent.mkdir(parents=True, exist_ok=True)
                im.save(target)
                paths.append(str(target))
            durations = [round((i + 1) * 100 / meta['fps']) * 10 - round(i * 100 / meta['fps']) * 10 for i in range(len(frames))]
            frames[0].save(PREVIEW / f'{name}_{state}.gif', save_all=True, append_images=frames[1:], duration=durations, loop=0, disposal=2)
            loop = subprocess.run(['python3', str(forge), 'loopcheck', '--frames', *paths, '--anchor-tolerance', '0'], capture_output=True, text=True)
            report['states'][name + '/' + state] = {
                'frames': len(frames), 'distinct': distinct, 'changed_pixels_each_transition': changed,
                'fps': meta['fps'], 'gif_frame_ms': durations, 'loop': True,
                'loopcheck_exit_code': loop.returncode, 'loopcheck_output': loop.stdout.strip()}
            assert loop.returncode == 0, (name, state, loop.stdout)
            if name == 'glow':
                audit = subprocess.run(['python3', str(forge), 'audit', paths[0], '--light', 'tl', '--json'], capture_output=True, text=True)
                start = audit.stdout.find('{\n')
                result = json.loads(audit.stdout[start:])
                result['exit_code'] = audit.returncode
                result['note'] = 'Lamp glow is emissive; directional light check is advisory, not a declared material-light gate. Palette is the exact RGBA grid legend.'
                (PREVIEW / 'glow_forge_audit.json').write_text(json.dumps(result, indent=2) + '\n')
    for name, variants, stride in [('terrain', 8, 128), ('paths', 16, 256)]:
        sheet = Image.open(SHEETS / (name + '.png')).convert('RGBA')
        bad = []
        for y in range(4):
            for x in range(variants):
                fs = [sheet.crop((phase * stride + x * 16, y * 16, phase * stride + x * 16 + 16, y * 16 + 16)) for phase in range(4)]
                if len({im.tobytes() for im in fs}) != 4:
                    bad.append([x, y])
        report['all_cells'][name] = {'variants_checked': variants * 4, 'bad_duplicate_cells': bad}
        assert not bad, (name, bad)
    (PREVIEW / 'world_contract_review.json').write_text(json.dumps(report, indent=2) + '\n')


def main():
    PREVIEW.mkdir(parents=True, exist_ok=True)
    rows = terrain()
    motes()
    fragment('world', REGISTRY)
    preview(rows)
    review()
    print('Built six new world resources; all idle/edges clips contain real ambient motion.')


if __name__ == '__main__':
    main()
