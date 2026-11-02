# Dư Âm Thế Giới Lãng Quên

Godot 4 · RPG pixel art góc nhìn từ trên xuống · tiếng Việt.

Mở `game/project.godot` bằng Godot 4.7.2 rồi nhấn **F6** ở scene Main hoặc **F5**.
Trên máy hiện tại có thể chạy nhanh bằng `bash run_game.sh`.
Chạy bằng terminal:

```bash
/home/luan/Downloads/Godot_v4.7.2-stable_linux.x86_64 --path game
```

WASD / phím mũi tên: đi · Shift: chạy · E: tương tác / tiếp tục hội thoại · J: đánh theo hướng nhìn · Chuột trái: đánh hướng con trỏ · H: uống thuốc · I: túi đồ · Q: nhật ký · F5: lưu · Esc: tạm dừng / quay lại · F11: toàn màn hình. Chuột và Tab / Enter điều khiển menu.

Phase 2: chọn **Hành trình mới**, trò chuyện xong với Rowan rồi tới cổng bắc và nhấn E. Theo đường đá lên vòng đá phía bắc rừng, hạ sinh vật canh giữ rồi E nhặt mảnh tinh thể. Theo đường xuống nam và E ở vòng sáng để về làng, báo tin cho Rowan để nhận thưởng. Q hiển thị từng mục tiêu. Khởi đầu có kiếm và ba thuốc; kẻ địch rơi quặng và thuốc, rừng có thảo dược và rương.

**Lưu là thủ công:** F5 hoặc Esc → Lưu hành trình. Một ô lưu và một bản dự phòng; Hành trình mới và Về menu không ghi đè bản lưu. **Tiếp tục bản lưu** chỉ bật khi bản chính hoặc dự phòng hợp lệ. Save nằm tại `user://journey.json` (Linux: `~/.local/share/godot/app_userdata/Dư Âm Thế Giới Lãng Quên/`). Chết sẽ hồi sinh ở làng, giữ đồ/tiến trình; bản lưu trên đĩa không tự đổi.

Phase 2 hoàn thành chặng thám hiểm của The First Echo. Lyra, sự kiện ký ức, Mira và các lựa chọn có hậu quả thuộc Phase 3; chưa phải bản chơi thử 20–40 phút. Chưa có audio hoặc bản export Windows.

Tài liệu và kết quả kiểm tra: [game/docs/PROGRESS.md](game/docs/PROGRESS.md).

Kiểm tra tự động: `bash game/tools/check.sh` (có thể đặt `GODOT_BIN` để dùng Godot ở đường dẫn khác). Chụp giao diện bằng Godot với `--path game --script res://tests/phase2_render.gd`; ảnh render thực nằm trong `game/tests/output/`. Test dùng save riêng có tên `phase2_*_only.json`, không chạm vào save người chơi. Không cần Python hoặc Pillow để chơi. Tạo lại toàn bộ asset bằng cách chạy lần lượt `python3 game/tools/generate_assets.py` và `python3 game/tools/generate_phase2_assets.py`.
# Project-G
