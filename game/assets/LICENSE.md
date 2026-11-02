# Asset provenance

The active runtime set is `art_refresh`, built by `tools/build_art_refresh.py`. New house/tree/actor identities use original project-owned ImageGen sources in `art_v3/sources`; the matching hero attack was created with built-in image_gen on 2026-11-02 and is stored with its generation record in `art_refresh/sources`. Source packing uses hardened alpha, nearest-neighbour sampling and local layer animation. Supporting props, items, terrain, UI and VFX were drawn anew from blank canvases with native pixel tools. The active set does not use retired `assets/sprites` or `art_stage1` pixels as input. Its 33 types have source/animation metadata in `resources/art/manifest.json`.

`art_stage1` and the Phase 1/2 generators are retained as retired history. `icon.svg` is original. Project-owned generated art may be used, modified and redistributed with this game; no external art library is required. No pixels from the user's mood reference are included in the game.

The user-provided image is a mood/palette reference only. Its pixels are not shipped in the game. The current art is an early original foundation, not a reproduction of that finished illustration.

`fonts/NotoSans-Regular.ttf`: Noto Sans, Google/Noto contributors, SIL Open Font License 1.1. Full distribution copyright and license are in `fonts/LICENSE-Noto.txt`. Font copied from the installed Debian package; no system font dependency at runtime.

Phase 1 has no audio assets. Audio/ambience belongs to the later content pass.
