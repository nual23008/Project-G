# Hướng mỹ thuật — lần nâng cấp đầu tiên

Ảnh quán trọ người dùng cung cấp là tham chiếu màu, độ chi tiết và vật liệu. Giữ góc nhìn top-down để bảo toàn bản đồ/collision/save Phase 2; không chuyển toàn bộ game sang isometric trong lần sửa hình ảnh này.

## Bảng màu và vật liệu
Ánh sáng hổ phách #f0bc73, điểm sáng kem #f6e3b0; gỗ óc chó #614234 và nâu đỏ #925446; ngói rượu #793d48; bóng tối mận #332938; đá đất nung/kem #ad9474; cây xanh olive/emerald. Viền tối có sắc độ, không dùng đen thuần bao mọi vật. Ít nhiễu pixel ngẫu nhiên, ưu tiên mảng vật liệu có khối, chi tiết chốt gỗ, mép mái, cửa sáng và tán lá phân tầng.

## Quy tắc asset
Luật bắt buộc nằm ở [AGENTS.md](../../AGENTS.md). Mỗi loại có tài nguyên ảnh và SpriteFrames riêng; cùng loại chia sẻ file giữa các instance. Những vật cứng không bị co giãn khi idle. Ưu tiên chuyển động có nghĩa (lửa, khói, glint, lá), kết hợp sprite sheet tách riêng khỏi logic.

## Animation chém
Tách body animation và VFX chém khỏi hitbox. Chuỗi có anticipation → tăng tốc → contact → follow-through → tàn vệt. Sprite sheet có nhiều frame thực sự khác nhau, không chỉ đổi góc một đường cung. Pha contact giữ thời điểm sát thương Phase 2 để không phá cân bằng; mỗi swing gây hit một lần cho mỗi hurtbox. Hit sparks là asset riêng.

## Nguồn và kiểm tra
Lưu prompt/nguồn ImageGen trong `assets/art_v3/sources/` và tài liệu nguồn. Bộ hình cuối được đưa vào workspace, không tham chiếu đường dẫn cache hoặc ảnh tham khảo bên ngoài. Preview phải gồm cả world, inventory và dải frame chém/animation động. Chưa tuyên bố chất lượng tương đương một game thương mại chỉ vì đổi bảng màu.
