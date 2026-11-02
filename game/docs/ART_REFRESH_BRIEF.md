# Đổi sang đồ họa mới — 2026-11-02

Yêu cầu: thay hẳn bộ hình cũ đã bị người dùng bác; đổi màu hoặc thêm glint vào silhouette cũ không được coi là hoàn thành. Các state của cùng loại phải cùng thiết kế mới và có idle riêng ngay khi không tương tác. Quy tắc bắt buộc đã ghi trong AGENTS.md.

Nguồn chính: nhà, cây, Rowan, guardian và hero_walk trong `assets/art_v3/sources` là bộ ảnh ImageGen mới trước đây chưa dùng. Hero attack tạo mới bằng built-in ImageGen, cùng nhân dạng và trang phục với hero_walk. Nguồn/prompt trong `assets/art_refresh/sources`. Các props phụ, terrain, UI và VFX được thiết kế lại từ canvas trống; không dùng pixel bộ `assets/sprites` hoặc `art_stage1` làm nguồn.

Đặc điểm phải đọc được: cottage mái burgundy, gỗ walnut/đá kem/cửa hổ phách; hero tóc nâu, khăn kem, áo indigo và waistcoat đỏ; Rowan tóc bạc áo plum có viền vàng; guardian nhiều tinh thể và tay chân khớp đá. Chiếu sáng phía trên trái, viền plum, tương phản với rừng olive/emerald. Giữ hình ảnh fantasy nhiều chi tiết, pixel nearest, không blur hoặc gradient halo nền.

Độ phân giải: viewport 640×360, tile16px. Hero frame96×64 pivot48,60 (margin cho kiếm, body cao khoảng52px); Rowan48×64 pivot24,60; guardian48×56 pivot24,52; nhà144×128 pivot72,124; pine80×112 pivot40,108; oak104×112 pivot52,108. Props phụ và item có canvas/pivot riêng trong manifest. Chân body/collision không scale theo sprite; không thay map ID/save schema.

Idle vật liệu: tán lá, mép áo/khăn, lửa, khói, nước; đá/đường dùng phản sáng ẩm rất nhẹ, không rung cả khối. Mọi loại terrain có loop riêng chậm, UI có nhịp glint ở viền/rune, không chớp cả bảng gây khó đọc. Các state cùng loại giữ canvas/pivot/palette/silhouette gốc; frame contact index2 của body và VFX cùng tick damage, swing .24s.

Rào file: Gameplay sở hữu 3 actor, scene offset và actor generator; Pixel Art sở hữu 17 props/item và generator; World Design sở hữu terrain/atmosphere; root sở hữu UI/VFX, helper/merge manifest, kiểm tra và render. Mỗi nhóm ghi fragment manifest riêng. Root chỉ merge khi các nhóm bàn giao, rồi chạy CLI tuần tự và xem ảnh trước/sau cùng camera.

Nghiệm thu: toàn bộ33ID active có revision `art_refresh`, idle/ambient ít nhất2frame thực (trừ hiệu ứng chỉ có play), không tham chiếu texture cũ. SpriteFrames nạp được, mọi state cùng frame_size/pivot. Headless hồi quy combat/save/quest xanh; render và animation preview thật; bộ hình mới nhìn khác rõ trong game.
