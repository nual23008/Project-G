# Tiến độ

## 2026-11-02 — Phase 2 hoàn tất: Core RPG Loop

Đọc lại Phase 1 và giữ kiến trúc scene + composition + signals, mở rộng bằng model Inventory/Quest/Save độc lập. Các ghi chú Phase 1 phía dưới là lịch sử, không còn mô tả giới hạn của bản hiện tại.

### Đã triển khai
- **Chiến đấu thật:** J hoặc chuột trái, hitbox shape query + hurtbox Area2D, raycast chặn đánh xuyên tường, cooldown, HP, immunity, knockback, hiệu ứng trúng đòn, hoạt ảnh attack/hurt/death. HUD đọc HP qua signal. Địch có body collision, 54 HP/14 damage và loot theo JSON.
- **AI:** patrol/detect/chase/telegraph/attack/recover/return/hurt/death. Tuần tra theo đoạn có chủ đích, phát hiện qua raycast, tìm waypoint AStarGrid2D để đi quanh vật cản, leash trở về. Một loại sinh vật, ba cá thể đặt thủ công; guardian ở vòng đá phía bắc.
- **Rừng Thì Thầm:** vùng tilemap nhỏ có đường đá, hồ, vòng đá tinh thể, cây/collision, rương, thảo dược, ba kẻ địch và portal về làng. Giữ làng hiện có. Đổi vùng bằng E với fade, chỉ nạp một vùng tại một thời điểm. Đã chừa lối sạch ở cổng nam để cây không che kín lối về.
- **Inventory:** 16 ô, icon/tên/mô tả/số lượng, stack giới hạn, add/remove/use và lưu/tải. Kiếm, thuốc hồi 40 HP, lá sương, quặng và mảnh tinh thể có dữ liệu riêng. H dùng thuốc nhanh; I mở túi. Không tiêu thuốc khi đầy máu hoặc đã chết. Túi đầy thì pickup/rương vẫn còn; thưởng thiếu chỗ thì rơi xuống đất.
- **Quest:** The First Echo — chặng rừng: nói chuyện xong với Rowan nhận việc → vào rừng → tìm tinh thể → hạ guardian → lấy mảnh dư âm → trở về → báo tin Rowan, nhận 2 thuốc + 3 quặng một lần. Q mở nhật ký với tiến trình thật. Diệt guardian trước lúc tìm tinh thể vẫn được tính. Ký ức với Lyra thuộc Phase 3, chưa công bố The First Echo hoàn chỉnh về cốt truyện.
- **Chết/hồi sinh:** có death animation và màn hồi sinh; về làng với 100 HP, giữ inventory và tiến trình thế giới; không tự ghi đè save. Nếu chết trong rừng, trở về làng cũng được tính là sự kiện về làng.
- **Save/load:** một ô `user://journey.json`, F5 hoặc Pause → Lưu. Continue/Pause → Tải hoạt động thật. Version 1, payload JSON + SHA-256, kiểm tra schema/giới hạn, ghi tạm và đọc xác minh, đổi tên atomic, giữ `.bak` hợp lệ. Bản chính lỗi thì đọc dự phòng. New Game và về menu không tự lưu. UI đóng băng physics/AI khi mở túi, nhật ký, thoại hoặc menu.
- **Trạng thái được lưu:** vùng/vị trí/HP player, inventory, quest + reward flag, met_rowan, object đã nhặt/rương đã mở, địch chết, vị trí/HP địch còn sống và đồ rơi chưa nhặt ở từng vùng. Cooldown/animation/AI state tạm thời reset khi load; HP địch không reset. Load được bảo vệ 0.8 giây đầu để tránh sát thương tức thì.
- Asset Phase 2 tạo mới bằng `tools/generate_phase2_assets.py`, không dùng art tải ngoài. Đã cập nhật README, kiến trúc, thiết kế, roadmap và check runner.

### Kiểm tra đã thực sự chạy trên mã cuối
Godot 4.7.2, Linux; import và cả ba bộ headless đều exit 0. Tổng **138/138 assertions đạt**:

