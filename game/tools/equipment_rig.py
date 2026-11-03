"""Native, joint-authored character layers. No colour-mask body segmentation.

Every cel is drawn from named anatomical anchors. Overlapping neck, shoulder,
waist, wrist and ankle joins belong to the base; clothes cover those joins.
The preserved directional face/hair is the identity reference, never a source
of fragments of sleeves, weapons or legs.
"""
import math
from PIL import Image, ImageDraw
from art_refresh_common import canvas
from race_heads import heritage

INK = '#332938'
SKIN = '#dca477'
SKIN_SHADE = '#b77e60'
SKIN_LIGHT = '#f5cd9a'
# Fixed ramps preserve the reference's hair/eye placement and warm materials,
# removing hundreds of antialiased intermediate colours from the native head.
HEAD_PALETTE = ['#332938','#4b2b31','#693b33','#845135','#a36b3c','#c08b49',
                '#dda65a','#f0c576','#b77e60','#dca477','#f5cd9a','#f6e3b0',
                '#2c2330','#9b4950','#613340','#925446']
DXY = {'down':(0,1),'up':(0,-1),'left':(-1,0),'right':(1,0),
       'down_right':(.707,.707),'down_left':(-.707,.707),
       'up_right':(.707,-.707),'up_left':(-.707,-.707)}
PARTS = ['bare_hands','hat','shirt','pants','shoe_left','shoe_right','necklace',
         'bracelet_left','bracelet_right','glove_left','glove_right','weapon_left','weapon_right']
ANCHORS = {}


def point(x,y):
    # Half-up rounding is translation invariant. Python's half-even rounding
    # can pin a wrist for one pixel and jump it by two on the next cel.
    return math.floor(x+.5),math.floor(y+.5)


def segment(draw,a,b,width,colour,lit=None):
    """A solid connected limb with a continuous dark silhouette."""
    draw.line((*a,*b),fill=INK,width=width+2)
    r=width//2
    for x,y in [a,b]:draw.ellipse((x-r-1,y-r-1,x+r+1,y+r+1),fill=INK)
    draw.line((*a,*b),fill=colour,width=width)
    for x,y in [a,b]:draw.ellipse((x-r,y-r,x+r,y+r),fill=colour)
    if lit:draw.line((a[0]-1,a[1],b[0]-1,b[1]),fill=lit,width=1)


def limb(draw,points,widths,colour,lit=None):
    # Outline the entire chain, then fill the entire chain. Outlining each
    # segment after filling its neighbour used to leave dark elbow/knee rings.
    for extra,fill in [(2,INK),(0,colour)]:
        for a,b,width in zip(points,points[1:],widths):
            width+=extra;r=width//2
            draw.line((*a,*b),fill=fill,width=width)
            for x,y in [a,b]:draw.ellipse((x-r,y-r,x+r,y+r),fill=fill)
    if lit:
        for a,b in zip(points,points[1:]):draw.line((a[0]-1,a[1],b[0]-1,b[1]),fill=lit)


RACES = {
    'human': dict(head=8,neck=25,hip=45,shoulder=7,hand=10,hand_y=40,feet=4,knee=50,torso=4,hips=3,arm=5,forearm=4,leg=5,shin=4,skin=SKIN,shade=SKIN_SHADE,light=SKIN_LIGHT),
    'elf': dict(head=5,neck=22,hip=44,shoulder=6,hand=9,hand_y=39,feet=3,knee=49,torso=3,linen_shade='#796958',hips=3,arm=4,forearm=3,leg=4,shin=3,skin='#e7bd92',shade='#b48776',light='#f6dbb0'),
    'dwarf': dict(head=16,neck=33,hip=48,shoulder=8,hand=12,hand_y=45,feet=5,knee=53,torso=6,hips=4,arm=6,forearm=5,leg=5,shin=4,skin='#c68d63',shade='#935747',light='#e4b87c'),
    'orc': dict(head=6,neck=24,hip=45,shoulder=10,hand=13,hand_y=40,feet=5,knee=50,torso=6,hips=4,arm=7,forearm=6,leg=6,shin=5,skin='#74945b',shade='#425c45',light='#a2b87a'),
}


