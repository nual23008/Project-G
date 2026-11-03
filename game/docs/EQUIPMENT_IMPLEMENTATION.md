# Trang bị12ô và nâng slash

Hành trang E giữ túi16ô, thêm12ô: mũ, áo, quần, giày trái/phải, vòng cổ, vòng tay trái/phải, găng tay trái/phải, vũ khí trái/phải. Trái/phải là phía cơ thể nhân vật, không phải phía màn hình. Nhấn vật phẩm rồi chọn ô hợp lệ để mặc/đổi; chọn đồ đang mặc để tháo. Giao dịch nguyên tử; túi đầy thì không tháo/mất đồ. Vật phẩm hai bên là hai đơn vị độc lập.

Inventory sở hữu bag/equipment, catalog JSON khai báo allowed_slots và visual; Main áp dụng loadout vào player/UI và tính damage từ vũ khí đang mặc (ưu tiên phải, sau đó trái), không từ kiếm nằm trong túi. Cả hai tay trống chặn slash trước khi tốn mana. Bonus trang bị chưa thêm vào quần áo khởi đầu để giữ chỉ số/cân bằng hiện tại; vũ khí thay thế có damage riêng. Không tự cấp điểm kỹ năng.

Đồ họa dùng cùng hero96×64/pivot48,60. Tách áo/quần/giày/găng khỏi nguồn active, dựng base bên dưới và accessory riêng; mọi lớp có animation cùng pose/timing, đủ8hướng và idle/walk/attack/hurt/death. Không để kiếm/giày/áo baked trên base khi tháo. Preview trong hành trang dùng chính tài nguyên runtime. Lớp trống không vẽ placeholder. Các icon/asset mới có nguồn/manifest/resource/idle riêng. Khi tháo áo/quần, base là lớp đồ lót kín đáo.

Save v3 lưu12slot; v1/v2 phải qua checksum/schema gốc rồi migrate trong bộ nhớ: giữ toàn bộ bag/progression/world/vitals, chuyển một kiếm đang có sang tay phải và cấp bộ trang phục khởi đầu cosmetic cùng nhân dạng. Không ghi đĩa khi load, backup vẫn bảo toàn; save mới ghi v3. Từ chối slot/item sai, field trang bị smuggle trong envelope cũ, số lượng/ID không hợp lệ.

Bộ khởi đầu đã có các món mặc để thử ngay và kiếm lữ hành ở tay phải; túi có thuốc, kiếm thép24damage và áo linen để thay. Bộ đồ khởi đầu cấp trong migration là cosmetic (không bonus chỉ số), không tiêu vật phẩm hay điểm có sẵn. Vũ khí phụ không cộng damage/không gây hit thứ hai; ưu tiên vũ khí tay phải, tay trái dự phòng. Chưa có vũ khí hai tay, độ bền, rarity, chế tạo hoặc cây kỹ năng dual-wield.

Nguồn đồ họa: `assets/equipment/sources/player_identity_reference.png` + `identity_manifest.json` chụp đúng bộ active trước khi tách, không dùng art_stage1/sprites cũ. Generator tách áo/scarf/satchel theo vật liệu, loại cả blade/outline cũ, dựng quần/giày theo rig bên trái/phải và anatomy linen bên dưới, giữ tóc/mặt8hướng. Mũ, vòng cổ/vòng tay, găng và vũ khí có lớp riêng. Áo linen/kiếm thép có resource riêng; không đổi identity giữa state. Source grid của icon/VFX trong `assets/art_refresh/sources/props/equipment_*`; mã dựng là master, chưa có `.pxo`. Không dùng API trả phí.

Mỗi lớp actor có40state/296frame,96×64/pivot48,60; mọi state lấy cùng bộ pose/clock. Các hold được đếm thật trong `equipment-animation-review.json`; không dùng hidden RGB để giả frame. Base tay riêng luôn hiện dưới găng; các ô trống không vẽ asset. `pose_clock` trỏ tới Sprite gốc; kiểm idle xác nhận clock đang chạy, pose khớp và frame thực sự thay đổi, không yêu cầu mỗi lớp có clock độc lập.

Slash thường/cường hóa96×96 gồm8phase@33,333FPS: anticipation, crescent nhiều lớp, lõi blade/contact flare, follow-through, shard tan. Contact vẫnframe2 ởtick0,1s (ngưỡng0,084s). `resources/equipment/contacts.json` ghi tip pixel của mỗi tay/hướng tạiframe2; melee đặt crest tại tip đó. Hit spark48×48 có pivot24,24. Không đổi tầm/LOS/hitbox, damage/cost/cooldown. Death xóa tint đỏ tạm thời của hurt, giữ màu body/trang bị.

Slash nâng texture riêng, contact body/FX/hitbox vẫnframe2/tick0,1s (ngưỡng0,084s), một hit mỗi receiver. Giữ collision/map/cooldown/sprint/XP. Nghiệm thu: model giao dịch, 12slot/độc lập trái phải, full bag, save migration/backup/downgrade, UI/input, toàn bộ40state/layer, contact8hướng, import/check.sh, renderer và motion preview thật; ghi kết quả vào PROGRESS.

Đổi trang bị trong lúc windup ngắt pending hit/VFX và chuyển idle, giữ mana/cooldown đã tiêu; giao dịch thất bại không ngắt đòn. Vì vậy tháo kiếm không thể để lại ghost damage. Idle base có nhịp thở thật (thân/đầu/tay nâng1pixel, chân giữ đất); da/tay có hold thật được ghi trung thực, áo/quần có chuyển động vật liệu riêng. Không dùng glint trên da để giả pose mới.

## Kết quả nghiệm thu cuối

`bash game/tools/check.sh`: 5.326/5.326 assertions Godot và 5/5 kiểm tra launcher đạt; import sạch. Suite trang bị có 116 kiểm tra, bao gồm đổi đồ khi túi đầy, độc lập trái/phải, thay giữa windup, save v3/migration và preview khi pause.

Renderer thật chụp 546 ảnh, không lỗi. Kiểm 5.032 frame của 17 lớp actor, 29 loại asset; các lớp khớp 40 state/timing/pivot, mọi clip có nhiều hình khác nhau, contact tip nằm trên kiếm thật. Manifest ghi rõ `distinct_drawings`, `reused_drawings`, `frame_drawings` cho base và các lớp mới; base idle có 2 hình nhịp thở trong 8 lượt frame. `gd_review.image_checks` đạt 13/13; rebuild cuối giữ nguyên hash file active.

[Hành trang mặc/tháo/thay đồ](../tests/output/equipment-outfits.png), [chém tám hướng](../tests/output/equipment-slash.gif), [chém tay trái](../tests/output/equipment-left_slash.gif), [cường hóa](../tests/output/equipment-empowered.gif), [idle](../tests/output/equipment-idle.gif), [đi](../tests/output/equipment-walk.gif), [hurt](../tests/output/equipment-hurt.gif), [death](../tests/output/equipment-death.gif). Báo cáo [render](../tests/output/equipment-render-review.json), [animation](../tests/output/equipment-animation-review.json), [image](../tests/output/equipment-image-review.json), [rebuild](../tests/output/equipment-rebuild-review.json).
