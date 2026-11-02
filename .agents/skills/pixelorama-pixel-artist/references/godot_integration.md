# Godot 4 integration

## AnimatedSprite2D and SpriteFrames

Export the untrimmed PNG inside the Godot project, then use either generated `.tres` resources or the editor's SpriteFrames panel to add named animations from a sheet. For manual slicing, set the actual sheet columns/rows, select the specified cells in playback order, and match FPS, loop, and individual frame durations. Save a dedicated resource for each visible type.

The helper uses broadly supported Godot 4 serialization (`animations`, `loop`, `speed`, `AtlasTexture`). Verify import on the project's installed version. A generated `metadata/pivot` records intent; SpriteFrames does not automatically move the sprite to that pivot.

For a new scene whose actor origin is the ground contact:

```gdscript
# Example values for a new 32x32 hero. Keep the project's actual family values.
@onready var art: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
    art.sprite_frames = preload("res://resources/art/pixelorama/hero.tres")
    art.centered = false
    art.offset = -Vector2(16, 30) # pivot from the frame's top-left
    art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    art.play(&"idle_down")
```

If retaining `centered = true`, use `offset = frame_size / 2 - pivot` with even/integer dimensions; do not combine both offset formulas. Position the collision shape independently at the feet, and keep shadow/weapon origins consistent. Respect existing controller ownership of animation and facing; avoid restarting the clip every frame or adding a second animation clock. Four displayed directions can accompany eight-direction movement if the controller resolves facing consistently.

SpriteFrames durations are relative: `absolute_seconds = relative_duration / fps` at normal playback speed. The exporter computes `relative_duration = duration_ms * fps / 1000`. It does not connect combat signals. Gameplay must cause damage once at the existing contact tick, with body/slash on matching contact frames; confirm interruptions and VFX origins in the engine.

Use nearest texture filtering, lossless texture import, and normally disable mipmaps for 1× pixel art. Keep the project's current viewport/integer-scaling arrangement. A 16px tile should occupy the same logical grid space after import. Inspect in motion for half-pixel placement and jitter.

## TileMap-ready exports

For the helper's tile specifications, export a tight atlas with no external margins/separation. Each grid cell is one 16×16 tile (or an approved override), with no trim or rotation. Larger decorative objects usually belong in prop scenes. Preview a repeated patch in Pixelorama to inspect seams, transitions, corners, and variant distribution.

In Godot, create a TileSet with tile size 16×16, add a `TileSetAtlasSource` using the PNG, set `texture_region_size` to 16×16 and margins/separation to zero, and expose the intended base tiles. Use `TileMapLayer` on Godot 4.3+; older Godot 4 projects can retain their `TileMap` workflow.

For an animated water atlas arranged as 4 columns × N rows, each row is one tile variant across four phases. For a row's base tile at `(0,row)`, configure animation columns 4, frame count 4, speed per the brief, and relative durations. Reserve the phase cells for animation instead of exposing them as unrelated static terrain. Validate every phase is a different useful drawing. The helper's `ambient_<variant>` clips specify those phase indices and timings. Review TileSet animation settings in the installed version rather than assuming PNG metadata imports them.

Set terrain sets/peering bits, collision polygons/layers, navigation, and variant probabilities from the tile brief. The helper cannot infer them from pixels. In this project, register terrain resources in the existing manifest format and ensure ambient animation is actually played. Consider independent phase for repeated ambient elements when supported.

## Verify integration

Run headless import with the installed engine, then the project's required checks. For this repository, run `bash game/tools/check.sh`. Import alone cannot approve visuals: view real engine renders and motion showing idle without input, walk loops in every direction, transitions, clipping, and contact. Use disposable test saves for combat/save checks. Record resources, consumers, preview files, results, and gaps in the project progress document.

Official references: [2D sprite animation](https://docs.godotengine.org/en/stable/tutorials/2d/2d_sprite_animation.html), [SpriteFrames](https://docs.godotengine.org/en/stable/classes/class_spriteframes.html), [AnimatedSprite2D](https://docs.godotengine.org/en/stable/classes/class_animatedsprite2d.html), [TileSetAtlasSource](https://docs.godotengine.org/en/stable/classes/class_tilesetatlassource.html).
