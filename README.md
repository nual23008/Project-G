# Dư Âm Thế Giới Lãng Quên

Godot 4 · RPG pixel art góc nhìn từ trên xuống · tiếng Việt.

Mở `game/project.godot` bằng Godot 4.7.2 rồi nhấn **F6** ở scene Main hoặc **F5**.
Trên máy hiện tại có thể chạy nhanh bằng `bash run_game.sh`.
Game mặc định toàn màn hình, mở rộng theo tỷ lệ màn hình; con lăn zoom75–200%, HUD giữ cỡ. GNOME typing guard được tạm tắt khi chơi để touchpad không đơ lúc giữ WASD và được khôi phục khi thoát. [Preview mới](game/tests/output/polish-motion.gif).

Chạy bằng terminal:

```bash
/home/luan/Downloads/Godot_v4.7.2-stable_linux.x86_64 --path game
```

WASD / mũi tên: đi8hướng · Shift: chạy · Chuột trái: chém · Chuột phải: tương tác gần hoặc chém cường hóa · E: hành trang chung · Con lăn: zoom · Esc: đóng/tạm dừng. Trong hội thoại E/Enter tiếp tục. F cũng tương tác được. Chuột và Tab/Enter điều khiển menu.

**E mở Túi đồ / Nâng điểm / Nhiệm vụ / Hệ thống**. Túi có12ô trang bị: mũ, áo, quần, giày trái/phải, vòng cổ, vòng tay trái/phải, găng tay trái/phải, vũ khí trái/phải. Chọn món trong túi → chọn ô → Trang bị; chọn ô rồi Tháo để cất lại. Nhân vật/preview đổi hình thật theo món mặc, đồng bộ8hướng.  Dùng thuốc, phân bổ7chỉ số theo batch1/5/10/100, xem quest, lưu/tải/cài đặt trong cùng bảng. Chém cường hóa tốn20năng lượng, sát thương×1.8. Mỗi cấp nhận5điểm, tối đa9999; orb XP tự hút khi ở gần. Scout hồi sinh khi rời/vào lại rừng; guardian không hồi sinh.

Khởi đầu: cấp 1, XP 0/100, 0 điểm; máu 100, năng lượng 50, thể lực 100, đi/chạy 72/112 px/s, may mắn 0, sức mạnh 10, phòng thủ 0. Prompt/phân tích/công thức đầy đủ ở [PROGRESSION_IMPLEMENTATION_PROMPT](game/docs/PROGRESSION_IMPLEMENTATION_PROMPT.md). Xem [bảng chỉ số](game/tests/output/progression_starting_stats.png), [điểm sau lên cấp](game/tests/output/progression_earned_points.png) và [preview animation](game/tests/output/progression-animation.gif).

Bản chơi hiện tại: chọn **Hành trình mới**, dùng chuột phải trò chuyện với Rowan, tới gần cổng bắc rồi chuột phải đi vào rừng. Theo đường đá lên bắc, hạ guardian rồi nhặt tinh thể bằng chuột phải. Quay về cổng nam, báo tin Rowan để nhận thưởng. E→Nhiệm vụ hiển thị mục tiêu. Khởi đầu có kiếm và ba thuốc; rừng có thảo dược/rương.

**Lưu là thủ công:** E → Hệ thống → Lưu hành trình (F5/Esc vẫn tương thích). Một ô lưu và một bản dự phòng; Hành trình mới và Về menu không ghi đè bản lưu. **Tiếp tục bản lưu** chỉ bật khi bản chính hoặc dự phòng hợp lệ. Save nằm tại `user://journey.json` (Linux: `~/.local/share/godot/app_userdata/Dư Âm Thế Giới Lãng Quên/`). Chết sẽ hồi sinh ở làng, giữ đồ/tiến trình; bản lưu trên đĩa không tự đổi.

Save hiện là version 3, lưu cả XP/level/điểm/chỉ số, HP/năng lượng/thể lực hiện tại, orb chưa nhặt và vòng hồi sinh scout. Save version1/2 được xác minh rồi chuyển trang bị trong bộ nhớ khi tải; chỉ khi bạn chủ động lưu mới ghi v3, giữ backup hợp lệ. Chết giữ cấp/XP/điểm và hồi đầy theo chỉ số tối đa đã nâng.

Phase 2 hoàn thành chặng thám hiểm của The First Echo. Lyra, sự kiện ký ức, Mira và các lựa chọn có hậu quả thuộc Phase 3; chưa phải bản chơi thử 20–40 phút. Chưa có audio hoặc bản export Windows.

Tài liệu và kết quả kiểm tra: [PROGRESS](game/docs/PROGRESS.md), [manifest](game/resources/art/manifest.json), [điều khiển/màn hình/đồ họa mới](game/docs/POLISH_CONTROLS_AND_VISUALS.md). Registry active có67loại/755state/5.590lượt frame; mọi loại persistent có animation riêng.

Đồ họa đang dùng đã thay sang bộ mới: cottage burgundy, cây nhiều tầng, hero tóc nâu áo indigo, Rowan áo plum và guardian tinh thể. Mỗi loại có idle riêng; các state dùng cùng nhân dạng/canvas/pivot. Xem [ảnh làng mới](game/tests/output/village.png), [trước/sau](game/tests/output/art-refresh-before-after.png), [chuyển động môi trường](game/tests/output/stage1_village.gif) và [đòn chém trong engine](game/tests/output/stage1_slash.gif). Quy tắc thêm đối tượng/animation nằm trong [AGENTS.md](AGENTS.md).

Kiểm tra tự động: `bash game/tools/check.sh` (có thể đặt `GODOT_BIN` để dùng Godot ở đường dẫn khác). Chụp giao diện bằng Godot với `--path game --script res://tests/render_preview.gd` và `--path game --script res://tests/phase2_render.gd`; ảnh nằm trong `game/tests/output/`. Preview chuyển động: chạy Godot windowed với `--path game --script res://tests/stage1_motion_preview.gd`, rồi `python3 game/tools/package_motion_preview.py`. Fixture dùng tên save test riêng.

Không cần Python/Pillow để chơi. Tạo lại art đang dùng bằng `python3 game/tools/build_art_refresh.py` (cần Pillow và các pixel skills đã cài). Bảy generator theo nhóm tạo source/sheet/resource, rồi merge manifest; không fallback về ảnh cũ. Bộ `art_stage1` và các generator Phase 1/2 được giữ làm lịch sử, không còn là pipeline active. Xem [asset-manifest](game/docs/asset-manifest.md) và [brief thay đồ họa](game/docs/ART_REFRESH_BRIEF.md).

Trang bị12ô + slash mới: [phân tích/nguồn/QA](game/docs/EQUIPMENT_IMPLEMENTATION.md), [ảnh các bộ đồ](game/tests/output/equipment-outfits.png), [chém8hướng](game/tests/output/equipment-slash.gif). Savev3 lưu cả đồ mặc; kiếm cũ được chuyển sang tay phải một lần khi đọc savecũ. Vũ khí phải ưu tiên, tay trái dự phòng; quần áo/phụ kiện hiện là cosmetic.
