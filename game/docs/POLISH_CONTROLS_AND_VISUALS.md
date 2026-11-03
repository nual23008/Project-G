# Điều khiển, màn hình và đồ họa — 2026-11-03

## Phân tích và triển khai

| Yêu cầu | Kết quả |
|---|---|
| Chuột đơ khi giữ phím đi | Máy GNOME/Wayland đang bật `disable-while-typing=true`. Game không có capture/warp chuột. Tạm tắt typing guard trong vòng đời game, khôi phục preference khi thoát; giữ mouse Visible. |
| Toàn màn hình | Mặc định mode3; viewport640×360, stretch expand/integer, nearest. Mở rộng vùng nhìn theo tỷ lệ màn hình; HUD neo cạnh, overlay ở giữa. |
| Zoom | Con lăn75/100/125/150/200%; nút−/+/100% trong cài đặt. Camera thay đổi, HUD giữ cỡ. Giới hạn nhỏ nhất theo map/viewport tránh lộ khoảng trống; giữ mức khi đổi vùng trong phiên. |
| Gom chức năng vào E | E mở Túi đồ / Nâng điểm / Nhiệm vụ / Hệ thống; dùng vật phẩm, phân bổ7chỉ số theo batch1/5/10/100, xem quest, lưu/tải/cài đặt/về menu. E/Esc đóng; E trong hội thoại vẫn tiếp lời. |
| Tương tác sau khi đổi E | Chuột phải gần đối tượng hợp lệ để tương tác; khi không có đối tượng thì chém cường hóa theo chuột. F dự phòng. I/C/Q/J/R/H/F5 vẫn tương thích, không cần nhớ để dùng các chức năng chính. |
| Nâng hình ảnh | Bóng tiếp đất đồng bộ mọi state/hướng, bụi chân play riêng, slash thường/cường hóa có lõi/dư ảnh/flare, lá rơi ambient, cụm cỏ/khe đá/gợn nước mới. Giữ hero và palette hiện tại. |

## Mouse và desktop

`scripts/core/desktop_pointer.gd` chỉ chạy Linux/GNOME có gsettings; bỏ qua headless và job `--script`. Đọc preference trước, chỉ ghi false nếu trước đó true, chỉ khôi phục khi chính nó đã thay. Không gọi lệnh trong physics/process. `run_game.sh` bảo vệ bên ngoài engine, khôi phục cả exit lỗi hoặc SIGTERM/INT/HUP; helper không nhận quyền restore khi launcher đã đặt false.

Đã thử process Godot native: **true→false→true**, exit0, polling CLI trong lúc game sống; `tests/output/polish-pointer-native-review.json`. Đây là kiểm preference và input engine, chưa phải kiểm touchpad vật lý bằng tay. Phiên game cũ không bị dừng/ghi save; cần khởi động lại để nhận mã mới.

## Asset và animation

Chỉnh generator native hiện tại; không gọi paid API hoặc đổi nhân dạng. Player96×64/pivot48,60 cho cả40state; bóng nằm trong ground line60. Body/FX/hitbox contact vẫnframe2, physics tick0,1s cho ngưỡng0,084s; damage/cost/cooldown/collision giữ nguyên.

Actors bake bóng; UI/VFX và progression generator nâng hai slash; world generator dựng lại cỏ/đá/nước/atlas đường, giữ hợp đồng phase. Nhóm thứ6 `build_polish_art.py` thêm:

| ID | Frame/pivot | Clip | Nguồn và runtime |
|---|---|---|---|
| footstep_dust |24×16 /12,12|play8@24FPS,8hình, không loop|Grid `sources/props/footstep_dust`; phát mỗi12px đi/16px chạy thật, không phát khi bị chặn hoàn toàn, tự hủy.|
| falling_leaf |16×16 /8,8|idle8@8FPS,6hình khác/2hold|Grid `sources/props/falling_leaf`;16instance trong Atmosphere, lệch frame/tốc độ/pha, drift và tumble.|

PNG/source grid/SpriteFrames/manifest nối vào game; **42loại/97state/710lượt frame**. Giữ holds trung thực. Build tổng chạy6nhóm rồi merge; không mất asset mới khi dựng lại.

## Nghiệm thu

- `bash game/tools/check.sh`: import; launcher5test; suite hub/mouse/zoom/layout; tám hướng; progression model/combat/UI/integration; art; làng/RPG/journey. Test dùng save riêng, không đổi schema v2 hoặc primary.
- Hub suite gửi E/echo/mouse qua engine, kiểm HP/điểm/potion/save, pause, context right-click, zoom clamp/UI isolation; giữ phím đi khi chuyển con trỏ/click chém; bụi sinh/hủy. Matrix1280×720,1366×768,1920×1200,2560×1080.
- Renderer Intel Iris Xe/Compatibility: **87capture** =15ảnh cảnh/UI +36walk30Hz +18slash và18empowered60Hz. Wayland giới hạn cửa sổ vật lý nên matrix dùng Godot SubViewport640×360,683×384,640×400,854×360 để kiểm góc nhìn/UI16:9/16:10/21:9; không nhận đó là phần cứng21:9.
- Đã xem world, bốn tab, settings, ultrawide/stats và dải chuyển động. `gd_review.image_checks`:13/13ảnh đạt; source clips có nhiều hình thực, holds được đếm riêng.
- [GIF chuyển động/chém](../tests/output/polish-motion.gif), [màn rộng](../tests/output/polish/wide_2560x1080.png), [nâng điểm](../tests/output/polish/hub_1.png), [matrix](../tests/output/polish-render-review.json), [animation review](../tests/output/polish-animation-review.json), [image review](../tests/output/polish-image-review.json).

Zoom giữ trong phiên, chưa lưu qua các lần mở game. Không thêm cây ability mới hoặc mở rộng map. Không tuyên bố đã playtest tay dài/gamepad/Windows.
