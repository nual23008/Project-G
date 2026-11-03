# Chủng tộc — thiết kế và phạm vi

Bốn ID cố định: human (Người), elf, dwarf (Dwarf/người lùn), orc. Giai đoạn này tập trung tạo hình/animation, menu trước game mới và lưu lựa chọn; dùng chung chỉ số, collision chân, tốc độ72/112, combat/quest/inventory hiện có. Không tự thêm bonus hoặc ability chưa được yêu cầu.

Người giữ nhân dạng đang active. Elf cao/thanh, tai dài nhọn, tóc bạc/bím dài; Dwarf thấp/đậm, tóc đồng/râu dày bám má/cằm; Orc to/vai rộng, da xanh, tóc đen và ngà. Cùng fantasy pixel art, ánh trên trái, vật liệu chàm/gỗ/đỏ rượu/hổ phách. Mỗi tộc có body/hands/gear riêng và đủ idle/walk/attack/hurt/death ×8 hướng. Mọi frame96×64, pivot48,60; không kéo scale toàn bộ human để giả tộc khác. Cổ/vai/hông/cổ tay/cổ chân cùng rig của chính tộc; tất cả lớp chuyển cùng design. Hướng lên là toàn thân quay lưng, walk6hình thật, hold ghi thật.

Ba tộc mới có lớp đặc điểm tự nhiên (râu/tóc gáy ngắn/bím/tóc cột) riêng, không chiếm12ô trang bị. Áo/quần/giày/găng/đồ trang sức/vũ khí vẫn tháo/mặc độc lập; đặc điểm tự nhiên giữ đúng nhân dạng. Nguồn là generator native + palette/pose presets, không tuyên bố có Pixelorama master hoặc dùng API trả phí.

Menu: Hành trình mới → bốn thẻ tộc idle thật → preview lớn có thể đổi state/góc → Bắt đầu. Huỷ/Esc về menu, chưa reset model/save trước xác nhận. Thumbnail dùng sheet8frame riêng để không nạp68layer vào menu; preview lớn dùng composite đúng các cel runtime của tộc, chỉ giữ một bộ đang xem. Vào game chỉ nạp layer tộc đang chơi; giữ tối ưu signal/frame, Nearest và camera interpolation.

Main sở hữu race_id; Player/EquipmentVisual và preview nhận ID trước khi dựng world. Save v4 kiểm ID hợp lệ. V1/v2/v3 qua checksum/schema gốc rồi migrate human trong bộ nhớ; load không ghi đĩa. V3 không được lén chứa race, v4 không được thiếu/sai race. Bộ test dùng save riêng; primary/backup người chơi không thay đổi.

Nghiệm thu: 4tộc ×40state, anatomy/foot/pivot/material/front-back, từng món tháo/mặc, menu/focus/cancel/confirm, v4roundtrip/migration/travel/death; import/check.sh, renderer thật và motion preview đủ state/góc. Ghi kết quả cuối vào PROGRESS.


Sửa theo ảnh phản hồi: bỏ hoàn toàn râu/bím dưới đầu ở up/up_left/up_right của Dwarf. Sideburn-ria-má-cằm nối liên tục; chân râu giữ vị trí, chỉ phần chót thở. Guard đo vùng overlap với đầu và cấm pixel heritage phía dưới occiput ở mọi frame rear ngoài death.

Kiếm: rest angle theo lateral của từng hướng và tay, profile mirror đúng khớp; guard quay vuông góc blade quanh grip. Cánh tay khi chém lên mở cạnh vai để kiếm không xuyên đầu. Weapon phía sau người/far hand dùng show_behind_parent của chính Sprite; mọi layer là child của Sprite, kế thừa tint/pose, đồng bộ theo signal. Không dùng Z âm chôn kiếm dưới terrain/UI hoặc tăng Z phá Y-sort. Showcase menu dùng cùng phép composite trước/sau thân. Contact được xuất lại từ frame 2 của chính vũ khí từng tộc.


Tái tạo: `python3 game/tools/build_equipment_art.py`, `python3 game/tools/build_race_art.py`, `python3 game/tools/build_art_refresh.py --merge-only`; hoặc full `build_art_refresh.py` theo đủ tám nhóm. QA logic/art: `bash game/tools/check.sh`. QA render: Godot `--path game --disable-vsync --max-fps 144 --script res://tests/races_preview.gd` rồi `python3 game/tools/review_race_art.py`. Disable-vsync chỉ dùng capture nền, không phải cấu hình game hoặc phép đo FPS khi chơi. Tests dùng save_path riêng. Native sources/asset brief/palette ở `assets/races`, geometry ở hai file rig/head; SpriteFrames/manifest là output được runtime dùng thật.

Giới hạn phạm vi: bốn tạo hình cố định, chưa chọn giới tính/tóc/màu da, chưa có bonus/ability tộc. Có sẵn 12 ô trang bị độc lập và cùng progression; không đổi race sau khi đã tạo nhân vật. Style audit 8/8 ở cel base idle_down của từng tộc mới với palette project/skin-hair ramp đã khai báo, không tuyên bố mọi frame/lớp đều qua cùng style gate. Toàn bộ state/direction đã qua anatomy, pixel composite render và loop/timing check. Đây là QA tự động + review ảnh/chuỗi frame, chưa thay thế playtest tay dài hoặc benchmark144Hz mới.
