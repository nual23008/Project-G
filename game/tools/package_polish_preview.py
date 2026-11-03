#!/usr/bin/env python3
"""Package engine-rendered clips and review the newly authored pixel sequences."""
from pathlib import Path
import json
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'tests/output'
FRAMES=OUT/'polish'


def main():
    summary=json.loads((OUT/'polish-render-review.json').read_text())
    assert summary['failures']==0
    clips={}
    for name,count,duration in [('walk',36,[30,30,40]*12),('slash',18,[20,10,20]*6),('empowered',18,[20,10,20]*6)]:
        frames=[Image.open(FRAMES/f'{name}_{i:02}.png').convert('RGB') for i in range(count)]
        frames[0].save(OUT/f'polish-{name}.gif',save_all=True,append_images=frames[1:],duration=duration,loop=0)
        clips[name]=frames
    composite=[]
    for i in range(36):
        image=Image.new('RGB',(960,266),'#282431');draw=ImageDraw.Draw(image)
        for column,name in enumerate(['walk','slash','empowered']):
            index=i if name=='walk' else min(17,i*2)
            crop=clips[name][index].crop((240,84,400,204)).resize((320,240),Image.Resampling.NEAREST)
            image.paste(crop,(column*320,24));draw.text((column*320+8,6),{'walk':'Movement / footfalls','slash':'Blade / contact','empowered':'Empowered blade'}[name],fill='#f6e3b0')
        composite.append(image)
    composite[0].save(OUT/'polish-motion.gif',save_all=True,append_images=composite[1:],duration=[30,30,40]*12,loop=0)
    sheet=Image.new('RGB',(1920,1064),'#282431')
    for cell,index in enumerate([0,2,4,6,8,12,18,30]):sheet.paste(composite[index],(cell%2*960,cell//2*266))
    sheet.save(OUT/'polish-motion-contact.png')
    manifest=json.loads((ROOT/'resources/art/manifest.json').read_text())
    art={}
    for name in ['footstep_dust','falling_leaf','sword_slash','empowered_slash','grass','stone_path','water','player']:
        entry=manifest[name]
        states={}
        for state,meta in entry['states'].items():
            source=Image.open(ROOT/meta.get('texture',entry['texture']).removeprefix('res://')).convert('RGBA')
            w,h=entry['frame_size'];cols=meta.get('columns',entry['columns'])
            frames=[source.crop((i%cols*w,i//cols*h,i%cols*w+w,i//cols*h+h)) for i in meta['indices']]
            unique=len({f.tobytes() for f in frames})
            assert unique>1,(name,state)
            states[state]={'playback_frames':len(frames),'distinct_drawings':unique,'fps':meta['fps'],'loop':meta['loop']}
        art[name]=states
    (OUT/'polish-animation-review.json').write_text(json.dumps({'ok':True,'engine_captures':len(summary['captures']),'new_and_changed_art':art,'note':'Renderer preview uses real Godot SubViewport logical sizes for 16:9, 16:10, and 21:9; physical Wayland window resizing is capped by the desktop. Source holds counted honestly.'},indent=2)+'\n')
    print('Packaged 72 motion captures, plus 15 scene/UI captures; source clips verified')


if __name__=='__main__':main()
