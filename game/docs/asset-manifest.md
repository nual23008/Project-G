# Bộ đồ họa mới đang dùng

Manifest chuẩn: `resources/art/manifest.json`. 40 loại, 75 state, 546 lượt frame. Dựng lại bằng `python3 game/tools/build_art_refresh.py`; runtime không cần Python/Pillow.

Mọi loại tồn tại thường xuyên có idle/ambient loop riêng, cả terrain/UI. Hiệu ứng ngắn có play riêng. Mọi state của cùng loại dùng cùng nhân dạng, canvas và pivot; `design_id` mô tả hợp đồng đó, đánh giá đồ họa vẫn cần xem preview thật.

| Loại | Frame | Pivot | State (số frame @ FPS) |
|---|---|---|---|
| rowan | 48×64 | 24,60 | idle_down (8 @ 5) |
| enemy | 48×56 | 24,52 | idle (8 @ 5), walk (8 @ 8), windup (8 @ 19), attack (8 @ 33.3), hurt (5 @ 27.8), death (9 @ 16.4) |
| player | 96×64 | 48,60 | idle_down (8 @ 5), walk_down (6 @ 9), attack_down (9 @ 33.3), hurt_down (5 @ 22.7), death_down (9 @ 10), idle_left (8 @ 5), walk_left (6 @ 9), attack_left (9 @ 33.3), hurt_left (5 @ 22.7), death_left (9 @ 10), idle_right (8 @ 5), walk_right (6 @ 9), attack_right (9 @ 33.3), hurt_right (5 @ 22.7), death_right (9 @ 10), idle_up (8 @ 5), walk_up (6 @ 9), attack_up (9 @ 33.3), hurt_up (5 @ 22.7), death_up (9 @ 10) |
| house | 144×128 | 72,124 | idle (8 @ 5) |
| pine | 80×112 | 40,108 | idle (8 @ 4) |
| oak | 104×112 | 52,108 | idle (8 @ 4) |
| rock | 48×40 | 24,36 | idle (8 @ 3) |
| lamp | 24×48 | 6,44 | idle (8 @ 8) |
| crystal | 64×80 | 32,74 | idle (8 @ 6) |
| fence | 64×32 | 32,28 | idle (8 @ 4) |
| sign | 40×48 | 20,44 | idle (8 @ 4) |
| fern | 32×40 | 16,36 | idle (8 @ 5) |
| flowers | 32×32 | 16,28 | idle (8 @ 4) |
| chest | 40×32 | 20,28 | idle (8 @ 4), open (8 @ 16) |
| portal | 56×64 | 28,58 | idle (8 @ 7) |
| rust_sword | 24×24 | 12,20 | icon (8 @ 5), idle (8 @ 5) |
| potion | 24×24 | 12,20 | icon (8 @ 5), idle (8 @ 5) |
| herb | 24×24 | 12,20 | icon (8 @ 5), idle (8 @ 5) |
| ore | 24×24 | 12,20 | icon (8 @ 5), idle (8 @ 5) |
| echo_shard | 24×24 | 12,20 | icon (8 @ 5), idle (8 @ 5) |
| grass | 16×16 | 0,0 | idle (4 @ 2) |
| stone_path | 16×16 | 0,0 | idle (4 @ 0.8), edges (4 @ 0.8) |
| water | 16×16 | 0,0 | idle (4 @ 5) |
| shore | 16×16 | 0,0 | idle (4 @ 1.2) |
| firefly | 8×8 | 4,4 | idle (8 @ 6) |
| glow | 64×64 | 32,32 | idle (4 @ 3) |
| ui_panel | 64×64 | 0,0 | idle (6 @ 2) |
| ui_button | 64×24 | 0,0 | normal (6 @ 3), hover (6 @ 3), pressed (6 @ 3), focus (6 @ 3) |
| ui_health | 132×5 | 0,0 | idle (6 @ 3) |
| sword_slash | 72×72 | 36,36 | play (8 @ 33.3) |
| enemy_strike | 72×72 | 36,36 | play (8 @ 33.3) |
| hit_spark | 32×32 | 16,16 | play (8 @ 30) |
| enemy_telegraph | 72×72 | 36,36 | play (8 @ 19) |
| experience_orb | 16×20 | 8,16 | idle (8 @ 8), collect (8 @ 24) |
| ui_experience | 132×5 | 0,0 | idle (6 @ 3) |
| ui_energy | 132×5 | 0,0 | idle (6 @ 3) |
| ui_stamina | 132×5 | 0,0 | idle (6 @ 3) |
| ui_stats_panel | 64×64 | 0,0 | idle (6 @ 2) |
| level_up | 96×96 | 48,48 | play (12 @ 20) |
| empowered_slash | 72×72 | 36,36 | play (8 @ 33.3) |

Nguồn: house/pine/oak/Rowan/enemy/hero_walk từ bộ ImageGen mới trong `assets/art_v3/sources`, hero_attack tạo mới bằng built-in image_gen (record ở `assets/art_refresh/sources/hero_attack_generation.json`). Props phụ/items/terrain/UI/VFX thiết kế mới từ canvas trống. Không lấy pixel `assets/sprites` hoặc `art_stage1` làm nguồn bộ active.

Một số keyframe được hold theo nhịp để giữ chuyển động pixel nguyên tự nhiên (ví dụ enemy idle có 3 hình khác nhau trong 8 tick). Không công bố mọi lượt frame đều là hình độc nhất. `tests/output/art-refresh-animation-integrity.json` đếm hình khác nhau từng clip; không clip nào tĩnh hoàn toàn.

Ảnh/GIF nguồn trong `assets/art_refresh/previews`; render engine trong `tests/output`. Body/slash contact index2 đồng tick damage; swing .24s. Kiểm tra biên cả202frame actor trong `assets/art_refresh/previews/actors_bounds.json`. Các generator/resources cũ giữ làm lịch sử, không còn được scene dùng.

XP/chỉ số: bảy loại mới do `tools/build_progression_art.py` tạo từ pixel grid, cùng palette/vật liệu hiện tại. Orb có idle/collect; level-up/empowered slash có play; UI có idle. Preview đủ tám clip ở `tests/output/progression-art-contact.png` và GIF từng state; motion engine ở `tests/output/progression-animation.gif`.
