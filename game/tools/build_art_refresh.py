#!/usr/bin/env python3
"""Merge disjoint art-group builds; never silently fall back to retired textures."""
from pathlib import Path
import json
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / 'assets/art_refresh'
GROUPS = ['actors', 'props', 'world', 'ui_fx', 'progression', 'polish', 'equipment', 'races']
REQUIRED = {'player','rowan','enemy','house','pine','oak','rock','lamp','crystal','fence','sign','fern','flowers','chest','portal',
            'rust_sword','potion','herb','ore','echo_shard','grass','stone_path','water','shore','firefly','glow',
            'ui_panel','ui_button','ui_health','sword_slash','enemy_strike','hit_spark','enemy_telegraph',
            'experience_orb','level_up','empowered_slash','ui_experience','ui_energy','ui_stamina','ui_stats_panel','footstep_dust','falling_leaf'}
CATALOG = json.loads((ROOT / 'resources/items/items.json').read_text())
REQUIRED.add('player_hands')
for item, data in CATALOG.items():
    if data.get('allowed_slots'):
        REQUIRED.add(item)
        REQUIRED.update('gear_'+item+'_'+slot for slot in data['allowed_slots'])

for race in ['human','elf','dwarf','orc']:
    REQUIRED.update('race_'+race+'_'+part for part in ['card','showcase'])
    if race != 'human':
        REQUIRED.update('race_'+race+'_'+part for part in ['player','player_hands','heritage'])
        for item,data in CATALOG.items():
            REQUIRED.update('race_'+race+'_gear_'+item+'_'+slot for slot in data.get('allowed_slots',[]))


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
        if name not in {'sword_slash','enemy_strike','hit_spark','enemy_telegraph','empowered_slash','level_up','footstep_dust'}:
            idle = [s for n,s in entry['states'].items() if n.startswith('idle') or n == 'normal']
            assert idle and all(s['count'] > 1 and s['loop'] for s in idle), (name, 'missing ambient loop')
    (ROOT / 'resources/art/manifest.json').write_text(json.dumps(registry,indent=2,ensure_ascii=False) + '\n')
    print('Active new visual designs:', len(registry), '; no retired texture fallback.')


if __name__ == '__main__':
    if '--merge-only' not in sys.argv:
        for script in ['build_refresh_actors.py','build_refresh_props.py','build_refresh_world.py','build_refresh_ui_fx.py','build_progression_art.py','build_polish_art.py','build_equipment_art.py','build_race_art.py']:
            subprocess.run([sys.executable,str(ROOT / 'tools' / script)],check=True)
    merge()
