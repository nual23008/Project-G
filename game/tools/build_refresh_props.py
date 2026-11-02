#!/usr/bin/env python3
"""Fresh prop designs and animation; never reads retired game sprite art.

The three large source sprites are project-owned ImageGen source work selected
for this refresh. All other designs are constructed here from new geometry.
"""
from pathlib import Path
from PIL import Image, ImageDraw
import importlib.util
import json
import math

from art_refresh_common import BASE, ROOT, SHEETS, canvas, source, register, fragment

OUT = BASE / 'previews' / 'props'
OUT.mkdir(parents=True, exist_ok=True)
GRIDS = BASE / 'sources' / 'props'
GRIDS.mkdir(parents=True, exist_ok=True)
REGISTRY = {}
FRAMES = {}

# Warm material ramps shared across all constructive assets. The new source
# sprites retain their original rich colour identity; no old sprite is sampled.
C = {
    'ink': '#332938', 'plum': '#4c3544', 'plum_hi': '#795263',
    'wood0': '#3e2a2d', 'wood1': '#614234', 'wood2': '#925446',
    'wood3': '#b57950', 'wood4': '#dbab70',
    'brass0': '#705142', 'brass1': '#ac7949', 'brass2': '#dfaf69', 'brass3': '#ffe0a0',
    'stone0': '#514653', 'stone1': '#7b6c69', 'stone2': '#ad9474',
    'stone3': '#d1ba91', 'stone4': '#f6e3b0',
    'leaf0': '#243d37', 'leaf1': '#3d5941', 'leaf2': '#5f7948',
    'leaf3': '#8b9d54', 'leaf4': '#c0ba6a',
    'crystal0': '#294a55', 'crystal1': '#477e81', 'crystal2': '#85b6a4',
    'crystal3': '#c5e2b5', 'wine0': '#572f3b', 'wine1': '#793d48', 'wine2': '#b66a63',
    'flame0': '#d17b48', 'flame1': '#f0bc73', 'flame2': '#ffe7ae',
    'steel0': '#4b4e60', 'steel1': '#7d8390', 'steel2': '#bdc4ba', 'steel3': '#f2e8c6',
}


def poly(d, points, fill, outline=None):
    d.polygon(points, fill=C.get(fill, fill), outline=C.get(outline, outline))


def line(d, points, fill, width=1):
    d.line(points, fill=C.get(fill, fill), width=width)


def rect(d, box, fill, outline=None):
    d.rectangle(box, fill=C.get(fill, fill), outline=C.get(outline, outline))


def ellipse(d, box, fill, outline=None):
    d.ellipse(box, fill=C.get(fill, fill), outline=C.get(outline, outline))


def shadow(d, box):
    ellipse(d, box, (29, 21, 34, 80))


def record(name, states, pivot, note, **extra):
    FRAMES[name] = states
    register(REGISTRY, name, states, pivot, note, **extra)
    # The newly constructed props are kept as editable character grids too.
    if name not in ['house', 'pine', 'oak']:
        for state, (frames, _, _) in states.items():
            for fi, im in enumerate(frames):
                write_grid(im, f'{name}/{state}-{fi:02}')


def write_grid(im, name):
    colors = sorted(set(im.getdata()))
    colors = [c for c in colors if c[3]]
    symbols = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@$%^&*()-_=+[]{};<>?,/'
    assert len(colors) <= len(symbols), (name, len(colors))
    inverse = {(0, 0, 0, 0): '.', **{color: symbols[i] for i, color in enumerate(colors)}}
    lines = ['name: '+name, 'legend:', '  ".": "transparent"']
    lines += [f'  "{symbols[i]}": "#{c[0]:02x}{c[1]:02x}{c[2]:02x}{c[3]:02x}"' for i, c in enumerate(colors)]
    lines += ['grid:']
    px = im.load()
    lines += [''.join(inverse[px[x, y]] if px[x, y][3] else '.' for x in range(im.width)) for y in range(im.height)]
    path = GRIDS / (name+'.txt')
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text('\n'.join(lines)+'\n')


