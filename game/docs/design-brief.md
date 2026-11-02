# Giai đoạn hiện tại — bản chơi mở đầu

Một RPG khám phá nơi người lữ hành trò chuyện với Rowan ở Làng Bình Minh, nhận việc tìm dư âm và trở về báo tin.

Vòng chơi đầu: đi quanh quảng trường → đến gần Rowan → E để nói chuyện → nhận nhiệm vụ trong nhật ký. Bản hiện hữu còn có chặng rừng: qua cổng → đánh guardian → nhặt mảnh dư âm → trở về nhận thưởng một lần. Đợt củng cố này giữ nội dung đó và save version 1, không thêm vùng hoặc chương truyện.

| Hành động | Phím | Hoạt ảnh |
|---|---|---|
| Đi tám hướng | WASD / mũi tên | idle/walk bốn hướng nhìn, chuyển động chéo chuẩn hóa |
| Chạy | Shift + di chuyển | walk tăng tốc |
| Tương tác / tiếp lời | E / Enter | idle; cửa sổ thoại dừng thế giới |
| Chém | J / chuột trái | attack, sword_slash; contact cùng tick sát thương |
| Dùng thuốc | H | icon thuốc riêng |
| Túi / nhật ký | I / Q | panel, button và trạng thái riêng |
| Lưu / tạm dừng | F5 / Esc | HUD/menu |

Giới hạn: 2 vùng nhỏ hiện có, 1 NPC truyện, 1 nhiệm vụ, 1 loại địch (3 cá thể), 5 loại vật phẩm, 16 ô túi. Không thêm chế tạo, boss, multiplayer, bản đồ vô hạn hay NPC mới trong đợt này. Danh sách asset chính xác ở [asset-manifest.md](asset-manifest.md) và [manifest.json](../resources/art/manifest.json).

| Tham số | Giá trị giữ nguyên | Mục đích |
|---|---|---|
| Tile / viewport | 16 px / 640×360 | nearest, integer scale |
| Đi / chạy | 72 / 112 px/s | tốc độ chéo bằng thẳng |
| Tương tác | 42 px + raycast | không nói xuyên vật cản |
| HP / kiếm | 100 / 18 damage | giữ cân bằng đã kiểm tra |
| Swing / windup | .24 s / 35% | contact ở bước physics vượt windup |
| Physics / render cap | 60 Hz / 60 FPS | đo trên máy hiện tại |

Đạt bản mở đầu khi menu → di chuyển tám hướng → Rowan → nhận việc chạy được, UI khóa đúng input, collision/camera ổn định và save cũ còn tải được. Chặng rừng thắng khi báo tin và nhận thưởng đúng một lần. Chết hồi sinh ở làng, giữ đồ và tiến trình, không tự ghi đè save. Đây là lát cắt ngắn chơi trong một phiên, chưa phải open world hoàn chỉnh hoặc nội dung 20–40 phút.
