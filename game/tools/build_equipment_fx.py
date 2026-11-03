"""Eight authored blade phases and impact shards; physics contact remains index2."""
import math,json
from PIL import ImageDraw
from art_refresh_common import BASE,canvas,register,fragment
from build_refresh_props import write_grid


def build():
    registry={}
    for name,empowered in [('sword_slash',False),('empowered_slash',True)]:
        frames=[]
        for i in range(8):
            im=canvas(96,96);d=ImageDraw.Draw(im)
            center=[-1.1,-.62,0,.43,.77,.96,1.13,1.3][i]
            span=[.12,.58,1.65,2.0,1.7,1.25,.82,.25][i]
            fade=[90,170,255,245,205,150,90,35][i]
            colors=[(86,50,65,fade//2),(171,116,79,fade),(240,188,115,fade),(255,239,195,fade)] if not empowered else [(75,44,99,fade//2),(132,91,177,fade),(202,173,238,fade),(248,235,255,fade)]
            for layer in range(4):
                outer=[];inner=[]
                for k in range(31):
                    t=k/30;a=center-span*.68+span*t
                    thickness=(2+10*math.sin(t*math.pi))*(1 if i<5 else .6)
                    radius=34+layer*.7
                    outer.append((round(48+math.cos(a)*radius),round(48+math.sin(a)*radius)))
                    inner.append((round(48+math.cos(a)*(radius-thickness*(1-layer*.2))),round(48+math.sin(a)*(radius-thickness*(1-layer*.2)))))
                d.polygon(outer+inner[::-1],fill=colors[layer])
            if i in [2,3]:
                # Blade-shaped bright core at contact, with separated chipped
                # light fragments rather than a uniformly glowing circular arc.
                d.polygon([(70,46),(86,47),(91,48),(86,49),(70,50),(77,48)],fill=colors[3])
                for k in range(7):
                    a=-1.05+k*.31;r=37+(k%3)
                    x=round(48+math.cos(a)*r);y=round(48+math.sin(a)*r)
                    d.line((x,y,x+round(math.cos(a)*3),y+round(math.sin(a)*3)),fill=colors[2],width=1)
            if i>2:
                for k in range(8):
                    a=center-span*.8-k*.08;r=27+k%4+i
                    x=round(48+math.cos(a)*r);y=round(48+math.sin(a)*r)
                    d.polygon([(x-1,y),(x,y-2),(x+1,y),(x,y+1)],fill=colors[2])
            frames.append(im);write_grid(im,f'equipment_fx/{name}-{i:02}')
        register(registry,name,{'play':(frames,8/.24,False)},(48,48),'Original96px tapered layered blade sweep: distinct anticipation/contact/overshoot/dispersal; copper/cream or violet; native grid sources/equipment_fx; build_equipment_fx.py',contact_frame=2,contact_time=.084,duration=.24)
        strip=canvas(96*8,96)
        for i,im in enumerate(frames):strip.alpha_composite(im,(96*i,0))
        strip.save(BASE/'previews'/f'{name}_equipment_strip.png')
        frames[0].save(BASE/'previews'/f'{name}_equipment.gif',save_all=True,append_images=frames[1:],duration=30,loop=0,disposal=2)
    frames=[]
    for i in range(8):
        im=canvas(48,48);d=ImageDraw.Draw(im)
        for k in range(10):
            angle=k*math.tau/10+.18;r=2+i*1.7
            x=round(24+math.cos(angle)*r);y=round(24+math.sin(angle)*r)
            length=max(1,8-i)
            d.line((x,y,x+round(math.cos(angle)*length),y+round(math.sin(angle)*length)),fill=(255,235,186,255-i*28),width=2 if i<4 else 1)
        if i<4:d.polygon([(24,16+i*2),(27,23),(32-i,24),(26,26),(24,32-i),(22,26),(16+i,24),(22,22)],fill='#fff2ce')
        frames.append(im);write_grid(im,f'equipment_fx/hit_spark-{i:02}')
    register(registry,'hit_spark',{'play':(frames,30,False)},(24,24),'Original48px blade impact flash, asymmetric shards and fading specks; native grid equipment_fx')
    for group,names in [('ui_fx',['sword_slash','hit_spark']),('progression',['empowered_slash'])]:
        current=json.loads((BASE/'manifests'/f'{group}.json').read_text())
        for name in names:current[name]=registry[name]
        fragment(group,current)
