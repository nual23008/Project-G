# Tiến độ

## 2026-11-02 — Bàn giao phiên: skill Pixelorama và rà soát asset hiện tại

Người dùng kết thúc phiên vì hết quota và yêu cầu ghi lại để tiếp tục lần sau. Đã tạo skill và đọc bộ asset hiện tại; chưa có yêu cầu sản xuất hoặc thay thế đồ họa tiếp theo. Việc rà soát này không sửa asset, scene, gameplay hoặc save.

### Skill đã tạo

- [pixelorama-pixel-artist](../../.agents/skills/pixelorama-pixel-artist/SKILL.md) nằm trong `.agents/skills/pixelorama-pixel-artist/`, có đủ ba template style/asset/animation và ba script `validate_assets.py`, `check_animation_sheet.py`, `export_manifest.py`. Các reference giải thích schema JSON, Godot import và ví dụ main character idle/walk bốn hướng, export 40 frame thành sheet 256×160.
- Pixelorama là editor chính; khi thiếu automation thì hướng dẫn thao tác thủ công, không tuyên bố đã vẽ khi chưa có file. Không dùng paid API nếu chưa được người dùng chấp thuận. Script dùng Python 3.10+/Pillow, chạy offline; xuất metadata và tùy chọn SpriteFrames `.tres`, tileset được hướng dẫn cấu hình thủ công.
- Schema `art_spec.json` của skill là định dạng staging riêng, **không phải** schema manifest đang dùng trong game. Khi tích hợp cần thích ứng theo registry hiện có, giữ ID và resource/runtime consumer.
- Trong bước tạo skill đã chạy: skill validator, **25 test Python**, **147 kiểm tra Godot 4.7.2** trong project tạm (region/frame/FPS/loop/pivot/timing biến thiên/playback), và `bash game/tools/check.sh` **1.222/1.222 đạt**, import sạch. Forward test độc lập với potion/water cũng đạt. Đây là fixture kiểm công cụ, không phải artwork Pixelorama hoàn chỉnh.

### Bộ asset thực tế đã đọc và xem

- Nguồn chuẩn: [manifest](../resources/art/manifest.json), [danh mục asset](asset-manifest.md), [brief đồ họa hiện tại](ART_REFRESH_BRIEF.md), [hướng mỹ thuật](ART_DIRECTION.md), [kiến trúc](ARCHITECTURE.md). Runtime dùng `assets/art_refresh/sheets/**` và `resources/art/*.tres`; `art_stage1`/sprites cũ giữ làm lịch sử. Ảnh trong `art_v3/sources` vẫn được một số generator active sử dụng làm nguồn.
- Đếm trực tiếp manifest: **40 loại, 75 state, 546 lượt frame**, 40 resource và **38 PNG texture** tính cả override của state. Grass/stone_path/water/shore dùng chung atlas `terrain.png`; state đường viền dùng thêm `paths.png`. Cần giữ layout pha của atlas khi chỉnh terrain.
- Đối chiếu PNG theo indices/columns từng state: không thấy resource thiếu, frame vượt biên, count sai hoặc clip hoàn toàn tĩnh. Đây là kiểm cấu trúc/khác biệt pixel, không thay thế đánh giá chuyển động và contact trong engine. Một số pose có hold hợp lệ: player idle 8 lượt/6 hình khác; guardian idle 8 lượt/3 hình khác.

| Nhóm | Quy cách đang dùng |
|---|---|
| Player | **96×64, pivot 48,60**; 20 state = idle/walk/attack/hurt/death × bốn hướng. Idle 8 lượt @5 FPS; walk 6 @9; attack 9 @33,33; hurt 5 @22,73; death 9 @10. Không ép về mặc định 32×32/48×48 của skill. |
| Rowan / guardian | Rowan 48×64 pivot24,60, idle_down; guardian 48×56 pivot24,52, idle/walk/windup/attack/hurt/death. |
| World props | Nhà144×128, pine80×112, oak104×112; đá/đèn/crystal/hàng rào/biển/cây nhỏ/rương/cổng có canvas và idle riêng. |
| Terrain / items | Tile16×16 có ambient; kiếm/thuốc/herb/ore/echo_shard24×24, icon và idle riêng; orb XP16×20 có idle/collect. |
| UI / VFX | Panel/nút/thanh HP/XP/mana/stamina và bảng chỉ số có animation; slash/telegraph/hit spark/level-up có play riêng. |

Đã xem ảnh render đang lưu `tests/output/village.png`, bảng chỉ số, dải frame Rowan/guardian/player và `tests/output/progression-art-contact.png`; không chạy lại renderer trong bước đọc asset. Nhận xét bằng mắt: fantasy top-down, ánh hổ phách trên trái, burgundy/indigo/plum, gỗ nâu/đá kem và rừng olive/emerald. Nhà/cây/nhân vật chi tiết hơn rõ so với props nhỏ, item, địa hình và VFX; đây là điểm cần đồng bộ nếu người dùng muốn nâng mỹ thuật tiếp.

