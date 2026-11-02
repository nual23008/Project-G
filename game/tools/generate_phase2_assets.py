#!/usr/bin/env python3
"""Original small RPG icons, guardian and action frames; build-time Pillow only."""
from pathlib import Path
from PIL import Image, ImageDraw
R=Path(__file__).resolve().parents[1]
def save(im,name): im.save(R/'assets/sprites'/name)
icons=Image.new('RGBA',(80,16)); d=ImageDraw.Draw(icons)
d.line((3,13,12,2), fill='#e9e4b9',width=3); d.line((2,9,7,14),fill='#b59a69',width=2); d.line((2,14,4,12),fill='#725b43',width=2)
d.rectangle((22,1,25,4),fill='#b2a27c'); d.rectangle((21,4,26,6),fill='#bacbbe'); d.rounded_rectangle((19,6,28,14),radius=2,fill='#ab5454'); d.rectangle((21,7,23,11),fill='#f8af85')
d.line((38,14,42,4),fill='#b5b27a',width=2); d.ellipse((34,5,40,10),fill='#67a36a'); d.ellipse((40,1,46,7),fill='#94bd76')
d.polygon([(50,12),(52,5),(59,3),(62,10),(59,14)], fill='#658c9d'); d.line((53,6,58,4,60,8),fill='#b6d6bf',width=2)
d.polygon([(72,1),(78,7),(74,14),(67,8)],fill='#76cbb7'); d.polygon([(72,1),(72,9),(78,7)],fill='#e4e5ab'); d.line((72,2,72,12),fill='#b6ecd2')
save(icons,'items.png')
im=Image.new('RGBA',(24,20)); d=ImageDraw.Draw(im); d.rectangle((2,7,21,17),fill='#684d38'); d.rectangle((2,3,21,8),fill='#a18350'); d.line((3,3,20,3),fill='#dbc48a'); d.rectangle((5,4,7,16),fill='#465b50'); d.rectangle((17,4,19,16),fill='#465b50'); d.rectangle((10,7,13,11),fill='#edd590'); save(im,'chest.png')
im=Image.new('RGBA',(32,32)); d=ImageDraw.Draw(im); d.ellipse((1,12,30,29),outline='#9bccb0',width=2); d.line((16,22,16,5,10,11),fill='#eddf9e',width=2); d.line((16,5,22,11),fill='#eddf9e',width=2); save(im,'portal.png')
im=Image.new('RGBA',(128,32))
for i in range(4):
 t=Image.new('RGBA',(32,32)); d=ImageDraw.Draw(t); dy=[0,1,0,-1][i]
 d.ellipse((3,23,29,30),fill=(8,24,30,100)); d.polygon([(4,23+dy),(7,10+dy),(16,5+dy),(25,11+dy),(29,24+dy),(19,28+dy),(8,27+dy)],fill='#4b7265'); d.polygon([(7,12+dy),(17,7+dy),(25,13+dy),(18,19+dy),(5,22+dy)],fill='#78937b'); d.polygon([(15,3+dy),(20,12+dy),(15,16+dy),(12,10+dy)],fill='#83cac3'); d.line((15,4+dy,15,12+dy),fill='#e3e9ad'); d.rectangle((9,19+dy,12,20+dy),fill='#eed094'); d.rectangle((21,19+dy,24,20+dy),fill='#eed094'); im.alpha_composite(t,(i*32,0))
save(im,'enemy.png')
lines=['[gd_resource type="SpriteFrames" load_steps=6 format=3]','[ext_resource type="Texture2D" path="res://assets/sprites/enemy.png" id="1"]']
for i in range(4): lines += [f'[sub_resource type="AtlasTexture" id="f{i}"]','atlas = ExtResource("1")',f'region = Rect2({i*32},0,32,32)']
lines += ['[resource]','animations = [{"name":&"walk","loop":true,"speed":6.0,"frames":['+','.join('{"duration":1.0,"texture":SubResource("f%d")}'%i for i in range(4))+']}]']; (R/'resources/enemy_frames.tres').write_text('\n'.join(lines)+'\n')
# Keep original idle/walk resources and extend with visibly distinct action frames.
source=Image.open(R/'assets/sprites/player.png'); sheet=Image.new('RGBA',(96,128))
for y in range(4):
 base=source.crop((0,y*32,24,y*32+32))
 attack=base.copy(); dr=ImageDraw.Draw(attack); endpoints=[(18,31),(0,18),(23,18),(18,0)]; dr.line((17,18,*endpoints[y]),fill='#f1dfa9',width=2)
 hurt=base.copy(); dr=ImageDraw.Draw(hurt); dr.line((3,10,0,7),fill='#df8d72',width=2); dr.line((20,10,23,7),fill='#df8d72',width=2)
 death=Image.new('RGBA',(24,32)); dr=ImageDraw.Draw(death); dr.ellipse((2,23,22,29),fill='#244453'); dr.rectangle((4,22,16,26),fill='#377e9a'); dr.ellipse((16,21,22,26),fill='#d4b887')
 for x,t in enumerate([attack,attack,hurt,death]): sheet.alpha_composite(t,(x*24,y*32))
save(sheet,'player_actions.png')
p=R/'resources/player_frames.tres'; s=p.read_text()
# Re-running the generator must be idempotent: start from the original generator output.
if 'player_actions.png' not in s:
 s=s.replace('load_steps=18','load_steps=35').replace('[resource]','[ext_resource type="Texture2D" path="res://assets/sprites/player_actions.png" id="actions"]\n\n'+''.join(f'[sub_resource type="AtlasTexture" id="a{y}_{x}"]\natlas = ExtResource("actions")\nregion = Rect2({x*24},{y*32},24,32)\n\n' for y in range(4) for x in range(4))+'[resource]')
 extras=[]
 for y,direction in enumerate(['down','left','right','up']):
  for kind,frames in [('attack',[0,1]),('hurt',[2]),('death',[3])]: extras.append('{"name":&"%s_%s","loop":false,"speed":8.0,"frames":[%s]}'%(kind,direction,','.join('{"duration":1.0,"texture":SubResource("a%d_%d")}'%(y,x) for x in frames)))
 ext='[ext_resource type="Texture2D" path="res://assets/sprites/player_actions.png" id="actions"]'
 s=s.replace(ext+'\n',''); s=s.replace('[sub_resource',ext+'\n\n[sub_resource',1)
 s=s.rstrip(); s=s[:-1]+',\n'+',\n'.join(extras)+'\n]\n'; p.write_text(s)
print('Generated Phase 2 original sprites and extended player animation resources.')
