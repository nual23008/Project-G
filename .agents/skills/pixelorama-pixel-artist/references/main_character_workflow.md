# Example: main character, idle and four-direction walk

This is a reusable production exercise for a new character family. It does not include finished art and does not replace this repository's active hero. If used for the existing hero, retain its actual canvas/pivot and all gameplay states, including attack/hurt/death. An idle/walk-only example cannot be declared a complete combat character.

## Brief

Create `hero`, a top-down fantasy traveler: brown hair, cream scarf, burgundy waistcoat, dark trousers, amber highlights, plum shadows, light from upper left. Use 32×32 frames and pivot (16,30) for this new example, with a 1px transparent guard. Use the palette in [main_character_spec.json](main_character_spec.json); it is a proposed example palette, not a sample of the project's active art.

Prepare the three templates in the game's art planning folder. Establish a readable 24–28px silhouette and fixed feet before animation. No API or paid service is needed.

## Pixelorama production

1. Create a 32×32 transparent project. Save as `game/art/source/characters/hero.pxo`. Create sketch, silhouette, color, and details layers. Set palette and guides at x=16/y=30; keep non-art guides hidden on export.
2. Draw all four base views, checking scarf length, head volume, waistcoat, and light direction. Do not mirror away equipment asymmetry. Keep silhouettes and palette ramps consistent.
3. Produce 40 timeline cels with the ranges below. Create matching tags and independently edit each drawing. For idle, use restrained scarf/breathing movement with stable feet. Walk uses contact→passing→recoil→opposite contact→passing→recoil; don't translate the whole figure to fake a stride.

| Tag | Pixelorama timeline (1-based) | Sheet indices (0-based) | Drawings | Playback |
|---|---|---|---|---|
| idle_down | 1–4 | 0–3 | 4 | 4 FPS, loop |
| idle_left | 5–8 | 4–7 | 4 | 4 FPS, loop |
| idle_right | 9–12 | 8–11 | 4 | 4 FPS, loop |
| idle_up | 13–16 | 12–15 | 4 | 4 FPS, loop |
| walk_down | 17–22 | 16–21 | 6 | 8 FPS, loop |
| walk_left | 23–28 | 22–27 | 6 | 8 FPS, loop |
| walk_right | 29–34 | 28–33 | 6 | 8 FPS, loop |
| walk_up | 35–40 | 34–39 | 6 | 8 FPS, loop |

4. A single timeline FPS can preview both timings: set it to 8 FPS, give idle frames duration multiplier 2× (250ms), and walk frames 1× (125ms). Alternatively preview each tag at its target FPS. The JSON specifies per-clip FPS; update it whenever artist timing changes.
5. Use onion skinning and tag playback; inspect seams and idle↔walk in each direction. Save an APNG preview per tag. Inspect at 1× and integer zoom against light and dark backgrounds. Keep ground contact fixed and verify no frame violates the 1px guard.

## Spritesheet export and checks

Export all 40 frames as a forward-order PNG spritesheet with 8 columns and 5 rows, transparent background, 1× scale, and no trim. Expected dimensions: **256×160**. This is a row-major timeline export, so some directional clips cross rows; use the index table instead of assuming one direction per sheet row. Save to `game/assets/art/characters/hero.png`, keeping the `.pxo` master.

From the repository root, copy the example spec to a new staging document such as `game/hero_art_spec.json`; do not replace an existing spec. Its paths are relative to `game/`. Replace the example `credit` with the real artist/license/source information before publishing. Use the actual skill directory for `<skill>`:

```bash
python3 <skill>/scripts/validate_assets.py game/hero_art_spec.json --root game
python3 <skill>/scripts/check_animation_sheet.py game/hero_art_spec.json --root game
python3 <skill>/scripts/export_manifest.py game/hero_art_spec.json --root game \
  --output game/resources/art/hero_pixelorama_export.json --godot-dir resources/art/pixelorama
```

Expect eight clips, 16 idle drawings and 24 walk drawings, each meeting its declared unique-drawing threshold. The scripts read PNGs, not `.pxo`; keep editor preview evidence separately. When drawing is pending, validation should fail on the missing PNG, not generate a substitute.

## Godot import

Import the PNG and generated `resources/art/pixelorama/hero.tres` in Godot. Assign the SpriteFrames to an `AnimatedSprite2D` below the actor; use `centered=false`, `offset=(-16,-30)`, and nearest filtering. Play `idle_down` at rest. Let the existing controller select `walk_down/left/right/up` while moving and the matching idle on release. Retain the last facing; avoid restarting animation each process tick.

Review every direction and idle↔walk transition in the engine at intended speed. In this repository, adapt the generated metadata into the existing `game/resources/art/manifest.json` schema before wiring it into the real world. Do not replace a live combat hero with this limited state set. Run the required game checks and view real renders/motion when integrating assets, then record actual results and remaining states in `PROGRESS.md`.
