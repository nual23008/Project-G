#!/usr/bin/env python3
"""Review exported pixels and package real engine playback, without editing art."""
from collections import defaultdict
from pathlib import Path
import hashlib
import json
import statistics
from PIL import Image, ImageChops, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'tests/output'
DIRECTIONS = ['up_left', 'up', 'up_right', 'right', 'down_right', 'down', 'down_left', 'left']


def frame_for(sheet, metadata, index):
    w, h = metadata['frame_size']
    cols = metadata['columns']
    return sheet.crop((index % cols*w, index//cols*h, index % cols*w+w, index//cols*h+h))


def art_review():
    metadata = json.loads((ROOT / 'resources/art/manifest.json').read_text())['player']
    sheet = Image.open(ROOT / metadata['texture'].removeprefix('res://')).convert('RGBA')
    result = {}
    for name, state in metadata['states'].items():
        frames = [frame_for(sheet, metadata, i) for i in state['indices']]
        # Compare visible RGBA, never hidden RGB in transparent regions.
        for frame in frames:
            pixels = frame.load()
            for y in range(frame.height):
                for x in range(frame.width):
                    if not pixels[x,y][3]:
                        pixels[x,y] = (0,0,0,0)
        unique = len({hashlib.sha256(f.tobytes()).hexdigest() for f in frames})
        assert unique > 1, (name, 'static clip')
        if name.startswith('walk_'):
            assert unique == 6, (name, 'walk needs six distinct drawings')
        if name.startswith(('idle_', 'walk_', 'hurt_')):
            assert all(f.getbbox()[3] == 60 for f in frames), (name, 'ground/pivot drift')
        changes = []
        for a, b in zip(frames, frames[1:] + frames[:1]):
            pixels_a, pixels_b = a.tobytes(), b.tobytes()
            changes.append(sum(pixels_a[i:i+4] != pixels_b[i:i+4] for i in range(0,len(pixels_a),4)))
        nonzero = [n for n in changes[:-1] if n]
        seam_ratio = changes[-1] / max(1, statistics.median(nonzero))
        if state['loop']:
            assert seam_ratio < 2.5, (name, 'loop seam spike', seam_ratio)
        result[name] = {'playback_frames':len(frames),'distinct_drawings':unique,
                        'reused_drawings':len(frames)-unique,'fps':state['fps'],
                        'loop':state['loop'],'last_to_first_change':changes[-1],
                        'seam_vs_median_step':round(seam_ratio,3)}
    return result


def package_grid(clips, kind, directions, count, durations):
    composites = []
    for index in range(count):
        composite = Image.new('RGB', (4*288, ((len(directions)+3)//4)*244), '#282431')
        draw = ImageDraw.Draw(composite)
        for cell, direction in enumerate(directions):
            records = clips[kind+'_'+direction]
            source = records[index]
            picture = Image.open(ROOT / source['path'].removeprefix('res://')).convert('RGB')
            assert picture.size == (640,360), picture.size
            crop = picture.crop((248,104,392,216)).resize((288,224),Image.Resampling.NEAREST)
            x,y = cell%4*288,cell//4*244
            composite.paste(crop,(x,y+20))
            draw.text((x+4,y+4), f'{kind}_{direction} / frame {source["frame"]}',fill='#f6e3b0')
        composites.append(composite)
    composites[0].save(OUT / f'eight-direction-{kind}.gif', save_all=True,
                       append_images=composites[1:],duration=durations,loop=0,disposal=2)
    return composites


def main():
    art = art_review()
    record = json.loads((OUT / 'eight-direction-motion.json').read_text())
    assert record['failures'] == 0
    clips = defaultdict(list)
    for sample in record['samples']:
        clips[sample['clip']].append(sample)
    observations = {}
    for direction in DIRECTIONS:
        walking = clips['walk_'+direction]
        idle = clips['idle_'+direction]
        assert len(walking) == 24 and len(idle) == 8
        assert all(s['animation'] == 'walk_'+direction for s in walking), direction
        assert len({s['frame'] for s in walking}) == 6, direction
        assert all(s['animation'] == 'idle_'+direction for s in idle), direction
        assert len({s['frame'] for s in idle}) >= 6, direction
        assert len({tuple(s['position']) for s in idle}) == 1, (direction,'idle drift')
        observations[direction] = {'walk_samples':24,'walk_frames_observed':6,
                                   'idle_samples':8,'idle_frames_observed':len({s['frame'] for s in idle}),
                                   'walk_start':walking[0]['position'],'walk_end':walking[-1]['position']}
    walk = package_grid(clips,'walk',DIRECTIONS,24,[30,30,40]*8)
    package_grid(clips,'idle',DIRECTIONS,8,200)
    diagonals = [d for d in DIRECTIONS if '_' in d]
    attacks = package_grid(clips,'attack',diagonals,18,[20,10,20]*6)
    package_grid(clips,'hurt',diagonals,7,[30,30,40,30,30,40,30])
    deaths = package_grid(clips,'death',diagonals,18,50)
    walk[5].save(OUT / 'eight-direction-in-game.png')
    for kind,sequence,indices in [('walk',walk,[0,3,6,9,12,15,18,23]),
                                  ('attack',attacks,[0,2,4,5,6,8,12,17]),
                                  ('death',deaths,[0,2,4,6,8,11,14,17])]:
        contact = Image.new('RGB',(sequence[0].width*2,sequence[0].height*4),'#282431')
        for cell,index in enumerate(indices):
            contact.paste(sequence[index],(cell%2*sequence[0].width,cell//2*sequence[0].height))
        contact.save(OUT / f'eight-direction-{kind}-contact.png')
    result = {'ok':True,'renderer':record['renderer'],'engine_samples':len(record['samples']),
              'art_states':art,'observed_engine_directions':observations,
              'note':'Real world renderer driven by movement input; idle runs without input. Contact damage asserted separately by player_eight_direction_test.gd. GIF timing quantized to 10ms with preserved average.'}
    (OUT / 'eight-direction-animation-review.json').write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps({'ok':True,'clips':len(art),'engine_samples':len(record['samples']),'directions':len(observations)}))


if __name__ == '__main__':
    main()
