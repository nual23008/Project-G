#!/usr/bin/env python3
"""Fresh carved-brass/plum UI and articulated contact VFX, no legacy art input."""
import math
from PIL import ImageDraw
from art_refresh_common import canvas, register, fragment

M = {}
INK = '#332938'
WOOD = '#614234'
PLUM = '#493543'
BRASS = '#b99362'
GOLD = '#f0bc73'
CREAM = '#f6e3b0'


def panel_frame(w, h, state, phase):
    im = canvas(w, h)
    d = ImageDraw.Draw(im)
    fill = '#55413f' if state == 'hover' else '#352b38' if state == 'pressed' else '#40303c'
    if state == 'focus':
        for x, y, sx, sy in [(0, 0, 1, 1), (w-1, 0, -1, 1), (0, h-1, 1, -1), (w-1, h-1, -1, -1)]:
            d.line((x, y+sy*5, x, y, x+sx*5, y), fill=CREAM, width=1)
        d.point((w//2+phase-2, 0), fill=GOLD)
        return im
    d.rectangle((1, 1, w-2, h-2), fill=INK)
    d.rectangle((3, 3, w-4, h-4), fill=fill)
    d.rectangle((1, 1, w-2, h-2), outline=WOOD)
    d.line((5, 1, w-6, 1), fill=BRASS)
    d.line((5, h-2, w-6, h-2), fill='#866145')
    d.line((1, 5, 1, h-6), fill=BRASS)
    d.line((w-2, 5, w-2, h-6), fill='#866145')
    for x, y, sx, sy in [(2, 2, 1, 1), (w-3, 2, -1, 1), (2, h-3, 1, -1), (w-3, h-3, -1, -1)]:
        d.polygon([(x, y), (x+sx*5, y), (x+sx*2, y+sy*2), (x, y+sy*5)], fill=BRASS)
        d.point((x+sx, y+sy), fill=CREAM)
    # The carved rune remains fixed; only its ember and bevel reflections animate.
    c = w // 2
    d.line((c-3, 2, c, 4, c+3, 2), fill='#795d4c')
    d.point((c, 2), fill=CREAM if phase in [1, 2] else GOLD)
    x = 7 + phase * max(1, (w-18)//5)
    d.line((x, 1, x+2, 1), fill=CREAM)
    return im


def ui():
    register(M, 'ui_panel', {'idle': ([panel_frame(64,64,'normal',i) for i in range(6)], 2, True)},
             (0,0), 'Fresh native carved brass/plum panel with six-frame ember/bevel loop; build_refresh_ui_fx.py', backend='Theme')
    states = {s: ([panel_frame(64,24,s,i) for i in range(6)], 3, True)
              for s in ['normal','hover','pressed','focus']}
    register(M, 'ui_button', states, (0,0), 'Fresh native carved-brass button and consistent state/ambient loops', backend='Theme')
    fs = []
    for i in range(6):
        im = canvas(132,5); d = ImageDraw.Draw(im)
        d.rectangle((0,0,131,4), fill='#783c48')
        d.rectangle((0,1,131,3), fill='#c76c61')
        d.line((0,1,131,1), fill=GOLD)
        d.line((6+i*21,1,10+i*21,1), fill=CREAM)
        fs.append(im)
    register(M,'ui_health',{'idle':(fs,3,True)},(0,0),'Fresh ruby/amber vitality strip; six-frame surface glint',backend='Theme')


def slash(name, color):
    fs = []
    for i in range(8):
        im = canvas(72,72); d = ImageDraw.Draw(im)
        # Frame2 contains the contact silhouette at +X. Anticipation then release.
        center = [-.8,-.42,0,.30,.58,.8,.95,1.08][i]
        span = [.12,.35,.85,1.15,1.05,.86,.54,.22][i]
        outer, inner = [], []
        for n in range(15):
            a = center-span/2+span*n/14
            outer.append((round(36+math.cos(a)*29),round(36+math.sin(a)*29)))
            inner.append((round(36+math.cos(a)*(25-(3 if i in [2,3] else 0))),round(36+math.sin(a)*(25-(3 if i in [2,3] else 0)))))
        d.polygon(outer+inner[::-1],fill=color)
        d.line(outer,fill=CREAM,width=1)
        for k in range(3 if i>1 else 1):
            a=center-span/2-k*.16
            x=round(36+math.cos(a)*(30+k)); y=round(36+math.sin(a)*(30+k))
            d.line((x,y,x+1,y-1),fill=GOLD)
        fs.append(im)
    register(M,name,{'play':(fs,8/.24,False)},(36,36),
             'Fresh native layered blade/contact ribbon; same amber light and plum-outline palette',
             contact_frame=2,contact_time=.084,duration=.24)


def effects():
    slash('sword_slash',GOLD)
    slash('enemy_strike','#ec9873')
    fs = []
    for i in range(8):
        im=canvas(32,32);d=ImageDraw.Draw(im)
        for j in range(6):
            a=j*math.tau/6+.2;r=2+i*1.5
            x=round(16+math.cos(a)*r); y=round(16+math.sin(a)*r)
            d.line((x,y,x+round(math.cos(a)*max(1,4-i//2)),y+round(math.sin(a)*max(1,4-i//2))),fill=CREAM if i<4 else GOLD)
        if i<3:d.polygon([(16,12+i),(19-i,16),(16,20-i),(13+i,16)],fill='#ffe2a0')
        fs.append(im)
    register(M,'hit_spark',{'play':(fs,30,False)},(16,16),'Fresh six-point brass/cream contact shards; no legacy pixels')
    fs=[]
    for i in range(8):
        im=canvas(72,72);d=ImageDraw.Draw(im)
        for j in range(8):
            a=j*math.tau/8; r=21+i//2;x=round(36+math.cos(a)*r);y=round(36+math.sin(a)*r*.5)
            d.polygon([(x,y-2),(x+2,y),(x,y+2),(x-2,y)],fill='#ec9873' if (j+i)%3 else CREAM)
        d.line((34,33,36,31,38,33),fill=GOLD if i%2 else '#a35d59')
        fs.append(im)
    register(M,'enemy_telegraph',{'play':(fs,8/.42,False)},(36,36),'Fresh carved-rune warning glows; eight rising energy frames')


if __name__ == '__main__':
    ui(); effects(); fragment('ui_fx',M)
    print('Built fresh UI/VFX:', ', '.join(M))
