# Machine specification contract

All three scripts accept the same `art_spec.json`, an offline staging document. Paths in `sheet` resolve against `--root` (default: the spec's directory). Use forward-slash relative paths without `..`; `--root game` means `sheet: "assets/art/characters/hero.png"` maps to `res://assets/art/characters/hero.png`. Do not put `game/` or `res://` into `sheet`.

This schema is intentionally independent of Pixelorama's native JSON export and this project's live art registry. Native Pixelorama JSON may be kept as export evidence; it is not parsed by these helpers. Inspect and map tags, frame order, and timings into this specification. Never overwrite a live registry with the staging manifest.

## Root object

| Field | Meaning |
|---|---|
| `schema_version` | Integer `1` |
| `palette` | Optional nonempty array of `#RRGGBB` colors; visible pixels must use these RGB values |
| `assets` | Nonempty array of asset objects |

## Asset object

| Field | Meaning |
|---|---|
| `id` | Required unique lowercase snake_case; must equal PNG basename |
| `kind` | `player`, `npc`, `enemy`, `item`, `tileset`, `prop`, `vfx`, or `ui` |
| `design_id` | Required nonempty identity string; preserve existing IDs including version separators |
| `source`, `credit` | Required strings describing editable source and author/license/reference provenance |
| `sheet` | Required existing single-image PNG, relative to root |
| `frame_size` | Required `[width,height]`, positive integers |
| `pivot` | Required integer `[x,y]` in pixels from frame top-left; frame-edge pivots allowed |
| `sheet_frame_count` | Required positive declared timeline cell count; ≤ grid capacity |
| `animations` | Required nonempty array of clips |
| `palette` | Optional per-asset palette overrides root palette |
| `alpha_mode` | `binary` (default, alpha 0/255) or `smooth` (documented exception, e.g. VFX) |
| `require_transparency` | Boolean, default `true`; every referenced nonempty frame needs transparent pixels. Set `false` for opaque ground tiles |
| `persistent` | Boolean, default `true` except VFX. Persistent types require looping idle/ambient |
| `edge_padding` | Optional integer transparent guard, default 0. Actors commonly use 1; seamless tiles use 0 |
| `allow_empty_frames` | Optional array of sheet indices intentionally blank (e.g. final disappearing VFX); default none |
| `tile_size` | Required for tilesets; equals frame_size, normally `[16,16]` |

The grid is tightly packed and untrimmed; dimensions must be exact multiples of the frame size. Index `i` has rectangle `[(i % columns)*width, (i // columns)*height, width, height]`. Cells past `sheet_frame_count` must be transparent. Unreferenced cells within the count are reported for review, not treated as played frames. Sources/credits are recorded but their license claims and `.pxo` contents require human verification.

## Animation object

| Field | Meaning |
|---|---|
| `name` | Unique lowercase snake_case within the asset, e.g. `walk_down` |
| `state` | Lowercase snake_case, e.g. idle/walk/attack/hurt/death/ambient/play |
| `direction` | up/down/left/right/none; default none |
| `frames` | Nonempty explicit array of zero-based sheet indices in playback order; reuse allowed for honest holds |
| `fps` | Required finite positive number |
| `loop` | Required boolean; transient VFX require a non-looping play clip |
| `durations_ms` | Optional array of positive milliseconds, one per playback frame. If omitted, use `1000/fps` |
| `min_unique` | Optional positive distinct visible drawing threshold; default 2 for multi-frame clips, 1 for single-frame clips. Idle/ambient/play always require at least 2 |
| `contact_frame` | Optional zero-based index into this clip's playback frames, not an absolute sheet index |

The specification supports explicit forward playback. For ping-pong, write out the desired sequence and durations, avoiding accidental doubled endpoints. Pixelorama's displayed frame numbers start at 1; JSON indices start at 0. For variable timing, set Pixelorama duration multipliers from `duration_ms * project_timeline_fps / 1000`; PNG alone stores no timing.

## Commands and outputs

```bash
python3 <skill>/scripts/validate_assets.py art_spec.json --root game --json-report /tmp/asset-report.json
python3 <skill>/scripts/check_animation_sheet.py art_spec.json --root game --asset hero
python3 <skill>/scripts/export_manifest.py art_spec.json --root game \
  --output /tmp/art-manifest.json --godot-dir resources/art/pixelorama
```

Both validators return JSON to stdout and exit 0 on success or 1 on validation errors. `--json-report` writes the same report to an existing parent directory. Errors in one asset are collected so a batch can be repaired together. The animation checker validates every PNG, then optionally limits its detailed motion checks with `--asset`.

The exporter checks every asset/clip before writing. JSON includes grid, dimensions, pivot, source, credit, animation FPS/loop/direction, explicit frame rectangles and milliseconds, distinct drawing counts, and contact times. Optional `.tres` files use `AtlasTexture` subresources and relative frame durations. Tilesets receive JSON metadata only. Output is deterministic; existing files cause exit 1 unless `--force` is supplied. Each file is replaced atomically, but a multi-file export is not a transaction: rerun after resolving any interrupted write.

Duplicate drawings are compared after clearing invisible RGB, so transparent RGB noise cannot satisfy uniqueness. Repeated poses can be valid timing holds; `reused_drawings` and `adjacent_holds` make them visible. A script pass does not prove silhouette consistency, meaningful motion, foot alignment, tile seams, or damage timing. Inspect rendered sheets, timed previews, and the runtime.