def large_sources():
    for name, size, pivot in [('house', (144, 128), (72, 124)), ('pine', (80, 112), (40, 108)), ('oak', (104, 112), (52, 108))]:
        base = source(name, size)
        fs = []
        for i in range(8):
            phase = i*math.tau/8
            im = base.copy()
            w, h = size
            if name == 'house':
                # The entire house silhouette and every timber/stone pixel stay
                # planted. Interior amber glass brightens with firelight only.
                px, src = im.load(), base.load()
                for y in range(h//3, h-12):
                    for x in range(w):
                        r, g, b, a = src[x, y]
                        if a and r > 175 and 95 < g < 225 and b < min(r*.62, g*.82):
                            light = round(5*math.sin(phase+x*.24+y*.11))
                            px[x, y] = (min(255, max(0, r+light)), min(255, max(0, g+light)), b, a)
                # Smoke exits the chimney, drifts in three rising curls, then
                # disperses. It is confined to the clear area above the roof.
                d = ImageDraw.Draw(im)
                for j in range(3):
                    yy = 13 - (i+j*3)%11
                    xx = 35+round(math.sin(phase+j*.8)*2)+j
                    ellipse(d, (xx, yy, xx+2+j//2, yy+1+j//2), (190, 165, 139, 90-j*15))
            else:
                # Bend only canopy rows by whole pixels. Root/trunk base is an
                # untouched layer, so every idle frame shares the same foot.
                fixed = 91 if name == 'pine' else 83
                im = canvas(w, h)
                im.alpha_composite(base.crop((0, fixed, w, h)), (0, fixed))
                for y in range(fixed):
                    falloff = (fixed-y)/fixed
                    dx = round(math.sin(phase+y*.045)*falloff*1.15)
                    im.alpha_composite(base.crop((0, y, w, y+1)), (dx, y))
            fs.append(im)
        record(name, {'idle': (fs, 5 if name == 'house' else 4, True)}, pivot,
               f'NEW selected project ImageGen source res://assets/art_v3/sources/{name}.png; nearest fixed-canvas import, material-only ambient animation; no retired sprite seed',
               source_files=[f'res://assets/art_v3/sources/{name}.png', 'res://assets/art_v3/sources/generation.json'],
               ambient_notes='Firelight and chimney smoke; structure fixed' if name == 'house' else 'Canopy wind; root/trunk foot fixed')


def rocks():
    fs = []
    for i in range(8):
        im = canvas(48, 40)
        d = ImageDraw.Draw(im)
        shadow(d, (3, 27, 46, 38))
        poly(d, [(4, 26), (8, 16), (18, 13), (25, 21), (23, 34), (7, 34)], 'stone0', 'ink')
        poly(d, [(6, 25), (10, 18), (18, 16), (19, 25), (11, 28)], 'stone2')
        poly(d, [(14, 24), (17, 9), (30, 4), (40, 12), (44, 28), (33, 35), (21, 33)], 'stone1', 'ink')
        poly(d, [(18, 11), (30, 6), (38, 12), (30, 20), (17, 21)], 'stone3')
        poly(d, [(30, 20), (38, 12), (42, 27), (33, 32)], 'stone2')
        line(d, (19, 12, 29, 8, 33, 10), 'stone4')
        line(d, (23, 14, 28, 18, 25, 23, 32, 28), 'stone0', 2)
        # Mineral vein catches light along a fixed split in the limestone.
        line(d, (24, 14, 29, 18, 26, 23, 33, 27), 'stone3')
        vein = [(24, 14), (26, 16), (29, 18), (27, 20), (26, 23), (28, 24), (31, 26), (33, 27)]
        for j in range(3):
            x, y = vein[(i+j)%8]
            line(d, (x, y, x+1, y+1), 'stone4' if j == 1 else 'stone3')
        for x, y in [(6, 29), (10, 31), (17, 29), (20, 32), (34, 31)]:
            poly(d, [(x-2, y), (x, y-3), (x+3, y-1), (x+2, y+2)], 'leaf1')
            line(d, (x, y-1, x+2, y-2), 'leaf3')
        fs.append(im)
    record('rock', {'idle': (fs, 3, True)}, (24, 36), 'Fresh constructive limestone outcrop with quartz seam and moss; tools/build_refresh_props.py', ambient_notes='Light travels along quartz seam; rigid rock silhouette fixed')


def lamps():
    fs = []
    for i in range(8):
        im = canvas(24, 48)
        d = ImageDraw.Draw(im)
        shadow(d, (3, 40, 23, 46))
        rect(d, (3, 5, 7, 42), 'wood0')
        rect(d, (4, 6, 5, 40), 'wood2')
        line(d, (6, 8, 6, 39), 'wood1')
        poly(d, [(2, 42), (8, 42), (10, 44), (1, 44)], 'brass0')
        line(d, (5, 6, 15, 6, 19, 10, 19, 13), 'ink', 3)
        line(d, (5, 5, 15, 5, 19, 9), 'brass2')
        line(d, (16, 12, 19, 12, 19, 15), 'brass1')
        poly(d, [(12, 17), (16, 14), (21, 17), (22, 19), (11, 19)], 'brass1', 'ink')
        line(d, (12, 17, 16, 15, 20, 17), 'brass3')
        poly(d, [(12, 19), (21, 19), (20, 34), (14, 34)], 'brass0', 'ink')
        poly(d, [(14, 21), (19, 21), (18, 31), (15, 31)], 'flame0')
        # The cage stays fixed; a complete flame deforms within its glass.
        tongue = [0, 1, 2, 1, 0, -1, -2, -1][i]
        poly(d, [(15, 30), (14, 27), (16+tongue//2, 22+i%2), (18, 26), (18, 30)], 'flame1')
        poly(d, [(16, 30), (16, 27), (17+(i%2), 25), (18, 29)], 'flame2')
        line(d, (13, 20, 14, 32, 20, 32, 20, 20), 'brass2')
        line(d, (16, 20, 16, 32), 'brass0')
        poly(d, [(13, 34), (21, 34), (19, 37), (15, 37)], 'brass1', 'ink')
        line(d, (15, 35, 19, 35), 'brass3')
        fs.append(im)
    record('lamp', {'idle': (fs, 8, True)}, (6, 44), 'Fresh constructive walnut post, curved brass hanger and glazed flame lantern; tools/build_refresh_props.py', ambient_notes='Flame moves inside stationary brass cage')


def crystals():
    fs = []
    for i in range(8):
        im = canvas(64, 80)
        d = ImageDraw.Draw(im)
        shadow(d, (3, 63, 61, 77))
        poly(d, [(8, 65), (19, 58), (45, 58), (56, 65), (53, 73), (32, 77), (11, 72)], 'stone0', 'ink')
        poly(d, [(10, 64), (20, 60), (44, 60), (54, 65), (44, 69), (20, 69)], 'stone3', 'stone1')
        poly(d, [(19, 60), (20, 50), (44, 50), (45, 60), (32, 65)], 'stone1', 'ink')
        poly(d, [(20, 52), (32, 56), (43, 52), (42, 60), (32, 64), (21, 60)], 'stone2')
        ellipse(d, (18, 46, 46, 58), 'brass1', 'ink')
        ellipse(d, (22, 48, 42, 54), 'plum')
        line(d, (22, 51, 31, 54, 42, 50), 'brass3')
        poly(d, [(31, 5), (46, 25), (39, 47), (29, 54), (17, 30)], 'crystal0', 'ink')
        poly(d, [(31, 7), (31, 30), (19, 29)], 'crystal2')
        poly(d, [(31, 7), (44, 25), (31, 30)], 'crystal3')
        poly(d, [(31, 30), (44, 25), (38, 46), (29, 52)], 'crystal1')
        poly(d, [(19, 29), (31, 30), (29, 52)], 'crystal0')
        # Light refracts through the inner facet, always within the same crystal.
        tones = ['crystal1', 'crystal1', 'crystal2', 'crystal3', 'crystal3', 'crystal2', 'crystal2', 'crystal1']
        poly(d, [(31, 17), (38, 26), (34, 40), (29, 43), (28, 29)], tones[i])
        line(d, (31, 9, 31, 29, 29, 49), 'crystal3')
        for x, y, facing in [(13, 48, -1), (48, 50, 1)]:
            poly(d, [(x, y-14), (x+facing*7, y-4), (x+facing*4, y+4), (x-3, y+2)], 'crystal1', 'ink')
            line(d, (x, y-12, x+facing*2, y), 'crystal3')
        for j, x in enumerate([18, 27, 36, 45]):
            col = 'brass3' if (i+j)%8 < 2 else 'brass1'
            line(d, (x, 67, x+2, 65, x+3, 68), col)
        fs.append(im)
    record('crystal', {'idle': (fs, 6, True)}, (32, 74), 'Fresh constructive faceted memory crystal on carved limestone/brass plinth; tools/build_refresh_props.py', ambient_notes='Inner crystal refraction and runic light; plinth fixed')


def fences_signs():
    fs = []
    for i in range(8):
        im = canvas(64, 32)
        d = ImageDraw.Draw(im)
        shadow(d, (2, 23, 61, 31))
        for x in [6, 52]:
            poly(d, [(x, 5), (x+3, 2), (x+7, 4), (x+7, 27), (x, 28)], 'wood0', 'ink')
            rect(d, (x+1, 6, x+3, 25), 'wood2')
            line(d, (x+1, 5, x+5, 4), 'wood4')
            for y in [10, 21]:
                rect(d, (x-1, y, x+7, y+2), 'brass0')
                line(d, (x, y, x+6, y), 'brass2')
            line(d, (x+5, 7, x+4, 15, x+5, 23), 'wood1')
        sag = round(math.sin(i*math.tau/8))
        for y in [11, 21]:
            line(d, (12, y, 24, y+2, 34, y+2+sag, 52, y), 'wood0', 3)
            line(d, (12, y-1, 24, y+1, 34, y+1+sag, 52, y-1), 'wood4')
            for x in [20, 28, 36, 44]:
                line(d, (x, y, x+1, y+2), 'brass0')
        # A knotted burgundy cloth tag catches wind independently of the posts.
        tip = round(math.sin(i*math.tau/8)*2)
        poly(d, [(34, 13), (38, 14), (38+tip, 25), (35+tip, 23)], 'wine1', 'wine0')
        line(d, (35, 14, 36+tip, 22), 'wine2')
        fs.append(im)
    record('fence', {'idle': (fs, 4, True)}, (32, 28), 'Fresh constructive carved walnut posts, braided rope and burgundy wind tag; tools/build_refresh_props.py', ambient_notes='Rope and cloth tag sway; posts fixed')

    fs = []
    for i in range(8):
        im = canvas(40, 48)
        d = ImageDraw.Draw(im)
        shadow(d, (10, 40, 32, 46))
        poly(d, [(17, 5), (22, 4), (24, 43), (17, 44)], 'wood0', 'ink')
        line(d, (18, 7, 20, 41), 'wood3', 2)
        poly(d, [(5, 7), (31, 7), (36, 12), (34, 29), (8, 32), (3, 25)], 'wood0', 'ink')
        poly(d, [(6, 9), (30, 9), (33, 13), (31, 26), (9, 29), (6, 24)], 'wood2')
        line(d, (8, 11, 28, 11), 'wood4')
        line(d, (7, 25, 15, 25, 18, 26, 30, 24), 'wood1')
        line(d, (9, 15, 15, 14, 17, 16, 23, 15), 'wood1')
        # Deep carved arrow remains readable without tiny artificial text.
        poly(d, [(11, 18), (23, 17), (22, 13), (30, 20), (22, 25), (23, 21), (11, 22)], 'wood0')
        line(d, (12, 18, 24, 18, 24, 15, 28, 20), 'wood4')
        for x, y in [(7, 11), (30, 12), (9, 26), (30, 24)]:
            rect(d, (x, y, x+1, y+1), 'brass1')
        sway = round(math.sin(i*math.tau/8)*1.5)
        line(d, (6, 25, 4+sway, 34, 7+sway, 40), 'leaf1')
        for x, y, direction in [(5+sway, 29, -1), (5+sway, 34, 1), (7+sway, 38, -1)]:
            poly(d, [(x, y), (x+direction*4, y-3), (x+direction*5, y), (x, y+2)], 'leaf2')
            line(d, (x, y, x+direction*3, y-1), 'leaf3')
        fs.append(im)
    record('sign', {'idle': (fs, 4, True)}, (20, 44), 'Fresh constructive thick carved direction board with brass pins and living ivy; tools/build_refresh_props.py', ambient_notes='Ivy foliage moves; carved sign and post fixed')


def plants():
    fs = []
    for i in range(8):
        im = canvas(32, 40)
        d = ImageDraw.Draw(im)
        shadow(d, (5, 32, 29, 39))
        for j in range(7):
            angle = -2.8+j*.4
            wind = math.sin(i*math.tau/8+j*.35)
            endx = round(16+math.cos(angle)*14+wind)
            endy = round(29+math.sin(angle)*24)
            stem = [(16, 35), (round((16+endx)/2), round((35+endy)/2)-3), (endx, endy)]
            line(d, [v for p in stem for v in p], 'leaf1', 2)
            line(d, [v for p in stem for v in p], 'leaf3')
            for n in range(2, 8):
                t = n/8
                x = round(16+(endx-16)*t)
                y = round(35+(endy-35)*t-3*math.sin(t*math.pi))
                reach = round((1-t)*5)+1
                for sign in [-1, 1]:
                    poly(d, [(x, y), (x+sign*reach, y-3), (x+sign*(reach+1), y-1), (x, y+1)], 'leaf2' if (j+n)%2 else 'leaf1')
                    line(d, (x, y, x+sign*reach, y-2), 'leaf3')
        fs.append(im)
    record('fern', {'idle': (fs, 5, True)}, (16, 36), 'Fresh constructive seven-frond forest fern, branching leaflets and planted root; tools/build_refresh_props.py', ambient_notes='Individual fronds bend in wind with fixed root')

    fs = []
    for i in range(8):
        im = canvas(32, 32)
        d = ImageDraw.Draw(im)
        shadow(d, (2, 23, 30, 30))
        for j, (x, y) in enumerate([(8, 21), (16, 18), (23, 22), (12, 26), (21, 26)]):
            ellipse(d, (x-5, y-4, x+5, y+4), 'leaf0')
            poly(d, [(x-4, y-1), (x, y-5), (x+4, y-2), (x+2, y+1)], 'leaf2')
            line(d, (x-2, y-2, x+2, y-3), 'leaf3')
        for j, (x, y) in enumerate([(7, 14), (16, 9), (24, 16), (15, 22)]):
            dx = round(math.sin(i*math.tau/8+j)*.8)
            line(d, (x, y+8, x+dx, y), 'leaf2')
            x += dx
            for ox, oy in [(0, -2), (-2, 0), (2, 0), (0, 2)]:
                ellipse(d, (x+ox-1, y+oy-1, x+ox+1, y+oy+1), 'stone4')
            rect(d, (x-1, y-1, x+1, y+1), 'brass2')
            d.point((x, y-1), fill=C['flame2'])
        fs.append(im)
    record('flowers', {'idle': (fs, 4, True)}, (16, 28), 'Fresh constructive flowering thyme bush with cream petals and amber hearts; tools/build_refresh_props.py', ambient_notes='Flower heads and stems move in light wind; root fixed')


def chest_frame(open_amount=0, phase=0):
    im = canvas(40, 32)
    d = ImageDraw.Draw(im)
    shadow(d, (2, 23, 38, 31))
    poly(d, [(4, 14), (9, 10), (34, 10), (37, 15), (35, 27), (8, 28), (4, 24)], 'wood0', 'ink')
    poly(d, [(6, 17), (33, 17), (33, 25), (9, 26), (6, 23)], 'wood2')
    line(d, (7, 21, 32, 21), 'wood1')
    line(d, (9, 23, 12, 22, 17, 24, 23, 23, 29, 24), 'wood3')
    for x in [9, 29]:
        rect(d, (x, 15, x+3, 26), 'steel0')
        line(d, (x, 16, x, 25), 'steel1')
        for y in [18, 24]:
            d.point((x+1, y), fill=C['steel2'])
    for x in [5, 33]:
        rect(d, (x, 23, x+3, 27), 'steel0')
        line(d, (x, 23, x+2, 23), 'steel2')
    # Hinged lid moves as a rigid part; the chest body never changes identity.
    lift = round(open_amount*9)
    poly(d, [(5, 14-lift), (7, 7-lift), (12, 4-lift), (30, 4-lift), (35, 9-lift), (35, 16-lift)], 'wood1', 'ink')
    poly(d, [(8, 8-lift), (13, 6-lift), (28, 6-lift), (32, 10-lift), (32, 13-lift), (7, 12-lift)], 'wood3')
    line(d, (9, 8-lift, 29, 8-lift), 'wood4')
    line(d, (7, 13-lift, 32, 14-lift), 'wood0')
    for x in [10, 29]:
        line(d, (x, 6-lift, x-1, 14-lift), 'steel0', 3)
        line(d, (x, 6-lift, x-1, 13-lift), 'steel1')
    if open_amount > .1:
        poly(d, [(7, 14-lift), (33, 15-lift), (32, 17), (7, 17)], 'ink')
        line(d, (8, 16, 31, 16), 'brass2')
    # The front brass clasp reflects a gentle travelling light while waiting.
    rect(d, (18, 12, 23, 20), 'brass0', 'ink')
    rect(d, (19, 13, 22, 18), 'brass1')
    row = 13+phase%5
    line(d, (19, row, 22, row), 'brass3' if phase%4<2 else 'brass2')
    rect(d, (20, 16, 21, 18), 'ink')
    return im


def chests_portals():
    idle = [chest_frame(0, i) for i in range(8)]
    opened = [chest_frame(i/7, i) for i in range(8)]
    record('chest', {'idle': (idle, 4, True), 'open': (opened, 16, False)}, (20, 28), 'Fresh constructive walnut travel chest, forged iron bands, brass lock and hinged lid; tools/build_refresh_props.py', ambient_notes='Brass clasp reflection while closed; separate rigid-lid opening')
    fs = []
    for i in range(8):
        im = canvas(56, 64)
        d = ImageDraw.Draw(im)
        shadow(d, (2, 49, 54, 62))
        # Plinth and carved standing stones form a single new arch design.
        poly(d, [(5, 53), (14, 48), (43, 48), (51, 53), (48, 59), (28, 62), (8, 58)], 'stone0', 'ink')
        poly(d, [(7, 52), (16, 49), (41, 49), (49, 53), (40, 56), (15, 56)], 'stone3')
        for side in [-1, 1]:
            x = 28+side*17
            poly(d, [(x-5, 48), (x-4, 19), (x+side*3, 10), (x+side*8, 15), (x+5, 49)], 'stone1', 'ink')
            line(d, (x-side*2, 21, x-side*3, 43), 'stone3', 2)
            line(d, (x-3, 31, x+4, 30), 'stone0')
            line(d, (x-3, 42, x+4, 41), 'stone0')
        poly(d, [(11, 20), (16, 9), (26, 4), (38, 8), (46, 20), (37, 20), (31, 12), (25, 12), (20, 21)], 'stone2', 'ink')
        line(d, (16, 13, 26, 7, 36, 11), 'stone4')
        poly(d, [(26, 7), (31, 6), (34, 12), (29, 17), (24, 13)], 'brass0', 'ink')
        line(d, (27, 9, 30, 11, 28, 14), 'brass3')
        # A spiral of refracted energy curls inside the stationary arch.
        for band in range(5):
            yy = 21+band*6
            shift = round(math.sin(i*math.tau/8+band*.7)*3)
            line(d, (18+shift, yy, 24, yy-2, 33, yy, 39-shift, yy-2), 'crystal1', 2)
            line(d, (21+shift, yy, 27, yy-1, 33, yy), 'crystal2')
        for j, (x, y) in enumerate([(12, 25), (11, 37), (44, 25), (45, 37), (21, 54), (35, 54)]):
            col = 'crystal3' if (i+j)%8 < 3 else 'brass1'
            line(d, (x, y-2, x-2, y, x, y+2, x+2, y, x, y-2), col)
        fs.append(im)
    record('portal', {'idle': (fs, 7, True)}, (28, 58), 'Fresh constructive limestone runic arch, brass keystone and layered memory current; tools/build_refresh_props.py', ambient_notes='Runes and inner energy flow; arch stone remains rigid')


def sword(i):
    im = canvas(24, 24)
    d = ImageDraw.Draw(im)
    shadow(d, (3, 17, 21, 23))
    poly(d, [(7, 16), (16, 4), (21, 2), (20, 8), (10, 18)], 'steel0', 'ink')
    poly(d, [(8, 15), (17, 5), (20, 3), (19, 7), (9, 17)], 'steel2')
    line(d, (9, 15, 18, 5), 'steel3')
    line(d, (7, 14, 12, 19), 'brass0', 3)
    line(d, (6, 13, 12, 19), 'brass2', 2)
    line(d, (5, 17, 7, 19), 'wood0', 3)
    line(d, (4, 20, 7, 17), 'wine1', 3)
    line(d, (3, 21, 6, 21), 'brass2', 2)
    # Directional steel sheen travels along the actual blade plane.
    x = 10+i
    y = 15-i
    line(d, (x, y, min(20, x+1), y+1), 'steel3')
    return im


def potion(i):
    im = canvas(24, 24)
    d = ImageDraw.Draw(im)
    shadow(d, (4, 18, 21, 23))
    rect(d, (9, 1, 15, 5), 'wood1', 'ink')
    line(d, (10, 2, 14, 2), 'wood4')
    poly(d, [(8, 5), (16, 5), (16, 8), (20, 12), (20, 19), (17, 22), (7, 22), (4, 18), (4, 13), (8, 8)], 'crystal0', 'ink')
    poly(d, [(8, 9), (16, 9), (18, 13), (18, 19), (16, 20), (8, 20), (6, 18), (6, 13)], 'wine0')
    surface = round(math.sin(i*math.tau/8)*1)
    poly(d, [(6, 13+surface), (11, 12), (18, 13-surface), (18, 18), (15, 20), (8, 20), (6, 18)], 'wine1')
    line(d, (7, 13+surface, 11, 12, 17, 13-surface), 'wine2')
    ellipse(d, (10+i%2, 15-i%3, 11+i%2, 16-i%3), 'flame1')
    line(d, (7, 10, 6, 14, 7, 18), 'crystal3')
    line(d, (10, 6, 14, 6), 'crystal2')
    poly(d, [(9, 15), (13, 14), (15, 17), (12, 19), (9, 18)], 'stone4')
    line(d, (11, 16, 13, 17, 11, 18), 'wine1')
    return im


def herb(i):
    im = canvas(24, 24)
    d = ImageDraw.Draw(im)
    shadow(d, (3, 18, 22, 23))
    sway = round(math.sin(i*math.tau/8))
    line(d, (7, 21, 12, 13, 14+sway, 3), 'leaf1', 2)
    line(d, (8, 21, 13, 13, 15+sway, 3), 'leaf3')
    for x, y, sign in [(11, 15, -1), (12, 11, 1), (14+sway, 7, -1), (14+sway, 3, 1)]:
        poly(d, [(x, y), (x+sign*6, y-4), (x+sign*7, y), (x+sign*3, y+2)], 'leaf1', 'leaf0')
        poly(d, [(x, y), (x+sign*5, y-3), (x+sign*3, y+1)], 'leaf3')
        line(d, (x, y, x+sign*5, y-1), 'leaf4')
    line(d, (6, 19, 11, 21), 'wine0', 3)
    line(d, (6, 18, 11, 20), 'wine2')
    return im


def ore(i):
    im = canvas(24, 24)
    d = ImageDraw.Draw(im)
    shadow(d, (2, 17, 23, 23))
    poly(d, [(3, 15), (7, 6), (16, 3), (22, 11), (20, 19), (10, 22), (3, 19)], 'stone0', 'ink')
    poly(d, [(5, 14), (8, 7), (15, 5), (18, 11), (12, 14)], 'stone2')
    poly(d, [(12, 14), (18, 11), (20, 13), (18, 18), (11, 20)], 'stone1')
    line(d, (9, 8, 13, 6, 16, 10, 12, 14, 15, 18), 'brass0', 3)
    line(d, (9, 8, 13, 7, 15, 10, 12, 14, 15, 18), 'brass2')
    vein = [(9, 8), (11, 7), (13, 8), (15, 10), (14, 12), (12, 14), (14, 16), (15, 18)]
    x, y = vein[i]
    line(d, (x, y, x+1, y+1), 'brass3')
    line(d, (5, 17, 8, 18), 'stone3')
    return im


def shard(i):
    im = canvas(24, 24)
    d = ImageDraw.Draw(im)
    shadow(d, (2, 18, 22, 23))
    poly(d, [(12, 1), (21, 9), (16, 20), (7, 22), (3, 12)], 'crystal0', 'ink')
    poly(d, [(12, 3), (12, 12), (5, 12)], 'crystal2')
    poly(d, [(12, 3), (19, 9), (12, 12)], 'crystal3')
    poly(d, [(12, 12), (19, 9), (15, 19), (8, 20)], 'crystal1')
    tone = ['crystal1', 'crystal2', 'crystal2', 'crystal3', 'crystal3', 'crystal2', 'crystal1', 'crystal1'][i]
    poly(d, [(12, 8), (16, 11), (13, 17), (10, 18), (10, 12)], tone)
    line(d, (12, 5, 12, 11, 9, 18), 'crystal3')
    line(d, (7, 14, 8, 10, 10, 12), 'brass2')
    line(d, (15, 15, 17, 13), 'brass3' if i%3 == 0 else 'brass1')
    return im


def items():
    for name, draw in [('rust_sword', sword), ('potion', potion), ('herb', herb), ('ore', ore), ('echo_shard', shard)]:
        fs = [draw(i) for i in range(8)]
        # Icons and pickups share exactly the same design and material animation.
        record(name, {'icon': (fs, 5, True), 'idle': (fs, 5, True)}, (12, 20),
               f'Fresh 24px constructive {name} icon and pickup; new silhouette/material layers in tools/build_refresh_props.py; no old icon pixels',
               ambient_notes={'rust_sword': 'Steel sheen', 'potion': 'Liquid surface and bubbles inside glass', 'herb': 'Leaves bend at stem', 'ore': 'Ore-vein reflection', 'echo_shard': 'Internal crystal refraction'}[name])


def preview():
    names = list(FRAMES)
    im = Image.new('RGB', (960, 640), '#293a35')
    d = ImageDraw.Draw(im)
    for n, name in enumerate(names):
        frame = FRAMES[name]['idle'][0][0]
        # Prop scale is 1:1 except small objects shown 2:1 for the visual board.
        scale = 2 if frame.width < 65 and frame.height < 90 else 1
        frame = frame.resize((frame.width*scale, frame.height*scale), Image.Resampling.NEAREST)
        x, y = n%6*160+80-frame.width//2, n//6*200+36
        im.paste(frame, (x, y), frame)
        d.text((n%6*160+10, n//6*200+10), name, fill='#f6e3b0')
    im.save(OUT/'new_props_board.png')
    strips = Image.new('RGB', (1152, 392), '#293a35')
    d = ImageDraw.Draw(strips)
    for row, name in enumerate(['house', 'pine', 'oak']):
        frames = FRAMES[name]['idle'][0]
        for i, frame in enumerate(frames):
            strips.paste(frame, (i*144, row*128+8), frame)
        d.text((4, row*128), name+' — NEW SOURCE', fill='#f6e3b0')
    strips.save(OUT/'source_animation_strips.png')
    motion = []
    for tick in range(16):
        pic = Image.new('RGB', (960, 640), '#293a35')
        d = ImageDraw.Draw(pic)
        for n, name in enumerate(names):
            frame = FRAMES[name]['idle'][0][tick%8]
            scale = 2 if frame.width < 65 and frame.height < 90 else 1
            frame = frame.resize((frame.width*scale, frame.height*scale), Image.Resampling.NEAREST)
            x, y = n%6*160+80-frame.width//2, n//6*200+36
            pic.paste(frame, (x, y), frame)
            d.text((n%6*160+10, n//6*200+10), name, fill='#f6e3b0')
        motion.append(pic)
    motion[0].save(OUT/'new_props_motion.gif', save_all=True, append_images=motion[1:], duration=170, loop=0, disposal=2)
    for name in ['house', 'pine', 'oak', 'chest']:
        frames, fps, _ = FRAMES[name]['idle']
        out = []
        for frame in frames:
            bg = Image.new('RGB', frame.size, '#293a35')
            bg.paste(frame, (0, 0), frame)
            out.append(bg.resize((bg.width*3, bg.height*3), Image.Resampling.NEAREST))
        out[0].save(OUT/(name+'_idle.gif'), save_all=True, append_images=out[1:], duration=round(1000/fps), loop=0, disposal=2)


if __name__ == '__main__':
    (BASE/'sources'/'props_brief.txt').write_text('''Fresh prop refresh brief\nsubject: village and forest props and five inventory icons\nrole: replace all retired prop designs while preserving gameplay IDs/collision\ncanvas: house144x128 pine80x112 oak104x112; other props24–80px, items24x24\npalette: amber, walnut, burgundy, plum, cream, olive, pale crystal; light top-left\nblock: 1 logical pixel, hard edges, no smoothing\nmust read as: distinct authored materials and silhouettes, clearly different from retired sprites\nstates: every object idle8frame loop; chest open8; item icon8 matched to idle8\ndeliverable: SpriteFrames+PNG, manifest fragment, geometry source+editable grids, visual boards+GIF\nprocess: selected NEW ImageGen house/pine/oak sources; all other art constructive fresh geometry\ngate: source identity, same size/pivot across states, real distinct idle frames, anchored rigid parts\nreport: root performs Godot import, runtime idle, interaction and regression renders\n''')
    large_sources()
    rocks()
    lamps()
    crystals()
    fences_signs()
    plants()
    chests_portals()
    items()
    fragment('props', REGISTRY)
    preview()
    print('Fresh props:', len(REGISTRY), 'types;', sum(len(s) for s in FRAMES.values()), 'states;', sum(len(st[0]) for states in FRAMES.values() for st in states.values()), 'state frames')
