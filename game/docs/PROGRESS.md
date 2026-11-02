# Tiến độ

## 2026-11-02 — Sửa đúng yêu cầu: thay đồ họa mới, idle riêng và đồng bộ state

Bộ `art_stage1` ở mục lịch sử dưới đây vẫn dựa trên sprite cũ đổi màu nên **không đáp ứng yêu cầu thay đồ họa**. Bộ đó đã được thay khỏi runtime. Active hiện tại là `assets/art_refresh`: **33 loại, 67 state, 486 lượt frame**, toàn bộ texture trong manifest trỏ vào thư mục mới, không fallback về sprite cũ.

### Bộ mới đã tích hợp
- Nhà/cây/Rowan/guardian/hero_walk lấy từ ảnh ImageGen mới chi tiết trong `art_v3/sources`, trước đây chưa được dùng. Hero tóc nâu, khăn kem, áo indigo/waistcoat đỏ; Rowan áo plum; nhà mái burgundy nhiều chi tiết. Hero attack tạo mới bằng **built-in image_gen** cùng identity; ảnh và prompt/reference record đã lưu ở `assets/art_refresh/sources/hero_attack.png` và `hero_attack_generation.json`.
- 17 props/items (gồm nhà/cây), terrain, UI và VFX có generator riêng. Props phụ/items/terrain/UI/VFX vẽ mới từ canvas trống, không lấy pixel `assets/sprites` hay `art_stage1` làm nguồn. File/nguồn/size/pivot/state chuẩn: [manifest](../resources/art/manifest.json), [asset-manifest](asset-manifest.md), [brief](ART_REFRESH_BRIEF.md). Dựng lại bằng `python3 game/tools/build_art_refresh.py`.
- Đã ghi **quy tắc bắt buộc trong [AGENTS.md](../../AGENTS.md)**: mọi loại mới có idle/ambient riêng ngay khi đứng yên/không tương tác, kể cả terrain/UI; state thêm mới phải cùng nhân dạng, silhouette, trang phục, vật liệu, palette, hướng sáng, frame size/pivot với bộ state cùng loại. Khi thay hình phải chuyển đồng bộ mọi state, không ghép bộ cũ với mới. Body/slash/hitbox giữ contact index2 cùng tick damage.
- Player mọi state96×64 pivot48,60 để giữ đủ kiếm, body cao khoảng52px; Rowan48×64 pivot24,60; enemy48×56 pivot24,52. Không đổi collision, map/object IDs, stats hay save version1. Tán lá/khói/cửa/lửa/áo/khăn/nước có chuyển động vật liệu; đá và UI phản sáng nhẹ, không kéo giãn cả khối.
- Review subagent phát hiện death bị cắt7–13px và HP địch hardcodeframe0: đã sửa bằng canvas đệm trước khi xoay/neo đất, HP lấy frame ambient thật; glow lệch pha giữa đèn. Chữ footer/thông báo thêm nền panel tối để đọc được trên cây vàng. Đã trực tiếp xem render mới và dải frame death/slash sau sửa.

