# Trang bị12ô và nâng slash

Hành trang E giữ túi16ô, thêm12ô: mũ, áo, quần, giày trái/phải, vòng cổ, vòng tay trái/phải, găng tay trái/phải, vũ khí trái/phải. Trái/phải là phía cơ thể nhân vật, không phải phía màn hình. Nhấn vật phẩm rồi chọn ô hợp lệ để mặc/đổi; chọn đồ đang mặc để tháo. Giao dịch nguyên tử; túi đầy thì không tháo/mất đồ. Vật phẩm hai bên là hai đơn vị độc lập.

Inventory sở hữu bag/equipment, catalog JSON khai báo allowed_slots và visual; Main áp dụng loadout vào player/UI và tính damage từ vũ khí đang mặc (ưu tiên phải, sau đó trái), không từ kiếm nằm trong túi. Cả hai tay trống chặn slash trước khi tốn mana. Bonus trang bị chưa thêm vào quần áo khởi đầu để giữ chỉ số/cân bằng hiện tại; vũ khí thay thế có damage riêng. Không tự cấp điểm kỹ năng.

Đồ họa dùng cùng hero96×64/pivot48,60. Dựng lại thân/áo/quần/giày/găng/phụ kiện bằng các khớp giải phẫu chung, không tách thân theo màu; mọi lớp có animation cùng pose/timing, đủ8hướng và idle/walk/attack/hurt/death. Không để kiếm/giày/áo baked trên base khi tháo. Preview trong hành trang dùng chính tài nguyên runtime. Lớp trống không vẽ placeholder. Các icon/asset mới có nguồn/manifest/resource/idle riêng. Khi tháo áo/quần, base là lớp đồ lót kín đáo.

Save v3 lưu12slot; v1/v2 phải qua checksum/schema gốc rồi migrate trong bộ nhớ: giữ toàn bộ bag/progression/world/vitals, chuyển một kiếm đang có sang tay phải và cấp bộ trang phục khởi đầu cosmetic cùng nhân dạng. Không ghi đĩa khi load, backup vẫn bảo toàn; save mới ghi v3. Từ chối slot/item sai, field trang bị smuggle trong envelope cũ, số lượng/ID không hợp lệ.

Bộ khởi đầu đã có các món mặc để thử ngay và kiếm lữ hành ở tay phải; túi có thuốc, kiếm thép24damage và áo linen để thay. Bộ đồ khởi đầu cấp trong migration là cosmetic (không bonus chỉ số), không tiêu vật phẩm hay điểm có sẵn. Vũ khí phụ không cộng damage/không gây hit thứ hai; ưu tiên vũ khí tay phải, tay trái dự phòng. Chưa có vũ khí hai tay, độ bền, rarity, chế tạo hoặc cây kỹ năng dual-wield.

Nguồn đồ họa: `assets/equipment/sources/player_identity_reference.png` + `identity_manifest.json` chụp đúng bộ active trước khi tách, không dùng art_stage1/sprites cũ. `equipment_rig.py` dựng native từng lớp từ cổ/vai/khuỷu tay/cổ tay/hông/gối/cổ chân. Chỉ giữ tóc/mặt tham chiếu tám hướng, bỏ pixel scarf/vai/tay cũ lẫn trong mép dưới của ảnh đầu; palette cố định, làm sạch silhouette một lần rồi dùng thống nhất mọi state. Áo/scarf/satchel là hình mới theo rig, không phải mảnh cắt từ nhân vật cũ. Mũ, vòng cổ/vòng tay, găng và vũ khí có lớp riêng. Áo linen/kiếm thép có resource riêng; không đổi identity giữa state. Source grid của icon/VFX trong `assets/art_refresh/sources/props/equipment_*`; mã dựng là master, chưa có `.pxo`. Không dùng API trả phí.

Mỗi lớp actor có40state/296frame,96×64/pivot48,60; mọi state lấy cùng bộ pose/clock. Các hold được đếm thật trong `equipment-animation-review.json`; không dùng hidden RGB để giả frame. Base tay riêng luôn hiện dưới găng; các ô trống không vẽ asset. `pose_clock` trỏ tới Sprite gốc; kiểm idle xác nhận clock đang chạy, pose khớp và frame thực sự thay đổi, không yêu cầu mỗi lớp có clock độc lập.

