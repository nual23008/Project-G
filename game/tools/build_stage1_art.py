#!/usr/bin/env python3
"""Build deterministic, editable pixel-grid assets for the existing playable slice.

Pillow composes integer pixel layers; every shipped frame is rendered from its
saved character grid by the studio's pixel_draw renderer. No runtime generation.
"""
from pathlib import Path
from PIL import Image, ImageDraw
import importlib.util
import json
import math

R = Path(__file__).resolve().parents[1]
A = R / 'assets/art_stage1'
S = A / 'sheets'
G = A / 'grids'
P = A / 'previews'
RES = R / 'resources/art'
TOOL = Path('/home/luan/.codex/plugins/cache/pixel-studio/godot-pixel-studio/0.1.0/scripts/pixel_draw.py')
spec = importlib.util.spec_from_file_location('pixel_draw', TOOL)
pixel_draw = importlib.util.module_from_spec(spec)
spec.loader.exec_module(pixel_draw)
PALETTE = [
    '#332938', '#493543', '#153a3b', '#214c43', '#315b43', '#47704a',
    '#64814e', '#87915c', '#b4bd79', '#614234', '#80513e', '#a57550',
    '#c79b67', '#572f3b', '#793d48', '#a35d59', '#726952', '#938368',
    '#ad9474', '#d0bc91', '#f6e3b0', '#214c58', '#346b70', '#508b87',
    '#80b4a4', '#b6d6b5', '#294453', '#3e667f', '#5b91a1', '#d49b58',
    '#f0bc73', '#ffe2a0', '#b47454', '#dfaf80', '#efd1a5', '#d2ccaa',
    '#8e4b4e', '#c76c61', '#ec9873', '#a5a26b', '#3d2f38', '#795d4c',
    '#b99362', '#e9c58b', '#d6e8c3', '#567c6d', '#203a3e', '#9cba8a',
]
RGBA = [pixel_draw.parse_color(c) for c in PALETTE]
ALPHA = [(12, 24, 29, 96)] + [(240, 188, 115, a) for a in [8, 16, 24, 32, 48, 96]]
SYMBOLS = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@$%^&*()-_=+[]{};<>?,/'
LEGEND = {'.': (0, 0, 0, 0), **dict(zip(SYMBOLS, RGBA + ALPHA))}
M = {}
REVIEW = {}


def blank(w, h):
    return Image.new('RGBA', (w, h))


def original(name):
    return Image.open(R / 'assets/sprites' / (name + '.png')).convert('RGBA')


def nearest(color):
    if color[3] == 0:
        return (0, 0, 0, 0)
    if color[3] < 200:
        return min(ALPHA, key=lambda c: sum((c[i]-color[i])**2 for i in range(4)))
    return min(RGBA, key=lambda c: sum((c[i]-color[i])**2 for i in range(3)))


def grid_render(im, name):
    """Persist a complete editable grid; render it through the installed skill."""
    colors = {c: nearest(c) for c in set(pixel_draw.all_pixels(im))}
    inverse = {v: k for k, v in LEGEND.items()}
    px = im.load()
    rows = [''.join(inverse[colors[px[x, y]]] for x in range(im.width)) for y in range(im.height)]
    used = set(''.join(rows))
    lines = ['name: ' + name, 'legend:']
    lines += [f'  "{c}": "#{col[0]:02x}{col[1]:02x}{col[2]:02x}{col[3]:02x}"'
              for c, col in LEGEND.items() if c in used]
    lines += ['grid:'] + rows
    path = G / (name + '.txt')
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text('\n'.join(lines) + '\n')
    return pixel_draw.render_grid(pixel_draw.parse_spec(path))


