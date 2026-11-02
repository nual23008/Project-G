# Dư Âm Thế Giới Lãng Quên

Godot 4 · RPG pixel art góc nhìn từ trên xuống · tiếng Việt.

Mở `game/project.godot` bằng Godot 4.7.2 rồi nhấn **F6** ở scene Main hoặc **F5**.
Trên máy hiện tại có thể chạy nhanh bằng `bash run_game.sh`.
Chạy bằng terminal:

```bash
/home/luan/Downloads/Godot_v4.7.2-stable_linux.x86_64 --path game
```

WASD / phím mũi tên: đi · Shift: chạy · E: tương tác / tiếp tục hội thoại · J: đánh theo hướng nhìn · Chuột trái: đánh hướng con trỏ · H: uống thuốc · I: túi đồ · Q: nhật ký · F5: lưu · Esc: tạm dừng / quay lại · F11: toàn màn hình. Chuột và Tab / Enter điều khiển menu.

**C: bảng nhân vật/chỉ số · R: chém cường hóa** (20 năng lượng, sát thương ×1.8). Chạy dùng thể lực; nghỉ sẽ hồi thể lực/năng lượng. Quái thường rơi 60 XP, guardian 120 XP; tới gần để hút/nhặt, không chiếm ô túi. Mỗi cấp nhận 5 điểm, tối đa cấp 9999. Bảng C có 7 chỉ số và các mức phân bổ 1/5/10/100 điểm. Scout hồi sinh khi rời rừng rồi vào lại; các lượt sau chỉ rơi XP, loot vật liệu rơi lần đầu. Guardian không hồi sinh.

Khởi đầu: cấp 1, XP 0/100, 0 điểm; máu 100, năng lượng 50, thể lực 100, đi/chạy 72/112 px/s, may mắn 0, sức mạnh 10, phòng thủ 0. Prompt/phân tích/công thức đầy đủ ở [PROGRESSION_IMPLEMENTATION_PROMPT](game/docs/PROGRESSION_IMPLEMENTATION_PROMPT.md). Xem [bảng chỉ số](game/tests/output/progression_starting_stats.png), [điểm sau lên cấp](game/tests/output/progression_earned_points.png) và [preview animation](game/tests/output/progression-animation.gif).

Bản chơi hiện tại: chọn **Hành trình mới**, trò chuyện xong với Rowan rồi tới cổng bắc và nhấn E. Theo đường đá lên vòng đá phía bắc rừng, hạ sinh vật canh giữ rồi E nhặt mảnh tinh thể. Theo đường xuống nam và E ở vòng sáng để về làng, báo tin cho Rowan để nhận thưởng. Q hiển thị từng mục tiêu. Khởi đầu có kiếm và ba thuốc; kẻ địch rơi quặng và thuốc, rừng có thảo dược và rương.

**Lưu là thủ công:** F5 hoặc Esc → Lưu hành trình. Một ô lưu và một bản dự phòng; Hành trình mới và Về menu không ghi đè bản lưu. **Tiếp tục bản lưu** chỉ bật khi bản chính hoặc dự phòng hợp lệ. Save nằm tại `user://journey.json` (Linux: `~/.local/share/godot/app_userdata/Dư Âm Thế Giới Lãng Quên/`). Chết sẽ hồi sinh ở làng, giữ đồ/tiến trình; bản lưu trên đĩa không tự đổi.

Save hiện là version 2, lưu cả XP/level/điểm/chỉ số, HP/năng lượng/thể lực hiện tại, orb chưa nhặt và vòng hồi sinh scout. Save version 1 được xác minh rồi chuyển trong bộ nhớ khi tải; chỉ khi bạn chủ động lưu mới ghi v2, giữ backup hợp lệ. Chết giữ cấp/XP/điểm và hồi đầy theo chỉ số tối đa đã nâng.

Phase 2 hoàn thành chặng thám hiểm của The First Echo. Lyra, sự kiện ký ức, Mira và các lựa chọn có hậu quả thuộc Phase 3; chưa phải bản chơi thử 20–40 phút. Chưa có audio hoặc bản export Windows.

Tài liệu và kết quả kiểm tra: [PROGRESS](game/docs/PROGRESS.md), [phân công và giai đoạn](game/docs/STAGE_PLAN.md), [manifest art](game/resources/art/manifest.json). Bản mở đầu đã được củng cố bằng các nhóm chuyên môn, giữ save version 1; 33 loại asset riêng được game sử dụng. Mỹ thuật vẫn cần trau chuốt, chưa phải thế giới mở hoàn chỉnh.

Đồ họa đang dùng đã thay sang bộ mới: cottage burgundy, cây nhiều tầng, hero tóc nâu áo indigo, Rowan áo plum và guardian tinh thể. Mỗi loại có idle riêng; các state dùng cùng nhân dạng/canvas/pivot. Xem [ảnh làng mới](game/tests/output/village.png), [trước/sau](game/tests/output/art-refresh-before-after.png), [chuyển động môi trường](game/tests/output/stage1_village.gif) và [đòn chém trong engine](game/tests/output/stage1_slash.gif). Quy tắc thêm đối tượng/animation nằm trong [AGENTS.md](AGENTS.md).

Kiểm tra tự động: `bash game/tools/check.sh` (có thể đặt `GODOT_BIN` để dùng Godot ở đường dẫn khác). Chụp giao diện bằng Godot với `--path game --script res://tests/render_preview.gd` và `--path game --script res://tests/phase2_render.gd`; ảnh nằm trong `game/tests/output/`. Preview chuyển động: chạy Godot windowed với `--path game --script res://tests/stage1_motion_preview.gd`, rồi `python3 game/tools/package_motion_preview.py`. Fixture dùng tên save test riêng.

Không cần Python/Pillow để chơi. Tạo lại art đang dùng bằng `python3 game/tools/build_art_refresh.py` (cần Pillow và các pixel skills đã cài). Bốn generator theo nhóm tạo source/sheet/resource, rồi merge manifest; không fallback về ảnh cũ. Bộ `art_stage1` và các generator Phase 1/2 được giữ làm lịch sử, không còn là pipeline active. Xem [asset-manifest](game/docs/asset-manifest.md) và [brief thay đồ họa](game/docs/ART_REFRESH_BRIEF.md).
