# Giai đoạn đang triển khai — củng cố bản chơi mở đầu

## Phạm vi

Một RPG khám phá nơi người chơi đi qua ngôi làng, gặp Rowan và nhận nhiệm vụ tìm mảnh dư âm. Bản đang có đã vượt nền tảng này với hai vùng, một loại địch, inventory và save/load; đợt hiện tại giữ nguyên vòng chơi đó và hoàn thiện việc dùng asset/animation đúng quy tắc dự án. Không mở thêm khu vực, NPC hay nhánh truyện.

Vòng mở đầu: bắt đầu hành trình → đi tám hướng trong làng → tới Rowan bằng đường đi có collision → đọc/chọn hội thoại → nhận mục tiêu thật trong nhật ký. Vòng hồi quy tiếp tục qua rừng, nhận mảnh dư âm, trở lại nhận thưởng đúng một lần và tải lại save.

Thông số giữ nguyên: Godot 4.7.2, Linux desktop, Compatibility, viewport 640×360, tile 16×16, integer scale/nearest, physics 60 Hz, mục tiêu render 60 FPS. Player đi 72/chạy 112 px/s, di chuyển chéo chuẩn hóa; vùng làng 64×48 tile. Di chuyển tám hướng dùng bốn hướng nhìn; đây không phải bộ sprite tám hướng nhìn riêng.

## Nhóm công việc và quyền ghi

Một file có một người ghi tại một thời điểm; thay đổi ngoài rào phải chuyển yêu cầu cho người sở hữu. Các subagent đọc chung workspace, không tự đổi scene của nhóm khác hoặc chạy Godot import đồng thời.

| Nhóm | File được sửa | Trách nhiệm trong đợt này |
|---|---|---|
| Game Architecture — subagent architecture | `scripts/save/**`, `scripts/inventory/**` chỉ khi phát hiện lỗi; `tests/art_contract_test.gd`, `tools/check.sh`, tài liệu này | Audit save/định dạng dữ liệu; cổng kiểm tra art/resource; giữ schema version 1 |
| Gameplay — subagent gameplay | `scripts/player/**`, `scripts/combat/**`, `scenes/player/player.tscn`, `scenes/npc/elder_rowan.tscn`, `scripts/dialogue/npc.gd`, `scripts/world/world_object.gd` | Nối animation actor/pickup/đòn chém và hit sparks; giữ damage, AI, inventory và tương tác hiện tại |
| World Design — root | `scripts/world/village.gd`, `scripts/world/atmosphere.gd`, `scenes/world/**`, `resources/world/**` | Dùng TileMapLayer/atlas thật; môi trường chuyển động theo vật liệu; giữ camera, y-sort, collision và lối đi |
| UI — nhóm UI do root điều phối | `scripts/ui/**`, `scenes/ui/**` | Nối tài nguyên panel/nút/HP/icon, giữ menu/HUD/thoại/nhật ký và focus bằng bàn phím |
| Pixel Art — subagent pixel_art | `tools/build_art_v3.py`, `assets/art_v3/**`, `resources/art/**`, tài liệu art riêng | Sprite sheets, SpriteFrames, palette thống nhất, nguồn/kích thước/pivot/FPS/state, manifest và preview |

Root giữ quyền tích hợp `scripts/core/**`, `project.godot`, README, `docs/PROGRESS.md`, `docs/ARCHITECTURE.md`, các fixture render/QA chung. Root chạy CLI tuần tự sau khi các nhóm bàn giao; renderer thật chỉ chạy sau khi headless đạt.

## Hợp đồng tài nguyên

`resources/art/manifest.json` là dictionary keyed theo loại vật thể. Mỗi entry khai báo `resource`, `texture`, `frame_size`, `pivot`, `columns`, `source`, `backend` và `states`. Mỗi state có `indices`, `count`, `fps`, `loop`; state dùng atlas phụ khai báo thêm `texture`/`columns`. Không scan folder để chọn asset lúc chạy. Instance cùng loại chia sẻ Resource, trạng thái HP/inventory/quest vẫn ở instance/model riêng.

SpriteFrames phải được game sử dụng thực sự. Tài nguyên nhiều frame phải có thay đổi pixel thật; vật tĩnh có một frame được khai báo trung thực. Nhà/đá không co giãn để giả animation. Slash và hit spark là tài nguyên riêng. Slash dài 0.24 s, pha tiếp xúc frame 2 ở thời gian danh nghĩa 0.084 s; ở physics 60 Hz phải kiểm chứng frame tiếp xúc tại tick phát damage.

Save giữ JSON version 1, payload/checksum SHA-256, validate schema, temp + xác minh + atomic rename và backup. Không đổi ID quest/object, vị trí/collision gameplay hoặc schema khi chỉ nâng cấp art. Các test phá file chỉ dùng tên save riêng, không chạm `user://journey.json`.

## Cổng nghiệm thu

1. `bash game/tools/check.sh`: import không parse/script/resource error; art contract xác minh registry, kích thước/pivot, state/FPS/loop, atlas cell và hình frame khác nhau; toàn bộ hồi quy Phase 1/2 và journey phải đạt.
2. Hồi quy Phase 1 chứng minh menu → spawn → WASD/mũi tên tám hướng, tốc độ chéo, chạy, collision, camera → Rowan → hội thoại Unicode/lựa chọn → trả lại điều khiển. Dùng bộ hiện có, không tạo test trùng để tăng số lượng.
3. Hồi quy Phase 2 và journey chứng minh nhận quest, combat/AI/pickup, thưởng một lần, chuyển vùng, inventory, chết/hồi sinh và save/load/backup không bị thay đổi bởi art.
4. Chạy renderer thật, mở ảnh làng/menu/thoại/HUD/inventory và contact sheet. Xem preview chuyển động, gồm sprite/đòn chém và môi trường; kiểm tra timing chứ không chỉ ảnh tĩnh.
5. Ghi lệnh đã chạy, log, ảnh/preview đã xem, lỗi còn lại và giới hạn vào PROGRESS. Chỉ chuyển sang giai đoạn nội dung tiếp theo sau khi bản chơi hiện tại đạt các cổng này.

## Tiếp theo sau nghiệm thu

Chọn một lát cắt nội dung nhỏ rồi mới triển khai; ưu tiên hoàn thiện nhiệm vụ mở đầu và cảm giác điều khiển. Nội dung Lyra/tàn tích, audio, crafting, gamepad, export và thế giới rộng hơn vẫn nằm ở roadmap. Chưa công bố bản hiện tại là open world hoàn chỉnh hoặc vertical slice 20–40 phút.