### Điểm cần giữ cho phiên sau

- **Chưa có file `.pxo` trong `game/`**. Nguồn hiện là PNG, pixel grid và generator Python (`tools/build_art_refresh.py` cùng năm nhóm generator). Chưa có master Pixelorama layered; không ghi nhận như đã chuyển pipeline sang Pixelorama.
- `docs/art-bible.md` còn mô tả bộ `art_stage1` cũ (actor24×32, palette/terrain tĩnh). Khi làm tiếp ưu tiên manifest, ART_REFRESH_BRIEF, ART_DIRECTION và quy tắc mới trong AGENTS; chưa sửa tài liệu cũ trong phiên này.
- Có **9 candidate player SpriteFusion** tại `assets/sprites/player/spritefusion_v1/candidates/`. [design_review.json](../assets/sprites/player/spritefusion_v1/design_review.json) còn `approved_asset_id: null`, `runtime_modified: false`; đề xuất frame48×48 đang chờ duyệt, player active vẫn96×64. Chưa chọn hoặc tích hợp candidate nào.
- Giữ mọi state cùng nhân dạng/palette/canvas/pivot; mọi loại persistent mới có idle/ambient nhiều hình thật ngay khi không tương tác. Body/slash/hitbox contact phải cùng tick damage, giữ nhịp combat hiện tại và save v2.
- Bắt đầu phiên sau bằng đọc mục bàn giao này, ARCHITECTURE, AGENTS và skill Pixelorama nếu tiếp tục công việc art. Khi có yêu cầu chỉnh asset: xác định đúng bộ active và phạm vi, rồi mới sửa; cập nhật manifest/resource/runtime, xem sheet và motion/render thật, chạy `bash game/tools/check.sh`, ghi kết quả mới.
- Ảnh tổng hợp và JSON khảo sát tạm ở `/tmp/project-g-current-assets.png`, `/tmp/project-g-player-animation-frames.png`, `/tmp/project-g-current-assets-inspection.json`; có thể mất sau khi dọn `/tmp`. Các kết luận cần thiết đã được ghi trong mục này; ảnh/preview gốc vẫn có trong `assets/art_refresh/previews` và `tests/output`.

## 2026-11-02 — XP, cấp 9999, bảy chỉ số và bộ chỉ số khởi đầu

Đã phân tích yêu cầu thành [prompt/đặc tả triển khai](PROGRESSION_IMPLEMENTATION_PROMPT.md), gồm công thức, khởi đầu, giao dịch, save/migration, rào file và nghiệm thu. Người dùng chọn bảy chỉ số và đòn chém cường hóa. Architecture làm model/save; Gameplay làm vitals/combat; UI làm HUD/bảng; root tích hợp Main/world/orb/respawn/art và kiểm tra. Giữ bộ nhân dạng đồ họa mới.

### Đã triển khai
- Khởi đầu: cấp 1, XP 0/100, 0 điểm; HP 100, năng lượng 50, thể lực 100, đi/chạy 72/112 px/s, May mắn 0, Sức mạnh 10, Phòng thủ 0. Mỗi cấp nhận đúng 5 điểm; tối đa cấp 9999 và 49.990 điểm. XP dư chuyển qua nhiều cấp. Ở MAX, orb vẫn được thu/xóa nhưng không thêm XP hoặc điểm.
- Quái thường rơi 60 XP, guardian 120 XP. Orb có idle/collect riêng, tự hút trong 64 px và thu trong 12 px khi player sống, đang chơi và không bị tường che. Không chiếm túi, không cộng ngay lúc giết. Orb chưa nhặt và vị trí đang hút được lưu, không mất hoặc nhân đôi khi đổi vùng/tải lại.
- C mở bảng bảy chỉ số, xem giá trị hiệu dụng và tiêu 1/5/10/100 điểm mỗi lần. HP +20/điểm, mana/stamina +10, Strength +2 damage; Speed/Luck/Defense dùng soft curve trong prompt. Tăng max giữ lượng vital đã mất, không hồi đầy bằng mở bảng hoặc nhận XP. Bảng pause world và hỗ trợ chuột/bàn phím, đóng bằng C/Esc.
- Shift dùng 18 thể lực/s khi thực sự chạy, hồi 20/s sau 0,6 s; kiệt sức đi bộ tới khi hồi 20 rồi chạy lại. Mana hồi 3/s sau 1,5 s; R dùng 20 cho slash ×1,8. Đòn bị chặn không tiêu mana. Crit ×1,5 chỉ roll một lần mỗi swing; Defense có giới hạn, luôn nhận ít nhất 1 damage. Nhịp bước theo Speed, action/idle giữ nhịp riêng.
- Scout hồi sinh khi rời/vào lại rừng; guardian không hồi sinh. Item loot chỉ rơi lần đầu, các vòng sau cấp XP. Orb chưa nhặt cùng nguồn được gộp để giới hạn số node. Loading không kích hoạt respawn; quest/chest/loot cũ vẫn one-shot. Player hồi sinh đầy theo max vitals hiện tại, giữ progression và không autosave.
- Save v2 lưu profile/vitals/orb/cycle. V1 qua checksum/schema rồi mới migrate trong bộ nhớ; chỉ ghi v2 khi chủ động Save. Giữ inventory/quest/HP/position/world. V1 có field dành riêng cho v2 bị từ chối để tránh hạ version làm reset XP; backup hợp lệ được dùng. Hurt ngắt hit đang chờ và ẩn VFX ở cả hai phía, giữ mana đã tiêu/cooldown.
- Bảy asset mới có resource/manifest/source grid riêng: orb XP, lên cấp, slash cường hóa, ba thanh HUD và bảng chỉ số. Bộ active hiện có **40 loại, 75 state, 546 lượt frame**. Nguồn: `tools/build_progression_art.py` và `assets/art_refresh/grids/progression`. Giữ palette/vật liệu/canvas/pivot và contact của body/sword.