def register(name, states, pivot, backend='SpriteFrames', **extra):
    images, meta = [], {}
    for state, (frames, fps, loop) in states.items():
        fs = [grid_render(im, f'{name}/{state}-{i:02}') for i, im in enumerate(frames)]
        meta[state] = {'indices': list(range(len(images), len(images)+len(fs))),
                       'count': len(fs), 'fps': fps, 'loop': loop}
        if len(fs) > 1:
            assert len({im.tobytes() for im in fs}) > 1, (name, state, 'static duplicate animation')
        REVIEW[name + '/' + state] = fs
        images.extend(fs)
    w, h = images[0].size
    cols = min(12, len(images))
    sheet = blank(w*cols, h*math.ceil(len(images)/cols))
    for i, im in enumerate(images):
        assert im.size == (w, h)
        sheet.alpha_composite(im, ((i % cols)*w, (i // cols)*h))
    texture = f'res://assets/art_stage1/sheets/{name}.png'
    sheet.save(S / (name + '.png'))
    write_resource(name, texture, w, h, cols, meta)
    M[name] = {'resource': f'res://resources/art/{name}.tres', 'texture': texture,
               'frame_size': [w, h], 'pivot': pivot, 'columns': cols,
               'states': meta, 'source': 'Original project pixel art; editable grids rendered with pixel_draw.py',
               'backend': backend, **extra}


def write_resource(name, texture, w, h, cols, states):
    lines = ['[gd_resource type="SpriteFrames" load_steps=2 format=3]',
             f'[ext_resource type="Texture2D" path="{texture}" id="sheet"]']
    external = {}
    for s in states.values():
        if 'texture' in s and s['texture'] != texture:
            external[s['texture']] = 'extra' + str(len(external))
    for path, rid in external.items():
        lines.append(f'[ext_resource type="Texture2D" path="{path}" id="{rid}"]')
    refs, animations = {}, []
    for state, data in states.items():
        frame_refs = []
        atlas = data.get('texture', texture)
        columns = data.get('columns', cols)
        for index in data['indices']:
            key = (atlas, index)
            if key not in refs:
                rid = 'f' + str(len(refs))
                refs[key] = rid
                lines += [f'[sub_resource type="AtlasTexture" id="{rid}"]',
                          f'atlas = ExtResource("{external.get(atlas, "sheet")}")',
                          f'region = Rect2({index%columns*w}, {index//columns*h}, {w}, {h})']
            frame_refs.append('{"duration": 1.0, "texture": SubResource("%s")}' % refs[key])
        animations.append('{"name": &"%s", "speed": %.10f, "loop": %s, "frames": [%s]}' %
                          (state, data['fps'], str(data['loop']).lower(), ', '.join(frame_refs)))
    lines[0] = f'[gd_resource type="SpriteFrames" load_steps={2+len(external)+len(refs)} format=3]'
    lines += ['[resource]', 'animations = [\n' + ',\n'.join(animations) + '\n]']
    (RES / (name + '.tres')).write_text('\n'.join(lines) + '\n')


def shade_glint(base, xy, i):
    im = base.copy()
    x, y = xy
    d = ImageDraw.Draw(im)
    tones = ['#ad9474', '#d0bc91', '#f6e3b0', '#d0bc91']
    d.line((x, y, x+2, y), fill=tones[i])
    if i == 2:
        d.point((x+1, y-1), fill=tones[i])
    return im


def props():
    for name in ['pine', 'oak', 'house', 'rock', 'lamp', 'crystal', 'fence', 'sign', 'fern', 'flowers', 'chest', 'portal']:
        base = original(name)
        w, h = base.size
        frames = []
        for i in range(4):
            im = base.copy()
            if name in ['pine', 'oak', 'fern', 'flowers']:
                # Only leaves move. Lower trunk/root/ground shadow stays planted.
                cutoff = {'pine': 72, 'oak': 64, 'fern': 19, 'flowers': 13}[name]
                im = blank(w, h)
                im.alpha_composite(base.crop((0, cutoff, w, h)), (0, cutoff))
                for y in range(cutoff):
                    shift = round(math.sin(i*math.tau/4 + y*.09) * (1-y/h))
                    im.alpha_composite(base.crop((0, y, w, y+1)), (shift, y))
            elif name == 'house':
                # Fixed stone, roof and beams; only chimney smoke and glass light.
                d = ImageDraw.Draw(im)
                for j in range(3):
                    x = 79 + [0, 1, 1, 0][(i+j)%4]
                    y = 7-j*3 - (i % 2)
                    d.line((x, y, x+3+j, y), fill=['#938368', '#ad9474', '#d0bc91', '#ad9474'][(i+j)%4])
                for x in [27, 77]:
                    d.rectangle((x+1, 58, x+4, 60), fill=['#ffe2a0', '#f6e3b0', '#f0bc73', '#d49b58'][i])
            elif name == 'lamp':
                d = ImageDraw.Draw(im)
                d.rectangle((5, 4, 10, 10), fill='#d49b58')
                d.polygon([(6, 10), (5+i%2, 7), (7+i%2, 4+(i+1)%3), (9, 8), (9, 10)], fill='#ffe2a0')
                d.point((8, 6+i%3), fill='#f6e3b0')
            elif name == 'crystal':
                im = shade_glint(base, (22+i*2, 20+i*2), i)
            elif name == 'rock':
                im = shade_glint(base, (13, 11), i)
            elif name == 'fence':
                im = shade_glint(base, (23, 5), i)
            elif name == 'sign':
                im = shade_glint(base, (3, 5), i)
            elif name == 'chest':
                im = shade_glint(base, (10, 8), i)
            elif name == 'portal':
                d = ImageDraw.Draw(im)
                for j in range(4):
                    a = i*math.tau/4+j*math.tau/4
                    x, y = round(16+math.cos(a)*12), round(21+math.sin(a)*7)
                    d.rectangle((x, y, x+1, y+1), fill='#ffe2a0' if j == 0 else '#80b4a4')
            frames.append(im)
        states = {'idle': (frames, 5 if name in ['lamp', 'portal'] else 3, True)}
        if name == 'chest':
            opened = []
            for i in range(6):
                im = base.copy()
                d = ImageDraw.Draw(im)
                d.rectangle((2, 2, 21, 8), fill=(0, 0, 0, 0))
                d.rectangle((3, 7, 20, 10), fill='#332938')
                d.polygon([(2, 7-i), (3, 3-i), (20, 3-i), (21, 7-i)], fill='#a57550')
                d.line((4, 4-i, 19, 4-i), fill='#e9c58b')
                opened.append(im)
            states['open'] = (opened, 15, False)
        pivot = {'house': [56, 88], 'pine': [32, 80], 'oak': [40, 80], 'portal': [16, 24], 'crystal': [24, 56]}.get(name, [w/2, h-4])
        register(name, states, pivot)


def cloth_idle(base, i, elder=False):
    im = base.copy()
    d = ImageDraw.Draw(im)
    # Hand/staff and scarf/robe highlight changes occupy a real local feature.
    if elder:
        d.line((19, 11, 21, 11), fill=['#d49b58', '#f0bc73', '#ffe2a0', '#c79b67'][i])
        if i == 2:
            d.line((10, 11, 11, 11), fill='#b47454')
            d.line((14, 11, 15, 11), fill='#b47454')
    else:
        d.line((7, 16+i%2, 9, 16+i%2), fill=['#d0bc91', '#f6e3b0', '#ad9474', '#d0bc91'][i])
        if i == 2:
            d.line((10, 11, 11, 11), fill='#b47454')
    return im


def actors():
    sheet = original('player')
    states = {}
    for row, direction in enumerate(['down', 'left', 'right', 'up']):
        base = sheet.crop((0, row*32, 24, row*32+32))
        idle = [cloth_idle(base, i) for i in range(4)]
        walk = []
        for i in range(4):
            im = sheet.crop((i*24, row*32, i*24+24, row*32+32))
            ImageDraw.Draw(im).line((6, 18+i%2, 7, 18+i%2), fill=['#5b91a1', '#3e667f', '#d0bc91', '#294453'][i])
            walk.append(im)
        attacks = []
        # A sword begins high on the right; contact index2 points in aim direction.
        angle0 = {'right': 0, 'down': math.pi/2, 'left': math.pi, 'up': -math.pi/2}[direction]
        angles = [-1.1, -.65, 0, .4, .75, .98, 1.12, 1.2, 1.25]
        for i, angle in enumerate(angles):
            im = base.copy()
            d = ImageDraw.Draw(im)
            cx, cy = 12, 18
            a = angle0 + angle
            hand = (round(cx+math.cos(a)*4), round(cy+math.sin(a)*4))
            tip = (max(1, min(22, round(cx+math.cos(a)*13))), max(1, min(30, round(cy+math.sin(a)*13))))
            d.line((cx, cy, *hand), fill='#dfaf80', width=2)
            d.line((*hand, *tip), fill='#f6e3b0', width=2)
            d.point(hand, fill='#c79b67')
            d.line((6, 21, 8+i%3, 21), fill='#3e667f')
            attacks.append(im)
        hurt = []
        for i in range(4):
            im = blank(24, 32)
            im.alpha_composite(base, ([-1, -2, -1, 0][i], 0))
            d = ImageDraw.Draw(im)
            d.line((2+i, 9, 3+i, 7), fill='#ec9873')
            hurt.append(im)
        death = []
        for i in range(6):
            if i < 3:
                im = blank(24, 32)
                im.alpha_composite(base.crop((0, 0, 24, 28)), (i-1, i*2))
            else:
                im = blank(24, 32)
                d = ImageDraw.Draw(im)
                d.ellipse((2, 24, 22, 29), fill=(12, 24, 29, 96))
                settle = i-3
                d.polygon([(3, 24), (6, 22+settle//2), (17, 23), (18, 28), (4, 27)], fill='#294453')
                d.line((5, 24+settle//2, 15, 25), fill='#3e667f', width=3)
                d.ellipse((16, 22+settle//2, 22, 27), fill='#dfaf80')
                d.line((18, 22+settle//2, 21, 23+settle//2), fill='#80513e', width=2)
                d.point((18+settle, 26), fill='#ad9474')
            death.append(im)
        states['idle_'+direction] = (idle, 4, True)
        states['walk_'+direction] = (walk, 8, True)
        states['attack_'+direction] = (attacks, 9/.27, False)
        states['hurt_'+direction] = (hurt, 4/.22, False)
        states['death_'+direction] = (death, 6/.9, False)
    register('player', states, [12, 28], contact_frame=2, contact_time=.084, attack_duration=.27)
    rowan = original('rowan').crop((0, 0, 24, 32))
    register('rowan', {'idle_down': ([cloth_idle(rowan, i, True) for i in range(4)], 3, True)}, [12, 28])

    enemy = original('enemy')
    base = enemy.crop((0, 0, 32, 32))
    states = {}
    for kind in ['idle', 'walk', 'windup', 'attack', 'hurt', 'death']:
        fs = []
        for i in range(8):
            im = base.copy()
            if kind == 'walk':
                im = enemy.crop(((i%4)*32, 0, (i%4)*32+32, 32))
                d = ImageDraw.Draw(im)
                d.line((7+i%3, 26, 10+i%3, 26), fill='#ad9474' if i<4 else '#726952')
            elif kind in ['idle', 'windup']:
                d = ImageDraw.Draw(im)
                brightness = ['#d49b58', '#f0bc73', '#ffe2a0', '#f0bc73'][(i//2)%4]
                d.rectangle((9, 19, 12, 20), fill=brightness)
                d.rectangle((21, 19, 24, 20), fill=brightness)
                d.point((14+i%3, 7+i%2), fill='#b6d6b5')
                if kind == 'windup':
                    d.line((5, 21-i//3, 8, 20-i//3), fill='#a35d59', width=2)
            elif kind == 'attack':
                d = ImageDraw.Draw(im)
                reach = [0, 1, 5, 6, 5, 3, 1, 0][i]
                d.polygon([(22, 15), (29, 17), (31, 18+reach), (25, 22+reach), (21, 21)], fill='#726952')
                d.line((25, 18, 29, 19+reach), fill='#ad9474', width=2)
                d.point((20+i%3, 17), fill='#f0bc73')
            elif kind == 'hurt':
                im = blank(32, 32)
                im.alpha_composite(base, (round(math.sin(i*math.pi/7)*-2), 0))
                d = ImageDraw.Draw(im)
                d.line((2+i, 8, 3+i, 6), fill='#ec9873')
            else:
                im = blank(32, 32)
                d = ImageDraw.Draw(im)
                d.ellipse((3, 24, 29, 30), fill=(12, 24, 29, 96))
                for j in range(5):
                    x = 6+j*4 + round((j-2)*i*.25)
                    y = min(27, 10+j%2*5+i*2)
                    if i < 7 or j%2 == 0:
                        d.polygon([(x, y-3), (x+3, y), (x+1, y+2), (x-2, y+1)], fill='#80b4a4' if j == 2 else '#726952')
            fs.append(im)
        fps = 8/.24 if kind == 'attack' else 8/.42 if kind == 'windup' else 8/.55 if kind == 'death' else 8/.18 if kind == 'hurt' else 8
        states[kind] = (fs, fps, kind in ['idle', 'walk'])
    register('enemy', states, [16, 26])


def items():
    sheet = original('items')
    for i, name in enumerate(['rust_sword', 'potion', 'herb', 'ore', 'echo_shard']):
        base = sheet.crop((i*16, 0, i*16+16, 16))
        fs = []
        # Highlight rides the actual metal/glass/leaf/crystal, not a shared box.
        points = {'rust_sword': (9, 5), 'potion': (7, 7), 'herb': (9, 5), 'ore': (8, 6), 'echo_shard': (8, 5)}
        for j in range(4):
            fs.append(shade_glint(base, points[name], j))
        register(name, {'icon': ([base], 1, False), 'idle': (fs, 4, True)}, [8, 12])


def effects():
    for name, color in [('sword_slash', '#f0bc73'), ('enemy_strike', '#c76c61')]:
        fs = []
        for i in range(8):
            im = blank(72, 72)
            d = ImageDraw.Draw(im)
            # Separate anticipation, sharp contact blade, follow-through and fragments.
            a = [-1.15, -.75, 0, .38, .7, .9, 1.02, 1.12][i]
            outer, inner = 30, [28, 25, 18, 19, 21, 24, 26, 28][i]
            length = [.12, .42, .9, 1.2, 1.2, 1.05, .75, .35][i]
            pts = [(round(36+math.cos(a-length+j*length/9)*outer), round(36+math.sin(a-length+j*length/9)*outer)) for j in range(10)]
            pts += [(round(36+math.cos(a-length+j*length/9)*inner), round(36+math.sin(a-length+j*length/9)*inner)) for j in range(9, -1, -1)]
            d.polygon(pts, fill=color)
            d.line(pts[:10], fill='#ffe2a0' if i < 5 else '#ad9474', width=2 if i<5 else 1)
            if i == 2:
                d.polygon([(41, 34), (66, 35), (69, 36), (65, 38), (42, 38)], fill='#f6e3b0')
            for j in range(max(0, i-2)):
                x, y = 62-i+j, 40+j*3
                d.line((x, y, x+2, y+1), fill='#d49b58')
            fs.append(im)
        register(name, {'play': (fs, 8/.24, False)}, [36, 36], contact_frame=2, contact_time=.084, duration=.24)
    fs = []
    for i in range(8):
        im = blank(32, 32)
        d = ImageDraw.Draw(im)
        for j in range(6):
            a = j*math.tau/6
            r = 2+i*1.5
            x, y = round(16+math.cos(a)*r), round(16+math.sin(a)*r)
            d.line((x, y, x+round(math.cos(a)*(3-i//3)), y+round(math.sin(a)*(3-i//3))), fill='#ffe2a0' if i<4 else '#c79b67')
        fs.append(im)
    register('hit_spark', {'play': (fs, 30, False)}, [16, 16])
    fs = []
    for i in range(8):
        im = blank(72, 72)
        d = ImageDraw.Draw(im)
        for j in range(8):
            a = j*math.tau/8
            x, y = round(36+math.cos(a)*28), round(36+math.sin(a)*16)
            color = '#ec9873' if j <= i else '#793d48'
            d.polygon([(x, y-2), (x+2, y), (x, y+2), (x-2, y)], fill=color)
        fs.append(im)
    register('enemy_telegraph', {'play': (fs, 8/.42, False)}, [36, 36], duration=.42)


def terrain():
    base = Image.open(R / 'assets/tilesets/village.png').convert('RGBA')
    atlas = blank(512, 64)
    water = []
    for phase in range(4):
        im = base.copy()
        # All water variants move their own horizontal ripple bands.
        for variant in range(8):
            tile = blank(16, 16)
            d = ImageDraw.Draw(tile)
            d.rectangle((0, 0, 15, 15), fill='#214c58')
            for band in range(4):
                x = (variant*3 + band*5 + phase*2) % 16
                y = (band*4+variant) % 16
                for off in range(5-band%2):
                    d.point(((x+off)%16, y), fill='#508b87' if band%2 else '#346b70')
                if band == 1:
                    d.point(((x+2)%16, y), fill='#80b4a4')
            im.paste(tile, (variant*16, 32))
            if variant == 0:
                water.append(grid_render(tile, f'water/idle-{phase:02}'))
        atlas.alpha_composite(grid_render(im, f'terrain/atlas-{phase:02}'), (phase*128, 0))
    atlas.save(S / 'terrain.png')
    paths = Image.open(R / 'assets/tilesets/paths.png').convert('RGBA')
    paths = grid_render(paths, 'terrain/paths')
    paths.save(S / 'paths.png')
    texture = 'res://assets/art_stage1/sheets/terrain.png'
    for name, row in [('grass', 0), ('stone_path', 1), ('water', 2), ('shore', 3)]:
        indices = [row*32+phase*8 for phase in range(4)] if name == 'water' else [row*32]
        states = {'idle': {'indices': indices, 'count': len(indices), 'fps': 5 if name == 'water' else 1, 'loop': True}}
        if name == 'stone_path':
            states['edges'] = {'indices': [0], 'count': 1, 'fps': 1, 'loop': True, 'texture': 'res://assets/art_stage1/sheets/paths.png', 'columns': 16}
        write_resource(name, texture, 16, 16, 32, states)
        M[name] = {'resource': f'res://resources/art/{name}.tres', 'texture': texture, 'frame_size': [16, 16], 'pivot': [0, 0], 'columns': 32, 'states': states, 'source': 'Original project terrain, palette matched; water ripple grids by pixel_draw.py', 'backend': 'TileSetAtlasSource'}
        REVIEW[name+'/idle'] = water if name == 'water' else [atlas.crop((0, row*16, 16, row*16+16))]


def ui():
    for name, w, h in [('ui_panel', 48, 48), ('ui_button', 48, 24), ('ui_health', 132, 5)]:
        states = {}
        for state in ['normal', 'hover', 'pressed', 'focus'] if name == 'ui_button' else ['idle']:
            im = blank(w, h)
            d = ImageDraw.Draw(im)
            if name == 'ui_health':
                d.rectangle((0, 0, w-1, h-1), fill='#a35d59')
                d.line((0, 0, w-1, 0), fill='#f0bc73')
                d.line((0, h-1, w-1, h-1), fill='#793d48')
            else:
                if state != 'focus':
                    d.rectangle((0, 0, w-1, h-1), fill='#332938')
                    d.rectangle((2, 2, w-3, h-3), fill='#614234' if state == 'hover' else '#3d2f38' if state == 'pressed' else '#493543')
                d.rectangle((0, 0, w-1, h-1), outline='#f0bc73' if state == 'focus' else '#b99362')
                d.rectangle((2, 2, w-3, h-3), outline='#795d4c')
                d.line((4, 3, w-5, 3), fill='#332938' if state == 'pressed' else '#c79b67')
                for x, y in [(1, 1), (w-4, 1), (1, h-4), (w-4, h-4)]:
                    d.rectangle((x, y, x+2, y+2), fill='#e9c58b')
                if state == 'focus':
                    d.line((5, h-4, w-6, h-4), fill='#ffe2a0')
            states[state] = ([im], 1, True)
        register(name, states, [0, 0], backend='Theme', nine_slice=[5, 5, 5, 5] if name != 'ui_health' else [1, 1, 1, 1])
    fs = []
    for i in range(8):
        im = blank(8, 8)
        d = ImageDraw.Draw(im)
        y = 3 + [0, 0, 1, 1, 0, 0, -1, -1][i]
        d.rectangle((3, y, 4, y+1), fill='#f0bc73' if i%4<2 else '#ffe2a0')
        d.point((2 if i%2 else 5, y), fill='#87915c')
        fs.append(im)
    register('firefly', {'idle': (fs, 6, True)}, [4, 4])
    fs = []
    for i in range(4):
        im = blank(64, 64)
        d = ImageDraw.Draw(im)
        for radius, alpha in [(30, 8), (23, 16), (16, 24), (9, 32)]:
            r = radius + (i%2)
            d.ellipse((32-r, 32-r, 32+r, 32+r), fill=(240, 188, 115, alpha))
        d.ellipse((29, 29, 35, 35), fill=(240, 188, 115, 32+i*16))
        fs.append(im)
    register('glow', {'idle': (fs, 3, True)}, [32, 32])


def previews():
    keys = ['player/walk_down', 'player/attack_right', 'player/death_down', 'rowan/idle_down', 'enemy/attack', 'house/idle', 'oak/idle', 'lamp/idle', 'water/idle', 'sword_slash/play', 'hit_spark/play', 'potion/idle', 'enemy_telegraph/play']
    width = 720
    sheet = Image.new('RGB', (width, len(keys)*120), '#214c43')
    d = ImageDraw.Draw(sheet)
    for row, key in enumerate(keys):
        frames = REVIEW[key]
        d.text((8, row*120+3), key, fill='#ffe2a0')
        for i, im in enumerate(frames):
            scale = 2 if im.width <= 48 else 1
            frame = im.resize((im.width*scale, im.height*scale), Image.Resampling.NEAREST)
            sheet.paste(frame, (8+i*(frame.width+10), row*120+22), frame)
    sheet.save(P / 'contact_sheet.png')
    gif = []
    motion_keys = ['player/walk_down', 'player/attack_right', 'enemy/attack', 'oak/idle', 'house/idle', 'lamp/idle', 'water/idle', 'sword_slash/play', 'potion/idle']
    for tick in range(24):
        im = Image.new('RGB', (600, 420), '#214c43')
        d = ImageDraw.Draw(im)
        for i, key in enumerate(motion_keys):
            fs = REVIEW[key]
            frame = fs[tick % len(fs)]
            frame = frame.resize((frame.width*2, frame.height*2), Image.Resampling.NEAREST)
            x, y = (i%3)*200+100-frame.width//2, (i//3)*140+35
            if frame.height > 110:
                frame = frame.resize((frame.width//2, frame.height//2), Image.Resampling.NEAREST)
                x = (i%3)*200+100-frame.width//2
            im.paste(frame, (x, y), frame)
            d.text(((i%3)*200+8, (i//3)*140+8), key, fill='#ffe2a0')
        gif.append(im)
    gif[0].save(P / 'animation_preview.gif', save_all=True, append_images=gif[1:], duration=100, loop=0, disposal=2)
    # Native timings for the important contact phase are preserved in separate GIFs.
    for key in ['player/attack_right', 'sword_slash/play', 'enemy_strike/play']:
        fs = REVIEW[key]
        out = []
        for i, frame in enumerate(fs):
            im = Image.new('RGB', (288, 320), '#214c43')
            f = frame.resize((frame.width*4, frame.height*4), Image.Resampling.NEAREST)
            im.paste(f, ((288-f.width)//2, 16), f)
            ImageDraw.Draw(im).text((8, 302), f'{key} frame{i}'+(' CONTACT' if i == 2 else ''), fill='#ffe2a0')
            out.append(im)
        out[0].save(P / (key.replace('/', '_')+'.gif'), save_all=True, append_images=out[1:], duration=30, loop=0, disposal=2)


if __name__ == '__main__':
    for folder in [S, G, P, RES]:
        folder.mkdir(parents=True, exist_ok=True)
    (A / 'palette.json').write_text(json.dumps({'opaque': PALETTE, 'alpha': ALPHA, 'light': 'top_left', 'opaque_color_cap': 48}, indent=2)+'\n')
    props()
    actors()
    items()
    effects()
    terrain()
    ui()
    previews()
    (RES / 'manifest.json').write_text(json.dumps(M, ensure_ascii=False, indent=2)+'\n')
    print(f'Built {len(M)} registered asset types, {len(REVIEW)} states, {sum(len(v) for v in REVIEW.values())} editable pixel-grid frames.')
