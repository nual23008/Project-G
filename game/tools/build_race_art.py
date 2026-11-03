#!/usr/bin/env python3
"""Race-specific joint cels plus lightweight animated selection composites.
All paths are native project-owned raster drawings; no paid/source-image service.
"""
import json
from PIL import Image, ImageDraw
from art_refresh_common import ROOT,BASE,canvas,register,fragment
from build_equipment_art import DIRS,META,CAT,ITEMS,PARTS,cell,head_info,annotate_drawings
from equipment_rig import draw_layers,head_image,collapse,ANCHORS,RACES
from race_heads import head as race_head

ORDER=['pants','shoe_left','shoe_right','shirt','bare_hands','glove_left','glove_right','bracelet_left','bracelet_right','necklace','heritage','hat','weapon_left','weapon_right']
DEFAULT={'hat':'traveler_hat','shirt':'indigo_coat','pants':'traveler_pants','shoe_left':'leather_boot','shoe_right':'leather_boot','necklace':'amber_necklace','bracelet_left':'copper_bracelet','bracelet_right':'copper_bracelet','glove_left':'leather_glove','glove_right':'leather_glove','weapon_right':'rust_sword'}


def variant(states,item):
    if item not in ['linen_tunic','steel_sword']:return states
    out={}
    for name,(fs,fps,loop) in states.items():
        frames=[]
        for im in fs:
            im=im.copy();px=im.load()
            for y in range(64):
                for x in range(96):
                    r,g,b,a=px[x,y]
                    if not a:continue
                    if item=='linen_tunic' and b>r*.9 and b>g*1.04:px[x,y]=(min(230,r+110),min(214,g+92),min(174,b+36),a)
                    elif item=='steel_sword' and abs(r-g)<45 and r>100:px[x,y]=(min(250,r+20),min(250,g+28),min(240,b+25),a)
            frames.append(im)
        out[name]=(frames,fps,loop)
    return out