| Bộ kiểm tra | Kết quả | Bằng chứng |
|---|---|---|
| Hồi quy Phase 1, thêm kiểm tra các link thoại mới | 68/68 | [phase2-regression.log](../tests/output/phase2-regression.log) |
| HP/combat/AI/inventory/quest/death/world state/save | 57/57 | [phase2-integration.log](../tests/output/phase2-integration.log) |
| Hành trình đầy đủ không teleport/gán quest flag/tiêm sát thương | 13/13 | [phase2-journey.log](../tests/output/phase2-journey.log) |
| Import scene/script/resource | exit 0, không lỗi | [phase2-import.log](../tests/output/phase2-import.log) |
| Renderer thật, 10 ảnh UI/gameplay | exit 0, không overflow được phát hiện | [phase2-render.log](../tests/output/phase2-render.log) |

- Hành trình dùng input di chuyển, hitbox thật, AI thật và thuốc hữu hạn; không gán HP để cứu bot. Đi từ spawn đến Rowan, vào rừng, hạ địch, lấy shard, về báo tin, nhận thưởng, save; tạo Main mới hoàn toàn rồi Continue từ dữ liệu trên đĩa. Đây là automation, không thay cho đánh giá cảm giác điều khiển của người chơi.
- Integration còn kiểm tra sát thương và telegraph/cooldown của địch, miễn sát thương, chặn input trong inventory, dùng thuốc qua UI, capacity/stack/failed removal, túi đầy không mất pickup, thưởng không lặp, save giữa trận giữ HP guardian và rương mở, đồ rơi chưa nhặt tồn tại sau reload. File hỏng, checksum sai, version không hỗ trợ, stack bất hợp lệ, vị trí NaN và lỗi ghi file tạm được thử; lỗi không ghi đè primary hợp lệ.
- Đã trực tiếp xem ảnh render bằng Intel Iris Xe/OpenGL compatibility: [menu](../tests/output/p2_menu.png), [forest entry](../tests/output/p2_forest_entry.png), [combat](../tests/output/p2_combat.png), [inventory](../tests/output/p2_inventory.png), [journal](../tests/output/p2_journal.png), [save/pause](../tests/output/p2_save_pause.png), [Continue](../tests/output/p2_continue.png), [death](../tests/output/p2_death.png), [report](../tests/output/p2_report.png), [after report](../tests/output/p2_quest_complete.png). Renderer kiểm tra biên label và chiều cao thoại; các trạng thái ảnh được thiết lập bằng fixture riêng. Chứng minh gameplay nằm ở journey test độc lập.
- Mẫu render forest có AI/physics hoạt động: **120 frame / 1.982 giây ≈ 60.5 FPS**, cap 60. Chỉ là mẫu ngắn trên máy hiện tại, chưa phải benchmark dài hoặc nhiều thiết bị. Driver NVIDIA phát cảnh báo khởi tạo như Phase 1 rồi engine chọn Intel thành công.
- `bash -n` launcher/runner, Python `py_compile` hai generator, parse toàn bộ JSON đã chạy thành công. Log cuối không có SCRIPT ERROR, ERROR hoặc FAIL.
- Save test dùng `phase2_automated_only.json`, `phase2_journey_only.json`, `phase2_render_only.json` cùng backup tương ứng; không đọc/ghi save người chơi qua các case test phá file.

### Lỗi đã tìm thấy và sửa trong Phase 2
- Godot yêu cầu khai báo ext_resource trước sub_resource trong SpriteFrames; generator đã sửa thứ tự và giữ chạy lại ổn định.
- Menu không được reset attack/death animation khi khóa input; stop chỉ đổi idle/walk.
- Tween đổi vùng được bind vào world để tự hủy khi world bị giải phóng.
- Cây mép nam rừng che lối đi; đã mở khoảng trống cho cổng.
- Trở về làng bằng hồi sinh cần phát area event như portal, tránh bắt người chơi đi rừng lại chỉ để báo tin.
- Thông báo lưu trong pause cần wrap thay vì cắt ngang.

