#!/usr/bin/env python3
"""Package engine captures and source animation clips; never redraw runtime art."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageChops
import json

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'tests/output'
registry=json.loads((ROOT/'resources/art/manifest.json').read_text())
new_ids=['experience_orb','level_up','empowered_slash','ui_experience','ui_energy','ui_stamina','ui_stats_panel']
canvas=Image.new('RGB',(1450,1050),'#332938');d=ImageDraw.Draw(canvas)
row_y=4
integrity={}
for name,state in [(name,state) for name in new_ids for state in registry[name]['states']]:
    entry=registry[name];w,h=entry['frame_size'];cols=entry['columns']
    sheet=Image.open(ROOT/entry['texture'].removeprefix('res://')).convert('RGBA')
    record=entry['states'][state]
    frames=[sheet.crop((idx%cols*w,idx//cols*h,idx%cols*w+w,idx//cols*h+h)) for idx in record['indices']]
    distinct=len({im.tobytes() for im in frames})
    assert distinct>1
    integrity.setdefault(name,{})[state]={'frames':len(frames),'distinct':distinct,'fps':record['fps'],'loop':record['loop']}
    scale=2 if w<=80 else 1
    d.text((8,row_y),f'{name} / {state} / {len(frames)} frames @ {record["fps"]:.3g} FPS',fill='#f6e3b0')
    choices=list(range(len(frames))) if len(frames)<=8 else [0,1,2,3,4,6,8,len(frames)-1]
    for n,index in enumerate(choices):
        canvas.paste(frames[index].resize((w*scale,h*scale),Image.Resampling.NEAREST),(8+n*(w*scale+12),row_y+18),frames[index].resize((w*scale,h*scale),Image.Resampling.NEAREST))
    row_y+=h*scale+28
    gif_frames=[]
    gif_scale=4 if w<=32 else 2
    for im in frames:
        bg=Image.new('RGBA',im.size,'#332938');bg.alpha_composite(im)
        gif_frames.append(bg.convert('RGB').resize((w*gif_scale,h*gif_scale),Image.Resampling.NEAREST))
    durations=[max(10,round((i+1)*100/record['fps'])*10-round(i*100/record['fps'])*10) for i in range(len(frames))]
    gif_frames[0].save(OUT/f'{name}_{state}_preview.gif',save_all=True,append_images=gif_frames[1:],duration=durations,loop=0)
canvas.crop((0,0,1450,row_y)).save(OUT/'progression-art-contact.png')
captures=[Image.open(p).convert('RGB') for p in sorted((OUT/'progression_motion').glob('frame_*.png'))]
assert len(captures)==36
captures[0].save(OUT/'progression-animation.gif',save_all=True,append_images=captures[1:],duration=100,loop=0)
changes=sum(ImageChops.difference(a,b).getbbox() is not None for a,b in zip(captures,captures[1:]))
result={'resources':integrity,'renderer_frames':len(captures),'interval_ms':100,'changing_transitions':changes,'fixture_note':'Resource playback showcase; the final orb collection is real. Gameplay rewards are verified by progression_integration_test.gd.'}
(OUT/'progression-animation-review.json').write_text(json.dumps(result,indent=2)+'\n')
assert changes>0
print(json.dumps({'animated_resources':len(integrity),'renderer_frames':len(captures),'changing_transitions':changes}))
