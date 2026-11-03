#!/usr/bin/env python3
"""Build connected native rig cels and independent equipment animations/icons.

The preserved active identity sheet is an immutable authoring reference. Clothing
is never left baked into the runtime base. Each anatomical side owns its frames.
"""
from pathlib import Path
from PIL import Image, ImageDraw
import json, math, statistics
from art_refresh_common import ROOT, BASE, canvas, register, fragment
from build_refresh_actors import rotate_layer
from build_refresh_props import write_grid

SRC=ROOT/'assets/equipment/sources'
META=json.loads((SRC/'identity_manifest.json').read_text())
SOURCE=Image.open(SRC/'player_identity_reference.png').convert('RGBA')
CAT=json.loads((ROOT/'resources/items/items.json').read_text())
DIRS=['down','left','right','up','down_right','down_left','up_right','up_left']
ITEMS=[k for k,v in CAT.items() if v.get('allowed_slots')]
CONTACTS={}
PARTS=['bare_hands','hat','shirt','pants','shoe_left','shoe_right','necklace','bracelet_left','bracelet_right','glove_left','glove_right','weapon_left','weapon_right']
DXY={'down':(0,1),'up':(0,-1),'left':(-1,0),'right':(1,0),'down_right':(.707,.707),'down_left':(-.707,.707),'up_right':(.707,-.707),'up_left':(-.707,-.707)}
INK='#332938'; SKIN='#dca477'; SKIN_LIT='#f5cd9a'; LINEN='#bca98c'


