# Kiến trúc

## Nền tảng kế thừa từ Phase 1
- `scenes/main/main.tscn` / `scripts/core/main.gd`: điều phối vòng đời menu, chơi, thoại, tạm dừng. Duy nhất nguồn quyết định khóa input và pause cây thế giới. Không autoload khi chưa cần trạng thái xuyên scene.
- `scripts/core/input_setup.gd`: input mapping tập trung, vật lý WASD và mũi tên; thiết lập trước khi world sinh ra.
- `scenes/world/dawn_village.tscn`: Ground TileMapLayer, Actors y-sort, player/NPC instance, camera độc lập. `resources/world/dawn_village.json` định nghĩa đường, hồ, công trình, cây và nơi xuất hiện.
- `scripts/world/village.gd`: tạo tilemap và props từ dữ liệu; collision vật cản ở layer Environment. Không tạo bản đồ vô hạn hay streaming khi chưa cần.
- `scenes/player/player.tscn` / `scripts/player/player.gd`: CharacterBody2D, capsule chân, AnimatedSprite2D, idle/walk và chạy. Interaction component chọn gần nhất theo khoảng cách + raycast, bỏ đối tượng bị che.
- `scenes/npc/elder_rowan.tscn` / `scripts/dialogue/npc.gd`: StaticBody2D ở chân; dữ liệu NPC và lời thoại ngoài code.
- `scripts/dialogue/dialogue_session.gd`: tải và kiểm tra đồ thị hội thoại; trạng thái logic độc lập giao diện, phát signals line_changed/finished. Phiên bị hủy khi về menu.
- `scripts/ui/game_ui.gd`: theme, menu, HUD, hộp thoại, typewriter, hỗ trợ bàn phím/chuột và khóa luồng UI. Kích thước thiết kế theo viewport nội bộ.
- `scripts/world/atmosphere.gd`: đom đóm và vòng sáng pixel được vẽ ở world space; trang trí không tham gia collision.
- `tools/generate_assets.py`: sprite/tileset PNG và SpriteFrames gốc, seed cố định; không cần Python khi chạy game. Font Noto Sans có giấy phép SIL OFL đi kèm.

## Quy ước
Scene sở hữu node, script sở hữu hành vi, JSON sở hữu nội dung; signal nối tại Main thay vì manager gọi vòng lẫn nhau. Collision: môi trường 1, player 2, NPC 3. Sprite và vật cản được neo tại chân; y-sort cùng Actors. Camera không smooth trong bản nền tảng, làm tròn tọa độ và snap transform; viewport integer scaling/nearest. Đây là lựa chọn có chủ đích để tránh rung ở độ phân giải thấp. Mục tiêu 60 Hz; chưa cam kết FPS ở mọi GPU.

## Phase 2 — module đang dùng
- `combat/health.gd` sở hữu HP, immunity, signals damaged/died/changed; `hurtbox.gd` là Area2D receiver; `melee.gd` truy vấn shape sau windup, một lần mỗi swing, raycast chặn đánh xuyên vật cản. Hurtbox layer bit 8, enemy body bit 16. Player body mask 21; enemy body mask 19.
- Player state machine idle/walk/attack/hurt/death, khóa di chuyển khi swing/hurt, knockback và death animation. Main mở màn hồi sinh sau hoạt ảnh. Enemy state patrol/chase/windup/recover/return/hurt/dead; stats và loot đọc `resources/enemies/guardian.json`.
- `village.gd` giữ chức năng Phase 1 và nhận `definition_path`; hai scene vùng dùng hai JSON khác nhau. Chỉ một vùng tồn tại tại một thời điểm. AStarGrid2D được tạo từ tile nước và chân các prop; enemy cập nhật waypoint mỗi 0.22 giây, thêm raycast phát hiện. Quy mô hiện tại chưa cần chunk streaming.
- `world_object.gd`: object data cho pickup/drop/chest/shard/portal. Main điều phối yêu cầu tương tác và giao dịch với Inventory, không đưa quest logic vào NPC. Portal dùng E và fade 0.25 giây; HP và world state được giữ khi đổi vùng.
- `inventory/inventory.gd` là model 16 slots, stack/capacity/add/remove/use, signals changed. ItemDB JSON có icon/type/stack/damage/heal. Kiếm trong túi cho phép cận chiến; chưa có equipment slots. Pickup/rương chỉ bị xóa khi toàn bộ vật phẩm đã vào túi. Thưởng không đủ chỗ thì trở thành đồ rơi trên đất.
- `quests/quest_manager.gd` đọc objective event/target/count từ JSON, lưu các mục tiêu đã đạt kể cả khi giết guardian trước lúc chạm tinh thể. Các signal từ world và sự kiện được Main chuyển vào manager. Một nhiệm vụ với available/active/completed; reward_claimed ngăn thưởng lặp. Locked/failed và nhiều quest/faction là phần mở rộng về sau.
- Main giữ `areas` dưới dạng snapshot thuần JSON. Mỗi vùng lưu collected IDs, defeated IDs, HP/vị trí địch còn sống và các drop chưa nhặt. Không serialize node hoặc RID. Animation/cooldown/AI state tạm thời được khởi tạo lại khi nạp; không hồi HP địch. Respawn giữ tiến trình hiện tại và không tự lưu xuống đĩa.
- `save/save_service.gd`: version 1, payload JSON có SHA-256, kiểm tra schema/giới hạn, ghi `.tmp` → đọc xác minh → dự phòng bản chính hợp lệ → atomic rename. Bản chính hỏng thì load `.bak`; chưa có migration vì chỉ có một version. Trước khi thay objective schema ở Phase 3 phải thiết kế migration/version 2, tránh làm hỏng save Phase 2.
- UI dùng model signals cập nhật HP, ô túi và journal; inventory/journal/death là mode độc lập của Main. Khi mở UI, cả world physics/AI/timer dừng. Save thủ công trong Playing/Pause; load trong Menu/Pause. Continue chỉ bật khi có snapshot hợp lệ. Settings hình ảnh vẫn giữ trong phiên, tách khỏi save game.

Không autoload mới hoặc dependency vòng; Main là composition root của các model RefCounted và scene hiện tại.

## Kiểm tra
Headless import kiểm tra toàn bộ script/resource. `tests/phase1_test.gd` chạy scene thực, mô phỏng input, physics, collision, thoại, focus/menu, kiểm tra trạng thái khóa input và reset. `tests/render_preview.gd` chụp viewport qua renderer thật. `tools/check.sh` chạy import rồi integration, trả lỗi nếu engine log chứa SCRIPT ERROR/ERROR, lưu evidence.

Tham chiếu API: [Godot TileSets](https://docs.godotengine.org/en/stable/tutorials/2d/using_tilesets.html), [multiple resolutions](https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html). Phiên bản kiểm chứng thực tế: Godot 4.7.2.