### Nghiệm thu trên mã cuối

Godot 4.7.2, Linux/Compatibility. `bash game/tools/check.sh`: **1.222/1.222 assertions đạt**, import không có lỗi script/resource/parse.

| Bộ | Đạt | Bằng chứng |
|---|---|---|
| Model/cấp/điểm/stats/JSON/migration/backup/downgrade | 128/128 | [model](../tests/output/progression-model.log) |
| Physics/vitals/regen/sprint/crit/defense/cường hóa/interruption | 83/83 | [combat](../tests/output/progression-combat.log) |
| UI/batch/focus/giá trị lớn/mọi stat ở full budget/MAX/ambient | 35/35 | [UI](../tests/output/progression-ui.log) |
| Kill → drop → save/load → collect → level → allocate → respawn → merge → reload/MAX | 30/30 | [integration](../tests/output/progression-integration.log) |
| Art/idle/pivot/FPS/contact/runtime | 808/808 | [art](../tests/output/art-contract.log) |
| Hồi quy làng/UI, RPG/save và journey bằng input thật | 68+57+13 | [làng](../tests/output/phase2-regression.log), [RPG](../tests/output/phase2-integration.log), [journey](../tests/output/phase2-journey.log) |

- Integration hạ guardian/scout bằng R/J và hitbox thật, dùng thuốc hữu hạn, không gán HP địch để giết. Fixture có teleport và dời pending orb để thử merge; journey độc lập vẫn đi bằng input, không teleport. Save/load giữ orb, thu một lần, phục hồi đúng điểm/vitals. Cap 9999 thử bằng grant tổng hợp; không tuyên bố đã chơi tay tới cấp đó.
- Đã tìm và sửa: comparator Dictionary phân biệt int/float sau JSON (test dùng structural comparator có bite checks); version flip có thể reset profile (đã chặn); Hurt trước contact vẫn gây ghost damage (đã hủy). Bộ combat mới trên hành vi cũ thất bại đúng 5 check, 78/83; sau sửa đạt 83/83.
- Renderer thật: 9 ảnh progression và 8 ảnh hồi quy menu/thoại/pause/settings, không tràn label/thoại được phát hiện. Đã xem [bảng khởi đầu](../tests/output/progression_starting_stats.png), [điểm kiếm được](../tests/output/progression_earned_points.png), [MAX](../tests/output/progression_level_9999.png), [contact sheet](../tests/output/progression-ui-contact.png). Log [progression](../tests/output/progression-render.log) và [hồi quy render](../tests/output/progression-regression-render.log).
- **36 frame renderer cách 100 ms**, 35/35 chuyển tiếp có đổi pixel, đóng thành [GIF animation](../tests/output/progression-animation.gif). Có [contact sheet nguồn](../tests/output/progression-art-contact.png) và GIF riêng cho đủ 8 clip mới. Fixture playback phát FX để review; chứng minh thưởng gameplay nằm ở integration riêng. [Motion log](../tests/output/progression-motion.log), [review JSON](../tests/output/progression-animation-review.json).
- `gd_review.image_checks` kiểm ảnh/frame; shell syntax, Python compile và JSON parse đều đã chạy. Tests chỉ dùng tên save riêng, không ghi đè primary người chơi. Số ảnh và kết quả cuối ở [image review](../tests/output/progression-image-review.json).

Giới hạn: đây là bảng nâng stat, chưa phải cây ability nhiều nhánh; mana hiện dùng đòn R. Hai vùng/quái vẫn là nội dung đầu game; chưa cân bằng endgame 1..9999 hoặc playtest tay dài/Windows/gamepad. Công thức và trần đã kiểm tra, chưa có nội dung quái cấp cao. Chạy `bash run_game.sh`, C mở nhân vật, R cường hóa.

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