def cell(i):
    return SOURCE.crop((i%META['columns']*96,i//META['columns']*64,i%META['columns']*96+96,i//META['columns']*64+64))


def head_info(im):
    points=[(x,y) for y in range(2,36) for x in range(22,75) if (lambda c:c[3]>200 and c[0]>c[1]*1.2 and c[0]>65 and c[1]>35)(im.getpixel((x,y)))]
    counts={y:sum(1 for x,yy in points if yy==y) for y in range(36)}
    top=min((y for y,n in counts.items() if n>=5),default=8)
    xs=[x for x,y in points if top+2<=y<top+13]
    return round(statistics.median(xs)) if xs else 48,top


# Parts are authored from anatomical joints, never extracted by colour masks.
from equipment_rig import draw_layers, head_image, collapse, ANCHORS


def frames_for(im,direction,state,index,head):
    hx,ht=head_info(head)
    return draw_layers(direction,state,index,head_image(head,hx,ht),CONTACTS)


def icon(name,index):
    im=canvas(24,24);d=ImageDraw.Draw(im);light=['#b99362','#f0bc73','#ffe0a0','#f6e3b0'][index%4]
    if 'sword' in name:
        d.polygon([(5,19),(7,14),(17,3),(20,2),(19,6),(9,17)],fill='#bdc4ba',outline=INK);d.line((8,14,18,3),fill='#f6e3b0');d.line((4,13,11,19),fill='#dfaf69',width=2);d.line((4,21,8,16),fill='#614234',width=3)
    elif name=='traveler_hat':
        d.polygon([(4,15),(6,7),(16,6),(19,15)],fill='#793d48',outline=INK);d.line((3,15,21,15),fill='#b99362',width=3);d.line((7,12,17,12),fill='#dfaf69')
    elif name in ['indigo_coat','linen_tunic']:
        c='#363c61' if name=='indigo_coat' else '#d1ba91';d.polygon([(8,4),(4,7),(2,14),(6,16),(8,10),(7,21),(17,21),(16,10),(18,16),(22,14),(20,7),(16,4)],fill=c,outline=INK);d.line((11,6,12,20),fill='#dfaf69');d.polygon([(8,5),(12,10),(16,5),(13,3)],fill='#f6e3b0')
    elif name=='traveler_pants':
        d.polygon([(6,4),(18,4),(18,21),(13,21),(12,11),(11,21),(6,21)],fill='#8a7c70',outline=INK);d.line((7,5,17,5),fill='#614234');d.line((8,7,8,18),fill='#bca98c')
    elif name=='leather_boot':
        d.polygon([(8,3),(15,3),(15,15),(20,17),(20,21),(5,21),(5,17),(8,14)],fill='#614234',outline=INK);d.line((9,5,14,5),fill='#dbab70',width=2);d.line((9,9,14,9),fill='#b99362');d.line((6,20,19,20),fill='#3e2a2d')
    elif name=='leather_glove':
        d.polygon([(7,20),(7,12),(4,9),(5,6),(8,8),(8,4),(10,3),(12,5),(13,3),(15,4),(16,8),(18,7),(19,9),(17,15),(17,20)],fill='#925446',outline=INK);d.line((8,17,16,17),fill='#dfaf69',width=2)
    elif name=='amber_necklace':
        d.arc((4,3,19,19),0,340,fill='#ac7949',width=2);d.polygon([(12,13),(16,17),(12,22),(8,17)],fill='#f0bc73',outline='#705142');d.line((11,15,11,18),fill='#ffe0a0')
    else:
        d.ellipse((4,5,20,19),fill='#705142',outline=INK,width=2);d.ellipse((7,8,17,16),fill=(0,0,0,0));d.arc((4,5,20,19),175,320,fill='#dfaf69',width=3)
    points=[(x,y) for y in range(24) for x in range(24) if im.getpixel((x,y))[3]>180]
    x,y=points[(index*7+len(points)//3)%len(points)];d.point((x,y),fill=light)
    return im


def annotate_drawings(registry):
    """Record playback holds explicitly, using visible RGBA rather than hidden RGB."""
    for entry in registry.values():
        sheet=Image.open(ROOT/entry['texture'].removeprefix('res://')).convert('RGBA')
        w,h=entry['frame_size'];cols=entry['columns']
        for meta in entry['states'].values():
            drawings=[];mapping=[]
            for i in meta['indices']:
                frame=sheet.crop((i%cols*w,i//cols*h,i%cols*w+w,i//cols*h+h))
                canonical=canvas(w,h);canonical.alpha_composite(frame);pixels=canonical.tobytes()
                if pixels not in drawings:drawings.append(pixels)
                mapping.append(drawings.index(pixels))
            meta['distinct_drawings']=len(drawings)
            meta['reused_drawings']=len(mapping)-len(drawings)
            meta['frame_drawings']=mapping


def main():
    reg={};sets={};base_states={};part_states={p:{} for p in PARTS}
    for direction in DIRS:
        head=cell(META['states']['idle_'+direction]['indices'][0]);idle_layers=None
        for state in ['idle','walk','attack','hurt']:
            name=state+'_'+direction;meta=META['states'][name]
            layers=[frames_for(cell(i),direction,state,n,head) for n,i in enumerate(meta['indices'])]
            if state=='idle':idle_layers=layers[0]
            base_states[name]=([x['base'] for x in layers],meta['fps'],meta['loop'])
            for p in PARTS:part_states[p][name]=([x[p] for x in layers],meta['fps'],meta['loop'])
        name='death_'+direction;meta=META['states'][name];layers=[collapse(idle_layers,i) for i in range(9)]
        base_states[name]=([x['base'] for x in layers],meta['fps'],False)
        for p in PARTS:part_states[p][name]=([x[p] for x in layers],meta['fps'],False)
    register(reg,'player',base_states,(48,60),'Native connected anatomy with neck/shoulder/hip/wrist/ankle overlap; preserved directional face/hair identity only. build_equipment_art.py; assets/equipment/sources. All states share frame/pivot/rig.',contact_frame=2,contact_time=.084,duration=.27)
    annotate_drawings(reg)
    actors=json.loads((BASE/'manifests/actors.json').read_text());actors['player']=reg.pop('player');fragment('actors',actors)
    register(reg,'player_hands',part_states['bare_hands'],(48,60),'Covered base anatomical hands, synchronized over sleeve cuffs and beneath removable gloves; build_equipment_art.py',family_id='hero_modular_20261103')
    for item in ITEMS:
        if item!='rust_sword':
            fs=[icon(item,i) for i in range(8)]
            for i,im in enumerate(fs):write_grid(im,f'equipment_icons/{item}-{i:02}')
            register(reg,item,{'icon':(fs,5,True),'idle':(fs,5,True)},(12,22),'Original native fantasy equipment icon and material glint; build_equipment_art.py; editable sources/props/equipment_icons')
        for slot in CAT[item]['allowed_slots']:
            states=part_states[slot]
            if item in ['linen_tunic','steel_sword']:
                changed={}
                for name,(fs,fps,loop) in states.items():
                    copies=[]
                    for im in fs:
                        im=im.copy();px=im.load()
                        for y in range(64):
                            for x in range(96):
                                r,g,b,a=px[x,y]
                                if not a:continue
                                if item=='linen_tunic' and b>r*.9 and b>g*1.04:px[x,y]=(min(230,r+110),min(214,g+92),min(174,b+36),a)
                                elif item=='steel_sword' and abs(r-g)<45 and r>100:px[x,y]=(min(250,r+20),min(250,g+28),min(240,b+25),a)
                        copies.append(im)
                    changed[name]=(copies,fps,loop)
                states=changed
            register(reg,'gear_'+item+'_'+slot,states,(48,60),'Native joint-authored synchronized anatomical '+slot+' layer for '+item+'; active hero cloth segmentation/native accessory source; build_equipment_art.py. Same pose indices/feet/physics contact as player.',family_id='hero_modular_20261103')
    annotate_drawings(reg)
    fragment('equipment',reg)
    contact_path=ROOT/'resources/equipment/contacts.json'
    contact_path.parent.mkdir(parents=True,exist_ok=True)
    contact_path.write_text(json.dumps(CONTACTS,indent=2)+'\n')
    from build_equipment_fx import build
    build()
    # Show the actual default composite and the covered base at identical scale.
    preview=Image.new('RGBA',(8*192,4*150),'#282431');d=ImageDraw.Draw(preview)
    default={'hat':'traveler_hat','shirt':'indigo_coat','pants':'traveler_pants','shoe_left':'leather_boot','shoe_right':'leather_boot','necklace':'amber_necklace','bracelet_left':'copper_bracelet','bracelet_right':'copper_bracelet','glove_left':'leather_glove','glove_right':'leather_glove','weapon_right':'rust_sword'}
    order=['pants','shoe_left','shoe_right','shirt','bare_hands','glove_left','glove_right','bracelet_left','bracelet_right','necklace','hat','weapon_left','weapon_right']
    for col,direction in enumerate(DIRS):
        for row,(state,idx,bare) in enumerate([('idle',0,False),('walk',2,False),('attack',2,False),('idle',0,True)]):
            name=state+'_'+direction;frame=base_states[name][0][idx].copy()
            if not bare:
                for p in order:
                    if p in default or p=='bare_hands':frame.alpha_composite(part_states[p][name][0][idx])
            preview.alpha_composite(frame.resize((192,128),Image.Resampling.NEAREST),(col*192,row*150+18));d.text((col*192+2,row*150+2),direction+(' / base' if bare else ' / '+state),fill='#f6e3b0')
    preview.save(BASE/'previews/equipment_identity.png')
    print('Built modular player and',len(reg),'equipment icon/layer resources')


if __name__=='__main__':main()