### Giới hạn còn lại và Phase 3
- Chưa có lỗi chặn vòng chơi trong phạm vi các kiểm tra trên. Chưa QA thủ công phiên dài, gamepad, F11/đa màn hình, Windows hoặc export binary. Chưa có audio, ngày/đêm, crafting/equipment slots hoặc boss. Settings vẫn giữ trong phiên chạy.
- Một quest/chặng rừng, một loại địch, hai vùng nhỏ. Quest manager hiện dùng available/active/completed; locked/failed, điều kiện nhánh phức tạp và nhiều quest chưa triển khai. Lời thoại hỏi thông tin Rowan chưa có hậu quả lựa chọn.
- Chưa có Lyra/Kael/Mira, nhiệm vụ Mira, tàn tích/dungeon và ký ức đầu tiên; chưa đạt vertical slice 20–40 phút. Mảnh dư âm được giữ làm quest item để nối sang Phase 3.
- Phase 3 tiếp theo: Lyra và sự kiện ký ức, Kael/hướng dẫn trang bị, Mira + lựa chọn có hậu quả chơi được, tàn tích nhỏ, âm thanh và polish. Trước khi thay schema quest phải thêm migration/save version 2 để giữ tiến trình Phase 2.
- Tiếp tục phiên sau: đọc tiến độ và ARCHITECTURE, chạy `bash game/tools/check.sh`, giữ hồi quy xanh. Chơi bằng `bash run_game.sh`.

---

## 2026-11-02 — Phase 1 hoàn tất trong phạm vi bản nền tảng

Môi trường ban đầu trống, không có dự án trước đó. Godot `/home/luan/Downloads/Godot_v4.7.2-stable_linux.x86_64`, phiên bản thực tế `4.7.2.stable.official.ed1daf0bf`. Python 3/Pillow chỉ để tạo lại asset; font Noto Sans tiếng Việt được đóng kèm cùng giấy phép. Terminal bị hạn chế ghi thư mục cấu hình Godot ở lần chạy đầu; sau khi người dùng cho phép chạy engine, kiểm tra import/runtime hoàn tất bình thường. Mã nguồn nằm trong `game/`.

### Đã hoàn thành
- Project Godot 4, scene chính, cấu trúc module, 640×360, cửa sổ 1280×720, nearest/integer scaling, giới hạn render 60 FPS và physics 60 Hz.
- Player CharacterBody2D: đi tám hướng WASD/mũi tên, chuẩn hóa chéo, Shift chạy, idle/walk bốn hướng, collision tại chân. HP ban đầu hiển thị 100; chưa có nhận sát thương.
- Dawn Village 64×48 tile, 16×16 px: đường đá viền rêu, quảng trường tinh thể, ba nhà, hồ, cây, hoa/dương xỉ, đèn và cổng bắc đóng. Layout lưu bằng JSON; TileMapLayer/TileSetAtlasSource và StaticBody2D có va chạm thật. Đây là khu vực nhỏ đầu tiên, chưa phải thế giới mở hoàn chỉnh.
- Camera bám nhân vật, giới hạn map, làm tròn vị trí, tắt smoothing để giữ pixel ổn định. Actors dùng y-sort.
- Rowan cùng dữ liệu hội thoại riêng; hai biển tương tác. Component chọn đối tượng gần nhất trong 42 px, raycast tránh tương tác xuyên vật cản.
- Hộp thoại tiếng Việt, chân dung, chữ chạy, E/Enter hiện hết/tiếp tục, lựa chọn bằng chuột hoặc Tab/Enter, Esc đóng. Các nhánh Rowan hiện tại cung cấp thông tin; chưa phải lựa chọn có hậu quả cốt truyện.
- Main Menu, Hành trình mới, Cài đặt, Thoát; HUD, hướng dẫn tương tác, định hướng sau khi hoàn thành thoại; pause/resume/về menu. Mở thoại/menu dừng cả world; mở phiên mới reset spawn và trạng thái trò chuyện.
- Settings thực: toàn màn hình/F11 và bật/tắt ánh sáng/đom đóm. Cài đặt giữ trong phiên chạy ứng dụng, chưa lưu xuống đĩa.
- Asset PNG/SpriteFrames vẽ mới bằng script, seed cố định; icon SVG gốc, font có giấy phép. Màu sắc tham chiếu ảnh người dùng, không phân phối lại ảnh đó.
- GAME_DESIGN, ARCHITECTURE, ROADMAP, hướng dẫn README và launcher `run_game.sh`.

