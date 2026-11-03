"""Native, joint-authored character layers. No colour-mask body segmentation.

Every cel is drawn from named anatomical anchors. Overlapping neck, shoulder,
waist, wrist and ankle joins belong to the base; clothes cover those joins.
The preserved directional face/hair is the identity reference, never a source
of fragments of sleeves, weapons or legs.
"""
import math
from PIL import Image, ImageDraw
from art_refresh_common import canvas

INK = '#332938'
SKIN = '#dca477'
SKIN_SHADE = '#b77e60'
SKIN_LIGHT = '#f5cd9a'
DXY = {'down':(0,1),'up':(0,-1),'left':(-1,0),'right':(1,0),
       'down_right':(.707,.707),'down_left':(-.707,.707),
       'up_right':(.707,-.707),'up_left':(-.707,-.707)}
PARTS = ['bare_hands','hat','shirt','pants','shoe_left','shoe_right','necklace',
         'bracelet_left','bracelet_right','glove_left','glove_right','weapon_left','weapon_right']
ANCHORS = {}


def point(x,y):
    return round(x),round(y)


def segment(draw,a,b,width,colour,lit=None):
    """A solid connected limb with a continuous dark silhouette."""
    draw.line((*a,*b),fill=INK,width=width+2)
    r=width//2
    for x,y in [a,b]:draw.ellipse((x-r-1,y-r-1,x+r+1,y+r+1),fill=INK)
    draw.line((*a,*b),fill=colour,width=width)
    for x,y in [a,b]:draw.ellipse((x-r,y-r,x+r,y+r),fill=colour)
    if lit:draw.line((a[0]-1,a[1],b[0]-1,b[1]),fill=lit,width=1)


def pose(direction,state,index):
    dx,dy=DXY[direction];lx=dy if dy else .40;ly=-dx*.42
    breath=int(index in [3,4,5]) if state=='idle' else 0
    bounce=[0,-1,-1,0,-1,-1][index] if state=='walk' else 0
    recoil=[-1,-2,-1,0,0][index] if state=='hurt' else 0
    cx=48+round(dx*recoil);cy=bounce+round(dy*recoil)
    joints={'head':(cx,8+cy),'neck':(cx,27+cy),'hip':(cx,45+cy),'breath':breath}
    for side,sign in [('left',1),('right',-1)]:
        stride=[0,3,3,0,-3,-3][index]*sign if state=='walk' else 0
        shoulder=point(cx+sign*7*lx,32+cy+sign*ly*2)
        hand=point(cx+sign*10*lx-dx*stride*.6,41+cy+sign*ly*2-dy*stride*.45)
        elbow=point((shoulder[0]+hand[0])/2+sign*(1+breath),37+cy)
        foot=point(48+sign*4*lx+dx*stride,58+sign*ly*2-dy*stride*.35)
        # The sole stays planted during idle; the ankle and knee absorb breath.
        ankle=(foot[0]+sign*breath,foot[1]-4)
        knee=point(cx+sign*4*lx+dx*stride*.4+sign*breath,50+cy-dy*stride*.2)
        if state=='attack':
            reach=[0,5,11,9,6,3,1,0,0][index]
            if index==1:hand=point(cx+sign*6*lx-dx*5,27+cy-dy*3)
            elif index in [2,3,4,5,6]:hand=point(cx+sign*4*lx+dx*reach,36+cy+dy*reach*.55+sign*ly)
            elbow=point((shoulder[0]+hand[0])/2+sign*2, (shoulder[1]+hand[1])/2+2)
        joints[side]={'shoulder':shoulder,'elbow':elbow,'hand':hand,
                      'knee':knee,'ankle':ankle,'foot':foot}
    return joints


def head_image(reference,hx,ht):
    image=reference.crop((hx-15,ht,hx+16,ht+19)).copy()
    # Preserve actual identity clusters and remove detached source specks.
    pixels=image.load();points={(x,y) for y in range(image.height) for x in range(image.width) if pixels[x,y][3]>=180}
    components=[]
    while points:
        todo=[points.pop()];group=set(todo)
        while todo:
            x,y=todo.pop()
            for nx,ny in [(x+a,y+b) for a in [-1,0,1] for b in [-1,0,1]]:
                if (nx,ny) in points:points.remove((nx,ny));group.add((nx,ny));todo.append((nx,ny))
        components.append(group)
    keep=max(components,key=len)
    for y in range(image.height):
        for x in range(image.width):
            r,g,b,a=pixels[x,y];pixels[x,y]=(r,g,b,255) if (x,y) in keep else (0,0,0,0)
    return image


