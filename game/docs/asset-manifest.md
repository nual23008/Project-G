# Bộ đồ họa mới đang dùng

Manifest chuẩn: `resources/art/manifest.json`. 67 loại, 755 state, 5.590 lượt frame. Dựng lại bằng `python3 game/tools/build_art_refresh.py`; runtime không cần Python/Pillow.

Mọi loại tồn tại thường xuyên có idle/ambient loop riêng, cả terrain/UI. Hiệu ứng ngắn có play riêng. Mọi state của cùng loại dùng cùng nhân dạng, canvas và pivot; `design_id` mô tả hợp đồng đó, đánh giá đồ họa vẫn cần xem preview thật.

| Loại | Frame | Pivot | State (số frame @ FPS) |
|---|---|---|---|
| rowan | 48×64 | 24,60 | idle_down (8 @ 5) |
| enemy | 48×56 | 24,52 | idle (8 @ 5), walk (8 @ 8), windup (8 @ 19), attack (8 @ 33.3), hurt (5 @ 27.8), death (9 @ 16.4) |
| player | 96×64 | 48,60 | idle (8 @ 5), walk (6 @ 9), attack (9 @ 33.3), hurt (5 @ 22.7), death (9 @ 10) ×8 hướng: down/left/right/up/down_right/down_left/up_right/up_left |
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
| sword_slash | 96×96 | 48,48 | play (8 @ 33.3) |
| enemy_strike | 72×72 | 36,36 | play (8 @ 33.3) |
| hit_spark | 48×48 | 24,24 | play (8 @ 30) |
| enemy_telegraph | 72×72 | 36,36 | play (8 @ 19) |
| experience_orb | 16×20 | 8,16 | idle (8 @ 8), collect (8 @ 24) |
| ui_experience | 132×5 | 0,0 | idle (6 @ 3) |
| ui_energy | 132×5 | 0,0 | idle (6 @ 3) |
| ui_stamina | 132×5 | 0,0 | idle (6 @ 3) |
| ui_stats_panel | 64×64 | 0,0 | idle (6 @ 2) |
| level_up | 96×96 | 48,48 | play (12 @ 20) |
| empowered_slash | 96×96 | 48,48 | play (8 @ 33.3) |

Nguồn: house/pine/oak/Rowan/enemy/hero_walk từ bộ ImageGen mới trong `assets/art_v3/sources`, hero_attack tạo mới bằng built-in image_gen (record ở `assets/art_refresh/sources/hero_attack_generation.json`). Props phụ/items/terrain/UI/VFX thiết kế mới từ canvas trống. Không lấy pixel `assets/sprites` hoặc `art_stage1` làm nguồn bộ active.

Một số keyframe được hold theo nhịp để giữ chuyển động pixel nguyên tự nhiên (ví dụ enemy idle có 3 hình khác nhau trong 8 tick). Không công bố mọi lượt frame đều là hình độc nhất. `tests/output/art-refresh-animation-integrity.json` đếm hình khác nhau từng clip; không clip nào tĩnh hoàn toàn.

Ảnh/GIF nguồn trong `assets/art_refresh/previews`; render engine trong `tests/output`. Body/slash contact index2 đồng tick damage; swing .24s. Bộ nguồn trước modular có350frame trong `assets/art_refresh/previews/actors_bounds.json`; bộ modular kiểm5.032frame player/layer trong `tests/output/equipment-animation-review.json`. Các generator/resources cũ giữ làm lịch sử, không còn được scene dùng.

Player tám hướng trước khi tách trang bị (2026-11-03): nguồn chéo `assets/art_refresh/sources/hero_walk_diagonal.png` và `hero_attack_diagonal.png`, built-in ImageGen cùng identity với bốn hướng cũ; prompt/reference trong `hero_diagonal_generation.json`. Xem [brief/timing/nguồn và nghiệm thu](PLAYER_EIGHT_DIRECTION.md). Bộ modular hiện tại thay thế các sheet đó; base idle có 2 hình nhịp thở trong 8 lượt frame. Manifest của từng lớp ghi `distinct_drawings`, `reused_drawings` và `frame_drawings` để phân biệt hình mới với hold. Preview hiện tại: `tests/output/equipment-{walk,idle,slash,hurt,death}.gif`.

XP/chỉ số: bảy loại mới do `tools/build_progression_art.py` tạo từ pixel grid, cùng palette/vật liệu hiện tại. Orb có idle/collect; level-up/empowered slash có play; UI có idle. Preview đủ tám clip ở `tests/output/progression-art-contact.png` và GIF từng state; motion engine ở `tests/output/progression-animation.gif`.

2026-11-03 polish: thêm `footstep_dust`24×16/pivot12,12/play8@24 và `falling_leaf`16×16/pivot8,8/idle8@8 (6hình khác,2hold); nhóm thứ6 `build_polish_art.py`. Player bake bóng mọi state, hai slash/cỏ/đá/nước nâng chi tiết. [Nguồn, runtime và QA](POLISH_CONTROLS_AND_VISUALS.md).

2026-11-03 trang bị: nhóm thứ7 `build_equipment_art.py` thay player bằng base cùng nhân dạng, thêm `player_hands`,15resource lớp mặc và9icon mới. Tất cả lớp actor40state/296frame,96×64/pivot48,60; icon24×24 có icon/idle8@5. Slash96×96/pivot48,48; hit48×48/pivot24,24. Registry67loại/755state/5.590frame. [Nguồn/pipeline/QA](EQUIPMENT_IMPLEMENTATION.md); contact tip2tay×8hướng trong `resources/equipment/contacts.json`.
