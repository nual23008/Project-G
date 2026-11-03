# Sửa giật di chuyển và hướng lưng — 2026-11-03

## Chẩn đoán

Người dùng xác nhận giật cả lúc đi bình thường. Đo trên Iris Xe, màn 1920×1200 / 143,89 Hz, scene có 1.249 node. Bản cũ giới hạn 60 FPS đồng thời VSync, viewport640×400 phóng3×, camera đọc vị trí trước Player trong tick rồi round xuống pixel logic. Mỗi bước camera trễ khoảng1,2px (P95 1,6px), hiển thị nền có bước3/6pixel trên màn hình. CPU render ~1ms và GPU ~0,6ms: chưa thiếu ngân sách render, vấn đề chính là nhịp trình bày và thứ tự camera.

Lượt baseline 347 frame/6giây: ~57,8FPS, P95 48,451ms (nội suy Type7). Thử chỉ bỏ cap trong cùng scene/root fullscreen đạt 756 frame/~6giây, ~125,9FPS, P95 8,847ms. Đây là thí nghiệm cô lập cap trước sửa camera. Lượt canvas thử riêng cho thấy GPU P95 ~3,226ms ở1920×1200, vẫn dưới budget144Hz. Các lượt cửa sổ bị che chỉ khoảng1FPS được đánh dấu invalid_foreground_run và không dùng để tuyên bố hiệu năng bản cuối. CSV/metadata gốc ở tests/output/movement-baseline*, movement-optimized*.

## Triển khai

- VSync giữ nhịp theo màn hình; bỏ cap60 cạnh tranh. Canvas Items/nearest cho chuyển động theo pixel màn hình thay vì nhảy theo pixel logic phóng lớn; không bật global transform snapping. Sprite và mọi lớp trang bị vẫn Nearest, giữ ảnh và pivot.
- Physics vẫn60Hz. World chạy physics sau Player, lấy previous/current position rồi nội suy khi render bằng Engine.get_physics_interpolation_fraction. Camera tắt nội suy riêng để tránh blend hai lần, force_update_scroll sau cập nhật; clamp/zoom vẫn do Camera2D. Node2D của engine này không có get_global_transform_interpolated, nên dùng cặp mẫu vị trí thật.
- Snap/reset cả lịch sử Player và camera khi spawn, load, travel, pause/resume; không blend từ gốc hoặc vùng cũ. Bụi/VFX reset interpolation khi spawn. Lá/đom đóm cập nhật float mỗi render, tắt physics interpolation riêng thay vì round từng bước.
- EquipmentVisual đổi texture/frame theo signal animation_changed/frame_changed, không ép13layer mỗi render. Loadout giữ nguyên thì không nạp/gán lại toàn bộ resource; thay một món chỉ cập nhật lớp đó. Modulate chỉ gán khi tint đổi. Các lớp lấy đúng frame clock; progress của lớp đang pause không dùng để blend hình.

## Lỗi quay lưng

Nguồn native từng vẽ mặt trước torso/áo/dây chuyền ở mọi hướng, chỉ đầu thay hướng. Nay up/up_left/up_right có cổ sau, đường may lưng, thắt lưng không khóa trước, khăn sau dạng dải thay yếm chữV, túi ở đúng hông sau, phần dây/clasp tại gáy thay mặt dây chuyền, gót giày và mu bàn tay. Hai hướng ngang thu gọn torso và chuyển chi tiết về phía mặt trước cơ thể. Mọi state idle/walk/attack/hurt/death của cùng món đổi đồng bộ, giữ nhân dạng/palette/frame96×64/pivot48,60/contact frame2. Manifest ghi direction/body_view.

Walk mỗi hướng có sáu hình thật với contact/compression/passing thay cho các hold lặp làm bước bị khựng; số frame/FPS và tốc độ72/112px/s không đổi. Không thêm item/save schema, không đổi damage/cooldown/mana.

## Nghiệm thu

