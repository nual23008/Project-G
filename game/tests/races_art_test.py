"""Race anatomy, grounded idle and per-item cel regression over all eight views."""
import json,sys
from pathlib import Path
from PIL import Image
sys.path.insert(0,str(Path(__file__).resolve().parent))
from equipment_art_test import MANIFEST,ROOT,frame,components
sys.path.insert(0,str(ROOT/'tools'))
from equipment_rig import RACES


def main():
    checks=0;errors=[];sizes={}
    def check(ok,*detail):
        nonlocal checks
        checks+=1
        if not ok:errors.append(detail)
    for race in ['elf','dwarf','orc']:
        prefix='race_'+race+'_';base_id=prefix+'player';base=MANIFEST[base_id]
        gear=[k for k in MANIFEST if k.startswith(prefix+'gear_')]
        anchors=json.loads((ROOT/'resources/equipment'/('rig_anchors_'+race+'.json')).read_text())
        check(len(base['states'])==40,race,'all eight views and five behaviours')
        for state,m in base['states'].items():
            for i in range(m['count']):
                im=frame(base_id,state,i);box=im.getbbox()
                check(len(components(im))==1,race,state,i,'base anatomy',components(im))
                check(box and box[0]>0 and box[2]<96 and box[1]>=0 and box[3]<=60,race,state,i,'canvas bounds',box)
                for part in gear+[prefix+'player_hands',prefix+'heritage']:
                    joined=im.copy();joined.alpha_composite(frame(part,state,i))
                    check(len(components(joined))==1,race,state,i,part,'detached worn layer',components(joined))
                if m['body_view']=='back':
                    for key,col in [(base_id,(240,223,184)),(prefix+'gear_indigo_coat_shirt',(223,175,105)),(prefix+'gear_amber_necklace_necklace',(240,188,115))]:
                        check(not any(px[3] and px[:3]==col for px in frame(key,state,i).get_flattened_data()),race,state,i,'front symbol on rear',key)
        if race=='dwarf':
            # A beard can touch the torso yet still read as a detached bib.
            # Its upper roots must overlap the actual cheek/temple region.
            for state,m in base['states'].items():
                if state.startswith('death_'):continue
                for i in range(m['count']):
                    cx,hy=anchors[state+'_'+str(i)]['head'];f=frame(base_id,state,i);h=frame(prefix+'heritage',state,i)
                    overlap=sum(bool(f.getpixel((x,y))[3] and h.getpixel((x,y))[3]) for y in range(hy+6,hy+13) for x in range(cx-14,cx+15))
                    check(overlap>=16,race,state,i,'beard/nape root must overlap head',overlap)
                    if m['body_view']=='back':
                        check(h.crop((0,hy+17,96,64)).getbbox() is None,race,state,i,'back must not show a beard/braid below the occiput')
            for direction in ['down','left','right','up','down_left','down_right','up_left','up_right']:
                hy=RACES[race]['head']
                check(len({frame(prefix+'heritage','idle_'+direction,i).crop((0,0,96,hy+15)).tobytes() for i in range(8)})==1,race,direction,'beard roots remain fixed on the cheeks during idle')
        for direction in ['down','left','right','up','down_left','down_right','up_left','up_right']:
            state='idle_'+direction;ny=RACES[race]['neck'];hy=RACES[race]['head']
            check(len({frame(base_id,state,i).crop((0,0,96,ny+1)).tobytes() for i in range(8)})==1,race,direction,'idle head origin')
            check(len({frame(base_id,state,i).crop((0,59,96,60)).tobytes() for i in range(8)})==1,race,direction,'idle sole origin')
            skin={tuple(bytes.fromhex(RACES[race][c][1:])) for c in ['skin','shade','light']}
            for i in range(8):
                f=frame(base_id,state,i);cx,_=anchors[state+'_'+str(i)]['neck']
                widths=[sum(f.getpixel((x,y))[:3] in skin and f.getpixel((x,y))[3]==255 for x in range(cx-4,cx+5)) for y in range(hy+17,ny+2)]
                check(min(widths)>=5,race,state,i,'neck support',widths)
            check(len({frame(base_id,'walk_'+direction,i).tobytes() for i in range(6)})==6,race,direction,'walk distinct poses')
        sizes[race]=(frame(base_id,'idle_down',0).getbbox(),frame(base_id,'idle_down',0).crop((0,28,96,46)).getbbox())
        for id,e in MANIFEST.items():
            if not id.startswith(prefix):continue
            for state,m in e['states'].items():
                check(m['distinct_drawings']>=2 and len(m['frame_drawings'])==m['count'],id,state,'honest moving cels')
                for i in range(m['count']):
                    check(frame(id,state,i).getbbox() is not None,id,state,i,'empty cel')
    check(sizes['elf'][0][1]<sizes['dwarf'][0][1] and sizes['orc'][1][2]-sizes['orc'][1][0]>sizes['elf'][1][2]-sizes['elf'][1][0],'race height and width silhouettes')
    # Nonhuman natural traits must be connected; a severed neck must fail.
    broken=frame('race_elf_player','idle_down',0);broken.paste((0,0,0,0),(0,22,96,25))
    check(len(components(broken))>1,'guard detects broken neck')
    out={'ok':not errors,'checks':checks,'errors':errors,'scope':'3 native races x 296 frames, all 15 item layers independently, hands/heritage, fixed idle roots/skin neck bridge, front/back symbols, honest playback holds'}
    (ROOT/'tests/output/races-art-review.json').write_text(json.dumps(out,indent=2)+'\n')
    print(f'RACES_ART_RESULT: {checks-len(errors)}/{checks} checks passed')
    if errors:print(json.dumps(errors[:30],indent=2));raise SystemExit(1)
if __name__=='__main__':main()
