#!/usr/bin/env python3
"""Native XP/vital/stat artwork matching the active brass/plum pixel set."""
from pathlib import Path
from PIL import ImageDraw
import importlib.util
import math
import string
from art_refresh_common import BASE, canvas, register, fragment
from build_refresh_ui_fx import panel_frame

TOOL = Path('/home/luan/.codex/plugins/cache/pixel-studio/godot-pixel-studio/0.1.0/scripts/pixel_draw.py')
spec = importlib.util.spec_from_file_location('pixel_draw', TOOL)
pixel_draw = importlib.util.module_from_spec(spec)
spec.loader.exec_module(pixel_draw)
M = {}


def grid(im, name):
    colors = sorted(set(im.get_flattened_data() if hasattr(im, 'get_flattened_data') else im.getdata()))
    chars = string.ascii_letters + string.digits + '!@$%^&*()-_=+[]{};<>?,/'
    colors = [c for c in colors if c[3] != 0]
    legend = {c: chars[i] for i,c in enumerate(colors)}
    rows = [''.join(legend.get(im.getpixel((x,y)),'.') for x in range(im.width)) for y in range(im.height)]
    lines = ['name: ' + name, 'legend:', '  ".": "#00000000"']
    lines += [f'  "{letter}": "#{c[0]:02x}{c[1]:02x}{c[2]:02x}{c[3]:02x}"' for c,letter in legend.items()]
    lines += ['grid:'] + rows
    p=BASE/'grids/progression'/ (name+'.txt');p.parent.mkdir(parents=True,exist_ok=True)
    p.write_text('\n'.join(lines)+'\n')
    return pixel_draw.render_grid(pixel_draw.parse_spec(p))


def orb():
    idle=[];collect=[]
    for i in range(8):
        im=canvas(16,20);d=ImageDraw.Draw(im);dy=round(math.sin(i*math.tau/8))
        d.ellipse((3,15,13,18),fill=(51,41,56,96))
        d.polygon([(8,2+dy),(12,6+dy),(11,11+dy),(8,14+dy),(4,10+dy),(3,6+dy)],fill='#493543')
        d.polygon([(8,3+dy),(11,6+dy),(10,10+dy),(8,13+dy),(5,9+dy),(4,6+dy)],fill='#805bad')
        d.polygon([(8,3+dy),(8,8+dy),(4,6+dy)],fill='#d3bde9')
        d.polygon([(8,8+dy),(11,6+dy),(10,10+dy)],fill='#f0bc73')
        x=round(8+math.cos(i*math.tau/8)*6);y=round(9+math.sin(i*math.tau/8)*4)
        d.point((x,y),fill='#f6e3b0');d.line((7,5+dy,7,7+dy),fill='#f6e3b0')
        idle.append(grid(im,f'experience_orb_idle_{i}'))
        part=canvas(16,20);pd=ImageDraw.Draw(part)
        for j in range(4):
            a=j*math.tau/4+i*.12;r=2+i*.8;x=round(8+math.cos(a)*r);y=round(10-i*.6+math.sin(a)*r)
            pd.line((x,y,x+1,y),fill='#f6e3b0' if i<4 else '#a980cc')
        collect.append(grid(part,f'experience_orb_collect_{i}'))
    register(M,'experience_orb',{'idle':(idle,8,True),'collect':(collect,24,False)},(8,16),'Original native faceted XP crystal, editable pixel grids; plum/gold identity and eight phase float/facet loop')


def bars():
    for name,dark,mid,lit in [('ui_experience','#4a365d','#9570b8','#e0c2ee'),('ui_energy','#214c58','#508b87','#b6d6b5'),('ui_stamina','#4a5537','#87915c','#e1d89c')]:
        fs=[]
        for i in range(6):
            im=canvas(132,5);d=ImageDraw.Draw(im);d.rectangle((0,0,131,4),fill=dark);d.rectangle((0,1,131,3),fill=mid);d.line((0,1,131,1),fill=lit)
            x=5+i*21;d.line((x,1,x+4,1),fill='#f6e3b0');d.point((x+2,2),fill=lit)
            fs.append(grid(im,f'{name}_{i}'))
        register(M,name,{'idle':(fs,3,True)},(0,0),'Original native animated vital strip; matches existing brass/plum HUD; editable pixel grids',backend='Theme')
    fs=[]
    for i in range(6):
        im=panel_frame(64,64,'normal',i);d=ImageDraw.Draw(im)
        # A dedicated violet inlay identifies the stat board within the same UI family.
        for x,y in [(3,3),(60,3),(3,60),(60,60)]:
            d.polygon([(x,y-2),(x+2,y),(x,y+2),(x-2,y)],fill='#9570b8')
            d.point((x,y),fill='#f6e3b0' if i in [1,2] else '#d3bde9')
        fs.append(grid(im,f'ui_stats_panel_{i}'))
    register(M,'ui_stats_panel',{'idle':(fs,2,True)},(0,0),'Dedicated animated stat board skin built from the same carved-brass/plum design as existing UI',backend='Theme')


def effects():
    fs=[]
    for i in range(12):
        im=canvas(96,96);d=ImageDraw.Draw(im);r=12+i*2
        for j in range(8):
            a=j*math.tau/8;x=round(48+math.cos(a)*r);y=round(66+math.sin(a)*r*.3-i*2)
            d.polygon([(x,y-2),(x+2,y),(x,y+2),(x-2,y)],fill='#f6e3b0' if i<7 else '#b99362')
        if i<9:d.line((45,45-i*3,48,41-i*3,51,45-i*3),fill='#f0bc73',width=2)
        fs.append(grid(im,f'level_up_{i}'))
    register(M,'level_up',{'play':(fs,20,False)},(48,48),'Original ascending rune/amber motes for level-up; no character rescaling')
    fs=[]
    for i in range(8):
        im=canvas(72,72);d=ImageDraw.Draw(im);a=[-.8,-.42,0,.3,.58,.8,.95,1.08][i];span=[.12,.35,.85,1.15,1.05,.86,.54,.22][i]
        outer=[];inner=[]
        for n in range(15):
            angle=a-span/2+span*n/14;outer.append((round(36+math.cos(angle)*29),round(36+math.sin(angle)*29)));inner.append((round(36+math.cos(angle)*24),round(36+math.sin(angle)*24)))
        d.polygon(outer+inner[::-1],fill='#a980cc');d.line(outer,fill='#f6e3b0')
        if i in [1,2,3,4]:
            for layer,tone in enumerate(['#6a4b81','#c7a4e3','#fff0c9']):
                points=[]
                for k in range(13):
                    angle=a-span*.6+span*k/12;r=23-layer*2+round(k/4)
                    points.append((round(36+math.cos(angle)*r),round(36+math.sin(angle)*r)))
                d.line(points,fill=tone,width=2 if layer == 0 else 1)
        if i in [2,3]:
            d.polygon([(62,35),(68,30),(65,36),(68,41),(61,37)],fill='#fff0c9')
        for j in range(3):
            angle=a-.2-j*.15;x=round(36+math.cos(angle)*31);y=round(36+math.sin(angle)*31);d.point((x,y),fill='#f0bc73')
        fs.append(grid(im,f'empowered_slash_{i}'))
    register(M,'empowered_slash',{'play':(fs,8/.24,False)},(36,36),'Empowered state of the existing blade ribbon: identical curve/canvas/pivot/contact; violet energy and warm cream highlight',contact_frame=2,contact_time=.084,duration=.24)


if __name__=='__main__':
    orb();bars();effects();fragment('progression',M)
    print('Built',len(M),'animated progression resources')
