#!/usr/bin/env python3
"""Pack new project-owned actor identities; integer layer motion, no old sprites.

The ImageGen identity/walk/attack sources are kept unchanged. This build hardens
alpha, uses nearest-neighbour sampling, aligns boots and animates local layers.
"""
from pathlib import Path
from PIL import Image, ImageDraw
import argparse
import json
import math
import statistics

from art_refresh_common import ROOT, BASE, canvas, source, register, fragment

PREVIEW = BASE / 'previews'
SOURCE_DIR = ROOT / 'assets/art_v3/sources'
PLAYER_SIZE = (96, 64)
PLAYER_PIVOT = (48, 60)


def hard_alpha(im):
    im = im.convert('RGBA')
    im.putalpha(im.getchannel('A').point(lambda a: 255 if a >= 210 else 0))
    return im


def components(im):
    """Drop only detached source specks at a grid boundary, never actor details."""
    alpha = im.getchannel('A')
    px = alpha.load()
    seen, groups = set(), []
    for y in range(im.height):
        for x in range(im.width):
            if not px[x, y] or (x, y) in seen:
                continue
            queue, group = [(x, y)], []
            seen.add((x, y))
            while queue:
                point = queue.pop()
                group.append(point)
                for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
                    q = point[0] + dx, point[1] + dy
                    if 0 <= q[0] < im.width and 0 <= q[1] < im.height and q not in seen and px[q[0], q[1]]:
                        seen.add(q)
                        queue.append(q)
            groups.append(group)
    largest = max((len(g) for g in groups), default=0)
    for group in groups:
        if len(group) < max(12, largest // 400):
            for point in group:
                im.putpixel(point, (0, 0, 0, 0))
    return im


def extract_sheet(path, columns, rows):
    sheet = hard_alpha(Image.open(path))
    result = []
    for row in range(rows):
        images = []
        for column in range(columns):
            box = (round(column * sheet.width / columns), round(row * sheet.height / rows),
                   round((column + 1) * sheet.width / columns), round((row + 1) * sheet.height / rows))
            im = components(sheet.crop(box))
            bbox = im.getchannel('A').getbbox()
            if not bbox:
                raise ValueError(f'Empty actor cell {path} {row}/{column}')
            images.append(im.crop(bbox))
        result.append(images)
    return result


def extract_connected_sheet(path, columns, rows):
    """A sword may cross its nominal cell: isolate the full connected actor."""
    sheet = hard_alpha(Image.open(path))
    px = sheet.getchannel('A').load()
    seen, groups = set(), []
    for y in range(sheet.height):
        for x in range(sheet.width):
            if not px[x, y] or (x, y) in seen:
                continue
            queue, group = [(x, y)], []
            seen.add((x, y))
            while queue:
                point = queue.pop()
                group.append(point)
                for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
                    q = point[0] + dx, point[1] + dy
                    if 0 <= q[0] < sheet.width and 0 <= q[1] < sheet.height and q not in seen and px[q[0], q[1]]:
                        seen.add(q)
                        queue.append(q)
            if len(group) >= 1000:
                groups.append(group)
    if len(groups) != columns * rows:
        raise ValueError(f'{path}: expected {columns * rows} complete actor components, found {len(groups)}')
    result = [[] for _ in range(rows)]
    for group in groups:
        x0, y0 = min(p[0] for p in group), min(p[1] for p in group)
        x1, y1 = max(p[0] for p in group) + 1, max(p[1] for p in group) + 1
        im = canvas(x1 - x0, y1 - y0)
        for x, y in group:
            im.putpixel((x - x0, y - y0), sheet.getpixel((x, y)))
        row = min(rows - 1, int((y1 - 1) / (sheet.height / rows)))
        result[row].append((x0, im))
    if any(len(row) != columns for row in result):
        raise ValueError('Actor source rows do not match the declared direction grid')
    return [[im for _, im in sorted(row, key=lambda pair: pair[0])] for row in result]


def brown_features(im):
    return [(x, y) for y in range(im.height) for x in range(im.width)
            if (lambda c: c[3] > 0 and c[0] > 40 and c[0] > c[1] * 1.2 and c[1] > c[2] * .9)(im.getpixel((x, y)))]


def body_height(im):
    points = brown_features(im)
    return max(p[1] for p in points) - min(p[1] for p in points) + 1 if points else im.height


def fit_at_feet(images, size, pivot, scale):
    fitted = []
    for im in images:
        resized = im.resize((max(1, round(im.width * scale)), max(1, round(im.height * scale))), Image.Resampling.NEAREST)
        # Lower boot mass is the anchor; a moving scarf must not shift the torso.
        points = brown_features(resized)
        boot_y = max((p[1] for p in points), default=resized.height - 1)
        boots = [p for p in points if p[1] >= boot_y - 5]
        foot_x = (min(p[0] for p in boots) + max(p[0] for p in boots) + 1) / 2 if boots else resized.width / 2
        out = canvas(*size)
        # Dark boot edging/toes can extend below the brown highlight. Ground the
        # complete opaque silhouette, so a dark toe is never cut by the canvas.
        opaque = resized.getchannel('A').getbbox()
        location = round(pivot[0] - foot_x), pivot[1] - opaque[3]
        out.alpha_composite(resized, location)
        if location[0] < 0 or location[0] + resized.width > size[0]:
            raise ValueError(f'Frame would clip a sword/identity: {resized.size} at {location} on {size}')
        fitted.append(out)
    return fitted


def move_regions(base, regions):
    out = base.copy()
    parts = []
    for box, dx, dy in regions:
        parts.append((base.crop(box), (box[0] + dx, box[1] + dy)))
        out.paste((0, 0, 0, 0), box)
    for part, point in parts:
        out.alpha_composite(part, point)
    return out


def rotate_layer(out, layer, degrees, source_anchor, destination_anchor):
    rotated = layer.rotate(degrees, Image.Resampling.NEAREST, expand=True)
    angle = math.radians(degrees)
    dx, dy = source_anchor[0] - layer.width / 2, source_anchor[1] - layer.height / 2
    ax = rotated.width / 2 + math.cos(angle) * dx + math.sin(angle) * dy
    ay = rotated.height / 2 - math.sin(angle) * dx + math.cos(angle) * dy
    out.alpha_composite(rotated, (round(destination_anchor[0] - ax), round(destination_anchor[1] - ay)))


def hero_idle(base, direction):
    frames = []
    # Only coat tails and the scarf end move. Head, torso and boots keep anchors.
    center = base.width // 2
    side = (center + 4, 20, center + 22, 35) if direction in ('down', 'left', 'up') else (center - 22, 20, center - 4, 35)
    for i in range(8):
        sway = round(math.sin(i * math.tau / 8))
        cloth = round(math.sin(i * math.tau / 8 + .8))
        im = move_regions(base, [(side, 0, sway), ((center - 14, 39, center + 14, 51), cloth, 0)])
        frames.append(im)
    return frames


def hurt_frames(base, size, pivot, count=5):
    frames = []
    for i in range(count):
        recoil = max([0, -2, -3, -2, -1][i % 5], 2 - base.getchannel('A').getbbox()[0])
        shoulder = max(0, round(math.sin(i / max(1, count - 1) * math.pi)))
        im = move_regions(base, [((0, 0, size[0], pivot[1] - 8), recoil, shoulder)])
        frames.append(im)
    return frames


def collapse_frames(base, size, pivot, count=9):
    """Bend at the hip, then fold legs; no full-body squeeze or unrelated corpse."""
    frames = []
    hip_y = pivot[1] - 14
    upper = base.crop((0, 0, size[0], hip_y + 1))
    lower = base.crop((0, hip_y + 1, size[0], size[1]))
    for i in range(count):
        t = i / (count - 1)
        angle = -min(78, t * 100)
        point = (pivot[0] - round(t * 17), hip_y + round(t * 10))
        # Rotate on padded scratch space BEFORE any fixed-frame composition.
        # Earlier fixed-canvas rotations silently discarded boots/cape pixels.
        padding = max(size) * 2
        scratch = canvas(size[0] + padding * 2, size[1] + padding * 2)
        padded_point = point[0] + padding, point[1] + padding
        rotate_layer(scratch, lower, min(68, t * 90), (pivot[0], 0), padded_point)
        rotate_layer(scratch, upper, angle, (pivot[0], hip_y), padded_point)
        box = scratch.getchannel('A').getbbox()
        assert box[2] - box[0] <= size[0] - 4 and box[3] - box[1] <= pivot[1] - 2, ('collapse does not fit without clipping', size, box)
        x0, x1 = box[0] - padding, box[2] - padding
        shift_x = 2 - x0 if x0 < 2 else size[0] - 2 - x1 if x1 > size[0] - 2 else 0
        shift_y = pivot[1] - (box[3] - padding)
        final_box = (x0 + shift_x, box[1] - padding + shift_y,
                     x1 + shift_x, box[3] - padding + shift_y)
        assert final_box[0] >= 2 and final_box[1] >= 2 and final_box[2] <= size[0] - 2 and final_box[3] == pivot[1], final_box
        im = canvas(*size)
        im.alpha_composite(scratch, (shift_x - padding, shift_y - padding))
        assert im.getchannel('A').getbbox() == final_box
        frames.append(im)
    return frames


def rowan_states():
    base = source('rowan', (48, 64), margin=4)
    frames = []
    for i in range(8):
        sway = round(math.sin(i * math.tau / 8))
        # Staff and feet stay planted; robe edge and beard follow the breeze.
        im = move_regions(base, [((18, 33, 42, 53), sway, 0), ((21, 22, 32, 29), 0, 1 if i in (3, 4) else 0)])
        frames.append(im)
    return {'idle_down': (frames, 5, True)}


def guardian_states():
    base = source('enemy', (48, 56), margin=3)
    # Keep the existing body scale, translating its complete sole to pivot 52.
    grounded = canvas(48, 56)
    grounded.alpha_composite(base, (0, 52 - base.getchannel('A').getbbox()[3]))
    base = grounded
    left_arm, right_arm = (2, 24, 14, 45), (35, 24, 47, 45)
    left_leg, right_leg = (11, 43, 23, 53), (25, 43, 39, 53)
    states = {}
    idle, walk, windup, attack = [], [], [], []
    for i in range(8):
        phase = i * math.tau / 8
        wave = round(math.sin(phase))
        im = move_regions(base, [(left_arm, 0, wave), (right_arm, 0, -wave)])
        idle.append(im)
        im = move_regions(base, [(left_arm, 0, round(math.sin(phase) * 2)),
                                 (right_arm, 0, -round(math.sin(phase) * 2)),
                                 (left_leg, wave, -max(0, wave)), (right_leg, -wave, -max(0, -wave))])
        walk.append(im)
        pull = round(i / 7 * 4)
        im = move_regions(base, [(left_arm, -min(2, pull), -pull), (right_arm, min(2, pull), -pull)])
        # Crystal facets gain a restrained amber charge over the anticipation.
        d = ImageDraw.Draw(im)
        d.line((22, 7, 22, 9 + i // 2), fill=('#e4d9aa' if i < 4 else '#fff0ba'))
        windup.append(im)
        # Raised fists -> simultaneous downward contact -> shoulder recovery.
        dy = [-4, -2, 5, 4, 3, 2, 1, 0][i]
        spread = [-1, 0, 2, 2, 1, 1, 0, 0][i]
        im = move_regions(base, [(left_arm, -spread, dy), (right_arm, spread, dy)])
        attack.append(im)
    states['idle'] = (idle, 5, True)
    states['walk'] = (walk, 8, True)
    states['windup'] = (windup, 8 / .42, False)
    states['attack'] = (attack, 8 / .24, False)
    states['hurt'] = (hurt_frames(base, (48, 56), (24, 52)), 5 / .18, False)
    states['death'] = (collapse_frames(base, (48, 56), (24, 52)), 9 / .55, False)
    return states


def assert_frame_guards(name, states, pivot):
    records = {}
    for state, (frames, _fps, _loop) in states.items():
        records[state] = []
        for i, frame in enumerate(frames):
            box = frame.getchannel('A').getbbox()
            assert box is not None, (name, state, i, 'empty frame')
            assert box[0] >= 1 and box[1] >= 1 and box[2] <= frame.width - 1 and box[3] <= frame.height - 1, (name, state, i, 'opaque outer edge', box)
            assert box[3] <= pivot[1], (name, state, i, 'opaque pixels below ground pivot', box)
            if state.startswith('death'):
                assert box[3] == pivot[1], (name, state, i, 'collapse must settle on ground', box)
            records[state].append(list(box))
    return records


def previews(name, states, size):
    labels = list(states)
    width = max(len(states[n][0]) for n in labels) * size[0]
    sheet = Image.new('RGBA', (width, len(labels) * (size[1] + 18)), '#282431')
    d = ImageDraw.Draw(sheet)
    for row, state in enumerate(labels):
        d.text((3, row * (size[1] + 18) + 2), state, fill='#e8d2a2')
        for i, im in enumerate(states[state][0]):
            sheet.alpha_composite(im, (i * size[0], row * (size[1] + 18) + 17))
    sheet.resize((sheet.width * 2, sheet.height * 2), Image.Resampling.NEAREST).save(PREVIEW / (name + '_states.png'))
    for state, (frames, fps, loop) in states.items():
        if not (state.endswith('_down') or name == 'enemy' or name == 'rowan'):
            continue
        ims = []
        for frame in frames:
            bg = Image.new('RGBA', size, '#282431')
            bg.alpha_composite(frame)
            ims.append(bg.convert('RGB').resize((size[0] * 5, size[1] * 5), Image.Resampling.NEAREST))
        ims[0].save(PREVIEW / f'{name}_{state}.gif', save_all=True, append_images=ims[1:], duration=round(1000 / fps), loop=0 if loop else 1, disposal=2)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--attack-source', type=Path, default=BASE / 'sources/hero_attack.png')
    parser.add_argument('--partial', action='store_true', help='Build Rowan/guardian while the new attack sheet is being authored')
    args = parser.parse_args()
    registry = {}
    rowan = rowan_states()
    enemy = guardian_states()
    bounds = {'rowan': assert_frame_guards('rowan', rowan, (24, 60)),
              'enemy': assert_frame_guards('enemy', enemy, (24, 52))}
    register(registry, 'rowan', rowan, (24, 60), 'New original ImageGen elder identity: assets/art_v3/sources/rowan.png; alpha>=210, nearest fixed canvas, local robe/beard animation')
    register(registry, 'enemy', enemy, (24, 52), 'New original ImageGen crystal guardian identity: assets/art_v3/sources/enemy.png; alpha>=210, articulated arm/leg/hip motion', contact_frame=2, contact_time=.084, duration=.24)
    previews('rowan', rowan, (48, 64))
    previews('enemy', enemy, (48, 56))
    walks = extract_sheet(SOURCE_DIR / 'hero_walk.png', 6, 4)
    all_walks = [im for row in walks for im in row]
    scale = min(56 / max(im.height for im in all_walks), 42 / max(im.width for im in all_walks))
    walks = [fit_at_feet(row, PLAYER_SIZE, PLAYER_PIVOT, scale) for row in walks]
    if not args.attack_source.exists():
        previews('player_walk_pending_attack', {'walk_' + direction: (walks[row], 9, True) for row, direction in enumerate(('down', 'left', 'right', 'up'))}, PLAYER_SIZE)
        fragment('actors', registry)
        if not args.partial:
            raise FileNotFoundError('New matching attack identity sheet is required: ' + str(args.attack_source))
        print('Built new Rowan/guardian; new hero walk reviewed, awaiting matching attack identity source')
        return
    attacks = extract_connected_sheet(args.attack_source, 8, 4)
    # Common scale per complete sheet, then boot alignment. No frame-by-frame
    # resizing and no old sprite is ever mixed into the new identity.
    walk_body_height = statistics.median(body_height(im) for im in all_walks) * scale
    attack_scale = walk_body_height / statistics.median(body_height(im) for row in attacks for im in row)
    attacks = [fit_at_feet(row, PLAYER_SIZE, PLAYER_PIVOT, attack_scale) for row in attacks]
    states = {}
    for row, direction in enumerate(('down', 'left', 'right', 'up')):
        base = walks[row][0]
        states['idle_' + direction] = (hero_idle(base, direction), 5, True)
        states['walk_' + direction] = (walks[row], 9, True)
        # Source index 2 is contact; retain it and add a sheathing/recovery frame.
        states['attack_' + direction] = (attacks[row] + [base.copy()], 9 / .27, False)
        states['hurt_' + direction] = (hurt_frames(base, PLAYER_SIZE, PLAYER_PIVOT), 5 / .22, False)
        states['death_' + direction] = (collapse_frames(base, PLAYER_SIZE, PLAYER_PIVOT), 9 / .9, False)
    register(registry, 'player', states, PLAYER_PIVOT, 'New original ImageGen indigo-coat identity: assets/art_v3/sources/hero_walk.png + assets/art_refresh/sources/hero_attack.png; hardened alpha, common body scale per sheet, full connected blade extraction, boot anchors, local scarf/coat/recoil/collapse motion', contact_frame=2, contact_time=.084, duration=.27)
    bounds['player'] = assert_frame_guards('player', states, PLAYER_PIVOT)
    previews('player', states, PLAYER_SIZE)
    fragment('actors', registry)
    (PREVIEW / 'actors_build.json').write_text(json.dumps({'ids': list(registry), 'walk_common_scale': scale, 'attack_common_scale': attack_scale, 'alpha_threshold': 210, 'renderer': 'Pillow packing only; Godot rendering is run by integration owner'}, indent=2) + '\n')
    (PREVIEW / 'actors_bounds.json').write_text(json.dumps({'ok': True, 'frames_checked': sum(len(frames) for actor in bounds.values() for frames in actor.values()), 'guard': 'No opaque outer border; all opaque bottoms <= ground pivot; every collapse bottom equals pivot; no frame resized during collapse', 'bounds': bounds}, indent=2) + '\n')
    print('Built player, Rowan and guardian from new identities:', sum(sum(s['count'] for s in e['states'].values()) for e in registry.values()), 'frames')


if __name__ == '__main__':
    main()
