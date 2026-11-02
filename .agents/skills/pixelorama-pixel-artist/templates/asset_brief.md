# Asset specification — {{asset_id}}

| Field | Value |
|---|---|
| Kind | player / npc / enemy / item / tileset / prop / vfx / ui |
| Role and visible identity | {{gameplay role, silhouette, costume/material}} |
| Design family | {{stable design_id; match existing states}} |
| Source and credit | {{.pxo path, artist/source, license, references}} |
| Frame size / tile size | {{width,height}} / {{16,16 for tilesets}} |
| Pivot from top-left | {{x,y}}; fixed across states |
| Palette / light | {{style-guide section and swatches}} |
| Runtime sheet / resource | {{PNG path}} / {{SpriteFrames or TileSet path}} |
| Frame layout | {{columns, rows, declared cell count; zero-based row-major}} |
| Alpha / guard | binary or smooth / {{edge_padding}} |
| Runtime consumer | {{scene/node/script that uses it}} |

## Behavior and states

| State | Directions | Drawings and holds | Timing/loop | Motion intent |
|---|---|---|---|---|
| idle / ambient | {{directions or none}} | {{real distinct count + holds}} | {{FPS/durations}}, loop | {{breathing/material motion}} |
| walk, if mobile | down/left/right/up | {{count}} | {{FPS}}, loop | {{contacts, stride}} |
| attack, if used | {{directions}} | {{count}} | {{durations}}, once | {{windup/contact/recovery}} |
| hurt, if used | {{directions}} | {{count}} | {{durations}}, once | {{recoil}} |
| death, if used | {{directions}} | {{count}} | {{durations}}, once | {{fall, final pose}} |

Remove unused behavior rows explicitly. Transient VFX use `play` rather than a persistent idle; slash and impact are separate assets. Items need a recognizable icon and ambient loop. Persistent props/terrain/UI in this project need true ambient motion even when untouched; a static placeholder is pending work.

## Tileset supplement (when applicable)

Record tile roles/coordinates, 16×16 cell grid, seamless edge/corner tests, variant weights, collision footprints, terrain peering plan, and animation frame order/FPS. Pack each animated tile's frames horizontally in one row for a simple Godot atlas setup. Export tiles, not a flattened map screenshot. Opaque ground can set `require_transparency: false`; the PNG should retain alpha capability for cutouts.

## Acceptance

- Approved family appearance across states and directions; pivot/feet stable, limbs and weapon never clipped.
- Sheet dimension/alpha/palette checks and true drawing counts pass; intentional blank VFX cells and holds documented.
- Timed loop and transition previews inspected; attack body/VFX/damage contact verified in engine if applicable.
- Resource and registry entry use actual files; idle plays without input; save/gameplay regression checks pass when game assets change.
- Evidence and remaining defects: {{paths, checks, pending work}}.

Convert these decisions into `art_spec.json` using [the specification contract](../references/specification.md). The prose brief carries visual intent; the JSON carries measurable export facts.