Bộ test mới đo camera ở sau physics và viewport canvas transform thực, kiểm tám hướng, reset teleport, pause, clamp biên, travel/save/load. Native art kiểm tính liền thân/từng gear, chân/cổ idle, sáu hình walk và cấm V ngực/khóa trước/pendant/yếm khăn trên lưng. Kết quả cuối và preview ghi ở PROGRESS.

### Lượt đo render cuối

Bài đo cửa sổ thực1280×763 với cap144 và VSync tắt **chỉ ở lệnh QA** đạt782frame/~6giây (~130,3FPS), P95 frame7,325ms, CPU render P95 1,000ms, GPU P95 1,515ms, xử lý node P95 0,121ms. Camera screen-center error đo từ Camera2D thực bằng0; có445mẫu render tiếp tục tiến giữa hai physics tick. Đây là kiểm ngân sách/render-interpolation, không phải cam kết FPS fullscreen/VSync của mọi máy. VSync trong bản game vẫn bật; số đo nền chỉ5frame/6giây bị loại.

Lệnh tái tạo: Godot windowed `--disable-vsync --path game --script res://tests/movement_profile.gd -- --tag=render-budget --fps=144`. Script tạo cửa sổ1280×800 (WM cấp client1280×763 trên máy này), warm-up tối đa2giây, đo6giây, không chụp/readback ảnh trong khoảng đo. Muốn đo VSync thực: bỏ disable-vsync/fps và giữ cửa sổ hiển thị; dùng `--wait-focus` để chờ focus. CSV/JSON [benchmark review](../tests/output/movement-performance-review.json). Chưa profile GPU4K hoặc thiết bị khác.

### Xác nhận cuối khi người dùng giữ cửa sổ hiển thị

Lượt cửa sổ1280×763 đạt~129,20FPS, P95 7,259ms; VSync1 và max_fps0 đúng bản game, không disable-vsync. Sau đó đo fullscreen **1920×1200** như baseline:754frame/~6giây, **~125,55FPS**, P95 **8,744ms**, camera screen-center error0. Baseline cùng máy/kích thước/node1249:~57,79FPS, P95 48,451ms (nội suy Type7). Đây là so sánh trước/sau trên máy Iris Xe /143,89Hz hiện tại, không cam kết cùng FPS ở mọi thiết bị. Tất cả mẫu occluded bị loại; dữ liệu fullscreen cuối có trong movement-foreground-fullscreen.csv/json và movement-performance-review.json. Lệnh: Godot `--path game --script res://tests/movement_profile.gd -- --tag=foreground-fullscreen --fullscreen-run --user-visible`, giữ cửa sổ phía trước cho đến khi tự đóng. Các số đo budget tắt VSync bên trên chỉ là chẩn đoán phụ.

Phân vị trong bảng cuối dùng cùng thuật toán Type7 (nội suy trên dãy đã sắp tại(n−1)×p). Thông báo sơ bộ lấy mẫu gần dưới nên baseline P95 29,116ms; với khoảng trống lớn đúng ngưỡng95%, nội suy chuẩn cho48,451ms. FPS tính từ mean không đổi; CSV gốc giữ nguyên. Không trộn hai định nghĩa trong so sánh cuối.

Bản cuối: check.sh5.343 assertions Godot +5.437 kiểm rig/views +5launcher; loop40/40; import và log renderer không lỗi. 546capture chính +70body-only (64mẫu mới),616ảnh unique/contact qua image_checks; đã xem front/back đủ3hướng lên, tám hướng đi/chém/chết và body trần. Guard5.032frame actor; registry67loại/755state/5.590lượt frame. Rebuild135file cùng hash. Cold launcher sạch; primary/backup không đổi. [Ảnh front/back](../tests/output/movement-rear-view.png), [motion](../tests/output/movement-rear-walk.gif), [rig](../tests/output/equipment-rig-review.json), [camera suite](../tests/output/movement-presentation.log), [renderer](../tests/output/equipment-render-review.json), [cold launch](../tests/output/movement-cold-launch-review.json).
