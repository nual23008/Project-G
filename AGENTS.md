# Quy tắc dự án — Dư Âm Thế Giới Lãng Quên

## Trước khi thay đổi
- Đọc `game/docs/PROGRESS.md` và `game/docs/ARCHITECTURE.md`.
- Giữ gameplay và save đang hoạt động; kiểm tra hồi quy khi đổi asset/animation/combat.

## Luật đồ họa và animation (yêu cầu người dùng, 2026-11-02)
- Mỗi **loại đối tượng nhìn thấy** phải có ảnh/sprite sheet và tài nguyên animation riêng được đăng ký trong `game/resources/art/manifest.json`. Không dùng một hình vuông hoặc một hình chung cho nhiều loại đối tượng.
- **Mọi đối tượng mới phải có animation riêng ngay cả khi đứng yên và không được tương tác** (yêu cầu bổ sung 2026-11-02). Trước khi đưa vào scene phải có idle/ambient loop với nhiều keyframe thật sự khác nhau, được game phát lúc chờ; không chấp nhận chỉ có ảnh tĩnh, chờ tương tác mới chuyển động hoặc dùng một hình lặp xuyên suốt loop để giả animation. Các hold giữ nhịp tự nhiên phải được ghi trung thực, không được tính là các hình khác nhau. Áp dụng cả vật phẩm, props, địa hình và thành phần UI nhìn thấy. Hiệu ứng chỉ tồn tại trong lúc phát phải có chuỗi play riêng; chữ/số HUD động vẫn được miễn sprite chữ.
- **Animation thêm mới phải đồng bộ và giữ đúng đồ họa của bộ animation hiện có của cùng đối tượng** (yêu cầu bổ sung 2026-11-02): cùng nhân dạng/silhouette, trang phục, chất liệu, bảng màu, hướng sáng, tỷ lệ, kích thước frame và pivot. Không ghép idle của một thiết kế với walk/attack của thiết kế khác. Khi thay toàn bộ đồ họa, các state phải chuyển cùng sang thiết kế mới. Quy tắc này giữ nhất quán giữa các state, không cho phép dùng lại bộ đồ họa cũ đã bị yêu cầu thay.
- Mỗi lần thêm đối tượng hoặc state: cập nhật manifest và tài nguyên → nối vào runtime → kiểm tra idle không tương tác, chuyển state/loop seam và timing → render/preview chuyển động → ghi kết quả vào PROGRESS. Frame contact của body/VFX/hitbox phải trùng tick damage; chân/pivot không nhảy khi đổi state. Animation môi trường cần nhịp phù hợp vật liệu, không bắt mọi instance rung cùng một pha.
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