### Nghiệm thu trên mã cuối
- `bash game/tools/check.sh`: import sạch và **837/837 kiểm tra đạt** =699 art/idle/contact +68 hồi quy làng/UI +57 combat/inventory/save +13 journey đầy đủ. Log: [art contract](../tests/output/art-contract.log), [làng](../tests/output/phase2-regression.log), [RPG](../tests/output/phase2-integration.log), [journey](../tests/output/phase2-journey.log). Save test riêng, không ghi đè save người chơi.
- Idle fixture không gửi input: **385 sprite** quan sát đều đổi frame; player đứng nguyên. Theme/button/HUD HP, HP địch và icon túi khi world pause cũng đổi frame. TileSet thật giữ loop cho cả4loại nền và đường mask. Kiểm tra metadata/canvas/design_id không thay thế review phong cách bằng mắt.
- Toàn bộ **202 frame actor** đạt guard không chạm biên/cắt hình, death đặt đáy tại pivot; [actors_bounds.json](../assets/art_refresh/previews/actors_bounds.json). Một số pose được hold theo nhịp tự nhiên (ví dụ enemyidle3 hình khác trong8tick); không công bố mọi lượt frame đều độc nhất. [Animation integrity](../tests/output/art-refresh-animation-integrity.json) đếm hình khác nhau từng clip, không clip nào hoàn toàn tĩnh.
- Renderer thật Intel Iris Xe/Compatibility: **17 ảnh UI/gameplay**, không overflow label/thoại được phát hiện; [làng](../tests/output/village.png), [trước/sau cùng camera](../tests/output/art-refresh-before-after.png), [UI contact sheet](../tests/output/art-refresh-ui-contact.png), log [UI](../tests/output/art-refresh-render.log) / [RPG](../tests/output/art-refresh-rpg-render.log).
- Motion engine thật: **60 frame làng cách100ms,18 frame chém theo60Hz,24 frame chết cách50ms**. Có GIF [môi trường](../tests/output/stage1_village.gif), [chém](../tests/output/stage1_slash.gif), [chết](../tests/output/stage1_death.gif); đã xem dải [contact](../tests/output/stage1-slash-contact.png) và [death](../tests/output/art-refresh-death-contact.png). Source previews/GIF trong `assets/art_refresh/previews`. [Motion log](../tests/output/art-refresh-motion.log), [timing JSON](../tests/output/stage1-motion-review.json).
- `gd_review.image_checks`:17ảnh +102frame motion đều đạt, không flag; [JSON](../tests/output/art-refresh-image-review.json). Mẫu120frame render khoảng2s/~60FPS trên máy này, không phải benchmark dài. Driver NVIDIA cảnh báo khởi tạo rồi Intel render được; log cuối không SCRIPT ERROR/ERROR/FAIL.

Giới hạn: đồ phụ native ít chi tiết hơn nguồn house/trees/actors, chưa công bố đạt toàn bộ Forge/commercial art gate. Chưa QA thủ công dài, jitter144Hz, từng mép nhà sau đổi silhouette, gamepad hay export Windows. Thế giới vẫn chỉ hai vùng nhỏ. Đợt này thay hình/animation và giữ vòng chơi/save, không thêm chương truyện. Các ghi chú art_stage1/Phase1/2 phía dưới là lịch sử.

## 2026-11-02 — Củng cố bản chơi mở đầu bằng các nhóm chuyên môn

Yêu cầu bắt đầu từ làng, tám hướng, Rowan và nhiệm vụ mở đầu đã có trong dự án, cùng chặng rừng/save Phase 2. Đợt này giữ vòng chơi đó, không dựng lại hoặc tự mở rộng Phase 3. Đã áp dụng các skills Studio/Architecture/Gameplay/2D/UI/Pixel Art/QA; các subagent nhận rào file trong [STAGE_PLAN](STAGE_PLAN.md). Root tích hợp World Design; subagent World Design review độc lập và xem render thật. Brief ở [design-brief](design-brief.md).

### Thay đổi đang dùng trong game
- **Art:** 33 loại, 67 state, 297 lượt frame trong [manifest](../resources/art/manifest.json), PNG/SpriteFrames riêng theo loại; 298 character grid có thể chỉnh sửa. `tools/build_stage1_art.py` dựng `assets/art_stage1` qua `pixel_draw.py`, dùng palette amber/gỗ/burgundy/plum. Nguồn/pivot/frame/FPS/loop khai báo đầy đủ. Bộ art_v3 thử nghiệm không được runtime dùng.
- **Actors/combat:** player idle/walk/attack/hurt/death bốn hướng nhìn, di chuyển vẫn tám hướng; Rowan idle riêng. Địch có idle/walk/windup/attack/hurt/death; quest/loot cập nhật ngay khi chết, animation xác chết tồn tại tạm thời. Chém/báo đòn/hit spark dùng sheet riêng, bỏ cung tròn tức thời. Body/slash theo physics; sprint không làm nhanh action animation. Contact frame index2 được giữ tại tick damage: danh nghĩa .084s, physics60Hz lấy tick đầu vượt mốc (~.100s), giữ cân bằng cũ.
- **World:** props dùng pivot manifest, giữ collision/layout/save IDs. Nhà đổi khói/cửa sáng, cây đổi tán, đèn đổi lửa, đá glint nhẹ; không kéo giãn nhà/đá. Nước 4 frame thật @5FPS, đất/đường/bờ tĩnh một frame khai báo trung thực. Glow/đom đóm, cổng, rương và từng loại pickup có resource riêng. Rương mở animation sau giao dịch inventory thành công.
- **UI:** nine-slice texture panel/button với các trạng thái, HP crop texture, chân dung/icon mới. Giữ layout/focus/typewriter Việt và khóa world khi UI mở. Bỏ nhãn Phase khỏi menu/nội dung quest. Save schema version1 và inventory model không đổi.

