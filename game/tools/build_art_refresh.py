#!/usr/bin/env python3
"""Merge disjoint art-group builds; never silently fall back to retired textures."""
from pathlib import Path
import json
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / 'assets/art_refresh'
GROUPS = ['actors', 'props', 'world', 'ui_fx']
REQUIRED = {'player','rowan','enemy','house','pine','oak','rock','lamp','crystal','fence','sign','fern','flowers','chest','portal',
            'rust_sword','potion','herb','ore','echo_shard','grass','stone_path','water','shore','firefly','glow',
            'ui_panel','ui_button','ui_health','sword_slash','enemy_strike','hit_spark','enemy_telegraph'}


def merge():
    registry = {}
    for group in GROUPS:
        fragment = json.loads((BASE / 'manifests' / (group + '.json')).read_text())
        assert not registry.keys() & fragment.keys(), group + ': overlapping writer IDs'
        registry.update(fragment)
    assert set(registry) == REQUIRED, ('missing', REQUIRED - registry.keys(), 'extra', registry.keys() - REQUIRED)
    for name, entry in registry.items():
        assert entry['texture'].startswith('res://assets/art_refresh/sheets/'), (name, 'retired texture')
        entry['revision'] = 'art_refresh'
        entry['design_id'] = 'new_20261102:' + name
        for state in entry['states'].values():
            state['design_id'] = entry['design_id']
        if name not in {'sword_slash','enemy_strike','hit_spark','enemy_telegraph'}:
            idle = [s for n,s in entry['states'].items() if n.startswith('idle') or n == 'normal']
            assert idle and all(s['count'] > 1 and s['loop'] for s in idle), (name, 'missing ambient loop')
    (ROOT / 'resources/art/manifest.json').write_text(json.dumps(registry,indent=2,ensure_ascii=False) + '\n')
    print('Active new visual designs:', len(registry), '; no retired texture fallback.')


if __name__ == '__main__':
    if '--merge-only' not in sys.argv:
        for script in ['build_refresh_actors.py','build_refresh_props.py','build_refresh_world.py','build_refresh_ui_fx.py']:
            subprocess.run([sys.executable,str(ROOT / 'tools' / script)],check=True)
    merge()
