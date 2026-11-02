# Pixel art style guide — {{project}}

Replace the template fields with approved decisions; sample choices are starting points, not permission to change an established style.

## Format and scale

| Property | Decision |
|---|---|
| Engine/camera | Godot 4 / top-down |
| Tile grid | 16×16 px unless project overrides |
| Character frame | Choose 32×32 or 48×48; retain existing family canvas |
| Visible body height / head-to-body ratio | {{pixels and ratio}} |
| Editable master | Layered Pixelorama `.pxo` |
| Runtime export | PNG, 1×, transparent background, regular untrimmed grid |
| Alpha | Binary 0/255; smooth alpha only for a documented VFX need |
| Pivot | {{x,y}} pixels from frame top-left; feet remain registered |
| Nearest review scale | 1× and integer zoom; no smoothed resize |

## Palette and materials

Extract approved swatches from the active project before selecting new colors. Store RGB hex values and roles in this table and in the machine specification's `palette`. This repository favors warm amber light, brown wood, burgundy, plum shadows, and cream stone, with clear separation from the forest. Do not claim these suggested hex values were sampled from existing art.

| Role | Suggested starting color | Approved RGB |
|---|---|---|
| Deep outline | `#241D2B` | {{hex}} |
| Plum shadow | `#49314D` | {{hex}} |
| Burgundy cloth | `#7D3544` | {{hex}} |
| Brown wood/leather | `#79523C` | {{hex}} |
| Amber highlight | `#D9A657` | {{hex}} |
| Cream stone | `#E5D4AA` | {{hex}} |
| Forest midtone | `#415B45` | {{hex}} |

Specify light direction, outline treatment, contrast hierarchy, metal/cloth/wood ramps, and permitted color additions: {{decisions}}. Avoid isolated noise, inconsistent antialiasing, and palette drift between states. VFX should not obscure actor silhouettes at contact.

## Identity and alignment

- Character landmarks: {{head width, shoulder width, torso/leg lengths, costume, weapon hand}}.
- Directional reference poses and distinguishing silhouette: {{approved reference files}}.
- Locked family values: {{design_id, canvas, pivot, light, equipment}}.
- Walk foot contacts and allowed vertical motion: {{per direction}}.
- Safe bounds for weapon reach, hurt, and death: {{edge guard / canvas allowance}}.
- Props/tiles: leaves sway, flame flickers, water ripples, stone glints subtly; rigid buildings/rocks retain their structure. {{approved ambient amplitude and phase rules}}.

## Names and folders

Use lowercase snake_case asset IDs, filenames matching IDs, and `state_direction` animation tags. Directions are `down`, `left`, `right`, `up`; nondirectional clips may use the state alone. Keep existing project IDs stable.

Suggested structure for a new family; adapt to established folders rather than duplicating them:

```text
game/
  art_spec.json
  art/
    briefs/hero.md
    style_guide.md
    source/characters/hero.pxo
    palettes/fantasy_palette.png
  assets/art/characters/hero.png
  assets/art/tilesets/forest_ground.png
  assets/art/items/healing_potion.png
  assets/art/props/lantern.png
  assets/art/vfx/sword_slash.png
  resources/art/pixelorama/hero.tres
  resources/art/pixelorama_export.json
  tests/output/art/hero_walk_down.apng
```

Master categories include player/NPC/enemy under `characters/`, plus items, tilesets, props, and VFX. Use separate type IDs for visually different designs. Store source credits/licenses and references in briefs. Do not redistribute reference images without permission.

## Review evidence

Record the sheet/contact sheet, timed motion preview, state-transition review, Godot resource/runtime consumer, and checks run: {{paths and findings}}. Metadata and byte uniqueness alone cannot approve art quality.
