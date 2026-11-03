"""Regression for the user's detached body and idle pixel-swim screenshots."""
import json
from pathlib import Path
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
MANIFEST=json.loads((ROOT/'resources/art/manifest.json').read_text())
SHEETS={}


def frame(key,state,index):
    e=MANIFEST[key]
    if key not in SHEETS:SHEETS[key]=Image.open(ROOT/e['texture'].removeprefix('res://')).convert('RGBA')
    i=e['states'][state]['indices'][index];w,h=e['frame_size'];c=e['columns']
    return SHEETS[key].crop((i%c*w,i//c*h,i%c*w+w,i//c*h+h))


def components(image):
    # Source alpha below 180 is deliberately excluded; it cannot bridge anatomy.
    pixels=image.load();pending={(x,y) for y in range(image.height) for x in range(image.width) if pixels[x,y][3]>=180}
    result=[]
    while pending:
        queue=[pending.pop()];n=0
        while queue:
            x,y=queue.pop();n+=1
            for a in [-1,0,1]:
                for b in [-1,0,1]:
                    p=x+a,y+b
                    if p in pending:pending.remove(p);queue.append(p)
        result.append(n)
    return sorted(result,reverse=True)


def main():
    checks=0;composites=0;errors=[]
    gear=[k for k in MANIFEST if k.startswith('gear_')]
    anchors=json.loads((ROOT/'resources/equipment/rig_anchors.json').read_text())
    for state,meta in MANIFEST['player']['states'].items():
        for index in range(meta['count']):
            base=frame('player',state,index)
            sizes=components(base);checks+=1
            if len(sizes)!=1:errors.append([state,index,'detached base',sizes])
            # Every independently equipped piece must touch coherent anatomy.
            for key in gear:
                composite=base.copy();composite.alpha_composite(frame(key,state,index))
                sizes=components(composite);checks+=1;composites+=1
                if len(sizes)!=1:errors.append([state,index,key,'detached gear',sizes])
    directions=['down','left','right','up','down_right','down_left','up_right','up_left']
    for direction in directions:
        state='walk_'+direction
        checks+=1
        if len({frame('player',state,i).tobytes() for i in range(6)})!=6:
            errors.append([direction,'walk needs six actual pose drawings, not repeated contact holds'])
    for direction in ['up','up_left','up_right']:
        for state_name in ['idle','walk','attack','hurt','death']:
            state=state_name+'_'+direction
            for index in range(MANIFEST['player']['states'][state]['count']):
                for key,front_colour in [('player',(240,223,184)),('gear_indigo_coat_shirt',(223,175,105)),('gear_linen_tunic_shirt',(223,175,105)),('gear_amber_necklace_necklace',(240,188,115))]:
                    checks+=1
                    pixels=frame(key,state,index).get_flattened_data()
                    if any(p[3] and p[:3]==front_colour for p in pixels):
                        errors.append([direction,state_name,index,key,'front chest V / buckle / pendant leaked into a back view'])
                if state_name!='death':
                    cx,ny=anchors[state+'_'+str(index)]['neck']
                    for key in ['gear_indigo_coat_shirt','gear_linen_tunic_shirt']:
                        checks+=1
                        chest=frame(key,state,index).crop((cx-2,ny+5,cx+3,ny+10))
                        if any(p[3] and p[:3]==(155,73,80) for p in chest.get_flattened_data()):
                            errors.append([direction,state_name,index,key,'front scarf bib is visible on the back'])
    for direction in directions:
        state='idle_'+direction
        head=[frame('player',state,i).crop((0,0,96,25)).tobytes() for i in range(8)]
        soles=[frame('player',state,i).crop((0,59,96,60)).tobytes() for i in range(8)]
        checks+=2
        if len(set(head))!=1:errors.append([direction,'head jitters during idle'])
        if len(set(soles))!=1:errors.append([direction,'grounded soles jitter during idle'])
        # A thick, visible skin bridge supports the jaw in every idle cel.
        # Connectivity alone used to accept a narrow accidental pixel bridge.
        for index in range(8):
            f=frame('player',state,index);checks+=1
            skin={(183,126,96),(220,164,119),(245,205,154)}
            widths=[sum(f.getpixel((x,y))[:3] in skin and f.getpixel((x,y))[3]==255 for x in range(44,53)) for y in [25,26]]
            if min(widths)<5:errors.append([direction,index,'unsupported neck',widths])
    # Prove that the detector rejects a visible disconnection, not only bounds.
    broken=frame('player','idle_down',0);broken.paste((0,0,0,0),(0,24,96,28));checks+=1
    assert len(components(broken))>1,'Connectivity guard cannot detect a cut neck'
    report={'ok':not errors,'checks':checks,'base_frames':296,'individual_equipment_composites':composites,'errors':errors,
            'scope':'Opaque anatomical connectivity in every state/direction, each equipped layer, fixed idle head/soles; mutation check cuts neck and must fail.'}
    (ROOT/'tests/output/equipment-rig-review.json').write_text(json.dumps(report,indent=2)+'\n')
    print(f'EQUIPMENT_RIG_RESULT: {checks-len(errors)}/{checks} checks passed')
    if errors:print(json.dumps(errors[:24],indent=2));raise SystemExit(1)


if __name__=='__main__':main()