def read_states(id):
    reg=json.loads((ROOT/'resources/art/manifest.json').read_text()) if id=='player' else {}
    # Human is owned by the equipment/actor fragments, even on the first build.
    if id=='player':reg=json.loads((BASE/'manifests/actors.json').read_text())
    elif id=='player_hands' or id.startswith('gear_'):reg=json.loads((BASE/'manifests/equipment.json').read_text())
    e=reg[id];sheet=Image.open(ROOT/e['texture'].removeprefix('res://')).convert('RGBA');w,h=e['frame_size'];cols=e['columns']
    return {name:([sheet.crop((i%cols*w,i//cols*h,i%cols*w+w,i//cols*h+h)) for i in m['indices']],m['fps'],m['loop']) for name,m in e['states'].items()}


def composite(base,parts,name,index,hat=True):
    direction=name.split('_',1)[1]
    rear=[p for p in ['weapon_left','weapon_right'] if direction.startswith('up') or (direction=='right' and p=='weapon_left') or (direction=='left' and p=='weapon_right')]
    im=canvas(96,64)
    for part in rear:
        if part in DEFAULT and part in parts:im.alpha_composite(parts[part][name][0][index])
    im.alpha_composite(base[name][0][index])
    for part in ORDER:
        if part in rear:continue
        if part in ['bare_hands','heritage'] or part in DEFAULT:
            if part not in parts or (part=='hat' and not hat):continue
            im.alpha_composite(parts[part][name][0][index])
    return im


def main():
    reg={};all_cels={};source=ROOT/'assets/races/sources';source.mkdir(parents=True,exist_ok=True)
    for race in ['human','elf','dwarf','orc']:
        contacts={};ANCHORS.clear()
        if race=='human':
            base=read_states('player');parts={'bare_hands':read_states('player_hands')}
            for part,item in DEFAULT.items():parts[part]=read_states('gear_'+item+'_'+part)
        else:
            base={};parts={p:{} for p in PARTS+['heritage']}
            for direction in DIRS:
                head=race_head(race,direction);head.save(source/(race+'_head_'+direction+'.png'))
                for state in ['idle','walk','attack','hurt','death']:
                    name=state+'_'+direction;meta=META['states'][name];layers=[]
                    for i in range(meta['count']):
                        cel=draw_layers(direction,state,i,head,contacts,race)
                        if state=='death':cel=collapse(cel,i)
                        layers.append(cel)
                    base[name]=([x['base'] for x in layers],meta['fps'],meta['loop'])
                    for p in parts:parts[p][name]=([x[p] for x in layers],meta['fps'],meta['loop'])
            prefix='race_'+race+'_';note='Native race identity/anatomy, equipment_rig.py RACES + race_heads.py; build_race_art.py. Separate joint widths/lengths/head/hair/palette, no full-body scaling or colour-mask cuts.'
            register(reg,prefix+'player',base,(48,60),note,race=race,contact_frame=2,contact_time=.084,duration=.27)
            register(reg,prefix+'player_hands',parts['bare_hands'],(48,60),note,race=race)
            register(reg,prefix+'heritage',parts['heritage'],(48,60),note+' Natural braid/beard/nape cels, separate from removable equipment.',race=race)
            for item in ITEMS:
                for slot in CAT[item]['allowed_slots']:
                    register(reg,prefix+'gear_'+item+'_'+slot,variant(parts[slot],item),(48,60),note+' Independently removable '+item+'/'+slot+'.',race=race)
            (ROOT/'resources/equipment'/('contacts_'+race+'.json')).write_text(json.dumps(contacts,indent=2)+'\n')
            (ROOT/'resources/equipment'/('rig_anchors_'+race+'.json')).write_text(json.dumps(ANCHORS,indent=2)+'\n')
        showcases={name:([composite(base,parts,name,i) for i in range(len(fs))],fps,loop) for name,(fs,fps,loop) in base.items()}
        register(reg,'race_'+race+'_showcase',showcases,(48,60),'Exact starter-equipment composite of runtime '+race+' cels for selected menu preview; build_race_art.py.',race=race)
        cards=[composite(base,parts,'idle_down',i,hat=False) for i in range(8)]
        register(reg,'race_'+race+'_card',{'idle':(cards,5,True)},(48,60),'Compact bareheaded '+race+' idle composite for selection thumbnail; build_race_art.py.',race=race)
        all_cels[race]=(base,parts,showcases)
    annotate_drawings(reg);fragment('races',reg)
    # Common-scale anatomy and actual equipment review (no per-race enlargement).
    board=Image.new('RGBA',(8*192,4*300),'#282431');d=ImageDraw.Draw(board)
    for row,(race,(base,parts,shows)) in enumerate(all_cels.items()):
        for col,direction in enumerate(DIRS):
            for band,bare in enumerate([False,True]):
                im=base['idle_'+direction][0][0].copy() if bare else composite(base,parts,'idle_'+direction,0,False)
                if bare and 'heritage' in parts:im.alpha_composite(parts['heritage']['idle_'+direction][0][0])
                board.alpha_composite(im.resize((192,128),Image.Resampling.NEAREST),(col*192,row*300+band*145+20))
                d.text((col*192+4,row*300+band*145+3),race+' / '+direction+(' base' if bare else ''),fill='#f6e3b0')
    board.save(BASE/'previews/races_identity.png')
    # Per-state moving preview: all races/directions, exact holds and durations.
    for state in ['idle','walk','attack','hurt','death']:
        count=META['states'][state+'_down']['count'];fps=META['states'][state+'_down']['fps'];frames=[]
        for index in range(count):
            im=Image.new('RGB',(8*192,4*144),'#282431');draw=ImageDraw.Draw(im)
            for row,(race,(_,_,shows)) in enumerate(all_cels.items()):
                for col,direction in enumerate(DIRS):
                    cel=shows[state+'_'+direction][0][index].resize((192,128),Image.Resampling.NEAREST)
                    im.paste(cel,(col*192,row*144+16),cel);draw.text((col*192+4,row*144+2),race+' / '+direction,fill='#f6e3b0')
            frames.append(im)
        frames[0].save(BASE/'previews'/('races_'+state+'.gif'),save_all=True,append_images=frames[1:],duration=round(1000/fps),loop=0,disposal=2)
    print('Built',len(reg),'race resources, 4 x 40 state/direction composites plus cards.')

if __name__=='__main__':main()