### Bằng chứng đã thực sự chạy

Godot **4.7.2.stable**, Linux, Compatibility/Intel Iris Xe. `bash game/tools/check.sh` đạt **669/669 kiểm tra**, import không parse/script/resource error:

| Bộ | Kết quả | Log |
|---|---|---|
| Registry/resource/size/pivot/FPS/loop/frame thật và contact physics | 531/531 | [art-contract.log](../tests/output/art-contract.log) |
| Làng, tám hướng, collision, Rowan, thoại, UI | 68/68 | [phase2-regression.log](../tests/output/phase2-regression.log) |
| Combat/AI/inventory/quest/death/save | 57/57 | [phase2-integration.log](../tests/output/phase2-integration.log) |
| Đi trọn tuyến bằng input, hoàn thành nhiệm vụ, save rồi Continue mới | 13/13 | [phase2-journey.log](../tests/output/phase2-journey.log) |

- Renderer thật: `tests/render_preview.gd` + `tests/phase2_render.gd`, **17 ảnh**, kiểm biên Label/chiều cao thoại đạt. Đã trực tiếp xem làng, thoại, túi và [contact sheet UI](../tests/output/stage1-ui-contact.png). `gd_review.image_checks`:17/17 đạt, không flag; [JSON](../tests/output/stage1-image-review.json). Log [làng/UI](../tests/output/stage1-render.log), [RPG](../tests/output/stage1-rpg-render.log).
- `tests/stage1_motion_preview.gd` ghi animation engine thật: **16 frame làng cách100ms + 18 frame attack theo physics60Hz**, 0 lỗi; 34/34 ảnh đạt image_checks. Có15/15 chuyển tiếp môi trường và15/17 chuyển tiếp attack thay pixel. Đã xem [dải frame contact](../tests/output/stage1-slash-contact.png); [timing JSON](../tests/output/stage1-motion-review.json), [log](../tests/output/stage1-motion.log), [GIF làng](../tests/output/stage1_village.gif), [GIF chém](../tests/output/stage1_slash.gif). `tools/package_motion_preview.py` chỉ đóng gói capture.
- Art nguồn có [contact sheet](../assets/art_stage1/previews/contact_sheet.png), [GIF animation](../assets/art_stage1/previews/animation_preview.gif). Kiểm thời điểm damage bằng test physics, không suy từ screenshot.
- Mẫu120frame: làng **1.985s≈60.5FPS**, rừng **1.980s≈60.6FPS**, cap60; chỉ mẫu ngắn trên máy hiện tại. Driver NVIDIA cảnh báo rồi Intel render thành công. Không có SCRIPT ERROR/ERROR/FAIL trong log cuối.
- `bash -n`, Python compile/generator/packaging đạt. Fixture dùng tên save test riêng, không ghi đè `journey.json`. Import đầu trong sandbox bị chặn socket/config; đã chạy lại ngoài sandbox theo quyền cấp và đạt.

### Giới hạn trung thực
- Vẫn chỉ **hai vùng nhỏ, một NPC truyện, một quest, một loại địch**; chưa phải open world đầy đủ. Audio, gamepad, export Windows/Linux và các chương sau chưa triển khai/QA trong đợt này.
- Art gốc kích thước nhỏ, **chưa đạt độ chi tiết của tham chiếu thương mại**. Forge audit còn flag craft ở nhà/cây/đá (cụm pixel, silhouette lá, midtone) và viền HP5px; [forge_audit.json](../assets/art_stage1/previews/forge_audit.json). UI panel/button đạt audit tương ứng; không công bố đạt toàn bộ Forge gate hoặc hoàn tất nâng chất lượng art.
- Chưa playtest thủ công dài, đánh giá jitter144Hz hay đi quanh mọi prop duyệt y-sort. Boundary/navigation cố định64×48 phù hợp hai map hiện tại; cần tổng quát hóa trước map kích thước khác. Giữ hồi quy xanh trước giai đoạn nội dung tiếp theo.

Chơi bằng `bash run_game.sh`: Hành trình mới → WASD/mũi tên → Rowan → E/Enter → Q xem nhiệm vụ. Không cần Python/Pillow để chơi.

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
