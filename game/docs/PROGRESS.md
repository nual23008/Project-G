# Tiến độ

## 2026-11-03 — Bốn chủng tộc, menu game mới; sửa râu Dwarf và hướng kiếm

Đã triển khai [thiết kế chủng tộc](RACES_IMPLEMENTATION.md): **Người / Elf / Dwarf / Orc**. Chọn **Hành trình mới → chọn tộc → Bắt đầu**; xem trước năm động tác và tám góc. Esc/Quay lại không reset hành trình trước khi xác nhận. Giai đoạn này tộc quyết định ngoại hình, cùng chỉ số khởi đầu; chưa thêm bonus/ability tộc.

- Người giữ nhân dạng active. Elf cao/thanh, tai nhọn, tóc bạc/bím; Dwarf thấp/đậm, tóc đồng/râu dày; Orc vai rộng, da xanh/tóc đen/ngà. Rig/head/material riêng, cùng fantasy pixel art và outfit hiện có; không scale/recolour toàn bộ Human. Mỗi tộc đủ **40 clip idle/walk/attack/hurt/death ×8 hướng**, canvas96×64/pivot48,60. Các hold được khai báo trung thực.
- Ba tộc mới có base/hands/heritage và **15 layer gear** riêng để vừa khớp. Đủ 12 ô hành trang tháo/mặc độc lập; preview túi dùng đúng tộc. Natural traits không chiếm ô trang bị; đầu/cổ/vai/cổ tay/hông/cổ chân cùng rig, đầu/đế chân idle giữ vị trí. Human dùng 17 layer, mỗi tộc mới18 layer; không preload cả bốn bộ trong lúc chơi.
- **Sửa theo ảnh phản hồi:** râu Dwarf nối liên tục từ tóc mai qua má/ria/cằm, chỉ chót râu thở; up/up_left/up_right bỏ hẳn râu/bím dưới gáy, thay bằng tóc occiput ngắn. Guard đo overlap root với đầu, cấm pixel heritage dưới đầu ở mọi frame rear ngoài death. [Tám góc đã sửa](../tests/output/dwarf-eight-views-fixed.png), [xoay nhân vật/kiếm](../tests/output/dwarf-turning-fixed.gif).
- **Sửa kiếm cho cả bốn tộc:** góc cầm nghỉ theo hướng và tay, profile mirror khớp, guard vuông góc lưỡi quay quanh grip. Khi chém lên, tay mở cạnh vai để blade không xuyên đầu; contact tip từng tộc/tay được xuất lại. Layer là child của Sprite và dùng show_behind_parent cho phía sau/far hand, không tăng/giảm globalZ làm mất kiếm dưới terrain/panel hoặc phá Y-sort. Showcase menu dùng đúng thứ tự occlusion của runtime.
- Menu có bốn card idle8 nhỏ, chỉ giữ một showcase40state của tộc đang xem; giải phóng khi vào game. Nối bàn phím/chuột, focus/cancel/confirm, tự phát lại preview nonloop sau hold để xem; resource giữ đúng loop flag. Đã xem layout640×360,854×360,640×400 và hành trang mặc đủ/bất đối xứng. [Menu](../tests/output/races/menu_dwarf.png), [hành trang](../tests/output/races/bag_mixed_dwarf.png).
- Main sở hữu race_id, gán trước khi world vào tree; travel/death/respawn/load giữ tộc. **Save v4** kiểm race bắt buộc/ID hợp lệ; v1/v2/v3 qua checksum/schema gốc rồi migrate Human trong bộ nhớ. Reserved field ngăn đổi version giả; checksum/atomic/temp/backup còn nguyên. Tests chỉ ghi save_path riêng, không ghi journey.json.
- Pipeline thêm nhóm thứ8 `build_race_art.py`, nguồn native `equipment_rig.py` / `race_heads.py`, brief/palette/source heads ở `assets/races`. Manifest active **129 loại / 3.079 state / 22.790 lượt frame**, gồm62 resource race mới; tất cả được runtime/menu sử dụng. Không có .pxo hay phiên Pixelorama được tuyên bố; không gọi API trả phí.

Nghiệm thu bản cuối:

- `bash game/tools/check.sh`: **18.369/18.369 assertions Godot + 43.072/43.072 kiểm tra art Python + 5/5 launcher**; import không SCRIPT ERROR/ERROR; hồi quy movement,12ô gear,controls,eight-direction,progression/combat/UI/save/quest/journey đạt. Race suite **378/378**, anatomy human **5.437/5.437** và ba tộc mới **37.635/37.635** kiểm tra; gồm từng gear+base, root râu, cổ/đầu/chân, front/back và mutation cổ. [Log toàn bộ](../tests/output/races-check-final.log), [art](../tests/output/races-art-review.json).
- Renderer Iris Xe/Compatibility **63 capture**, không lỗi. **1.184/1.184 cel** composite từ actor runtime khớp pixel với showcase (cả lớp kiếm trước/sau thân); **63/63 image checks**, **160/160 clip** qua Forge loopcheck baseline tolerance0. Chỉ bỏ hold liên tiếp khi so hình học, timing thật không đổi; action nonloop bỏ seam check. Style audit **8/8** cho base idle_down của từng tộc mới với palette/ramp khai báo, không tuyên bố audit style cho mọi cel/layer. [Render](../tests/output/races-render-review.json), [review](../tests/output/races-forge-review.json).
- Cold launch qua `run_game.sh` trong cửa sổ thật, tự thoát sau120frame, exit0, không SCRIPT ERROR/ERROR.
- Đã xem ảnh đủ hướng, chuỗi frame và preview chuyển động [đứng](../tests/output/races-idle.gif), [đi](../tests/output/races-walk.gif), [chém](../tests/output/races-attack.gif), [hurt](../tests/output/races-hurt.gif), [death](../tests/output/races-death.gif), [xoay](../tests/output/races-turning.gif). CLI render tắt VSync chỉ để capture nền; cấu hình chơi vẫn VSync/maxfps0/camera interpolation trước đó. Chưa đo lại FPS144Hz hoặc playtest tay dài trong đợt này.

Chạy lại game bằng `bash run_game.sh` để nạp script/atlas mới. Các mục bên dưới là lịch sử các milestone trước.

## 2026-11-03 — Bản EXE Windows 64-bit

Đã xuất **Windows x86_64 release**, Godot **4.7.2.stable.official.ed1daf0bf**, Compatibility. Dữ liệu nằm trong EXE, không cần `.pck` rời hoặc cài Godot/Python/.NET trên máy người chơi.

- [File EXE](../builds/windows/DuAmTheGioiLangQuen.exe): **120.464.360 byte**. [Gói ZIP](../builds/DuAmTheGioiLangQuen-Windows-x64.zip): **42.450.838 byte**, kèm hướng dẫn tiếng Việt, giấy phép engine/font và SHA-256. Giải nén rồi mở `DuAmTheGioiLangQuen.exe` trên Windows 64-bit.
- Thêm `export_presets.cfg`: Windows Desktop, nhúng PCK, bytecode release, không console wrapper; include JSON/font/license, exclude tests/tools/docs/builds và nguồn art. Export templates tải từ release chính thức, SHA-512 archive khớp `SHA512-SUMS.txt`. Cache Windows template tại `builds/.templates/4.7.2.stable/`; preset nguồn vẫn dùng template tiêu chuẩn, không chứa đường dẫn tuyệt đối của máy này.
- Chụp nguồn cố định để tránh trộn file đang cập nhật song song. Lượt cuối khớp **499 file runtime** trên đĩa; đã nhận cả bản sửa sprite Elf sau snapshot đầu và kiểm lại art. Mốc nguồn cuối **2026-11-03 23:41:56 UTC+7**. Đợt export chỉ thêm cấu hình/giấy phép/bản build/tài liệu, không sửa gameplay, save hoặc vẽ lại asset.
- `bash game/tools/check.sh` trên bản sao nguồn: **18.353/18.353 assertions Godot + 43.072/43.072 kiểm tra art Python + 5/5 launcher**; import sạch. Sau cập nhật riêng sprite Elf, chạy lại `races_art_test.py`: **37.635/37.635** đạt. Gameplay/save từ chính PCK nhúng trong EXE: **362/362** đạt, dữ liệu lưu kiểm thử được cách ly.
- Kiểm PE32+/x86_64/GUI và footer PCK; kiểm toàn bộ **17 JSON, 129 loại art, 3.079 animation state**, tải texture/frame thật: **26.058/26.058** đạt. Render menu/chọn tộc/Elf/Orc từ EXE bằng engine Linux/Iris Xe; đã xem ảnh, **4/4 image checks** đạt. ZIP CRC và SHA-256 file EXE trong ZIP khớp bản ngoài.
- SHA-256 EXE: `00e5a801dd767749e77c1c365e289781b5640699a01b45c5ef3bd05ac336497d`. [Báo cáo đóng gói](../tests/output/windows-export/export-review.json), [kiểm resource](../tests/output/windows-export/pack-audit.json), [ảnh Elf](../tests/output/windows-export/game-elf.png), [ảnh chọn tộc](../tests/output/windows-export/race-selection.png). Log và hash snapshot ở `tests/output/windows-export/`.

