#!/usr/bin/env python3
"""Forge audits and loopcheck, plus lossless packaging of engine cel captures."""
from pathlib import Path
from PIL import Image,ImageChops
import sys,json,contextlib,io,argparse,hashlib
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'tests/output';FRAMES=OUT/'races'
FORGE=Path('/home/luan/.codex/plugins/cache/pixel-studio/pixel-art-forge/0.2.0/skills/pixel-art-forge')
sys.path.insert(0,str(FORGE/'scripts'));import pixel_forge as forge
sys.path.insert(0,str(ROOT/'tools'));from race_heads import RAMPS
sys.path.insert(0,str(ROOT/'tests'));from equipment_art_test import frame,MANIFEST

def main():
    review=json.loads((OUT/'races-render-review.json').read_text());assert not review['failures']
    loops={};audits={};render_guards=0;audit_dir=OUT/'races-forge';audit_dir.mkdir(exist_ok=True)
    for race in ['human','elf','dwarf','orc']:
        for state in ['idle','walk','attack','hurt','death']:
            frames=[Image.open(FRAMES/('gallery_'+state+'_%02d.png'%i)).convert('RGB') for i in range(MANIFEST['player']['states'][state+'_down']['count'])]
            # Exact renderer captures; every race/direction in one animation.
            if race=='human':frames[0].save(OUT/('races-'+state+'.gif'),save_all=True,append_images=frames[1:],duration=round(1000/MANIFEST['player']['states'][state+'_down']['fps']),loop=0)
            for direction in ['down','left','right','up','down_right','down_left','up_right','up_left']:
                id='player' if race=='human' else 'race_'+race+'_player';key=state+'_'+direction
                row=['human','elf','dwarf','orc'].index(race);col=['down','left','right','up','down_right','down_left','up_right','up_left'].index(direction)
                for index,render in enumerate(frames):
                    cel=frame('race_'+race+'_showcase',key,index)
                    expected=Image.new('RGBA',(96,64),'#282431');expected.alpha_composite(cel)
                    actual=render.crop((col*192,row*144+14,col*192+192,row*144+142)).resize((96,64),Image.Resampling.NEAREST)
                    diff=ImageChops.difference(expected.convert('RGB'),actual).crop(cel.getbbox())
                    assert diff.getbbox() is None,(race,key,index,'runtime composite / rear occlusion differs from the menu preview')
                    render_guards+=1
                paths=[]
                for i in range(MANIFEST[id]['states'][key]['count']):
                    path=audit_dir/(race+'_'+key+'_%02d.png'%i);frame(id,key,i).save(path);paths.append(str(path))
                unique=[];last=None
                for path in paths:
                    raw=Image.open(path).tobytes()
                    if raw != last: unique.append(path)
                    last=raw
                if state in ['idle','walk'] and len(unique)>2 and Image.open(unique[-1]).tobytes()==Image.open(unique[0]).tobytes(): unique.pop()
                buf=io.StringIO()
                with contextlib.redirect_stdout(buf):
                    code=forge.cmd_loopcheck(argparse.Namespace(frames=unique,anchor_tolerance=0,jump_ratio=2.5,seam_ratio=2.5,open_ended=state in ['attack','hurt','death']))
                loops[race+'_'+key]={'exit_code':code,'output':buf.getvalue(),'holds':MANIFEST[id]['states'][key]['frame_drawings']}
        if race=='human':continue
        # Palette declared from constructive source material constants + shared
        # equipment atlas: no palette snapping, synthetic AA or smoothing step.
        palette=set(json.loads((ROOT/'assets/races/palette.json').read_text())['colours'])
        forge.PALETTES['project_'+race]=sorted(palette)
        materials=[','.join([RAMPS[race][1],RAMPS[race][0],RAMPS[race][2]]),','.join(RAMPS[race][3:])]
        path=audit_dir/(race+'_idle_down_00.png')
        buf=io.StringIO()
        with contextlib.redirect_stdout(buf):
            code=forge.cmd_audit(argparse.Namespace(infile=str(path),palette='project_'+race,max_colors=32,max_isolated=.02,min_run_share=.25,aa_tolerance=10,min_tonal_gap=6,max_smooth_gaps=2,light='tl',material=materials,light_band=90,ui=False,ui_flat_min=.45,ui_tones=6,max_jaggy=8,json=True))
        output=buf.getvalue();audits[race]={'exit_code':code,'output':output,'palette':sorted(palette),'materials':materials}
    # Exact review image checks, downscaled only in UI display, no editing assets.
    sys.path.insert(0,str(ROOT.parent/'.agents/skills/scenario-godot-expert/scripts'))
    import gd_review
    checks={str(p.relative_to(OUT)):gd_review.image_checks(p) for p in FRAMES.glob('*.png')}
    (OUT/'races-forge-review.json').write_text(json.dumps({'loops':loops,'audits':audits,'image_checks':checks,'rendered_composites':render_guards},indent=2)+'\n')
    # Clockwise turn review, directly from the engine's idle cels. Four races
    # side by side, so front/rear hand and sword occlusion remain inspectable.
    turns=[];directions=['down','down_left','left','up_left','up','up_right','right','down_right'];cols=['down','left','right','up','down_right','down_left','up_right','up_left']
    for direction in directions:
        for index in [0,3]:
            source=Image.open(FRAMES/('gallery_idle_%02d.png'%index)).convert('RGB')
            strip=Image.new('RGB',(768,144),'#282431')
            for row in range(4):
                col=cols.index(direction)
                strip.paste(source.crop((col*192,row*144,col*192+192,row*144+144)),(row*192,0))
            turns.append(strip)
    turns[0].save(OUT/'races-turning.gif',save_all=True,append_images=turns[1:],duration=160,loop=0)
    print('RACES_REVIEW:',len(loops),'clips;',sum(not x['exit_code'] for x in loops.values()),'loop checks passed;',len(checks),'engine captures;', {k:v['exit_code'] for k,v in audits.items()})
    for race,data in audits.items():
        print(race,data['output'][-2200:])
    for key,result in loops.items():
        if result['exit_code']:print(key,result['output'])
if __name__=='__main__':main()