### Kiểm tra đã thực sự chạy
1. **Headless import cuối: đạt.** Exit 0, không có `SCRIPT ERROR` hoặc `ERROR:` trong [import.log](../tests/output/import.log). Script và tham chiếu scene/resource được engine nạp.
2. **Integration cuối: 66/66 đạt.** Chạy scene thật bằng `--headless --fixed-fps 60 --script res://tests/phase1_test.gd`, exit 0; [integration.log](../tests/output/integration.log). Bao gồm di chuyển tám hướng, tốc độ chéo/chạy, va chạm nhà/cây/NPC/hàng rào/nước/biên, khoảng tương tác, Unicode/typewriter/nhánh, gameplay bị khóa trong UI, pause/settings/menu/reset. Mô phỏng phím W/D đi từ spawn tới Rowan rồi E; kiểm tra cả Enter và click chuột ở menu.
3. **Render đồ họa thật: đạt.** Godot chạy X11/OpenGL compatibility trên Mesa Intel Iris Xe. Đã chụp và trực tiếp xem tám ảnh 640×360: [menu](../tests/output/menu.png), [village](../tests/output/village.png), [dialogue](../tests/output/dialogue.png), [choices](../tests/output/choices.png), [forest sign](../tests/output/forest_sign.png), [village sign](../tests/output/village_sign.png), [pause](../tests/output/pause.png), [settings](../tests/output/settings.png). Script còn kiểm tra label nằm trong viewport và chiều cao thoại đủ chứa nội dung, exit 0; [render.log](../tests/output/render.log).
4. **Mẫu render ngắn:** 120 frame khi world đang hoạt động trong 1.981 giây, trung bình 60.6 FPS với cap 60. Đây là mẫu khoảng 2 giây trên máy hiện tại, không phải benchmark nhiều thiết bị hoặc cam kết hiệu năng bản game sau này.
5. **Công cụ:** `bash -n run_game.sh game/tools/check.sh` và Python `py_compile` generator đã chạy thành công.

Các lỗi tìm thấy và đã sửa: thứ tự gắn atlas trước khi đặt polygon va chạm nước; Enter trong typewriter vô tình kích hoạt Close; font mặc định làm giãn label tràn viewport; hội thoại biển nhiều dòng cần hộp cao hơn. Các log cuối không còn lỗi engine/script. Khởi tạo OpenGL có cảnh báo driver NVIDIA trước khi chọn Intel thành công; không ảnh hưởng kết quả render này.

### Giới hạn và chưa kiểm chứng
- Bản nền tảng khám phá ngắn, chưa đạt nội dung 20–40 phút của Phase 3; đồ họa là bộ pixel art gốc sơ khởi, chưa đạt độ chi tiết của ảnh tham chiếu.
- Chưa QA thủ công một phiên chơi dài, chưa kiểm tra thực tế F11 trên nhiều màn hình hoặc resize ở mọi tỷ lệ; chưa chạy trên Windows.
- Chưa export binary Windows/Linux. Có thể chơi ngay bằng Godot, không cần cài Python. Chưa có audio ở Phase 1.
- Chưa có save/Continue, inventory, pickup, quest manager/journal, combat/attack/hurt/death, AI địch, Lyra/Kael/Mira, rừng có thể chơi, chuyển vùng/streaming, ngày đêm/thời tiết hoặc nội dung chương sau. Cổng rừng và menu ghi đúng phạm vi hiện tại.

### Công việc tiếp theo — Phase 2
1. Health/Hitbox/Hurtbox, melee/cooldown, hurt/death/respawn và AI patrol/detect/chase/attack/return dựa trên dữ liệu.
2. ItemDB + inventory ô lưới/stack/use, thuốc hồi máu, vũ khí, tài nguyên và vật phẩm quest.
3. Rừng Thì Thầm nhỏ, quest theo sự kiện cho The First Echo, nhặt tinh thể và nhận thưởng đúng một lần.
4. Save/load JSON có version, ghi tạm + kiểm tra + backup, kiểm thử file hỏng và round-trip. Sau đó mới thêm Continue và giao diện lưu/tải.

Khi tiếp tục, đọc file tiến độ này và ARCHITECTURE trước; giữ các kiểm tra hiện có xanh khi mở rộng.