**Giới hạn kiểm chứng:** môi trường hiện tại không có Windows/Wine. Đã kiểm cấu trúc file Windows và chạy/render dữ liệu đóng gói bằng Godot Linux cùng phiên bản; **chưa chạy PE trực tiếp trên Windows**. Không tuyên bố đã nghiệm thu Windows native. Save Windows dùng `user://journey.json`, tự nằm trong `%APPDATA%\Godot\app_userdata\Dư Âm Thế Giới Lãng Quên\`; không đụng primary save Linux của người chơi.

## 2026-11-03 — Tối ưu nhịp di chuyển và sửa toàn thân quay lưng

Người dùng xác nhận giật cả lúc đi bình thường. Đã đo trước/sau bằng renderer thật trên Iris Xe/màn143,89Hz, sửa camera/presentation và bộ hình front/profile/back. [Phân tích, lệnh tái tạo và giới hạn phép đo](MOVEMENT_AND_REAR_VIEW.md).

- Nguyên nhân: cap60 cùng VSync trên144Hz; viewport640×400 phóng3× và round camera theo pixel logic; World đọc vị trí trước Player trong cùng tick, camera trễ khoảng1,2px (P95 mẫu1,6px). GPU cũ khoảng0,6ms nên không cần cắt đồ họa/animation để giải quyết nhịp bước. Body nguồn cũng vẽ V ngực/khóa/pendant trước ở mọi hướng, chỉ đầu đổi view.
- Bỏ cap60, VSync vẫn bật; Canvas Items/Nearest và không snap transform toàn cục cho bước theo pixel màn hình. Physics/combat vẫn60Hz. World physics priority100 lấy mẫu sau Player; render lerp previous/current cùng fraction với actor, camera OFF interpolation riêng và force_update_scroll. Camera2D vẫn giữ zoom/limit/clamp.
- Reset history khi spawn/teleport/load/travel/pause/resume; đầu swing và VFX spawn reset pose. Lá/đom đóm đi float mỗi render, không round từng pixel logic. EquipmentVisual sync theo signal frame/animation, cache loadout/slot thay đổi, tint chỉ gán khi đổi; giảm ép13lớp mỗi render, không làm mất state/loop.
- Đã dựng đủ mặt lưng cho up/up_left/up_right ở mọi layer/state: cổ sau/đường may lưng, khăn sau dạng dải, không yếmV/khóa/mặt dây chuyền phía trước, túi đúng hông, gót giày và mu tay. Profile trái/phải thu gọn torso/chuyển chi tiết về mặt trước cơ thể. Walk đủ6hình thật, frame/FPS/pivot96×64/48,60 và contactframe2 giữ nguyên; manifest ghi direction/body_view.

### Kết quả cuối

- **Fullscreen1920×1200, VSync1, cùng1249node/cùng máy, đo6giây sau warm-up:** ~**57,79→125,55FPS**. P95 theo cùng nội suy Type7 **48,451→8,744ms**; số29,116ms thông báo sơ bộ là mẫu gần dưới ngưỡng95%, được chuẩn hoá trong báo cáo. Người dùng giữ cửa sổ hiển thị ở lượt cuối. Sai số screen-center camera so với vị trí trình bày bằng0. [CSV gốc trước](../tests/output/movement-baseline.csv), [sau](../tests/output/movement-foreground-fullscreen.csv), [tổng hợp](../tests/output/movement-performance-review.json).
- Lượt windowed1280×763 với cấu hình game/VSync bật ~129,20FPS/P95 7,259ms. Probe render-budget cap144/VSync tắt riêng lệnh QA ~130,30FPS; không dùng probe này làm cam kếtFPS bản game. Các lượt bị compositor che/hạ xuống~1FPS được đánh dấu invalid và loại khỏi kết luận. Chưa profileGPU4K hoặc thiết bị khác.
- `bash game/tools/check.sh`: **5.343/5.343 assertions Godot +5/5 launcher**, import sạch. Thêm13kiểm camera/physics/render-position/zoom-clamp/pause/teleport/travel/save/load; suite trang bị120, điều khiển47, tám hướng136, model/save129, combat83, UI35, integration30, art4612, làng68, RPG57, journey13.
- Python rig/views **5.437/5.437**: anatomy/từng gear, cổ/chân idle ổn định,6pose walk thật, không marker mặt trước/khăn yếm trước trên các view sau. **40/40 loop base**, zero baseline drift; **8/8 style audit** riêng base idle_down. Registry giữ **67loại/755state/5.590lượt frame**,5.032frame actor được guard;135file rebuild cùng hash.
- Renderer chính **546capture** +body-only **70capture** (64mẫu mới +6UIlặp),0lỗi; **616/616 ảnh engine/contact** qua image_checks. Đã xem body trần, front/back ba hướng lên, profile và contact sheet đi/chém/chết. [Front/back](../tests/output/movement-rear-view.png), [motion](../tests/output/movement-rear-walk.gif), [tám hướng](../tests/output/equipment-walk.gif), [chém](../tests/output/equipment-slash.gif), [body](../tests/output/equipment-body-idle.gif).
- Cold launcher bản cuối sạch, primary/backup không đổi và preference touchpad restore đúng. VSync chỉ tắt ở lệnh smoke nền để tránh compositor; lượt fullscreen chính dùng VSync bật. [Cold review](../tests/output/movement-cold-launch-review.json). Không đổi schema/item/HP/damage/mana/cooldown/XP/tốc độ72/112 hoặc tự đóng phiên game của người dùng; kiểm tự động không thay thế playtest dài.

Khởi động lại bằng `bash run_game.sh` để nhận mã và mọi state/frame mới. Bộ native vẫn có source/generator/manifest/resource riêng; không dùng API trả phí, chưa có `.pxo`.

## 2026-11-03 — Sửa đầu/thân tách rời, khớp và pixel idle

Phản hồi người dùng cho thấy bộ tách trang bị trước chưa đạt: đầu có cảm giác dán rời, pixel trên thân bị xô đẩy khi idle, và có log thiếu `steel_sword`/`set_equipment`. Đã sửa bộ đang active và cập nhật quy tắc nghiệm thu trong AGENTS; không dùng lại body/trang phục bị từ chối.

- Nguyên nhân hình học: cắt trang phục theo màu và crop đầu hình chữ nhật 19 hàng làm lẫn scarf/vai/tay của sheet cũ; cổ đặt thấp hơn cằm. Viền riêng từng đoạn tay/chân tạo vòng tối ở khớp. Glint đổi vị trí và dịch riêng nửa thân theo frame làm idle rời rạc. Các kiểm tra bounds/count của lần bàn giao trước không phát hiện được anatomy này.
- `tools/equipment_rig.py` dựng lại native body/trang phục từ chung khớp cổ/vai/khuỷu/cổ tay/hông/gối/cổ chân; mỗi lớp vẫn có SpriteFrames riêng, đủ 40 state và lấy clock gốc. Chỉ giữ tóc/mặt tham chiếu, loại mép scarf/tay cũ, dùng palette cố định. Cổ có vùng da nối rộng thật, vai/cổ áo đưa lên đỡ cằm. Outline toàn chuỗi chi thay viền từng đoạn; không còn thao tác tách theo màu, glint nhảy pixel hoặc cắt/dịch nửa thân trong idle.
- Idle giữ đầu/cổ và đế chân cố định; thân/khớp thở có chủ đích với hold ghi thật. Rounding half-up tránh tọa độ nửa pixel bị giữ rồi nhảy đôi. Death dùng biến đổi chung, vũ khí có cel gập riêng; lấy thân làm mốc mặt đất thay mũi kiếm để tránh cả cơ thể bị nhấc lên. Áo có cel vải ép vào thân khi nằm.
- Khóa **Nearest** trên cả body và từng layer trong `equipment_visual.setup`, áp dụng cả preview hành trang. SubViewport QA cũng chọn Nearest đúng pixel pipeline. Crop nhân vật trần trong preview từ 1.140 màu do linear filtering còn **21 màu** (20 màu sprite + nền), có assertion chống tái phát trong bước đóng gói.
- Log thật: phiên 09:25 có 226 SCRIPT ERROR (thiếu cả signal equip_requested), trong khi player/UI trên đĩa đổi lúc 09:28; phiên mới 10:00 sạch. Phiên cũ đã nạp lẫn script cache cũ với catalog/API mới. `_item_art` nay resolve tại lúc dùng nếu thiếu cache, thay index trực tiếp map năm icon cũ; suite xóa cả cache rồi kiểm toàn catalog và fresh player/UI API. [Báo cáo sự cố](../tests/output/equipment-runtime-incident.json).

### Nghiệm thu bản cuối

- `bash game/tools/check.sh`: **5.330/5.330 assertions Godot + 5/5 launcher**. Equipment 120, điều khiển 47, tám hướng 136, model/save 129, combat 83, UI 35, integration 30, art 4.612, làng 68, RPG 57, journey 13. Import không có SCRIPT ERROR/ERROR. Save/progression/combat vẫn qua hồi quy.
- Thêm `equipment_art_test.py` vào check.sh: **4.817/4.817 kiểm tra**, gồm 296 frame body liên thông opaque, 4.440 tổ hợp từng gear + body, đầu/đế chân idle ổn định ở 8 hướng, vùng cổ ít nhất 5 pixel da opaque ở hai hàng đỡ cằm. Mutation cắt cổ bắt buộc bị phát hiện. [Rig review](../tests/output/equipment-rig-review.json).
- **40/40 clip base** qua Pixel Forge loopcheck với baseline tolerance 0; nonloop bỏ seam check. Chỉ loại hold liên tiếp khi so hình học, không đổi timing thật. **8/8 style checks** cho cel base idle_down với palette project/ramp da/linen đã khai báo (không tuyên bố mọi cel đã qua style audit này). [Loop](../tests/output/equipment-loop-review.json), [style](../tests/output/equipment-forge-review.json).
- Renderer Intel Iris Xe/Compatibility: **546 capture** lượt chính và **70 capture** lượt tháo hết đồ (64 sample idle mới đủ tám hướng + 6 cảnh/UI lặp), không lỗi. Đã xem thân trần, mặc đủ, bất đối xứng, contact sheet chém/chết, nhịp idle và các preview. **615/615 ảnh engine/contact** qua `gd_review.image_checks`. Guard 5.032 frame actor và timing/contact 29 loại vẫn đạt. [Main renderer](../tests/output/equipment-render-review.json), [body renderer](../tests/output/equipment-body-render-review.json), [ảnh](../tests/output/equipment-image-review.json), [animation](../tests/output/equipment-animation-review.json).
- [Ảnh trước/sau từ ảnh người dùng và render mới](../tests/output/equipment-neck-before-after.png), [thân trần tám hướng](../tests/output/equipment-neck-fixed.png), [idle thân trần](../tests/output/equipment-body-idle.gif), [đi](../tests/output/equipment-walk.gif), [chém](../tests/output/equipment-slash.gif), [hurt](../tests/output/equipment-hurt.gif), [death](../tests/output/equipment-death.gif). Tái tạo `tests/equipment_preview.gd` bình thường và thêm `-- --body-only`, rồi `tools/package_equipment_preview.py`.
- Rebuild generator native/FX + merge bảy fragment giữ hash **135 file** art/resource/manifest/contact/rig/palette. Registry không đổi: **67 loại / 755 state / 5.590 lượt frame**; `rig_anchors.json` và `assets/equipment/palette.json` lưu điểm neo/palette, mã native là master, chưa có `.pxo`; không gọi API trả phí. [Rebuild](../tests/output/equipment-rebuild-review.json).
- Launcher mở process cửa sổ mới, tự thoát sau 120 frame, exit 0, không script/engine error; primary save/backup không đổi và preference touchpad được khôi phục. [Cold launch](../tests/output/equipment-cold-launch-review.json). Đây là QA tự động, không thay thế playtest tay dài.

Cần đóng phiên game đã mở trước khi cập nhật script rồi chạy lại `bash run_game.sh`. Không thêm item/save schema mới trong đợt sửa này. [Phân tích/runtime/nguồn chi tiết](EQUIPMENT_IMPLEMENTATION.md).

## 2026-11-03 — Trang bị 12 ô và hiệu ứng chém mới

Đã phân tích và triển khai [tính năng trang bị](EQUIPMENT_IMPLEMENTATION.md). Nhấn **E** để mở hành trang, chọn vật phẩm trong túi → chọn ô phù hợp → Trang bị; chọn ô đang mặc → Tháo.

- Đủ 12 ô: mũ, áo, quần, giày trái/phải, vòng cổ, vòng tay trái/phải, găng tay trái/phải, vũ khí trái/phải. Mỗi bên dùng một món riêng. Ngoại hình và preview thay theo từng ô; base bên dưới là trang phục linen kín đáo, không còn kiếm/áo/giày baked khi tháo.
- Inventory giữ 16 ô túi cùng equipment riêng. Đổi đồ là giao dịch nguyên tử, dùng chính ô túi vừa trống để chứa món thay ra; tháo khi túi đầy báo lỗi và giữ nguyên đồ. Đổi trang bị giữa windup hủy pending hit/VFX, giữ mana/cooldown đã tiêu; giao dịch lỗi không hủy đòn.
- Vũ khí đang cầm quyết định damage: tay phải ưu tiên, tay trái dự phòng; hai tay trống không chém hoặc tiêu mana. Kiếm lữ hành 18, kiếm thép 24 sát thương cơ bản. Hai vũ khí không cộng damage hoặc đánh hai hit. Quần áo/phụ kiện hiện đổi ngoại hình, chưa thêm bonus chỉ số, rarity hoặc độ bền. Game mới có bộ mặc sẵn và áo linen/kiếm thép để thay thử.
- Hero cùng nhân dạng, đủ idle/walk/attack/hurt/death × 8 hướng trên tất cả lớp. `equipment_visual.gd` lấy animation/frame/progress từ clock gốc; không lệch chân hoặc contact. Idle có nhịp thở thân/đầu/tay 1 pixel, chân giữ đất. Manifest ghi số hình khác nhau và map hold thật, không tính frame trùng là hình mới.
- Slash thường/cường hóa có sheet 96×96 riêng, lõi sáng, crescent, dư ảnh và mảnh tan; hit spark 48×48 riêng. Tip của từng tay/tám hướng được xuất từ frame vũ khí thật và dùng đặt VFX. Body/VFX/damage giữ contact frame 2, tick 0,1 giây; tầm, LOS, cost và cooldown giữ cân bằng hiện có.
- Save **v3** lưu đủ 12 ô. V1/v2 qua checksum/schema gốc trước khi migrate trong bộ nhớ: giữ túi, quest, progression, vitals và world; đưa một kiếm có sẵn sang tay phải, cấp trang phục cosmetic khởi đầu. Đọc/load/has_save không ghi đĩa; save mới vẫn ghi tạm/xác minh/atomic rename/backup. Bộ test dùng file riêng, không ghi primary save người chơi.
- Pipeline nhóm thứ 7 `build_equipment_art.py` + `build_equipment_fx.py`: **67 loại / 755 state / 5.590 lượt frame**. Có 17 lớp actor × 296 frame; mọi icon/lớp mới có nguồn, SpriteFrames, manifest và runtime riêng. Nguồn đầu/nhân dạng là bản active được giữ tại `assets/equipment/sources`; generator và native grid là master, chưa có `.pxo`; đợt này không dùng API trả phí.

### Nghiệm thu trên mã và asset cuối

- `bash game/tools/check.sh`: **5.326/5.326 assertions Godot + 5/5 kiểm tra launcher**, import không có lỗi script/resource. Suite trang bị 116; điều khiển 47; tám hướng 136; model/save 129; combat 83; UI 35; integration 30; art 4.612; làng 68; RPG 57; journey 13. Log tại `tests/output/equipment.log` và các log hồi quy tương ứng.
- Kiểm tra 12 giao dịch mặc/tháo, hai bên độc lập, full bag không mất/nhân đôi đồ, đổi hai kiếm khác nhau khi túi đầy, compatibility, unarmed/left-only/right priority, ghost hit khi thay đồ, pause/UI preview, save v3 roundtrip và migration/backup/schema cũ. Không thay thế playtest tay dài.
- Renderer Intel Iris Xe / Compatibility: **546 capture, 0 lỗi**, gồm 6 cảnh/UI, đủ tám hướng idle/walk/slash/hurt/death, left-only và empowered. Matrix SubViewport 640×360, 640×400, 854×360; không tuyên bố có màn hình phần cứng ultrawide. Đã xem contact sheet idle/chém/chết và ba trạng thái mặc/tháo/bất đối xứng. `gd_review.image_checks` **13/13 đạt**.
- [Hành trang và các bộ mặc](../tests/output/equipment-outfits.png), [preview chém](../tests/output/equipment-slash.gif), [chém cường hóa](../tests/output/equipment-empowered.gif), [đi tám hướng](../tests/output/equipment-walk.gif), [idle](../tests/output/equipment-idle.gif), [hurt](../tests/output/equipment-hurt.gif), [death](../tests/output/equipment-death.gif). [Renderer](../tests/output/equipment-render-review.json), [timing/hold/contact](../tests/output/equipment-animation-review.json), [kiểm ảnh](../tests/output/equipment-image-review.json).
- Guard **5.032 frame actor** không cắt biên hoặc vượt pivot; 29 loại được kiểm pixel/timing. Tất cả lớp cùng 40 state/FPS/frame count; contact tip nằm trên pixel thật của kiếm. Rebuild generator cuối + merge bảy fragment giữ đúng hash toàn bộ texture/resource/manifest/contact active: [kết quả](../tests/output/equipment-rebuild-review.json). Tái tạo render bằng `tests/equipment_preview.gd`, đóng gói bằng `tools/package_equipment_preview.py`.

Khởi động lại bằng `bash run_game.sh` để nhận phiên bản mới. Không thêm dual-wield, vũ khí hai tay, đồ rơi trang bị mới hoặc chế tạo trong đợt này.

## 2026-11-03 — Sửa chuột, toàn màn hình, zoom và hành trang chung E

Đã phân tích và triển khai theo [đặc tả/kết quả chi tiết](POLISH_CONTROLS_AND_VISUALS.md). Giữ hero tám hướng, gameplay và save v2.

- Máy GNOME/Wayland bật `disable-while-typing=true`, gây chặn touchpad khi giữ WASD; không có capture/warp chuột trong game. `desktop_pointer.gd` tạm tắt preference cho process game và restore khi exit. Launcher thêm trap restore khi engine lỗi/tín hiệu; headless/QA job không đổi desktop. Mouse Visible. Đã quan sát process native **true→false→true**, exit0; [record](../tests/output/polish-pointer-native-review.json). Chưa nhận là thử touchpad vật lý bằng tay.
- Mặc định fullscreen, viewport expand/integer/nearest; vùng nhìn phủ tỷ lệ màn hình, HUD neo cạnh/overlay ở giữa. Zoom con lăn75/100/125/150/200%, nút−/+/100% trong cài đặt, giới hạn theo map tránh void. Zoom giữ trong phiên/khi đổi vùng, HUD không zoom.
- E mở hành trang kể cả cạnh NPC: Túi đồ / Nâng điểm / Nhiệm vụ / Hệ thống. Dùng thuốc, tiêu điểm7chỉ số/batch, xem quest, lưu/tải/cài đặt/về menu trong bảng. Main giữ pause/giao dịch. E/Esc đóng; E trong hội thoại tiếp lời. Chuột phải tương tác gần/tầm nhìn hợp lệ, nếu không có target thì empowered; F dự phòng. Shortcut cũ còn tương thích, footer chỉ hướng dẫn nhóm điều khiển chính.
- Đồ họa: bake bóng chân cùng96×64/pivot48,60 cho40state player; bụi bước theo quãng đường thật, tự hủy; slash thường/cường hóa thêm lõi/dư ảnh/flare; cỏ/khe đá/gợn nước nâng chi tiết;16lá rơi lệch phase/tốc độ. Contact body/VFX/hitbox vẫnframe2 ởtick0,1s, không đổi damage/cost/cooldown/collision.
- Hai asset mới có nguồn grid/resource/manifest/runtime riêng: `footstep_dust`24×16/pivot12,12/play8@24 (8hình), `falling_leaf`16×16/pivot8,8/idle8@8 (6hình/2hold). Generator nhóm thứ6 `build_polish_art.py`; build tổng giữ đủ **42loại/97state/710lượt frame**. Không gọi paid API, không đổi nhân dạng hoặc ghép state thiết kế khác. Actor rebuild sau dọn code giữ đúng SHA-256sheet/resource/manifest.

### Nghiệm thu trên mã cuối

- `bash game/tools/check.sh`: **1.549/1.549 assertions Godot và5/5test launcher**, import sạch. Suite mới47; tám hướng128; model/save128; combat83; UI35; integration30; art960; làng68; RPG57; journey13. Log `tests/output/polish-controls.log` và các log hồi quy hiện có; launcher test kiểm normal/error/false preference/headless/termination trong tempdir.
- Suite mới dùng input thật của engine: E/echo/nav, HP/điểm/potion/save/load/settings, pause, right-click context, zoom clamp/không zoom qua túi, chuyển chuột và click chém khi đang giữ phím đi, bụi sinh/hủy; layout cả4tab tại1280×720,1366×768,1920×1200,2560×1080. Đây là kiểm tự động, không thay thế playtest tay dài.
- Renderer Intel Iris Xe/Compatibility: **87capture** gồm15ảnh cảnh/UI và72motion sample (36walk30Hz,18slash+18empowered60Hz). Wayland giới hạn resize cửa sổ vật lý; matrix render SubViewport logical640×360/683×384/640×400/854×360 kiểm16:9,16:10,21:9, không tuyên bố có màn hình phần cứng21:9. Đã xem bốn tab/settings/world/zoom/ultrawide và contact sheet. `gd_review.image_checks`13/13đạt.
- [Preview chuyển động/chém](../tests/output/polish-motion.gif), [world màn rộng](../tests/output/polish/wide_2560x1080.png), [nâng điểm trong hành trang](../tests/output/polish/hub_1.png), [motion contact](../tests/output/polish-motion-contact.png), [renderer review](../tests/output/polish-render-review.json), [art/timing review](../tests/output/polish-animation-review.json), [image review](../tests/output/polish-image-review.json). Tái tạo bằng `tests/polish_preview.gd` và `tools/package_polish_preview.py`.

Không ghi primary save hoặc dừng phiên game cũ đang mở; cần khởi động lại bằng `bash run_game.sh` để nhận mã/asset mới. Zoom chưa lưu qua các lần mở; không thêm cây ability/map mới, chưa QA gamepad/Windows/audio trong đợt này.

## 2026-11-03 — Nhân vật di chuyển và animation tám hướng

Yêu cầu tiếp tục: nhân vật đi đủ8hướng và có animation khi di chuyển. Trước sửa, vị trí đã đi chéo nhưng facing/art chỉ4hướng. Đã nối đủ8hướng vào runtime, giữ thiết kế hero đang active.

- `player.gd`: tám sector45° cho hướng đi/aim, vector chéo chuẩn hóa; tốc độ khởi đầu vẫn72/112px/s. Walk đổi hướng giữ frame/progress; dừng về idle cùng hướng, giữ cadence sprint/Speed và khóa UI. J/R/chuột đánh chéo cùng body/VFX/hitbox, không đổi nhịp contact/cooldown/mana/damage.
- Thêm4hướng chéo ×5state (idle/walk/attack/hurt/death), **148lượt frame mới**. Player40state/296frame,96×64,pivot48,60. Tổng manifest40loại/95state/694frame. Sheet/resource/manifest/runtime/generator đều cập nhật; không dùng candidate SpriteFusion chưa duyệt. Walk mỗi hướng có6hình khác; idle8lượt/6hình, không giả animation bằng frame trùng toàn bộ.
- Built-in ImageGen tạo hai nguồn cùng tóc/khăn/áo/vật liệu/palette hero; đã sửa góc lên phải từ ngang sang lưng. PNG/prompt/reference lưu `assets/art_refresh/sources/hero_{walk,attack}_diagonal.png`, `hero_diagonal_generation.json`. Không dùng paid API; chưa có `.pxo`. Actor generator giữ alpha/canvas/pivot, loại speck nhỏ sau downsample tránh neo chân vào pixel rời. [Brief chi tiết](PLAYER_EIGHT_DIRECTION.md).

### Nghiệm thu

Godot4.7.2 / Linux Compatibility. `bash game/tools/check.sh`: **1.474/1.474 assertions đạt**, import sạch. Bộ tám hướng mới128, model/save128, combat83, UI35, integration30, art932, hồi quy làng68, RPG57, journey13. Save kiểm thử riêng; không đổi schema hoặc save người chơi.

- [Suite tám hướng](../tests/player_eight_direction_test.gd) thử input/physics thật cả8hướng, tốc độ đi/chạy, idle không input, cadence/chuyển hướng giữa bước, opposing keys, sector aim, trượt tường, UI lock, hurt/death và một hit đúng frame2body/VFX ở tick0,1s. Log `tests/output/player-eight-direction.log`.
- Guard cả **350frame actor**, không cắt biên/bottom vượt pivot; idle/walk/hurt đáy60. Kiểm pixel của40clip player:296lượt/272hình khác khi đếm riêng từng clip; không clip tĩnh, walk đủ6hình, loop seam không vượt2,5×medianstep. Giữ holds thật.
- Renderer Intel Iris Xe: **428ảnh thật** trong map qua input, đủ6frame walk/hướng; idle8sample/1,6s không trôi, bốn hướng chéo có attack/hurt/death. Đã xem identity/dải frame đi/chém/chết và preview đã đóng gói. [GIF đi8hướng](../tests/output/eight-direction-walk.gif), [idle](../tests/output/eight-direction-idle.gif), [attack](../tests/output/eight-direction-attack.gif), [hurt](../tests/output/eight-direction-hurt.gif), [death](../tests/output/eight-direction-death.gif), [ảnh trong game](../tests/output/eight-direction-in-game.png), [review timing/frame](../tests/output/eight-direction-animation-review.json). Fixture ngắt mở menu chết giữa các take để quay state; hồi quy cũ kiểm luồng chết thật.
- Generator dựng lại sheet/resource/manifest **đúng SHA-256**. `gd_review.image_checks` kiểm render/contact; kết quả `tests/output/eight-direction-image-review.json`. Render log `tests/output/eight-direction-render.log`; script tái tạo `tests/player_eight_direction_preview.gd` + `tools/package_eight_direction_preview.py`.

Điều khiển: WASD/mũi tên, giữ hai phím để đi chéo; Shift chạy. Khởi động `bash run_game.sh`. Không thêm hành vi/map/NPC; chưa playtest tay dài hoặc gamepad.

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
