# Nhân vật di chuyển tám hướng — 2026-11-03

## Hợp đồng hình ảnh

Giữ hero tóc nâu, khăn kem, áo indigo viền vàng, waistcoat burgundy, quần taupe và giày/túi da nâu. Ánh sáng hổ phách từ trên trái, viền mận, cùng độ chi tiết với bộ active. Canvas **96×64**, pivot **48,60**, collision chân và tỷ lệ viewport **640×360/integer/nearest** giữ nguyên.

Tám hướng: `down`, `down_left`, `left`, `up_left`, `up`, `up_right`, `right`, `down_right`. Hướng xuống chéo là góc nhìn trước ba phần tư; lên chéo là góc nhìn lưng ba phần tư. Không xoay cả sprite để giả hướng, không dùng candidate SpriteFusion đang chờ duyệt.

## Nguồn và dựng lại

- Bốn hướng cũ: `assets/art_v3/sources/hero_walk.png` và `assets/art_refresh/sources/hero_attack.png`.
- Bốn hướng chéo: `assets/art_refresh/sources/hero_walk_diagonal.png` (1536×1024, 6 cột ×4 hàng) và `hero_attack_diagonal.png` (1774×887, 8 cột ×4 hàng). Hàng lần lượt xuống phải, xuống trái, lên phải, lên trái. Built-in ImageGen tạo thêm cùng identity; prompt/reference lưu trong `hero_diagonal_generation.json`. Hướng lên phải đã được sửa từ góc ngang sang góc lưng.
- `tools/build_refresh_actors.py` cắt actor/blade liên thông, alpha≥210, nearest, tỷ lệ chung cho từng sheet và neo sole vào pivot. Sau downsample, riêng sheet chéo loại đảo pixel tách rời <5px bằng liên thông tám chiều để speck không bị nhận làm chân. Không sửa PNG nguồn. Idle dùng chuyển động khăn/đuôi áo; hurt recoil và death gập thân từ cùng base chéo. Nguồn hiện là PNG + generator; chưa có master Pixelorama `.pxo`.
- Dựng actor: `python3 game/tools/build_refresh_actors.py`, rồi `python3 game/tools/build_art_refresh.py --merge-only`. Lệnh build tổng vẫn tái tạo đúng bộ này. Rebuild đã đối chiếu SHA-256: sheet/resource/manifest không đổi.
- Runtime: `assets/art_refresh/sheets/player.png` → `resources/art/player.tres` → `scenes/player/player.tscn`. Manifest `player` có **40 state, 296 lượt frame**; tổng registry **40 loại, 95 state, 694 lượt frame**.

## Animation và điều khiển

Mỗi hướng có cùng năm state:

| State | Lượt frame | FPS | Loop | Ghi chú |
|---|---:|---:|---|---|
| idle | 8 | 5 | có | 6 hình khác, có hold theo nhịp; chân đứng yên |
| walk | 6 | 9 | có | đủ 6 hình khác; chân/tay đổi pose |
| attack | 9 | 33,333 | không | 8 pose kiếm + recovery; 0,27 giây |
| hurt | 5 | 22,727 | không | recoil 0,22 giây |
| death | 9 | 10 | không | 0,9 giây; giữ frame cuối |

Input.get_vector vẫn chuẩn hóa vector; đi 72 px/s, chạy 112 px/s ở chỉ số khởi đầu. WASD/mũi tên, giữ hai phím để đi chéo, Shift chạy. Nhịp walk theo Speed và sprint như trước. Tám sector 45°, ranh giới 22,5°, dùng chung cho facing và mouse aim. Thả phím giữ hướng idle cuối. Đổi hướng giữa bước giữ `frame/frame_progress`; attack/hurt/death do clock physics sở hữu, không chịu cadence walk.

J/R và chuột có thể đánh chéo, cùng hướng với body/VFX/hitbox. Không đổi damage/cooldown/cost/LOS. Contact frame **2** của body và slash vẫn trùng tick gây damage (**0,1 giây** khi physics60Hz lấy mẫu ngưỡng **0,084**). Không đổi save schema.

## Nghiệm thu

- `bash game/tools/check.sh`: **1.474/1.474** đạt. Suite mới `player_eight_direction_test.gd`: **128/128** về tám hướng, nhịp bước, idle không input, sprint, đổi hướng giữa bước, sector aim, đối phím, khóa UI, trượt tường, contact một hit, hurt/death. Các suite cũ tiếp tục kiểm combat/progression/UI/save/quest/journey.
- Kiểm ảnh source: **40 clip, 296 lượt frame, 272 hình khác khi đếm riêng từng clip**, không clip tĩnh; walk mỗi hướng đủ 6 hình khác; mọi loop seam <2,5×median pixel step. Guard actor kiểm **350 frame**; không cắt biên, bottom≤pivot, death settle đúng ground. Idle/walk/hurt giữ đáy60.
- Godot4.7.2 / Compatibility / Intel Iris Xe: **428 frame renderer thật**, dùng input trong bản đồ. Tám hướng quan sát đủ6frame walk, idle8sample/1,6giây không trôi vị trí; bốn hướng chéo có attack/hurt/death preview. Fixture ngắt handler mở death menu giữa các take; luồng chết/respawn thật do hồi quy cũ kiểm.
- Chạy preview: Godot windowed với `--path game --fixed-fps 60 --resolution 640x360 --script res://tests/player_eight_direction_preview.gd`, sau đó `python3 game/tools/package_eight_direction_preview.py`.
- Bằng chứng trong `tests/output`: `eight-direction-walk.gif`, `eight-direction-idle.gif`, `eight-direction-attack.gif`, `eight-direction-hurt.gif`, `eight-direction-death.gif`, `eight-direction-in-game.png`, contact sheets và `eight-direction-animation-review.json`. Đã xem dải frame renderer/identity/walk/contact/death; GIF đóng gói theo timing thực, lượng tử 10ms cho GIF. Kết quả kiểm hình nằm trong `eight-direction-image-review.json`.
