# Asset bản chơi mở đầu

Manifest máy đọc: `resources/art/manifest.json`. Mỗi loại dùng PNG và SpriteFrames riêng; cùng loại chia sẻ tài nguyên. Pivot tính từ góc trên trái. Frame, FPS, loop và nguồn ghi trong JSON. Generator: `python3 game/tools/build_stage1_art.py` (Pillow và skill `pixel_draw.py` chỉ cần khi build lại).

| Loại | Frame | Pivot | States |
|---|---|---|---|
| player | 24×32 | 12,28 | idle/walk/attack/hurt/death × down/left/right/up |
| rowan | 24×32 | 12,28 | idle_down |
| enemy | 32×32 | 16,26 | idle/walk/windup/attack/hurt/death |
| pine/oak | 64×88 / 80×88 | 32,80 / 40,80 | idle lá lay |
| house | 112×96 | 56,88 | idle khói/cửa sổ |
| rock/lamp/crystal | 32×32 / 16×32 / 48×64 | 16,28 / 8,28 / 24,56 | idle glint/lửa/tinh thể |
| fence/sign/fern/flowers | 48×16 / 32×32 / 16×24 / 16×16 | đáy giữa−4 | idle đinh bắt sáng/lá/hoa |
| chest/portal | 24×20 / 32×32 | 12,16 / 16,24 | idle; chest thêm open |
| rust_sword/potion/herb/ore/echo_shard | 16×16 | 8,12 | icon, idle |
| sword_slash/enemy_strike | 72×72 | 36,36 | play8@33.333fps, contact2 tại .084s |
| hit_spark | 32×32 | 16,16 | play8@30fps |
| grass/stone_path/water/shore | 16×16 | 0,0 | idle; chỉ water4@5fps, đất1 frame |
| ui_panel/ui_button/ui_health | 48×48 / 48×24 / 132×5 | 0,0 | panel idle; button normal/hover/pressed/focus; health idle |
| firefly/glow | 8×8 / 64×64 | 4,4 / 32,32 | idle |

Ảnh review và GIF trong `assets/art_stage1/previews`. Preview này cho phép kiểm tra sheet, nhịp và phối màu; ảnh engine và hồi quy do root chạy trước khi nghiệm thu. Các asset này vẫn là bộ gốc nhỏ phục vụ bản chơi, chưa phải mức minh họa chi tiết của tham chiếu thương mại.
