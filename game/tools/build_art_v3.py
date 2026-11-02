#!/usr/bin/env python3
"""Production packing for original ImageGen sources and editable pixel VFX/materials."""
from pathlib import Path
from PIL import Image, ImageDraw
import math,json,random
R=Path(__file__).resolve().parents[1]; SRC=R/'assets/art_v3/sources'; OUT=R/'assets/art_v3/sheets'; RES=R/'resources/art'
OUT.mkdir(parents=True,exist_ok=True); RES.mkdir(parents=True,exist_ok=True)
M={}
def new(w,h): return Image.new('RGBA',(w,h))
def source(name,size):
 im=Image.open(SRC/(name+'.png')).convert('RGBA'); a=im.getchannel('A').point(lambda x:255 if x>220 else 0); im.putalpha(a); im=im.crop(a.getbbox()); im.thumbnail((size[0]-6,size[1]-6),Image.Resampling.NEAREST)
 out=new(*size); out.alpha_composite(im,((size[0]-im.width)//2,size[1]-4-im.height)); return out
def register(name,states,pivot=None,origin='Editable native pixel artwork',backend='sprite'):
 images=[]; meta={}
 for state,(fs,fps,loop) in states.items():
  meta[state]={'indices':list(range(len(images),len(images)+len(fs))),'count':len(fs),'fps':fps,'loop':loop}; images.extend(fs)
 w,h=images[0].size; cols=min(16,len(images)); sheet=new(w*cols,h*math.ceil(len(images)/cols))
 for i,im in enumerate(images): sheet.alpha_composite(im,((i%cols)*w,(i//cols)*h))
 sheet.save(OUT/(name+'.png'))
 lines=[f'[gd_resource type="SpriteFrames" load_steps={len(images)+2} format=3]',f'[ext_resource type="Texture2D" path="res://assets/art_v3/sheets/{name}.png" id="1"]']
 for i in range(len(images)): lines += [f'[sub_resource type="AtlasTexture" id="f{i}"]','atlas = ExtResource("1")',f'region = Rect2({i%cols*w},{i//cols*h},{w},{h})']
 entries=[]
 for state,s in meta.items(): entries.append('{"name":&"%s","speed":%s,"loop":%s,"frames":[%s]}'%(state,s['fps'],str(s['loop']).lower(),','.join('{"duration":1.0,"texture":SubResource("f%d")}'%i for i in s['indices'])))
 (RES/(name+'.tres')).write_text('\n'.join(lines+['[resource]','animations = ['+',\n'.join(entries)+']'])+'\n')
 M[name]={'resource':f'res://resources/art/{name}.tres','texture':f'res://assets/art_v3/sheets/{name}.png','frame_size':[w,h],'pivot':pivot or [w/2,h-4],'columns':cols,'states':meta,'source':origin,'backend':backend}
def warm(im):
 out=im.copy()
 for y in range(im.height):
  for x in range(im.width):
   r,g,b,a=im.getpixel((x,y))
   if a:
    if g>r*1.2: r,g,b=min(255,round(r*1.6)),min(255,round(g*1.13)),round(b*.82)
    elif b>r*1.15: r,g,b=min(255,round(r*1.25+8)),g,min(255,round(b*.92))
    else: r,g,b=min(255,round(r*1.1+5)),g,b
    out.putpixel((x,y),(r,g,b,a))
 return out
def props():
 for name,size in [('house',(144,128)),('pine',(64,96)),('oak',(80,96)),('rowan',(48,64)),('enemy',(48,52))]:
  base=source(name,size); w,h=size; fs=[]
  for i in range(8):
   im=base.copy(); d=ImageDraw.Draw(im)
   if name in ['pine','oak']:
    im=new(w,h); split=int(h*.69); im.alpha_composite(base.crop((0,split,w,h)),(0,split))
    for y in range(split): im.alpha_composite(base.crop((0,y,w,y+1)),(round(math.sin(i*math.tau/8+y*.03)*.8*(1-y/h)),y))
    d=ImageDraw.Draw(im); d.point((w//2+i%4,h//3),fill='#bdba73')
   elif name=='house':
    for j in range(3):
     x=round(w*.27)+round(math.sin(i+j)*2); y=11-(i+j*3)%10; d.ellipse((x,y,x+3+j,y+2+j),fill=(225,191,156,45+j*20))
    for y in range(h//2,h-6):
     for x in range(w):
      r,g,b,a=base.getpixel((x,y))
      if a and r>175 and g>100 and b<r*.7:
       v=round(9*math.sin(i*math.tau/8+x*.2)); im.putpixel((x,y),(min(255,max(0,r+v)),min(255,max(0,g+v)),b,a))
   elif name=='rowan':
    hem=base.crop((0,40,w,56)); im.paste((0,0,0,0),(0,40,w,56)); im.alpha_composite(hem,(round(math.sin(i*math.tau/8)*.7),40)); ImageDraw.Draw(im).point((11+i%3,29),fill='#ffdfa2')
   else:
    body=base.crop((0,0,w,39)); im.paste((0,0,0,0),(0,0,w,39)); im.alpha_composite(body,(0,round(math.sin(i*math.tau/8)))); ImageDraw.Draw(im).point((20+i,11+i%3),fill='#ffe6a3')
   fs.append(im)
  states={'idle_down' if name=='rowan' else 'idle':(fs,6,True)}
  if name=='enemy':
   states={}
   for state in ['idle','walk','windup','attack','hurt','death']:
    frames=[]
    for i,base_frame in enumerate(fs):
     im=base_frame.copy(); d=ImageDraw.Draw(im)
     if state in ['windup','attack','hurt']: d.line((16,27,19,27),fill=('#ffbd76' if i%2 else '#ffe4ba')); d.line((28,27,31,27),fill=('#ffbd76' if i%2 else '#ffe4ba'))
     if state=='death': im.putalpha(im.getchannel('A').point(lambda a:round(a*(1-i/8))))
     frames.append(im)
    states[state]=(frames,12,state in ['idle','walk','windup'])
  register(name,states,origin='Original ImageGen source + material-specific sprite animation')
 for name in ['rock','lamp','crystal','fence','sign','fern','flowers','chest','portal']:
  base=warm(Image.open(R/'assets/sprites'/(name+'.png')).convert('RGBA')); w,h=base.size; fs=[]
  for i in range(8):
   im=base.copy(); d=ImageDraw.Draw(im)
   if name in ['fern','flowers']:
    im=new(w,h)
    for y in range(h): im.alpha_composite(base.crop((0,y,w,y+1)),(round(math.sin(i*math.tau/8)*.8*(1-y/h)),y))
    d=ImageDraw.Draw(im)
   if name=='lamp': d.polygon([(6,10),(7+i%2,4+i%3),(10,8),(9,10)],fill=('#fff0b7' if i%2 else '#ffc879'))
   elif name=='crystal':
    x=24+round(math.cos(i*math.tau/8)*19); y=24+round(math.sin(i*math.tau/8)*7); d.line((x-1,y,x+1,y),fill='#fff1be'); d.line((x,y-1,x,y+1),fill='#fff1be')
   elif name=='portal':
    x=16+round(math.cos(i*math.tau/8)*13); y=22+round(math.sin(i*math.tau/8)*5); d.rectangle((x,y,x+1,y+1),fill='#ffe6a9')
   else: d.point((2+i%max(2,w-4),max(1,h//3)),fill='#e9c58b')
   fs.append(im)
  states={'idle':(fs,8 if name in ['lamp','portal'] else 6,True)}
  if name=='chest':
   opened=[]
   for i in range(6):
    im=base.copy(); d=ImageDraw.Draw(im); d.rectangle((2,2,21,8),fill=(0,0,0,0)); d.rectangle((4,7,20,10),fill='#3a2833'); d.polygon([(2,7-i),(3,3-i),(20,3-i),(21,7-i)],fill='#c38b52'); d.line((4,4-i,19,4-i),fill='#efcf8e'); opened.append(im)
   states['open']=(opened,15,False)
  register(name,states)
def items():
 old=Image.open(R/'assets/sprites/items.png').convert('RGBA')
 for idx,name in enumerate(['rust_sword','potion','herb','ore','echo_shard']):
  base=warm(old.crop((idx*16,0,idx*16+16,16))); frames=[]
  for i in range(8):
   im=new(24,24); im.alpha_composite(base,(4,4+round(math.sin(i*math.tau/8)*.8))); d=ImageDraw.Draw(im); x=3+i*2; d.line((x-1,5,x+1,5),fill='#ffe4b0'); d.point((x,4),fill='#ffe4b0'); frames.append(im)
  pickup=[]
  for i,base in enumerate(frames):
   im=base.copy(); im.putalpha(im.getchannel('A').point(lambda a:round(a*(1-i/8)))); pickup.append(im)
  register(name,{'idle':(frames,9,True),'pickup':(pickup,24,False)})
def effects():
 for name,color in [('sword_slash',(255,225,165)),('enemy_strike',(255,144,102))]:
  fs=[]
  for i in range(16):
   im=new(72,72); d=ImageDraw.Draw(im); t=i/15; angle=-1.3+2.6*(1-(1-t)**2)
   if i<15:
    length=.12+math.sin(min(1,t*1.5)*math.pi)*1.4; pts=[]
    for j in range(22):
     a=angle-length+j/21*length; radius=27+j/21*3; pts.append((round(36+math.cos(a)*radius),round(36+math.sin(a)*radius)))
    for j in range(21,-1,-1):
     a=angle-length+j/21*length; radius=28-(2+6*j/21)*(1-t*.5); pts.append((round(36+math.cos(a)*radius),round(36+math.sin(a)*radius)))
    d.polygon(pts,fill=(*color,round(240*(1-t*.8)))); d.line(pts[:22],fill=(255,249,224,round(255*(1-t*.7))),width=2)
   if 4<=i<14:
    for j in range(4):
     a=angle-.3+j*.25; radius=28+(i-4)*.8; x=round(36+math.cos(a)*radius); y=round(36+math.sin(a)*radius); d.line((x,y,x+2,y-1),fill=(*color,220-i*12))
   fs.append(im)
  register(name,{'play':(fs,16/.24,False)},pivot=[36,36])
 for name in ['hit_spark','enemy_death']:
  fs=[]
  for i in range(10):
   im=new(48,48); d=ImageDraw.Draw(im)
   for j in range(8):
    a=j*math.tau/8; r=3+i*1.7; x=round(24+math.cos(a)*r); y=round(24+math.sin(a)*r); d.line((x,y,x+round(math.cos(a)*3),y+round(math.sin(a)*3)),fill=(255,224,155,max(0,255-i*24)),width=2)
   fs.append(im)
  register(name,{'play':(fs,30,False)},pivot=[24,24])
def cells(name,cols,rows):
 sheet=Image.open(SRC/(name+'.png')).convert('RGBA'); w,h=sheet.size; result=[]
 for row in range(rows):
  imgs=[]
  for col in range(cols):
   im=sheet.crop((round(col*w/cols),round(row*h/rows),round((col+1)*w/cols),round((row+1)*h/rows))); a=im.getchannel('A').point(lambda x:255 if x>220 else 0); im.putalpha(a); box=a.getbbox(); imgs.append(im.crop(box) if box else new(1,1))
  scale=48/max(1,imgs[0].height); fitted=[]
  for im in imgs:
   im=im.resize((max(1,round(im.width*scale)),max(1,round(im.height*scale))),Image.Resampling.NEAREST); out=new(64,64); out.alpha_composite(im,((64-im.width)//2,60-im.height)); fitted.append(out)
  result.append(fitted)
 return result
def characters():
 walks=cells('hero_walk',6,4); attacks=cells('hero_attack',8,4); states={}
 for row,direction in enumerate(['down','left','right','up']):
  base=walks[row][0]; idle=[]; hurt=[]; death=[]
  for i in range(6):
   im=base.copy(); part=base.crop((0,38,64,54)); im.paste((0,0,0,0),(0,38,64,54)); im.alpha_composite(part,(round(math.sin(i*math.tau/6)*.7),38)); ImageDraw.Draw(im).point((39+i%3,41),fill='#cba46c'); idle.append(im)
   im=new(64,64); im.alpha_composite(base,(-round(math.sin(i/5*math.pi)*2),0)); hurt.append(im)
   death.append(base.rotate(-min(90,i*22),resample=Image.Resampling.NEAREST))
  states['idle_'+direction]=(idle,6,True); states['walk_'+direction]=(walks[row],10,True); states['attack_'+direction]=(attacks[row],8/.27,False); states['hurt_'+direction]=(hurt,6/.22,False); states['death_'+direction]=(death,9,False)
 register('player',states,pivot=[32,60],origin='Original ImageGen direction/walk and 8-frame-per-direction sword attack sheets')
def terrain():
 rng=random.Random(65); originals=[]
 for row in range(4):
  for col in range(8):
   im=new(16,16); d=ImageDraw.Draw(im)
   if row==0:
    d.rectangle((0,0,15,15),fill=['#626d47','#687448','#626c48','#6a724a'][col%4])
    for j in range(6):
     x=rng.randrange(16); y=rng.randrange(16); d.line((x,y,x+1,y-1),fill=rng.choice(['#7c8550','#586342','#91935b']))
   elif row==1:
    d.rectangle((0,0,15,15),fill='#85745f')
    for y in (0,8):
     for x in range(-8+y//8*5,16,10):
      d.rounded_rectangle((x,y,x+8,y+6),radius=1,fill=rng.choice(['#b7a07b','#c4ab81','#b39a79','#c9b38a'])); d.line((x+1,y+1,x+7,y+1),fill='#deca9d'); d.point((x+2,y+5),fill='#9a8567')
   elif row==2:
    d.rectangle((0,0,15,15),fill='#417a7c')
    for j in range(5):
     x=rng.randrange(14); y=rng.randrange(16); d.line((x,y,x+4,y),fill=rng.choice(['#699e96','#508987','#80b4a4']))
   else:
    d.rectangle((0,0,15,15),fill='#8b805a')
    for j in range(10): d.point((rng.randrange(16),rng.randrange(16)),fill=rng.choice(['#aa986b','#788153','#6e754b']))
   originals.append(im)
 atlas=new(512,64)
 for frame in range(4):
  for idx,base in enumerate(originals):
   im=base.copy(); row,col=divmod(idx,8); d=ImageDraw.Draw(im)
   if row==2: d.line(((col*3+frame*2)%12,7,(col*3+frame*2)%12+3,7),fill='#c5d4b1')
   else: d.line(((col*5+frame)%15,13,(col*5+frame)%15+1,11),fill='#90975c' if row==0 else '#94905f')
   atlas.alpha_composite(im,(frame*128+col*16,row*16))
 atlas.save(OUT/'terrain.png'); paths=new(1024,64)
 for frame in range(4):
  for v in range(4):
   for mask in range(16):
    im=originals[8+v].copy()
    for bit in (1,2,4,8):
     if mask&bit: continue
     for p in range(16):
      for cross in range(1+(p+v)%2):
       x,y=(cross,p) if bit==1 else (15-cross,p) if bit==2 else (p,cross) if bit==4 else (p,15-cross); im.putpixel((x,y),originals[v].getpixel((x,y)))
    ImageDraw.Draw(im).point((2+frame,14),fill='#92905c'); paths.alpha_composite(im,(frame*256+mask*16,v*16))
 paths.save(OUT/'paths.png')
 for name,row in [('grass',0),('stone_path',1),('water',2),('shore',3)]: register(name,{'idle':([atlas.crop((i*128,row*16,i*128+16,row*16+16)) for i in range(4)],4,True)},backend='TileSetAtlasSource')
def ui():
 for name,w,h in [('ui_panel',48,48),('ui_button',48,24),('ui_health',132,5)]:
  states={}
  for state in (['idle'] if name!='ui_button' else ['normal','hover','pressed']):
   fs=[]
   for i in range(4):
    im=new(w,h); d=ImageDraw.Draw(im)
    if name=='ui_health': d.rectangle((0,0,w-1,h-1),fill='#d39968'); d.line((0,0,w-1,0),fill='#f5ce95'); d.line((15+i*30,1,21+i*30,1),fill='#ffebbd')
    else:
     d.rectangle((0,0,w-1,h-1),fill='#342c3c'); d.rectangle((2,2,w-3,h-3),fill='#795947' if state=='hover' else '#3d2f38' if state=='pressed' else '#493c43'); d.rectangle((0,0,w-1,h-1),outline='#b99362'); d.rectangle((2,2,w-3,h-3),outline='#795d4c'); d.line((4,3,w-5,3),fill='#cba770')
     for x,y in [(1,1),(w-4,1),(1,h-4),(w-4,h-4)]: d.rectangle((x,y,x+2,y+2),fill='#e9c58b')
     d.point((5+i*9,0),fill='#ffe8b1')
    fs.append(im)
   states[state]=(fs,6,True)
  register(name,states,pivot=[0,0],backend='Theme')
if __name__=='__main__':
 props(); items(); effects(); characters(); terrain(); ui()
 (RES/'manifest.json').write_text(json.dumps(M,ensure_ascii=False,indent=2)+'\n'); print('Built',len(M),'separate art/animation resources.')