Slash thường/cường hóa96×96 gồm8phase@33,333FPS: anticipation, crescent nhiều lớp, lõi blade/contact flare, follow-through, shard tan. Contact vẫnframe2 ởtick0,1s (ngưỡng0,084s). `resources/equipment/contacts.json` ghi tip pixel của mỗi tay/hướng tạiframe2; melee đặt crest tại tip đó. Hit spark48×48 có pivot24,24. Không đổi tầm/LOS/hitbox, damage/cost/cooldown. Death xóa tint đỏ tạm thời của hurt, giữ màu body/trang bị.

Slash nâng texture riêng, contact body/FX/hitbox vẫnframe2/tick0,1s (ngưỡng0,084s), một hit mỗi receiver. Giữ collision/map/cooldown/sprint/XP. Nghiệm thu: model giao dịch, 12slot/độc lập trái phải, full bag, save migration/backup/downgrade, UI/input, toàn bộ40state/layer, contact8hướng, import/check.sh, renderer và motion preview thật; ghi kết quả vào PROGRESS.

Đổi trang bị trong lúc windup ngắt pending hit/VFX và chuyển idle, giữ mana/cooldown đã tiêu; giao dịch thất bại không ngắt đòn. Vì vậy tháo kiếm không thể để lại ghost damage. Idle base có nhịp thở qua bề rộng thân và góc khớp; đầu/cổ/bàn chân giữ nguyên điểm neo, không nâng hoặc cắt/dịch một nửa hình. Da/tay có hold thật được ghi trung thực; từng lớp mặc có cel riêng theo cùng khớp. Không dùng glint trên da để giả pose mới.

## Kết quả nghiệm thu cuối

`bash game/tools/check.sh`: 5.330/5.330 assertions Godot và 5/5 kiểm tra launcher đạt; import sạch. Suite trang bị có 120 kiểm tra, bao gồm đổi đồ khi túi đầy, độc lập trái/phải, thay giữa windup, save v3/migration và preview khi pause.

Renderer thật chụp 546 ảnh, không lỗi. Kiểm 5.032 frame của 17 lớp actor, 29 loại asset; các lớp khớp 40 state/timing/pivot, mọi clip có nhiều hình khác nhau, contact tip nằm trên kiếm thật. Manifest ghi rõ `distinct_drawings`, `reused_drawings`, `frame_drawings` cho base và các lớp mới; base idle có 2 hình nhịp thở trong 8 lượt frame. `gd_review.image_checks` đạt 13/13; rebuild cuối giữ nguyên hash file active.

[Hành trang mặc/tháo/thay đồ](../tests/output/equipment-outfits.png), [chém tám hướng](../tests/output/equipment-slash.gif), [chém tay trái](../tests/output/equipment-left_slash.gif), [cường hóa](../tests/output/equipment-empowered.gif), [idle](../tests/output/equipment-idle.gif), [đi](../tests/output/equipment-walk.gif), [hurt](../tests/output/equipment-hurt.gif), [death](../tests/output/equipment-death.gif). Báo cáo [render](../tests/output/equipment-render-review.json), [animation](../tests/output/equipment-animation-review.json), [image](../tests/output/equipment-image-review.json), [rebuild](../tests/output/equipment-rebuild-review.json).

## Sửa đầu/thân và pixel idle sau phản hồi

Bản tách lớp đầu tiên đã được thay bằng rig native. Chỉ kiểm frame count/bounds chưa phát hiện được lỗi anatomy: crop đầu 19 hàng chứa scarf/tay cũ, cổ nằm thấp hơn cằm, viền từng đoạn chi tạo vòng tối, glint đổi pixel tùy index và dịch nửa thân khi idle gây cảm giác ghép rời. Bản hiện tại bỏ các thao tác đó; cổ có vùng da đỡ dưới cằm, vai/cổ áo cao hơn, outline tay/chân vẽ theo toàn bộ chuỗi khớp. Tất cả state và 12 vị trí trang bị dùng bộ mới cùng nhân dạng, không trộn với bộ đã bị từ chối.

