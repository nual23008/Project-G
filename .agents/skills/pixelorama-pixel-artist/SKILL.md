---
name: pixelorama-pixel-artist
description: Plan, draw, refine, and validate top-down fantasy RPG sprites, tiles, and animations in Pixelorama, then prepare PNGs and Godot 4 resources. Use for a Pixelorama art pipeline or asset work; not for unrelated gameplay programming.
---

# Pixelorama Pixel Artist

Use Pixelorama as the primary drawing, cel editing, and animation tool. Codex handles planning, naming, repeatable validation, metadata, and Godot integration. Preserve layered `.pxo` masters alongside exported transparent PNGs. Never use paid APIs without explicit approval; this workflow works locally without APIs.

## Establish the contract

Read the target project's `AGENTS.md`, art manifest, existing style guide, and relevant runtime resource before changing art. In this repository, also read `game/docs/PROGRESS.md` and `game/docs/ARCHITECTURE.md`. Reuse current folders, names, identity, pivots, and timing where established.

Defaults for a new asset family: Godot 4, top-down fantasy, 16×16 tiles, 32×32 character frames (48×48 when detail needs it), transparent PNG at 1×. Existing project dimensions take priority: this project's player is currently 96×64 with pivot (48,60). Do not resize an existing family to a default. Read actual resources to verify current values.

Create or update these deliverables using the templates:

- [Style guide](templates/style_guide.md): palette, materials, scale, proportions, lighting, silhouette, alignment, naming, and folder structure.
- [Asset brief](templates/asset_brief.md): one specification per visible type, source/credit, dimensions, pivot, states, and acceptance evidence.
- [Animation brief](templates/animation_brief.md): drawing count versus playback holds, directions, timing, loop, contacts, and transitions.

Plan only behaviors that exist or are requested. Actors need idle/walk/attack/hurt/death when those behaviors exist. Items need distinct icons and idle loops; props and terrain need material-appropriate ambient loops. Transient VFX use their own play sequence. In this project, every new persistent visible type, including UI backgrounds, needs a real idle/ambient loop before entering a scene. Instances of one type can share assets; different visual designs need separate sheets/resources.

## Produce and refine in Pixelorama

First discover whether a usable Pixelorama editor integration or local executable exists. Do not invent automation commands. If desktop CLI is available, check its installed `-- --help` before scripting export; CLI export support does not imply a drawing API. Native `.pxo` is the editable source, not a Godot runtime image.

When direct editor automation is unavailable, prepare briefs and an export contract, then give the artist these manual steps. Continue any metadata or tooling work independently. Record drawing/export as pending until files actually exist; never claim manual editor work happened.

1. Open/create the project with the approved frame dimensions. Load the agreed palette and mark foot/pivot guides. Separate sketch, silhouette, color, details, and optional shadow/VFX layers; hide non-export guides and sketches.
2. Resolve the base pose and four directional silhouettes before adding frames. Keep costume, anatomy, light direction, palette, and equipment handedness consistent. Mirror only when asymmetry permits it, then correct lighting and accessories.
3. Add and edit cels on the timeline; use onion skinning to track feet and volumes. Use tags named `idle_down`, `walk_left`, etc. Edit distinct drawings after duplication; linked identical cels are holds, not new poses.
4. Set playback and per-frame durations to the animation brief. Preview each tag, the last→first seam, and state changes at 1× and nearest zoom. Inspect foot plants, weapon arcs, silhouette readability, and clipping. Record timing changes in the machine spec.
5. Save the layered `.pxo`. In File → Export, select a PNG spritesheet, approved frame/tag range and visible layers. Use the prescribed columns, forward order, 1× scale, transparency, and no trimming or packing rotation. Export an animated preview separately; keep previews out of runtime textures. Reopen the sheet and verify the export preview matches the specification.

For large batches, export a single pilot first and validate it before repeating. Refine the master and re-export rather than painting over generated PNGs. AI references, if separately authorized, still require Pixelorama cleanup and matching every state to the same design; do not substitute an image API for this workflow.

## Validate and export metadata

Scripts require Python 3.10+ and Pillow. If missing, use a project virtual environment and `python -m pip install Pillow` within existing installation permissions. There are no network or API calls in the helpers.

Read [the specification contract](references/specification.md) when writing `art_spec.json`. It is a staging format, not the schema of an existing game registry. Keep the three scripts together because they share validation functions.

Run from the repository root, replacing `<skill>` with this skill's directory:

```bash
python3 <skill>/scripts/validate_assets.py game/art_spec.json --root game
python3 <skill>/scripts/check_animation_sheet.py game/art_spec.json --root game
python3 <skill>/scripts/export_manifest.py game/art_spec.json --root game \
  --output game/resources/art/pixelorama_export.json --godot-dir resources/art/pixelorama
```

The first script checks size/grid, binary alpha or declared smooth alpha, transparent background, optional palette, edge guards, indices/counts, and family canvas/pivot/palette agreement. The second counts distinct visible frames, reports holds/durations/contact time, and rejects static idle/ambient/play sequences. The exporter runs both checks before writing deterministic JSON and optional `SpriteFrames` `.tres` files. Reruns require `--force` only for outputs known to be generated. It never merges a live registry automatically.

These checks cannot judge anatomy, silhouette, foot placement, palette distribution, material quality, or gameplay contact. Review sheets and motion visually. Record an intentional hold honestly; changing a hidden transparent RGB value does not create a new drawing. Multiple instances should not all pulse in the same phase where random phase is appropriate.

## Integrate with Godot 4

Read [Godot integration](references/godot_integration.md) for pivot setup, variable durations, and TileSet preparation. Generated `SpriteFrames` resources use atlas regions; assign them to `AnimatedSprite2D`. The recorded pivot is metadata and must also be applied to the node's draw offset. Match the project's nearest filtering and scaling setup.

Tile sheets must use regular 16×16 cells by default, with documented terrain roles, seamless borders, collision intentions, and animated-tile layout. Exported tile metadata helps configure a `TileSetAtlasSource`; it does not infer terrain peering bits or generate a complete TileSet.

In this repository, adapt/merge reviewed entries into `game/resources/art/manifest.json` using its existing schema; preserve unrelated entries and IDs. Attach resources to runtime consumers and verify they actually play while waiting. Keep save/gameplay behavior intact. For attack art, synchronize body, separate slash/hit VFX, and hitbox damage on the same contact tick, respecting the existing combat clock.

When changing game assets, run Godot import and `bash game/tools/check.sh`; inspect real rendered images and motion previews as required by project rules. Use test saves. A tooling-only skill edit can be verified using isolated fixtures without modifying the game. Report completed checks and pending manual/engine review accurately in the relevant progress record.

## Example and authoritative references

Use [the main-character workflow](references/main_character_workflow.md) and its runnable [specification](references/main_character_spec.json) for four-direction walk, idle, spritesheet export, and Godot import. This is an art production example, not finished character artwork.

Consult installed-version help and official documentation when UI labels or APIs differ:

- Pixelorama: [save/export](https://pixelorama.org/user_manual/save_and_export/), [timeline and tags](https://pixelorama.org/user_manual/user_interface/timeline/), [CLI](https://pixelorama.org/user_manual/cli/), [tilemaps](https://pixelorama.org/user_manual/tilemaps/).
- Godot: [SpriteFrames](https://docs.godotengine.org/en/stable/classes/class_spriteframes.html), [AnimatedSprite2D](https://docs.godotengine.org/en/stable/classes/class_animatedsprite2d.html), [TileSetAtlasSource](https://docs.godotengine.org/en/stable/classes/class_tilesetatlassource.html).
