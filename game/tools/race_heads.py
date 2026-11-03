"""Native directional race identities, authored on the same 96x64 actor grid.
No resize/recolour of the human sheet. Hair/beard appendages have their own cels.
"""
from PIL import ImageDraw
from art_refresh_common import canvas
INK='#332938'
RAMPS={
 'elf': ('#e7bd92','#b48776','#f6dbb0','#878b9a','#d0ccc2','#eee5d1'),
 'dwarf': ('#c68d63','#935747','#e4b87c','#693b33','#a36b3c','#dda65a'),
 'orc': ('#74945b','#425c45','#a2b87a','#252836','#41423b','#6b6250'),
}


def head(race,direction):
    im=canvas(39,18);d=ImageDraw.Draw(im);cx=19
    skin,shade,lit,dark,hair,hl=RAMPS[race]
    back=direction.startswith('up');profile=direction in ['left','right']
    dx=-1 if 'left' in direction else 1 if 'right' in direction else 0
    half={'elf':8,'dwarf':10,'orc':11}[race]
    # Solid jaw silhouette and ears overlap, with banded, opaque material ramps.
    d.polygon([(cx-half+2,3),(cx+half-2,3),(cx+half,7),(cx+half-1,12),(cx+5,16),(cx-5,16),(cx-half+1,12),(cx-half,7)],fill=skin,outline=INK)
    d.polygon([(cx+half-3,6),(cx+half-1,8),(cx+half-2,12),(cx+4,15),(cx-3,15),(cx-4,13),(cx+3,13)],fill=shade)
    d.polygon([(cx-half+2,6),(cx+1,6),(cx+1,11),(cx-3,13),(cx-half+3,11)],fill=lit)
    if race=='elf':
        for sign in [-1,1]:
            tip=cx+sign*(17 if not profile else (17 if sign==-dx else 10))
            d.polygon([(cx+sign*7,7),(tip,3),(cx+sign*12,11),(cx+sign*7,12)],fill=skin,outline=INK)
            d.line((cx+sign*9,8,tip-sign*2,5),fill=shade)
        d.polygon([(cx-8,3),(cx-5,0),(cx+4,0),(cx+9,4),(cx+8,9),(cx+5,6),(cx+1,4),(cx-2,7),(cx-5,6),(cx-7,12),(cx-9,10)],fill=hair,outline=dark)
        d.line((cx-6,3,cx-2,1,cx+3,1),fill=hl,width=2)
        d.line((cx+5,2,cx+8,6),fill=hl)
    elif race=='dwarf':
        for sign in [-1,1]:d.rectangle((cx+sign*9-1,7,cx+sign*9+1,11),fill=skin)
        d.polygon([(cx-10,7),(cx-10,3),(cx-6,0),(cx+6,0),(cx+10,3),(cx+10,8),(cx+7,9),(cx+6,5),(cx-5,4),(cx-7,9)],fill=hair,outline=dark)
        d.line((cx-7,3,cx-3,1,cx+3,1),fill=hl,width=2)
        d.line((cx+7,3,cx+8,6),fill=dark,width=2)
    else:
        d.polygon([(cx-12,7),(cx-15,5),(cx-13,11),(cx-10,12)],fill=skin,outline=INK)
        d.polygon([(cx+12,7),(cx+15,5),(cx+13,11),(cx+10,12)],fill=shade,outline=INK)
        d.polygon([(cx-10,5),(cx-8,1),(cx-2,1),(cx,0),(cx+5,1),(cx+9,4),(cx+9,7),(cx+5,5),(cx-4,4),(cx-8,7)],fill=hair,outline=dark)
        d.line((cx-7,3,cx-2,2,cx+3,2),fill=hl)
    if back:
        # Full occiput, nape and rear ear contours, never eyes or tusks.
        d.polygon([(cx-half+1,5),(cx+half-1,5),(cx+half-2,12),(cx+5,15),(cx-5,15),(cx-half+2,12)],fill=hair,outline=dark)
        for off in [-4,1,5]: d.line((cx+off,5,cx+off-1,11),fill=hl if off==-4 else dark)
        d.line((cx-3,14,cx+3,14),fill=dark)
    else:
        face=cx+dx*3
        d.line((face-3,12,face+1,12),fill=lit)
        eyes=[face+dx*3] if profile else [face-4,face+4]
        for ex in eyes:
            d.line((ex-1,8,ex+1,8),fill=INK,width=2)
            d.point((ex,9),fill='#5a8667' if race=='elf' else '#dbab70' if race=='orc' else '#332938')
            d.line((ex-2,6,ex+1,6),fill=dark)
        if profile:
            d.polygon([(face+dx*5,9),(face+dx*8,11),(face+dx*5,12)],fill=skin)
            d.point((face+dx*7,11),fill=lit)
        else:d.line((face,9,face-1,11,face+1,11),fill=shade)
        d.line((face-2,14,face+2,14),fill='#613340' if race!='orc' else '#425c45')
        if race=='orc':
            for sign in ([-dx] if profile else [-1,1]):
                x=face+sign*5
                d.polygon([(x-1,14),(x,10),(x+2,14)],fill='#e6d8ae',outline='#a9906a')
    return im