Death dùng một phép biến đổi chung cho toàn thân, có cel gập vũ khí riêng và lấy thân làm mốc mặt đất. Không lấy mũi kiếm làm mốc khiến cơ thể nổi lên. Rounding half-up giữ tính bất biến khi dịch tọa độ nguyên, tránh khớp bị giữ một pixel rồi nhảy hai pixel.

`tests/equipment_art_test.py` chạy trong check.sh: **4.817/4.817** kiểm tra anatomy/lớp mặc, 296 frame thân và 4.440 tổ hợp mỗi món với thân. Vùng cổ phải có ít nhất 5 pixel da opaque ở hai hàng đỡ cằm, đầu và đế chân idle giống hệt theo pixel ở cả 8 hướng. Mutation cắt cổ phải bị phát hiện. Pixel Forge đạt 8/8 cho cel base idle_down với palette/ramp khai báo; loopcheck đạt 40/40 clip base, giữ nguyên timing/hold trong manifest (chỉ bỏ hold liên tiếp khi so hình học).

[So sánh ảnh người dùng với render mới](../tests/output/equipment-neck-before-after.png), [thân không trang bị tám hướng](../tests/output/equipment-neck-fixed.png), [idle không trang bị](../tests/output/equipment-body-idle.gif), [rig review](../tests/output/equipment-rig-review.json), [loop review](../tests/output/equipment-loop-review.json), [palette/light audit](../tests/output/equipment-forge-review.json).

Lỗi runtime trong ảnh được đối chiếu với log thật: phiên 09:25 có 226 SCRIPT ERROR và thiếu cả signal equip_requested; UI/player đổi trên đĩa lúc 09:28, còn log phiên mới 10:00 không lỗi. Đây là phiên dùng script cache cũ lẫn catalog/API mới. `_item_art` nay tra resource tại lúc dùng, không index thẳng cache icon năm món cũ; test xóa toàn bộ cache rồi khôi phục đủ catalog. API player/signal UI được kiểm trong một Main mới và sau các luồng save/travel. Cần mở phiên mới sau khi cập nhật source; không dùng has_method để âm thầm bỏ qua trang bị bị hỏng. [Báo cáo nguyên nhân runtime](../tests/output/equipment-runtime-incident.json).

Nearest được khóa trực tiếp cho base và từng phần ở equipment_visual.setup, nên preview vẫn sắc khi đặt dưới viewport parent linear. Renderer QA dùng default Nearest; crop body trong bag_removed có 21 màu thay vì 1.140 màu blend ở lượt linear trước. Bước đóng gói assert crop ≤32 màu. Lượt cuối gồm 546 capture chính +70 lượt body-only (64 mẫu mới), 615 ảnh unique/contact qua image_checks; [cold launch](../tests/output/equipment-cold-launch-review.json) sạch, primary/backup không đổi và touchpad preference restore đúng.

## Quay lưng và tối ưu trình bày — bản hiện tại

Bộ front/profile/back mới thay lỗi chỉ đổi đầu mà giữ mặt trước thân: up/up_left/up_right có cổ sau/đường may lưng/khăn sau dạng dải, không có V ngực/khóa trước/pendant trước; giày hiện gót, tay hiện mu và túi cùng hông giải phẫu. Hai profile thu gọn torso, các state chuyển cùng bộ. Walk đủ6hình thật, manifest ghi direction/body_view. Xem [ảnh front/back](../tests/output/movement-rear-view.png), [đi](../tests/output/movement-rear-walk.gif) và [phân tích/đo hiệu năng](MOVEMENT_AND_REAR_VIEW.md).

Camera/actor nội suy cùng vị trí ở render, không đọc vị trí Player trước khi di chuyển rồi round xuống pixel logic. VSync theo màn hình, không cap60; Canvas Items/Nearest giữ nét. EquipmentVisual sync theo signal và chỉ nạp lại slot thay đổi; progress của sprite paused không dùng để blend texture. Physics/contact/damage/save giữ nguyên. Check.sh hiện5.343 assertions Godot +5.437 kiểm rig/views +5launcher; các đoạn nghiệm thu phía trên là lịch sử.
