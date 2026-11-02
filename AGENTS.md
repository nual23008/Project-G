# Quy tắc dự án — Dư Âm Thế Giới Lãng Quên

## Trước khi thay đổi
- Đọc `game/docs/PROGRESS.md` và `game/docs/ARCHITECTURE.md`.
- Giữ gameplay và save đang hoạt động; kiểm tra hồi quy khi đổi asset/animation/combat.

## Luật đồ họa và animation (yêu cầu người dùng, 2026-11-02)
- Mỗi **loại đối tượng nhìn thấy** phải có ảnh/sprite sheet và tài nguyên animation riêng được đăng ký trong `game/resources/art/manifest.json`. Không dùng một hình vuông hoặc một hình chung cho nhiều loại đối tượng.
- Áp dụng cho nhân vật, NPC, kẻ địch, vật phẩm, cây, nhà, đá, nước, đèn, rương, cổng và hiệu ứng. Các instance cùng loại được dùng chung asset để tiết kiệm bộ nhớ; biến thể có thiết kế khác phải có asset riêng.
- Nhân vật có idle/walk/attack/hurt/death khi hành vi đó tồn tại. Đòn chém và hiệu ứng trúng đòn có sprite sheet riêng, không thay bằng cung tròn vẽ tức thời. Đồng bộ frame gây sát thương với pha tiếp xúc.
- Animation môi trường phải phù hợp vật liệu: tán lá lay, lửa lập lòe, nước gợn, cửa sổ/khói nhà, glint rất nhẹ trên đá. Không kéo giãn toàn bộ nhà/đá để giả chuyển động; không lặp cùng một frame rồi gọi là animation.
- Vật phẩm dùng icon riêng và vòng animation riêng; UI có tài nguyên hình nền/trạng thái riêng. Chữ và giá trị HUD động không cần sprite chữ riêng.
- Phong cách hiện tại: fantasy pixel art chi tiết, ánh hổ phách ấm, gỗ nâu, đỏ rượu, bóng tím mận, đá kem; giữ sự tương phản với rừng. Ảnh người dùng là tham chiếu màu/vật liệu, không phân phối logo hoặc cắt nội dung ảnh đó vào game.
- Mỗi asset mới cần ghi nguồn, kích thước frame, pivot, số frame, FPS/loop/state trong manifest/tài nguyên; resource phải được game sử dụng thực sự. Có ảnh và preview animation để kiểm tra.
- Mọi trường hợp chưa có asset/animation đạt yêu cầu phải ghi rõ trong PROGRESS; không đánh dấu hoàn tất bằng placeholder hoặc hình tĩnh nhiều frame trùng nhau.

## Nghiệm thu
- Godot import không có lỗi; chạy các bộ kiểm tra trong `game/tools/check.sh`.
- Khi sửa hình ảnh, chạy render thật và xem ảnh. Khi sửa animation, kiểm tra sprite sheet/timing và preview chuyển động, không chỉ một screenshot.
