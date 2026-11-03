#!/usr/bin/env python3
"""Material-specific movement/foliage motion in the active fantasy palette."""
from PIL import ImageDraw
from art_refresh_common import BASE, canvas, register, fragment
from build_refresh_props import write_grid


def main():
    registry = {}
    dust = []
    for i in range(8):
        im = canvas(24,16)
        d = ImageDraw.Draw(im)
        for j in range(5):
            side = -1 if j%2 else 1
            x = 11 + side*(2+j//2+i//2)
            y = 11 - min(7,i*(j%3+1)//3)
            radius = 1 if i < 4 else 0
            alpha = max(0,170-i*20)
            d.ellipse((x-radius,y-radius,x+radius+1,y+radius),fill=(173,148,116,alpha))
            if i < 5:
                d.point((x,y-1),fill=(208,188,145,alpha))
        dust.append(im)
        write_grid(im,f'footstep_dust/play-{i:02}')
    register(registry,'footstep_dust',{'play':(dust,24,False)},(12,12),
             'Original native ochre/stone dust clusters; build_polish_art.py; editable grids in sources/props/footstep_dust. Eight dispersal drawings; no collision or save state.')
    leaves = []
    for i in range(8):
        im = canvas(16,16)
        d = ImageDraw.Draw(im)
        turn = [0,1,2,1,0,-1,-2,-1][i]
        d.polygon([(4,7),(7,3),(11,5+turn),(10,9),(6,11)],fill='#b99362' if i < 4 else '#8b9d54',outline='#3d5941')
        d.line((5,10,8,7,10,5+turn),fill='#d0bc91')
        d.line((8,7,6,6),fill='#87915c')
        leaves.append(im)
        write_grid(im,f'falling_leaf/idle-{i:02}')
    register(registry,'falling_leaf',{'idle':(leaves,8,True)},(8,8),
             'Original native olive/amber tumbling leaf; build_polish_art.py; editable eight-frame grid source; upper-left warm highlights.')
    for name,entry in registry.items():
        frames = dust if name == 'footstep_dust' else leaves
        bg = canvas(frames[0].width*len(frames),frames[0].height)
        for index,im in enumerate(frames): bg.alpha_composite(im,(index*im.width,0))
        bg.resize((bg.width*4,bg.height*4)).save(BASE/'previews'/f'{name}_strip.png')
        frames[0].save(BASE/'previews'/f'{name}.gif',save_all=True,append_images=frames[1:],duration=42 if name == 'footstep_dust' else 125,loop=0,disposal=2)
    fragment('polish',registry)
    print('Built footstep dust and eight-frame tumbling foliage')


if __name__ == '__main__':
    main()