def heritage(race,direction,p):
    im=canvas(96,64);d=ImageDraw.Draw(im);cx,hy=p['head'];ny=p['neck'][1];b=p['breath']
    back=direction.startswith('up');profile=direction in ['left','right']
    dx=-1 if 'left' in direction else 1 if 'right' in direction else 0
    skin,shade,lit,dark,hair,hl=RAMPS[race]
    if race=='elf':
        # Two weighted braids rooted at the temples/nape. End bends during breath.
        signs=[-1,1] if not profile else [-dx]
        for sign in signs:
            x=cx+sign*(6 if back else 7)
            d.line((x,hy+11,x+sign,ny+8,x+sign*(1+b),ny+12),fill=dark,width=4)
            d.line((x-1,hy+12,x,ny+8,x+sign*b,ny+11),fill=hair,width=2)
            for y in range(hy+14,ny+10,3):d.line((x-1,y,x+1,y+1),fill=hl)
            d.line((x-1+sign*b,ny+10,x+2+sign*b,ny+10),fill='#b99362')
    elif race=='dwarf':
        if back:
            # True back view: short occipital hair only. No front beard, chin
            # cone or long nape braid on the neck. Tiny attached side locks flex.
            d.polygon([(cx-8,hy+8),(cx+8,hy+8),(cx+7,hy+15),
                       (cx+5,hy+16),(cx-5,hy+16),(cx-7,hy+15)],fill=hair)
            d.line((cx-5,hy+9,cx-5,hy+14,cx-4-b,hy+15),fill=hl,width=2)
            d.line((cx+4,hy+10,cx+4,hy+14,cx+5+b,hy+15),fill=dark,width=2)

        else:
            # Continuous cheek -> sideburn -> jaw -> beard silhouette. The
            # roots overlap the temple hair, never a separate outlined U under
            # the face. Only the weighted braided tip bends during breathing.
            x=cx+dx*3
            if profile:
                front=x+dx*8;rear=x-dx*5
                d.polygon([(rear,hy+6),(rear-dx*2,hy+7),(rear-dx,hy+15),
                           (x-dx*3,hy+22),(x+dx*(2+b),hy+27),
                           (x+dx*(5+b),hy+26),(front,hy+19),(front,hy+12),
                           (x+dx*5,hy+12),(x+dx*3,hy+15),(rear,hy+13)],fill=hair)
                d.line((rear,hy+7,rear,hy+14,x,hy+22,x+dx*(3+b),hy+25),fill=hl,width=2)
                d.line((front,hy+15,front-dx,hy+20,x+dx*(5+b),hy+25),fill=dark)
                tip=x+dx*(3+b)
            else:
                d.polygon([(x-9,hy+6),(x-7,hy+7),(x-7,hy+12),(x-3,hy+14),
                           (x,hy+13),(x+3,hy+14),(x+7,hy+11),(x+7,hy+7),
                           (x+9,hy+6),(x+9,hy+17),(x+6,hy+23),
                           (x+2+b,hy+27),(x-2+b,hy+27),(x-7,hy+23),(x-9,hy+16)],fill=hair)
                d.line((x-8,hy+8,x-7,hy+17,x-4,hy+23,x+b,hy+25),fill=hl,width=2)
                d.line((x+7,hy+9,x+7,hy+17,x+3,hy+23),fill=dark,width=2)
                # Moustache joins both cheek roots around a small mouth opening.
                d.line((x-6,hy+12,x-2,hy+11,x,hy+12,x+2,hy+11,x+6,hy+12),fill=hair,width=2)
                d.line((x-2,hy+13,x+2,hy+13),fill=dark)
                tip=x+b
            d.line((tip-2,hy+25,tip+2,hy+25),fill='#dfaf69',width=2)

    else:
        x=cx+dx*3
        if back:
            d.polygon([(cx-4,hy+12),(cx+4,hy+12),(cx+3,ny+3),(cx+b,ny+6),(cx-2+b,ny+5)],fill=hair,outline=dark)
            d.line((cx-1,hy+14,cx-1,ny+2,cx+b,ny+4),fill=hl)
        else:
            d.polygon([(x-3,hy+15),(x+3,hy+15),(x+2,ny+3),(x+b,ny+5),(x-2+b,ny+4)],fill=hair,outline=dark)
            d.line((x-1,hy+16,x+b,ny+3),fill=hl)
        d.line((x-1+b if not back else cx-1+b,ny+3,x+1+b if not back else cx+1+b,ny+3),fill='#b99362')
    return im
