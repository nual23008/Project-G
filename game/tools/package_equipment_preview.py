#!/usr/bin/env python3
"""Visible-pixel, rig/pivot/contact QA plus unmodified engine motion packaging."""
from pathlib import Path
from PIL import Image,ImageDraw
import hashlib,json
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'tests/output';FRAMES=OUT/'equipment'
DIRECTIONS=['up_left','up','up_right','right','down_right','down','down_left','left']


def grid(kind,count,durations):
    result=[]
    for index in range(count):
        image=Image.new('RGB',(1088,456),'#282431');draw=ImageDraw.Draw(image)
        for cell,direction in enumerate(DIRECTIONS):
            source=Image.open(FRAMES/f'{kind}_{direction}_{index:02}.png').convert('RGB')
            frame=source.crop((252,108,388,212)).resize((272,208),Image.Resampling.NEAREST)
            x,y=cell%4*272,cell//4*228;image.paste(frame,(x,y+20));draw.text((x+4,y+3),kind+' / '+direction,fill='#f6e3b0')
        result.append(image)
    result[0].save(OUT/f'equipment-{kind}.gif',save_all=True,append_images=result[1:],duration=durations,loop=0)
    return result


def main():
    review=json.loads((OUT/'equipment-render-review.json').read_text());assert review['failures']==0
    for capture in review['captures']:
        for slot,layer in capture['layers'].items():
            if layer['visible']:
                assert layer['animation']==capture['animation'] and layer['frame']==capture['frame'],(capture['name'],slot)
    m=json.loads((ROOT/'resources/art/manifest.json').read_text());base=m['player'];art={};guards=0
    ids=['player','player_hands','sword_slash','empowered_slash','hit_spark']+[k for k in m if k.startswith('gear_')]
    catalog=json.loads((ROOT/'resources/items/items.json').read_text());ids +=[k for k in catalog if catalog[k].get('allowed_slots') and k!='rust_sword']
    for key in ids:
        e=m[key];states={};sheet=Image.open(ROOT/e['texture'].removeprefix('res://')).convert('RGBA');w,h=e['frame_size'];cols=e['columns']
        is_actor=key in ['player','player_hands'] or key.startswith('gear_')
        if is_actor:assert set(e['states'])==set(base['states'])
        for name,s in e['states'].items():
            frames=[]
            for index in s['indices']:
                frame=sheet.crop((index%cols*w,index//cols*h,index%cols*w+w,index//cols*h+h))
                # Hidden RGB differences cannot manufacture new animation poses.
                raw=bytearray(frame.tobytes())
                for i in range(0,len(raw),4):
                    if raw[i+3]==0:raw[i:i+4]=bytes(4)
                frames.append(hashlib.sha256(raw).hexdigest())
                if is_actor:
                    bounds=frame.getbbox();assert bounds and bounds[0]>=1 and bounds[1]>=1 and bounds[2]<=95 and bounds[3]<=60,(key,name,bounds)
                    guards+=1
            unique=len(set(frames));assert unique>1,(key,name,'static')
            if is_actor:
                ref=base['states'][name]
                assert (s['count'],s['fps'],s['loop'])==(ref['count'],ref['fps'],ref['loop'])
            states[name]={'frames':len(frames),'distinct_drawings':unique,'reused_drawings':len(frames)-unique,'fps':s['fps'],'loop':s['loop']}
        art[key]=states
    contacts=json.loads((ROOT/'resources/equipment/contacts.json').read_text())
    for direction,sides in contacts.items():
        for side,point in sides.items():
            e=m['gear_rust_sword_'+side];s=e['states']['attack_'+direction];idx=s['indices'][2]
            sh=Image.open(ROOT/e['texture'].removeprefix('res://')).convert('RGBA');f=sh.crop((idx%12*96,idx//12*64,idx%12*96+96,idx//12*64+64))
            assert f.getpixel((point[0]+48,point[1]+60))[3]>0,(direction,side,'tip anchor outside weapon')
    walk=grid('walk',12,[70,60,70]*4);idle=grid('idle',8,200)
    slash=grid('slash',18,[20,10,20]*6);hurt=grid('hurt',7,[30,30,40,30,30,40,30]);death=grid('death',18,50)
    for kind in ['left_slash','empowered']:
        frames=[Image.open(FRAMES/f'{kind}_{i:02}.png').convert('RGB') for i in range(18)]
        frames[0].save(OUT/f'equipment-{kind}.gif',save_all=True,append_images=frames[1:],duration=[20,10,20]*6,loop=0)
    for name,frames,indices in [('slash',slash,[0,2,4,5,6,8,12,17]),('death',death,[0,2,4,6,8,11,14,17])]:
        sheet=Image.new('RGB',(2176,1824),'#282431')
        for cell,index in enumerate(indices):sheet.paste(frames[index],(cell%2*1088,cell//2*456))
        sheet.save(OUT/f'equipment-{name}-contact.png')
    scenes=[Image.open(FRAMES/f'{name}.png').convert('RGB') for name in ['bag_default','bag_removed','bag_asymmetric']]
    image=Image.new('RGB',(1920,360),'#282431')
    for i,scene in enumerate(scenes):image.paste(scene,(640*i,0))
    image.save(OUT/'equipment-outfits.png')
    (OUT/'equipment-animation-review.json').write_text(json.dumps({'ok':True,'engine_captures':len(review['captures']),'actor_layer_frames_guarded':guards,'art':art,'contacts':contacts,'note':'Real renderer inputs and health events; paper-doll layers share the base frame clock. Holds counted honestly; no hidden RGB/static-loop substitution.'},indent=2)+'\n')
    print(json.dumps({'ok':True,'engine_captures':len(review['captures']),'actor_frames_guarded':guards,'art_types_reviewed':len(art)}))


if __name__=='__main__':main()