def pose(direction,state,index,race='human'):
    r=RACES[race]
    dx,dy=DXY[direction];lx=dy if dy else dx*.40;ly=-dx*.42
    breath=int(index in [3,4,5]) if state=='idle' else 0
    bounce=[0,1,0,0,1,0][index] if state=='walk' else 0
    if state=='attack':bounce=[0,-1,0,1,1,0,-1,0,0][index]
    recoil=[-1,-2,-1,0,0][index] if state=='hurt' else 0
    cx=48+(1 if dx>0 else -1 if dx<0 else 0)*recoil
    cy=bounce+(1 if dy>0 else -1 if dy<0 else 0)*recoil
    joints={'head':(cx,r['head']+cy),'neck':(cx,r['neck']+cy),'hip':(cx,r['hip']+cy),'breath':breath}
    for side,sign in [('left',1),('right',-1)]:
        stride=[4,2,-2,-4,-2,2][index]*sign if state=='walk' else 0
        shoulder=point(cx+sign*r['shoulder']*lx,r['neck']+5+cy+sign*ly*2)
        hand=point(cx+sign*r['hand']*lx-dx*stride*.6,r['hand_y']+cy+sign*ly*2-dy*stride*.45)
        elbow=point((shoulder[0]+hand[0])/2+sign*(1+breath),(r['neck']+5+r['hand_y'])/2+cy)
        brace=[0,1,2,2,1,1,0,0,0][index] if state=='attack' else 0
        foot=point(48+sign*(r['feet']+brace)*lx+dx*stride+round(dx*recoil*.5),min(58,58+sign*ly*2-dy*stride*.35))
        # The sole stays planted during idle; the ankle and knee absorb breath.
        ankle=(foot[0]+sign*breath,foot[1]-4+max(-1,min(1,cy)))
        knee=point(cx+sign*r['feet']*lx+dx*stride*.4+sign*breath,r['knee']+cy-dy*stride*.2)
        if state=='attack':
            reach=[0,5,11,9,6,3,1,0,0][index]
            if index==1:hand=point(cx+sign*6*lx-dx*5,r['neck']+2+cy-dy*3)
            elif index in [2,3,4,5,6]:
                # Raised rear swings clear the shoulder beside the head.
                spread=4+9*max(0,-dy)
                hand=point(cx+sign*spread*lx+dx*reach,min(35,r['neck']+10)+cy+dy*reach*.55+sign*ly)
            elbow=point((shoulder[0]+hand[0])/2+sign*2, (shoulder[1]+hand[1])/2+2)
        joints[side]={'shoulder':shoulder,'elbow':elbow,'hand':hand,
                      'knee':knee,'ankle':ankle,'foot':foot}
    return joints


def head_image(reference,hx,ht,direction):
    # Only hair/face belongs here. The old 19-row rectangular cut contained
    # old scarf/shoulders and even the attack arm in some diagonal references.
    # Taper the jaw's anatomical silhouette; author the neck below it natively.
    image=reference.crop((hx-15,ht,hx+16,ht+17)).copy()
    dx,dy=DXY[direction];jaw=15+round(dx*3)
    mask=canvas(31,17);md=ImageDraw.Draw(mask)
    md.polygon([(0,0),(30,0),(30,12),(jaw+10,14),(jaw+7,15),(jaw+5,16),
                (jaw-5,16),(jaw-7,15),(jaw-10,14),(0,12)],fill='white')
    alpha=image.getchannel('A')
    from PIL import ImageChops
    image.putalpha(ImageChops.multiply(alpha,mask.getchannel('A')))
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
    palette=Image.new('P',(1,1))
    rgb=[tuple(bytes.fromhex(c[1:])) for c in HEAD_PALETTE]
    palette.putpalette([v for c in rgb for v in c]+list(rgb[0])*(256-len(rgb)))
    quantized=image.convert('RGB').quantize(palette=palette,dither=Image.Dither.NONE).convert('RGBA')
    quantized.putalpha(image.getchannel('A'))
    image=quantized
    # Clean inherited single-pixel hair spikes/notches once in the identity,
    # not separately in each animation cel (which would make pixels swim).
    source=image.copy();sp=source.load();out=image.load()
    for y in range(image.height):
        for x in range(image.width):
            ns=[sp[a,b] for a,b in [(x-1,y),(x+1,y),(x,y-1),(x,y+1)]
                if 0<=a<image.width and 0<=b<image.height and sp[a,b][3]]
            if out[x,y][3] and len(ns)<=1:out[x,y]=(0,0,0,0)
            elif not out[x,y][3] and len(ns)>=3:out[x,y]=min(ns,key=lambda c:sum(c[:3]))
    return image


