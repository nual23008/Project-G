#!/usr/bin/env python3
"""Original deterministic pixel art. Pillow is build-time only; no downloaded art."""
from pathlib import Path
from PIL import Image, ImageDraw
import random
import shutil

ROOT = Path(__file__).resolve().parents[1]
rng = random.Random(2207)


def canvas(w, h):
    im = Image.new('RGBA', (w, h))
    return im, ImageDraw.Draw(im)


def save(im, path):
    target = ROOT / path
    target.parent.mkdir(parents=True, exist_ok=True)
    im.save(target)


def tiles():
    atlas, _ = canvas(128, 64)
    for idx in range(32):
        im, d = canvas(16, 16)
        if idx < 8:
            d.rectangle((0, 0, 15, 15), fill='#315745')
            for _ in range(14):
                x, y = rng.randrange(16), rng.randrange(16)
                d.line((x, y, x+1, y), fill=rng.choice(['#365e48', '#3d6249', '#294d42', '#426b4d']))
            for _ in range(3):
                x, y = rng.randrange(14), rng.randrange(13)
                d.line((x, y+2, x+1, y), fill='#58734d')
        elif idx < 16:
            d.rectangle((0, 0, 15, 15), fill='#78765b')
            for yy in (0, 8):
                offset = (yy//8 * 7 + idx*3) % 10 - 6
                for xx in range(offset, 16, 10):
                    d.rectangle((xx, yy, xx+8, yy+6), fill=rng.choice(['#9c9672', '#a59c77', '#918b6b', '#b0a17c']))
                    d.line((xx+1, yy+1, xx+7, yy+1), fill='#b3ad83')
                    d.point((xx+2, yy+5), fill='#7b8261')
            for _ in range(9):
                x, y = rng.randrange(16), rng.randrange(16)
                if rng.random() < .6:
                    d.rectangle((x, y, x+1, y+1), fill='#627953')
        elif idx < 24:
            d.rectangle((0, 0, 15, 15), fill='#1b444d')
            for _ in range(7):
                x, y = rng.randrange(16), rng.randrange(16)
                d.line((x, y, x+rng.randrange(2, 6), y), fill=rng.choice(['#255965', '#347478', '#28535b']))
            d.line((idx % 10, 5, idx % 10+4, 5), fill='#548f87')
        else:
            d.rectangle((0, 0, 15, 15), fill='#4a6048')
            for _ in range(55):
                x, y = rng.randrange(16), rng.randrange(16)
                d.point((x, y), fill=rng.choice(['#506a4c', '#536d50', '#395542', '#827958']))
        atlas.alpha_composite(im, ((idx % 8)*16, (idx//8)*16))
    save(atlas, 'assets/tilesets/village.png')
    transitions, _ = canvas(256, 64)
    for variation in range(4):
        for mask in range(16):
            tile = atlas.crop((variation*16, 16, variation*16+16, 32))
            grass = atlas.crop((variation*16, 0, variation*16+16, 16))
            for bit in (1, 2, 4, 8):
                if mask & bit:
                    continue
                for along in range(16):
                    depth = 1 + (along*3+variation+bit) % 3
                    for cross in range(depth):
                        px, py = ((cross, along) if bit == 1 else (15-cross, along) if bit == 2 else (along, cross) if bit == 4 else (along, 15-cross))
                        tile.putpixel((px, py), grass.getpixel((px, py)))
            transitions.alpha_composite(tile, (mask*16, variation*16))
    save(transitions, 'assets/tilesets/paths.png')


def pine():
    im, d = canvas(64, 88)
    d.ellipse((12, 73, 55, 85), fill=(8, 28, 33, 110))
    d.rectangle((28, 58, 35, 80), fill='#363e37')
    d.line((30, 58, 30, 77), fill='#68654b', width=2)
    for cy, half, tall in [(73, 29, 29), (59, 25, 29), (45, 20, 28), (31, 15, 26), (19, 9, 19)]:
        d.polygon([(32, cy-tall), (32+half, cy-1), (32+half-6, cy+3), (32, cy-1), (32-half+5, cy+4), (32-half, cy)], fill='#102f3c')
        d.polygon([(31, cy-tall+2), (31+half-6, cy-3), (29, cy-7), (32-half+6, cy)], fill='#1d4b4b')
        d.line((31, cy-tall+4, 24-half//2, cy-6), fill='#407160', width=2)
        for _ in range(20):
            x = rng.randrange(32-half+4, 32+half-3)
            y = rng.randrange(cy-12, cy)
            if abs(x-32) < (y-(cy-tall))*half/tall:
                d.line((x, y, x+2, y), fill=rng.choice(['#2d6257', '#356957', '#4e7b60', '#194143']))
    save(im, 'assets/sprites/pine.png')


def oak():
    im, d = canvas(80, 88)
    d.ellipse((12, 71, 71, 86), fill=(8, 28, 33, 110))
    d.polygon([(33, 78), (38, 45), (27, 27), (33, 25), (45, 44), (54, 24), (59, 28), (47, 54), (48, 78), (58, 82), (41, 80), (29, 84)], fill='#3b493c')
    d.line((39, 74, 42, 44, 32, 29), fill='#7c7250', width=3)
    d.line((47, 58, 55, 34), fill='#615f45', width=2)
    for x, y, r in [(20, 34, 19), (52, 30, 23), (34, 18, 22), (30, 42, 24), (60, 42, 17)]:
        d.ellipse((x-r, y-r//2, x+r, y+r), fill='#193e3d')
        d.ellipse((x-r+2, y-r//2, x+r-3, y+r-7), fill='#2d5645')
        for _ in range(55):
            px, py = rng.randrange(max(0, x-r+3), min(80, x+r-2)), rng.randrange(max(0, y-r//2), y+r-5)
            if (px-x)**2+(py-y)**2 < (r-2)**2:
                d.rectangle((px, py, px+3, py+1), fill=rng.choice(['#406647', '#57784e', '#65834e', '#254e42', '#305d46']))
    save(im, 'assets/sprites/oak.png')


def house():
    im, d = canvas(112, 96)
    d.ellipse((7, 79, 108, 95), fill=(7, 24, 30, 110))
    d.rectangle((17, 40, 95, 86), fill='#b1a17a')
    d.rectangle((18, 82, 96, 88), fill='#67715a')
    for y in range(45, 82, 9):
        d.line((18, y, 94, y), fill='#8a8667')
        for x in range(23 + (y % 2)*9, 95, 18):
            d.line((x, y, x, y+8), fill='#8a8667')
    d.rectangle((47, 58, 66, 86), fill='#384638')
    d.rectangle((50, 61, 64, 85), fill='#5d6044')
    for x in (51, 56, 61):
        d.line((x, 62, x, 84), fill='#82744b')
    d.point((62, 74), fill='#e4c27d')
    for x in (26, 76):
        d.rectangle((x-2, 55, x+14, 73), fill='#55563d')
        d.rectangle((x, 57, x+12, 69), fill='#e6bb70')
        d.rectangle((x+2, 58, x+5, 62), fill='#ffe0a1')
        d.line((x+6, 57, x+6, 69), fill='#6d6a46')
        d.line((x, 63, x+12, 63), fill='#6d6a46')
        d.rectangle((x-3, 72, x+15, 75), fill='#425d42')
        for xx in range(x-2, x+15, 3):
            d.point((xx, 71), fill='#b19d6c')
    d.rectangle((76, 8, 87, 31), fill='#7a7761')
    d.polygon([(8, 44), (25, 15), (84, 15), (105, 44), (102, 51), (7, 51)], fill='#343f39')
    d.polygon([(9, 43), (26, 13), (83, 13), (104, 43)], fill='#825b4c')
    for y in range(16, 45, 5):
        left = 25-(y-14)//2
        right = 84+(y-14)//2
        d.line((left, y, right, y), fill='#b17d5a')
        for x in range(left+4+(y%3)*2, right, 9):
            d.line((x, y+1, x-1, y+4), fill='#614c45')
    d.line((25, 12, 83, 12), fill='#cf9e6b', width=2)
    for _ in range(35):
        x, y = rng.randrange(13, 99), rng.randrange(38, 48)
        d.rectangle((x, y, x+3, y+2), fill=rng.choice(['#52664a', '#6b784b']))
    d.rectangle((45, 87, 69, 89), fill='#c1b18a')
    d.rectangle((42, 90, 72, 92), fill='#7f8567')
    save(im, 'assets/sprites/house.png')


def props():
    im, d = canvas(48, 64)
    d.ellipse((3, 47, 45, 61), fill=(7, 23, 29, 100))
    d.ellipse((4, 44, 43, 57), fill='#4e655b')
    d.ellipse((7, 41, 40, 51), fill='#83947a')
    d.rectangle((18, 32, 29, 46), fill='#526c62')
    d.polygon([(24, 5), (35, 21), (29, 37), (22, 41), (12, 22)], fill='#54a698')
    d.polygon([(24, 5), (24, 25), (35, 21)], fill='#d6e7aa')
    d.polygon([(24, 25), (22, 41), (12, 22)], fill='#378581')
    d.polygon([(24, 25), (35, 21), (29, 37)], fill='#88d4ae')
    d.line((24, 7, 24, 24, 22, 38), fill='#e9ebbd')
    save(im, 'assets/sprites/crystal.png')
    im, d = canvas(32, 32)
    d.ellipse((1, 21, 31, 30), fill=(6, 24, 28, 90))
    d.polygon([(3, 22), (4, 13), (14, 8), (24, 11), (30, 24), (22, 28), (7, 27)], fill='#4e635e')
    d.polygon([(4, 13), (14, 8), (24, 11), (19, 18), (8, 20)], fill='#819081')
    d.line((10, 12, 15, 10, 21, 12), fill='#a0aa8c', width=2)
    d.rectangle((4, 22, 14, 24), fill='#456b48')
    d.rectangle((8, 20, 18, 21), fill='#68854f')
    save(im, 'assets/sprites/rock.png')
    im, d = canvas(16, 32)
    d.ellipse((1, 26, 15, 31), fill=(5, 24, 28, 80))
    d.rectangle((7, 10, 9, 28), fill='#6a6347')
    d.rectangle((3, 3, 12, 13), fill='#485749')
    d.rectangle((4, 4, 11, 11), fill='#f0c880')
    d.rectangle((6, 5, 9, 9), fill='#fff0b1')
    d.rectangle((3, 1, 12, 3), fill='#9e9670')
    d.line((5, 14, 11, 14), fill='#a99c6d')
    save(im, 'assets/sprites/lamp.png')
    im, d = canvas(32, 32)
    d.rectangle((14, 13, 17, 30), fill='#7c7551')
    d.rectangle((1, 3, 30, 18), fill='#424f3c')
    d.rectangle((2, 4, 29, 15), fill='#a49367')
    d.line((5, 8, 24, 8), fill='#505b41', width=2)
    d.line((22, 6, 26, 9, 22, 12), fill='#505b41')
    save(im, 'assets/sprites/sign.png')
    im, d = canvas(16, 16)
    for x, y in [(3, 12), (8, 8), (12, 13)]:
        d.line((x, y, x, y-5), fill='#5c8151')
        d.rectangle((x-1, y-6, x+1, y-4), fill='#c2b87b')
        d.point((x, y-5), fill='#f0d29a')
    save(im, 'assets/sprites/flowers.png')
    im, d = canvas(16, 24)
    for direction in (-1, 1):
        for height in range(4, 17, 3):
            x = 8 + direction * (18-height)//3
            d.line((8, 21, x, height), fill='#426c4a')
            d.line((x, height, x+direction*3, height-1), fill='#75904e')
            d.line((x, height+2, x+direction*2, height+1), fill='#557f48')
    d.line((8, 21, 8, 7), fill='#8a9a59')
    save(im, 'assets/sprites/fern.png')
    im, d = canvas(48, 16)
    for x in (3, 23, 43):
        d.rectangle((x, 1, x+3, 15), fill='#6b7452')
        d.line((x, 1, x+3, 1), fill='#a1a078')
    d.rectangle((3, 5, 46, 7), fill='#96936a')
    d.rectangle((3, 10, 46, 12), fill='#6b7452')
    save(im, 'assets/sprites/fence.png')


def actor(name, elder=False):
    sheet, _ = canvas(24*4, 32*4)
    for direction in range(4):
        for frame in range(4):
            im, d = canvas(24, 32)
            step = [0, 1, 0, -1][frame]
            d.ellipse((4, 25, 20, 30), fill=(4, 20, 27, 100))
            d.rectangle((8+step, 24, 10+step, 28), fill='#293b41')
            d.rectangle((14-step, 24, 16-step, 28), fill='#293b41')
            d.rectangle((8+step, 28, 11+step, 29), fill='#9b8561')
            d.rectangle((14-step, 28, 17-step, 29), fill='#9b8561')
            outline = '#193f4b' if not elder else '#4c453d'
            coat = '#337d9e' if not elder else '#ad9562'
            highlight = '#55a6bb' if not elder else '#d0b47a'
            d.polygon([(7, 13), (16, 13), (19, 25), (15, 27), (5, 25)], fill=outline)
            d.polygon([(8, 14), (15, 14), (17, 24), (13, 26), (6, 24)], fill=coat)
            d.line((8, 16, 7, 23), fill=highlight, width=2)
            d.rectangle((7, 7, 16, 14), fill='#e2bc88')
            d.rectangle((8, 6, 15, 7), fill='#765e48' if not elder else '#d4ccaa')
            if not elder:
                d.polygon([(6, 10), (7, 5), (12, 3), (16, 6), (18, 12), (15, 10), (13, 8), (9, 9), (7, 13)], fill='#306b89')
                d.line((8, 6, 12, 4, 15, 7), fill='#5aa2b3')
                d.rectangle((15, 18, 18, 23), fill='#ad9065')
                d.point((16, 19), fill='#9bddc1')
            else:
                d.rectangle((6, 7, 8, 15), fill='#d4ccaa')
                d.rectangle((15, 7, 17, 15), fill='#d4ccaa')
                d.polygon([(8, 14), (16, 14), (13, 20), (10, 19)], fill='#ded6b0')
                d.line((21, 12, 20, 28), fill='#927e52', width=2)
                d.rectangle((19, 9, 22, 12), fill='#e3c783')
            if direction == 0:
                d.point((10, 11), fill='#3d4140')
                d.point((14, 11), fill='#3d4140')
            elif direction == 3:
                d.rectangle((8, 8, 15, 13), fill='#326c87' if not elder else '#c2bb9d')
                d.line((9, 15, 14, 15), fill=highlight)
            else:
                eye = 8 if direction == 1 else 15
                d.point((eye, 11), fill='#3d4140')
                d.rectangle((14 if direction == 1 else 7, 9, 16 if direction == 1 else 9, 13), fill='#326c87' if not elder else '#c2bb9d')
            sheet.alpha_composite(im, (frame*24, direction*32))
    save(sheet, f'assets/sprites/{name}.png')
    lines = ['[gd_resource type="SpriteFrames" load_steps=18 format=3]', '', f'[ext_resource type="Texture2D" path="res://assets/sprites/{name}.png" id="1"]', '']
    for y in range(4):
        for x in range(4):
            lines += [f'[sub_resource type="AtlasTexture" id="F{y}_{x}"]', 'atlas = ExtResource("1")', f'region = Rect2({x*24}, {y*32}, 24, 32)', '']
    lines += ['[resource]', 'animations = [']
    anims = []
    for y, direction in enumerate(['down', 'left', 'right', 'up']):
        for kind in ['idle', 'walk']:
            frames = [0] if kind == 'idle' else [0, 1, 2, 3]
            fs = ', '.join('{"duration": 1.0, "texture": SubResource("F%d_%d")}' % (y, x) for x in frames)
            anims.append('{"frames": [%s], "loop": true, "name": &"%s_%s", "speed": 8.0}' % (fs, kind, direction))
    lines += [',\n'.join(anims), ']']
    (ROOT / f'resources/{name}_frames.tres').write_text('\n'.join(lines)+'\n')


if __name__ == '__main__':
    for folder in ['scenes/main', 'scenes/player', 'scenes/world', 'scenes/npc', 'scenes/enemies', 'scenes/items', 'scenes/ui', 'scenes/effects', 'scripts/core', 'scripts/player', 'scripts/world', 'scripts/combat', 'scripts/dialogue', 'scripts/quests', 'scripts/inventory', 'scripts/save', 'scripts/ui', 'resources/items', 'resources/quests', 'resources/dialogue', 'resources/enemies', 'resources/world', 'assets/audio', 'assets/fonts', 'tests/output']:
        (ROOT / folder).mkdir(parents=True, exist_ok=True)
    tiles(); pine(); oak(); house(); props()
    actor('player'); actor('rowan', True)
    if not (ROOT / 'assets/fonts/NotoSans-Regular.ttf').exists():
        shutil.copyfile('/usr/share/fonts/truetype/noto/NotoSans-Regular.ttf', ROOT / 'assets/fonts/NotoSans-Regular.ttf')
    print('Generated original tiles, blended paths, 11 props and two 4-direction sprite sheets.')