def draw_layers(direction,state,index,head,contacts):
    p=pose(direction,state,index);cx,hy=p['head'];ny=p['neck'][1];hip=p['hip'];breath=p['breath']
    images={name:canvas(96,64) for name in ['base']+PARTS}
    b=ImageDraw.Draw(images['base']);shirt=ImageDraw.Draw(images['shirt']);pants=ImageDraw.Draw(images['pants'])
    # Base anatomy: continuous neck -> torso -> covered pelvis -> both legs.
    b.rectangle((cx-3,hy+14,cx+3,ny+7),fill=SKIN_SHADE)
    b.rectangle((cx-2,hy+14,cx+2,ny+6),fill=SKIN)
    for side,sign in [('left',1),('right',-1)]:
        j=p[side];root=(hip[0]+sign*3,hip[1]-1)
        segment(b,root,j['knee'],5,SKIN,SKIN_LIGHT)
        segment(b,j['knee'],j['ankle'],4,SKIN,SKIN_LIGHT)
        fx,fy=j['foot'];ax,ay=j['ankle']
        segment(b,j['ankle'],j['foot'],4,SKIN,SKIN_LIGHT)
        b.ellipse((fx-3,fy-1,fx+3,fy+1),fill=SKIN_SHADE)
        b.line((fx-2,fy,fx+2,fy),fill=SKIN_LIGHT)
        # Pants overlap the covered hips and both boot shafts by >=2 pixels.
        segment(pants,root,j['knee'],6,'#8a7c70','#bca98c')
        segment(pants,j['knee'],j['ankle'],5,'#8a7c70','#bca98c')
        pants.line((j['knee'][0]-2,j['knee'][1],j['knee'][0]+1,j['knee'][1]+1),fill='#615553')
        boot=ImageDraw.Draw(images['shoe_'+side]);toe=2 if DXY[direction][0]>=0 else -2
        boot.polygon([(ax-3,ay-2),(ax+3,ay-2),(fx+3,fy-1),(fx+toe+2,fy),(fx+toe+2,fy+1),(fx-3,fy+1),(fx-3,fy-2)],fill='#614234',outline=INK)
        boot.line((ax-2,ay-1,ax+2,ay-1),fill='#b99362')
        boot.line((fx-2,fy,fx+toe+1,fy),fill='#925446')
    w=6+breath;top=ny+2;bottom=hip[1]+1
    b.polygon([(cx-5,top),(cx-7,top+4),(cx-w,bottom),(cx+w,bottom),(cx+7,top+4),(cx+5,top)],fill='#bca98c',outline=INK)
    b.line((cx-4,top+3,cx-4,bottom-3),fill='#e4d3ac')
    b.line((cx+4,top+4,cx+4,bottom-3),fill='#8e7c69')
    b.line((cx-3,top+1,cx,top+4,cx+3,top+1),fill='#f0dfb8')
    b.polygon([(cx-6,hip[1]-2),(cx+6,hip[1]-2),(cx+6,hip[1]+4),(cx+1,hip[1]+4),(cx,hip[1]+1),(cx-1,hip[1]+4),(cx-6,hip[1]+4)],fill='#796958',outline=INK)
    b.line((cx-5,hip[1]-1,cx+5,hip[1]-1),fill='#bca98c')
    pants.rectangle((cx-6,hip[1]-3,cx+6,hip[1]+1),fill='#8a7c70',outline=INK)
    pants.line((cx-5,hip[1]-2,cx+5,hip[1]-2),fill='#b99362')
    # Sleeves are authored from the very same shoulder/elbow joints as the skin.
    for side,sign in [('left',1),('right',-1)]:
        j=p[side];s,e,h=j['shoulder'],j['elbow'],j['hand']
        segment(b,s,e,5,SKIN,SKIN_LIGHT);segment(b,e,h,4,SKIN,SKIN_LIGHT)
        segment(shirt,s,e,7,'#363c61','#646184')
        cuff=point(e[0]+(h[0]-e[0])*.35,e[1]+(h[1]-e[1])*.35)
        segment(shirt,e,cuff,5,'#363c61','#646184')
        hand=ImageDraw.Draw(images['bare_hands']);x,y=h
        hand.ellipse((x-2,y-2,x+2,y+2),fill=SKIN_SHADE)
        hand.ellipse((x-2,y-2,x+1,y+1),fill=SKIN)
        hand.line((x-1,y-1,x+1,y-1),fill=SKIN_LIGHT)
        hand.line((x+sign*2,y,x+sign*3,y+breath),fill=SKIN)
        b.ellipse((x-2,y-2,x+2,y+2),fill=SKIN)
        glove=ImageDraw.Draw(images['glove_'+side])
        glove.ellipse((x-3,y-3,x+3,y+2),fill='#614234',outline=INK)
        glove.line((x-2,y-2,x+1,y-2),fill='#b57950',width=2)
        glove.line((x+sign*2,y,x+sign*3,y+breath),fill='#b57950',width=2)
        # Bracelet follows the angle of the forearm; no wandering highlight dot.
        wx,wy=point(h[0]*.75+e[0]*.25,h[1]*.75+e[1]*.25)
        vx,vy=h[0]-e[0],h[1]-e[1];length=max(1,math.hypot(vx,vy))
        a=point(wx-vy/length*3,wy+vx/length*3);z=point(wx+vy/length*3,wy-vx/length*3)
        bracelet=ImageDraw.Draw(images['bracelet_'+side]);bracelet.line((*a,*z),fill=INK,width=3);bracelet.line((*a,*z),fill='#dfaf69',width=2)
        # Each rigid blade rotates about its actual grip, never random pixels.
        rest=math.atan2(.94,sign*.34)
        if state=='attack':
            angle=math.atan2(DXY[direction][1],DXY[direction][0])+[0,-1.7,0,.45,.8,.6,.35,.15,0][index]
            if index in [0,8]:angle=rest
            elif index in [6,7]:angle+=((rest-angle+math.pi)%math.tau-math.pi)*(.45 if index==6 else .8)
        else:angle=rest+(.045*breath if state=='idle' else .025*math.sin(index))
        tip=point(x+math.cos(angle)*18,y+math.sin(angle)*18)
        if state=='attack' and index==2:contacts.setdefault(direction,{})['weapon_'+side]=[tip[0]-48,tip[1]-60]
        weapon=ImageDraw.Draw(images['weapon_'+side]);weapon.line((x,y,*tip),fill=INK,width=4)
        weapon.line((x,y,*tip),fill='#7d8390',width=3);weapon.line((x,y-1,tip[0],tip[1]-1),fill='#f2e8c6')
        weapon.line((x-2,y-2,x+2,y+2),fill='#dfaf69',width=2)
        weapon.line((x,y,x-round(math.cos(angle)*3),y-round(math.sin(angle)*3)),fill='#614234',width=2)
    # Detailed coat/scarf/satchel are native cels, not cut from the old hero.
    shirt.polygon([(cx-6,top),(cx-8,top+4),(cx-7-breath,bottom+1),(cx+7+breath,bottom+1),(cx+8,top+4),(cx+6,top)],fill='#363c61',outline=INK)
    shirt.polygon([(cx-6,top+2),(cx-3,top+3),(cx-3,bottom),(cx-6-breath,bottom)],fill='#646184')
    shirt.line((cx+5,top+4,cx+5,bottom-1),fill='#24283f')
    shirt.line((cx,top+4,cx,bottom-2),fill='#b99362')
    shirt.rectangle((cx-7-breath,bottom-4,cx+7+breath,bottom-2),fill='#614234',outline=INK)
    shirt.rectangle((cx-1,bottom-4,cx+2,bottom-2),fill='#dfaf69')
    shirt.polygon([(cx-5,top-1),(cx+5,top-1),(cx+4,top+3),(cx,top+4),(cx-5,top+2)],fill='#9b4950',outline='#613340')
    shirt.line((cx-4,top,cx+3,top),fill='#d48462')
    shirt.polygon([(cx+2,top+3),(cx+4,top+3),(cx+3+breath,top+10),(cx+1,top+9)],fill='#9b4950')
    shirt.line((cx-5,top+4,cx+5,bottom-3),fill='#925446',width=2)
    shirt.rectangle((cx+3,bottom-5,cx+8,bottom),fill='#614234',outline=INK)
    shirt.line((cx+4,bottom-4,cx+7,bottom-4),fill='#b99362')
    images['base'].alpha_composite(head,(cx-15,hy))
    # The hat's feather flexes at its stem; the brim/head origin remains fixed.
    hat=ImageDraw.Draw(images['hat'])
    hat.polygon([(cx-9,hy+5),(cx-6,hy+1),(cx+5,hy+1),(cx+9,hy+6)],fill='#793d48',outline=INK)
    hat.line((cx-10,hy+6,cx+9,hy+6),fill='#dfaf69',width=2)
    hat.line((cx+5,hy+3,cx+8+breath,hy-1),fill='#b99362',width=2)
    necklace=ImageDraw.Draw(images['necklace']);swing=breath
    necklace.line((cx-4,top,cx-2,top+4,cx+swing,top+6,cx+3,top+3,cx+4,top),fill='#ac7949')
    necklace.polygon([(cx+swing,top+4),(cx+2+swing,top+6),(cx+swing,top+8),(cx-2+swing,top+6)],fill='#f0bc73',outline='#705142')
    ANCHORS[state+'_'+direction+'_'+str(index)]=p
    return images


def collapse(layers,index):
    """One common full-body transform: no split/cut at the waist."""
    angle=[0,8,18,30,44,58,70,80,88][index]
    scratch={}
    for name,frame in layers.items():
        full=canvas(224,192);full.alpha_composite(frame,(64,64))
        scratch[name]=full.rotate(angle,Image.Resampling.NEAREST,center=(112,110))
    composite=canvas(224,192)
    for frame in scratch.values():composite.alpha_composite(frame)
    box=composite.getbbox();left=round((box[0]+box[2])/2)-48;top=box[3]-60
    return {name:frame.crop((left,top,left+96,top+64)) for name,frame in scratch.items()}