def draw_layers(direction,state,index,head,contacts,race='human'):
    r=RACES[race];skin,shade,light=r['skin'],r['shade'],r['light']
    p=pose(direction,state,index,race);cx,hy=p['head'];ny=p['neck'][1];hip=p['hip'];breath=p['breath']
    dx,dy=DXY[direction];back=dy<0;profile=dy==0
    torso_half=round(r['torso']+2*abs(dy));coat_half=torso_half+1
    front_edge=cx+round(dx*(torso_half-1))
    images={name:canvas(96,64) for name in ['base']+PARTS}
    b=ImageDraw.Draw(images['base']);shirt=ImageDraw.Draw(images['shirt']);pants=ImageDraw.Draw(images['pants'])
    # Base anatomy: continuous neck -> torso -> covered pelvis -> both legs.
    b.rectangle((cx-3,hy+14,cx+3,ny+7),fill=shade)
    b.rectangle((cx-2,hy+14,cx+2,ny+6),fill=skin)
    for side,sign in [('left',1),('right',-1)]:
        j=p[side];root=(hip[0]+sign*r['hips'],hip[1]-1)
        limb(b,[root,j['knee'],j['ankle']],[r['leg'],r['shin']],skin,light)
        fx,fy=j['foot'];ax,ay=j['ankle']
        b.polygon([(ax-2,ay-1),(ax+2,ay-1),(fx+3,fy),(fx+3,fy+1),(fx-3,fy+1),(fx-3,fy-1)],fill=skin)
        b.ellipse((fx-2 if back else fx-3,fy-1,fx+2 if back else fx+3,fy+1),fill=shade)
        b.line((fx-2,fy,fx+2,fy),fill=light)
        # Pants overlap the covered hips and both boot shafts by >=2 pixels.
        limb(pants,[root,j['knee'],j['ankle']],[r['leg']+1,r['shin']+1],'#8a7c70','#bca98c')
        pants.line((j['knee'][0]-2,j['knee'][1],j['knee'][0]+1,j['knee'][1]+1),fill='#615553')
        boot=ImageDraw.Draw(images['shoe_'+side]);toe=2 if DXY[direction][0]>=0 else -2
        if back:
            # Heel counter, not a front-view toe, when walking away.
            boot.polygon([(ax-3,ay-2),(ax+3,ay-2),(fx+3,fy-1),(fx+3,fy+1),(fx-3,fy+1),(fx-3,fy-1)],fill='#614234',outline=INK)
            boot.line((fx-2,fy-2,fx+2,fy-2),fill='#925446')
        else:
            boot.polygon([(ax-3,ay-2),(ax+3,ay-2),(fx+3,fy-1),(fx+toe+2,fy),(fx+toe+2,fy+1),(fx-3,fy+1),(fx-3,fy-2)],fill='#614234',outline=INK)
        boot.line((ax-2,ay-1,ax+2,ay-1),fill='#b99362')
        boot.line((fx-2,fy,fx+toe+1,fy),fill='#925446')
    w=torso_half+breath;top=ny+2;bottom=hip[1]+1
    b.polygon([(cx-torso_half+1,top),(cx-torso_half-1,top+4),(cx-w,bottom),(cx+w,bottom),(cx+torso_half+1,top+4),(cx+torso_half-1,top)],fill='#bca98c',outline=INK)
    b.line((cx-torso_half+2,top+3,cx-torso_half+2,bottom-3),fill='#e4d3ac')
    b.line((cx+torso_half-2,top+4,cx+torso_half-2,bottom-3),fill=r.get('linen_shade','#88736a'))
    if back:
        # High back neckline and center seam; no chest V on the rear view.
        b.line((cx-3,top+1,cx+3,top+1),fill=r.get('linen_shade','#88736a'))
        b.line((cx-round(dx*2),top+4,cx-round(dx*2),bottom-3),fill=r.get('linen_shade','#88736a'))
    else:
        b.line((max(cx-torso_half+1,front_edge-3),top+1,front_edge,top+4,min(cx+torso_half-1,front_edge+3),top+1),fill='#f0dfb8')
    b.polygon([(cx-6,hip[1]-2),(cx+6,hip[1]-2),(cx+6,hip[1]+4),(cx+1,hip[1]+4),(cx,hip[1]+1),(cx-1,hip[1]+4),(cx-6,hip[1]+4)],fill='#796958',outline=INK)
    b.line((cx-5,hip[1]-1,cx+5,hip[1]-1),fill='#bca98c')
    pants.rectangle((cx-6,hip[1]-3,cx+6,hip[1]+1),fill='#8a7c70',outline=INK)
    pants.line((cx-5,hip[1]-2,cx+5,hip[1]-2),fill='#b99362')
    if back:
        for pocket in [-3,3]:
            pants.line((cx+pocket-1,hip[1],cx+pocket-1,hip[1]+2,cx+pocket+1,hip[1]+2),fill='#615553')
    # Sleeves are authored from the very same shoulder/elbow joints as the skin.
    for side,sign in [('left',1),('right',-1)]:
        j=p[side];s,e,h=j['shoulder'],j['elbow'],j['hand']
        limb(b,[s,e,h],[r['arm'],r['forearm']],skin,light)
        cuff=point(e[0]+(h[0]-e[0])*.35,e[1]+(h[1]-e[1])*.35)
        limb(shirt,[s,e,cuff],[r['arm']+2,r['forearm']+1],'#363c61','#646184')
        hand=ImageDraw.Draw(images['bare_hands']);x,y=h
        hand.ellipse((x-2,y-2,x+2,y+2),fill=shade)
        hand.ellipse((x-2,y-2,x+1,y+1),fill=skin)
        hand.line((x-1,y-1,x+1,y-1),fill=shade if back else light)
        hand.line((x+sign*2,y,x+sign*3,y+breath),fill=skin)
        b.ellipse((x-2,y-2,x+2,y+2),fill=skin)
        glove=ImageDraw.Draw(images['glove_'+side])
        glove.ellipse((x-3,y-3,x+3,y+2),fill='#614234',outline=INK)
        glove.line((x-2,y-2,x+1,y-2),fill='#b57950',width=2)
        if back:glove.line((x-1,y,x+1,y),fill=INK)
        glove.line((x+sign*2,y,x+sign*3,y+breath),fill='#b57950',width=2)
        # Bracelet follows the angle of the forearm; no wandering highlight dot.
        wx,wy=point(h[0]*.75+e[0]*.25,h[1]*.75+e[1]*.25)
        vx,vy=h[0]-e[0],h[1]-e[1];length=max(1,math.hypot(vx,vy))
        a=point(wx-vy/length*3,wy+vx/length*3);z=point(wx+vy/length*3,wy-vx/length*3)
        if state=='idle':a=(a[0],a[1]+breath);z=(z[0],z[1]-breath)
        bracelet=ImageDraw.Draw(images['bracelet_'+side])
        if state=='idle':
            bracelet.ellipse((wx-3,wy-2-breath,wx+3,wy+1),fill='#dfaf69',outline=INK)
            bracelet.line((wx-2,wy-1-breath,wx+1,wy-1-breath),fill='#b99362')
        else:
            bracelet.line((*a,*z),fill=INK,width=3);bracelet.line((*a,*z),fill='#dfaf69',width=2)
        # Each rigid blade rotates about its actual grip, never random pixels.
        # Blade points down/out from its anatomical hand. Mirroring only
        # the head used to put the rear blade across the legs when turning.
        lateral=sign*dy*(.74 if race=='dwarf' else .5)-dx*.25
        rest=math.atan2(.67 if race=='dwarf' else .94,lateral)
        if state=='death':
            angle=rest+(-math.pi/2-rest)*min(1,index/5)
        elif state=='attack':
            angle=math.atan2(DXY[direction][1],DXY[direction][0])+[0,-1.7,0,.45,.8,.6,.35,.15,0][index]
            if index in [0,8]:angle=rest
            elif index in [6,7]:angle+=((rest-angle+math.pi)%math.tau-math.pi)*(.45 if index==6 else .8)
        else:angle=rest+(.09*breath if state=='idle' else .025*math.sin(index))
        # Foreshorten towards the floor rather than clip the blade at the pivot.
        length=min(18,(57-y)/math.sin(angle)) if math.sin(angle)>0 else 18
        tip=point(x+math.cos(angle)*length,y+math.sin(angle)*length)
        if state=='attack' and index==2:contacts.setdefault(direction,{})['weapon_'+side]=[tip[0]-48,tip[1]-60]
        weapon=ImageDraw.Draw(images['weapon_'+side]);weapon.line((x,y,*tip),fill=INK,width=4)
        weapon.line((x,y,*tip),fill='#7d8390',width=3);weapon.line((x,y-1,tip[0],tip[1]-1),fill='#f2e8c6')
        # Guard is perpendicular to the blade; the grip and pommel rotate
        # about the same wrist instead of retaining a fixed screen diagonal.
        gx,gy=x+math.cos(angle)*2,y+math.sin(angle)*2
        a=point(gx-math.sin(angle)*3,gy+math.cos(angle)*3)
        z=point(gx+math.sin(angle)*3,gy-math.cos(angle)*3)
        weapon.line((*a,*z),fill=INK,width=3)
        weapon.line((*a,*z),fill='#dfaf69',width=2)
        weapon.line((x,y,x-round(math.cos(angle)*3),y-round(math.sin(angle)*3)),fill='#614234',width=2)
    # Detailed coat/scarf/satchel are native cels, not cut from the old hero.
    shirt.polygon([(cx-coat_half+1,top),(cx-coat_half-1,top+4),(cx-coat_half-breath,bottom+1),(cx+coat_half+breath,bottom+1),(cx+coat_half+1,top+4),(cx+coat_half-1,top)],fill='#363c61',outline=INK)
    shirt.polygon([(cx-coat_half+1,top+2),(cx-coat_half+4,top+3),(cx-coat_half+4,bottom),(cx-coat_half+1-breath,bottom)],fill='#646184')
    shirt.line((cx+coat_half-2,top+4,cx+coat_half-2,bottom-1),fill='#24283f')
    shirt.rectangle((cx-coat_half-breath,bottom-4,cx+coat_half+breath,bottom-2),fill='#614234',outline=INK)
    if back:
        seam=cx-round(dx*2)
        shirt.line((seam,top+4,seam,bottom-5),fill='#24283f')
        shirt.line((cx-4,top+5,seam,top+7,cx+4,top+5),fill='#646184')
        shirt.line((cx-5,bottom-3,cx+5,bottom-3),fill='#925446')
    else:
        shirt.line((front_edge,top+4,front_edge,bottom-2),fill='#b99362')
        shirt.rectangle((front_edge-1,bottom-4,front_edge+2,bottom-2),fill='#dfaf69')
    if back:
        shirt.rectangle((cx-5,top-1,cx+5,top+1),fill='#9b4950',outline='#613340')
        shirt.line((cx-4,top,cx+3,top),fill='#d48462')
    else:
        shirt.polygon([(cx-5,top-1),(cx+5,top-1),(cx+4,top+3),(cx,top+4),(cx-5,top+2)],fill='#9b4950',outline='#613340')
        shirt.line((cx-4,top,cx+3,top),fill='#d48462')
    if not back:
        shirt.polygon([(front_edge+2,top+3),(front_edge+4,top+3),(front_edge+3+breath,top+10),(front_edge+1,top+9)],fill='#9b4950')
    # Satchel remains on the same anatomical hip, mirrored from the rear.
    bag_side=-1 if back else 1
    bag_center=cx+round(5*dy)
    shirt.line((cx-bag_side*5,top+4,bag_center,bottom-3),fill='#925446',width=2)
    shirt.rectangle((bag_center-2,bottom-5,bag_center+3,bottom),fill='#614234',outline=INK)
    shirt.line((bag_center-1,bottom-4,bag_center+2,bottom-4),fill='#b99362')
    if state=='death' and index>=6:
        # The thick sleeve/hem settles inward against the body on the ground.
        settled=canvas(96,64);settled.alpha_composite(images['shirt'],(1,0));images['shirt']=settled
    if race != 'human':
        # The neck is one continuous skin bridge, including side views where
        # the near shoulder's outline would otherwise draw a dark ring over it.
        b.rectangle((cx-3,hy+14,cx+3,top-1),fill=shade)
        b.rectangle((cx-2,hy+14,cx+2,top-1),fill=skin)
    images['base'].alpha_composite(head,(cx-head.width//2,hy))
    # The hat's feather flexes at its stem; the brim/head origin remains fixed.
    hat=ImageDraw.Draw(images['hat'])
    hat.polygon([(cx-9,hy+5),(cx-6,hy+1),(cx+5,hy+1),(cx+9,hy+6)],fill='#793d48',outline=INK)
    hat.line((cx-10,hy+6,cx+9,hy+6),fill='#dfaf69',width=2)
    feather=-1 if back else 1
    hat.line((cx+feather*5,hy+3,cx+feather*(8+breath),hy-1),fill='#b99362',width=2)
    necklace=ImageDraw.Draw(images['necklace']);swing=breath
    if back:
        necklace.line((cx-4,top,cx-swing,top+2,cx+4,top),fill='#ac7949')
        necklace.rectangle((cx-swing,top+1,cx+1-swing,top+2),fill='#b99362')
    elif profile:
        pendant=front_edge+round(dx*swing)
        necklace.line((cx-round(dx*2),top,front_edge,top+3,pendant,top+6),fill='#ac7949')
        necklace.polygon([(pendant,top+4),(pendant+1,top+6),(pendant,top+8),(pendant-1,top+6)],fill='#f0bc73',outline='#705142')
    else:
        necklace.line((front_edge-4,top,front_edge-2,top+4,front_edge+swing,top+6,front_edge+3,top+3,front_edge+4,top),fill='#ac7949')
        necklace.polygon([(front_edge+swing,top+4),(front_edge+2+swing,top+6),(front_edge+swing,top+8),(front_edge-2+swing,top+6)],fill='#f0bc73',outline='#705142')
    if race != 'human': images['heritage']=heritage(race,direction,p)
    ANCHORS[state+'_'+direction+'_'+str(index)]=p
    return images


def collapse(layers,index):
    """One common full-body transform: no split/cut at the waist."""
    angle=[0,8,18,30,44,58,70,80,88][index]
    scratch={}
    for name,frame in layers.items():
        full=canvas(224,192);full.alpha_composite(frame,(64,64))
        scratch[name]=full.rotate(angle,Image.Resampling.NEAREST,center=(112,110))
    # Ground the body, never the lowest weapon pixel. Weapons have their own
    # folded grip cels so they remain above the same ground plane while falling.
    box=scratch['base'].getbbox();left=64;top=box[3]-60
    return {name:frame.crop((left,top,left+96,top+64)) for name,frame in scratch.items()}
