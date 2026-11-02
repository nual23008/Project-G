# Dư Âm Thế Giới Lãng Quên — thiết kế

## Bản đang chơi — Phase 2
Vòng lõi đã triển khai: Rowan mở cổng sau khi nói chuyện xong → dùng portal E vào rừng → tìm vòng đá → đánh guardian → nhặt mảnh dư âm → quay về báo tin → nhận 2 thuốc + 3 quặng. Journal theo dõi mục tiêu thực và thưởng chỉ nhận một lần. Mảnh dư âm được giữ làm vật phẩm quest cho chặng Lyra sau này.

Player 100 HP, đi 72/chạy 112 px/s, kiếm 18 sát thương, cooldown 0.44 s; hit immunity 0.5 s. Enemy một loại 54 HP, 14 sát thương, phát hiện 112 px, leash 180 px, báo đòn 0.42 s và cooldown 1.15 s. Ba cá thể bố trí có chủ đích trong rừng, không respawn sau khi chết; trạng thái và đồ rơi được lưu. Có ba thuốc ban đầu, thuốc hồi 40 HP, không dùng khi đầy hoặc đã chết. Người chơi chết trở lại làng, giữ đồ và tiến trình.

16 ô túi, item stack hữu hạn, kiếm/thuốc/lá sương/quặng/mảnh dư âm. Tài nguyên chưa dùng chế tạo; equipment và crafting dành cho giai đoạn sau. Một ô lưu thủ công + backup; New Game không xóa save cho tới khi người chơi chủ động lưu phiên mới.

Các đoạn dưới đây giữ thiết kế định hướng và phạm vi Phase 1 ban đầu; lộ trình các chương vẫn chưa phải nội dung đã hoàn thành. Phân nhánh hiện tại của Rowan chỉ hỏi thông tin; chưa quảng cáo hậu quả lựa chọn hoặc kết thúc truyện đã chơi được.

## Trải nghiệm và phạm vi
Một nhà thám hiểm mang tinh thể ký ức tỉnh dậy ở Aetheria sau Đêm Lặng. Khám phá yên tĩnh xen kẽ chiến đấu có nhịp, tìm lại lịch sử và chịu trách nhiệm cho cách sử dụng nó. Chỉ xây Phase 1 trong lần đầu; không coi bản nền tảng là vertical slice 20–40 phút.

Phase 1 là một khu làng nhỏ 64×48 tile (16 px), nội bộ 640×360, chơi đơn, tiếng Việt. Đi lại tám hướng, chạy, vật cản, camera, Rowan, thoại nhiều bước, menu chính, tạm dừng và cài đặt. Không triển khai nút hay hệ thống giả cho inventory, chiến đấu, quest hoặc Continue. Continue chỉ được thêm khi save/load thực sự tồn tại.

Ảnh người dùng cung cấp là tham chiếu màu sắc/không khí: rừng xanh sẫm nhiều tầng, đường đá rêu, ánh vàng. Asset được vẽ mới bằng script, không cắt hoặc phân phối lại ảnh tham chiếu. Làng ấm hơn rừng, đường dẫn tới quảng trường dễ nhận biết, có hồ, nhà, vườn và cổng rừng đóng.

## Nhịp mở đầu dự kiến
Thức dậy → Rowan → Rừng Thì Thầm → mảnh tinh thể → sinh vật canh giữ → về làng → Lyra → ký ức đầu tiên. Rowan vừa muốn bảo vệ dân làng vừa sợ công nghệ gây ra thảm họa lần nữa. Lyra tìm bằng chứng để sửa hệ thống. Kael muốn công nghệ phục vụ cuộc sống hằng ngày. Mira tìm em trai mất tích, chống lại cách coi con người như dữ liệu.

Phase 1 kết thúc ở lời nhắn của Rowan và mục tiêu khám phá làng; lời thoại không hứa rằng rừng hoặc nhiệm vụ đã chơi được. Lựa chọn hỏi thêm về làng/tinh thể là thông tin, không được quảng cáo là phân nhánh có hậu quả.

## Nhiệm vụ và lựa chọn cho Phase 2–3
The First Echo: trạng thái locked/available/active/completed/failed; mục tiêu talk/visit/collect/defeat/interact/choice/secret. Dữ liệu riêng, signal theo sự kiện gameplay, phần thưởng chỉ nhận một lần.

Mira: tìm thẻ ký ức của em trai trong tàn tích. Trả thẻ cho Mira sẽ tăng lòng tin, mở đường bí mật cùng một người dẫn đường; trao Lyra để giải mã sẽ mở thông tin công nghệ nhưng Mira đóng tuyến trợ giúp cho tới khi bồi thường. Cả hai nhánh phải tác động nội dung chơi được trước khi công bố hoàn thành.

## Năm chương và kết thúc dự kiến
1. Khởi đầu: Dawn Village, Rừng Thì Thầm và ký ức đầu tiên.
2. Những vùng đất lãng quên: Crystal Lake/Hollow Caverns, phe Bảo Tồn và Cộng Sinh, tích lũy quan hệ và mảnh ký ức.
3. Sự thật bị che giấu: Forgotten Ruins; Đêm Lặng là ngắt mạng khẩn cấp để ngăn khai thác ký ức con người.
4. Xung đột: Ashen Mountains; lựa chọn phân phối mảnh tinh thể quyết định đồng minh, các tuyến đường và nhiệm vụ bị khóa.
5. Lựa chọn cuối: khôi phục (cần quyền truy cập cùng phe Bảo Tồn), phá hủy (cần giải cứu các cộng đồng phụ thuộc), hoặc cộng sinh (cần Lyra, Mira và dữ liệu sinh thái). Các điều kiện phải được chơi và lưu, không chỉ là ba nút ở cuối.

## Tiêu chí Phase 1
- Mở game tới menu, chuột/Tab/Enter chọn hành trình mới.
- Đi WASD/mũi tên, tốc độ chéo bằng thẳng, Shift nhanh hơn; không đi xuyên nhà, nước, cây, NPC và biên.
- Camera bám trong biên map, pixel sắc ở hệ số nguyên và không lộ ngoài map.
- Tới gần Rowan: E chỉ chọn đối tượng gần nhất trong tầm, thoại Unicode, bỏ qua hiệu ứng chữ, tiếp tục, đóng.
- Thoại hoặc menu khóa di chuyển; Esc tạm dừng và trở về menu; bắt đầu mới reset phiên.
- Parse/import sạch, kiểm tra logic và kiểm tra render thực tế được ghi riêng trong PROGRESS.
